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

import 'dkd/proc.dart';
import 'core/processor.dart';

import 'facebook.dart';
import 'messenger.dart';
import 'twins.dart';


abstract class MessageProcessor extends TwinsHelper implements Processor {
  MessageProcessor(Facebook facebook, Messenger messenger)
      : super(facebook, messenger) {
    factory = createFactory(facebook, messenger);
  }

  /// CPU factory
  // private
  late final ContentProcessorFactory factory;

  // protected
  ContentProcessorFactory createFactory(Facebook facebook, Messenger messenger);

  //
  //  Processing Message
  //

  @override
  Future<List<Uint8List>> processPackage(Uint8List data) async {
    Messenger? transceiver = messenger;
    assert(transceiver != null, 'messenger not ready');
    // 1. deserialize message
    ReliableMessage? rMsg = await transceiver?.deserializeMessage(data);
    if (rMsg == null) {
      // no valid message received
      return [];
    }
    // 2. process message
    List<ReliableMessage> responses = await transceiver!.processReliableMessage(rMsg);
    if (responses.isEmpty) {
      // nothing to respond
      return [];
    }
    // 3. serialize responses
    List<Uint8List> packages = [];
    Uint8List? pack;
    for (ReliableMessage res in responses) {
      pack = await transceiver.serializeMessage(res);
      if (pack == null) {
        // should not happen
        continue;
      }
      packages.add(pack);
    }
    return packages;
  }

  @override
  Future<List<ReliableMessage>> processReliableMessage(ReliableMessage rMsg) async {
    // TODO: override to check broadcast message before calling it
    Messenger? transceiver = messenger;
    assert(transceiver != null, 'messenger not ready');
    // 1. verify message
    SecureMessage? sMsg = await transceiver?.verifyMessage(rMsg);
    if (sMsg == null) {
      // TODO: suspend and waiting for sender's meta if not exists
      return [];
    }
    // 2. process message
    List<SecureMessage> responses = await transceiver!.processSecureMessage(sMsg, rMsg);
    if (responses.isEmpty) {
      // nothing to respond
      return [];
    }
    // 3. sign responses
    List<ReliableMessage> messages = [];
    ReliableMessage? msg;
    for (SecureMessage res in responses) {
      msg = await transceiver.signMessage(res);
      if (msg == null) {
        // should not happen
        continue;
      }
      messages.add(msg);
    }
    return messages;
    // TODO: override to deliver to the receiver when catch exception "receiver error ..."
  }

  @override
  Future<List<SecureMessage>> processSecureMessage(SecureMessage sMsg, ReliableMessage rMsg) async {
    Messenger? transceiver = messenger;
    assert(transceiver != null, 'messenger not ready');
    // 1. decrypt message
    InstantMessage? iMsg = await transceiver?.decryptMessage(sMsg);
    if (iMsg == null) {
      // cannot decrypt this message, not for you?
      // delivering message to other receiver?
      return [];
    }
    // 2. process message
    List<InstantMessage> responses = await transceiver!.processInstantMessage(iMsg, rMsg);
    if (responses.isEmpty) {
      // nothing to respond
      return [];
    }
    // 3. encrypt responses
    List<SecureMessage> messages = [];
    SecureMessage? msg;
    for (InstantMessage res in responses) {
      msg = await transceiver.encryptMessage(res);
      if (msg == null) {
        // should not happen
        continue;
      }
      messages.add(msg);
    }
    return messages;
  }

  @override
  Future<List<InstantMessage>> processInstantMessage(InstantMessage iMsg, ReliableMessage rMsg) async {
    Messenger? transceiver = messenger;
    assert(facebook != null && transceiver != null, 'twins not ready');
    // 1. process content
    List<Content>? responses = await transceiver?.processContent(iMsg.content, rMsg);
    if (responses == null || responses.isEmpty) {
      // nothing to respond
      return [];
    }
    // 2. select a local user to build message
    ID sender = iMsg.sender;
    ID receiver = iMsg.receiver;
    ID? me = await facebook?.selectLocalUser(receiver);
    if (me == null) {
      assert(false, 'receiver error: $receiver');
      return [];
    }
    // 3. pack messages
    List<InstantMessage> messages = [];
    Envelope env;
    for (Content res in responses) {
      // assert(res.isNotEmpty, 'should not happen');
      env = Envelope.create(sender: me, receiver: sender);
      iMsg = InstantMessage.create(env, res);
      // assert(iMsg.isNotEmpty, 'should not happen');
      messages.add(iMsg);
    }
    return messages;
  }

  @override
  Future<List<Content>> processContent(Content content, ReliableMessage rMsg) async {
    // TODO: override to check group
    ContentProcessor? cpu = factory.getContentProcessor(content);
    if (cpu == null) {
      // default content processor
      cpu = factory.getContentProcessorForType(ContentType.ANY);
      assert(cpu != null, 'failed to get default CPU');
    }
    return await cpu!.processContent(content, rMsg);
    // TODO: override to filter the responses
  }

}
