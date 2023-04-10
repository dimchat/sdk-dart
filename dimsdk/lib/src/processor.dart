/* license: https://mit-license.org
 *
 *  DIM-SDK : Decentralized Instant Messaging Software Development Kit
 *
 *                               Written in 2023 by Moky <albert.moky@gmail.com>
 *
 * =============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2023 Albert Moky
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 * =============================================================================
 */
import 'dart:typed_data';

import 'package:dimp/dimp.dart';

import 'core/twins.dart';
import 'cpu/base.dart';
import 'cpu/content.dart';
import 'messenger.dart';

class MessageProcessor extends TwinsHelper implements Processor {
  MessageProcessor(super.facebook, super.messenger) {
    _factory = createFactory();
  }

  late final ContentProcessorFactory _factory;

  // protected
  ContentProcessorFactory createFactory()
  => BaseContentProcessorFactory(facebook!, messenger!, createCreator());

  // protected
  ContentProcessorCreator createCreator()
  /// override for creating customized CPUs
  => BaseContentProcessorCreator(facebook!, messenger!);

  ContentProcessor? getProcessor(Content content) {
    return _factory.getProcessor(content);
  }
  ContentProcessor? getContentProcessor(int msgType) {
    return _factory.getContentProcessor(msgType);
  }
  ContentProcessor? getCommandProcessor(int msgType, String cmd) {
    return _factory.getCommandProcessor(msgType, cmd);
  }

  @override
  Future<List<Uint8List>> processPackage(Uint8List data) async {
    Messenger transceiver = messenger!;
    // 1. deserialize message
    ReliableMessage? rMsg = await transceiver.deserializeMessage(data);
    if (rMsg == null) {
      // no valid message received
      return [];
    }
    // 2. process message
    List<ReliableMessage> responses = await transceiver.processReliableMessage(rMsg);
    if (responses.isEmpty) {
      // nothing to respond
      return [];
    }
    // 3. serialize responses
    List<Uint8List> packages = [];
    Uint8List pack;
    for (ReliableMessage res in responses) {
      pack = await transceiver.serializeMessage(res);
      assert(pack.isNotEmpty, 'should not happen');
      packages.add(pack);
    }
    return packages;
  }

  @override
  Future<List<ReliableMessage>> processReliableMessage(ReliableMessage rMsg) async {
    // TODO: override to check broadcast message before calling it
    Messenger transceiver = messenger!;
    // 1. verify message
    SecureMessage? sMsg = await transceiver.verifyMessage(rMsg);
    if (sMsg == null) {
      // TODO: suspend and waiting for sender's meta if not exists
      return [];
    }
    // 2. process message
    List<SecureMessage> responses = await transceiver.processSecureMessage(sMsg, rMsg);
    if (responses.isEmpty) {
      // nothing to respond
      return [];
    }
    // 3. sign responses
    List<ReliableMessage> messages = [];
    ReliableMessage msg;
    for (SecureMessage res in responses) {
      msg = await transceiver.signMessage(res);
      assert(msg.isNotEmpty, 'should not happen');
      messages.add(msg);
    }
    return messages;
    // TODO: override to deliver to the receiver when catch exception "receiver error ..."
  }

  @override
  Future<List<SecureMessage>> processSecureMessage(SecureMessage sMsg, ReliableMessage rMsg) async {
    Messenger transceiver = messenger!;
    // 1. decrypt message
    InstantMessage? iMsg = await transceiver.decryptMessage(sMsg);
    if (iMsg == null) {
      // cannot decrypt this message, not for you?
      // delivering message to other receiver?
      return [];
    }
    // 2. process message
    List<InstantMessage> responses = await transceiver.processInstantMessage(iMsg, rMsg);
    if (responses.isEmpty) {
      // nothing to respond
      return [];
    }
    // 3. encrypt responses
    List<SecureMessage> messages = [];
    SecureMessage msg;
    for (InstantMessage res in responses) {
      msg = await transceiver.encryptMessage(res);
      assert(msg.isNotEmpty, 'should not happen');
      messages.add(msg);
    }
    return messages;
  }

  @override
  Future<List<InstantMessage>> processInstantMessage(InstantMessage iMsg, ReliableMessage rMsg) async {
    Messenger transceiver = messenger!;
    // 1. process content
    List<Content> responses = await transceiver.processContent(iMsg.content, rMsg);
    if (responses.isEmpty) {
      // nothing to respond
      return [];
    }
    // 2. select a local user to build message
    ID sender = iMsg.sender;
    ID receiver = iMsg.receiver;
    User? user = await facebook?.selectLocalUser(receiver);
    if (user == null) {
      assert(false, 'receiver error: $receiver');
      return [];
    }
    // 3. pack messages
    List<InstantMessage> messages = [];
    Envelope env;
    for (Content res in responses) {
      // assert(res.isNotEmpty, 'should not happen');
      env = Envelope.create(sender: user.identifier, receiver: sender);
      iMsg = InstantMessage.create(env, res);
      // assert(iMsg.isNotEmpty, 'should not happen');
      messages.add(iMsg);
    }
    return messages;
  }

  @override
  Future<List<Content>> processContent(Content content, ReliableMessage rMsg) async {
    // TODO: override to check group
    ContentProcessor? cpu = getProcessor(content);
    if (cpu == null) {
      // default content processor
      cpu = getContentProcessor(0);
      assert(cpu != null, 'failed to get default CPU');
    }
    return cpu!.processContent(content, rMsg);
    // TODO: override to filter the responses
  }

}
