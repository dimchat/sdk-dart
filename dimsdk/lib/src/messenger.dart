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

abstract class CipherKeyDelegate {

  ///  Get cipher key for encrypt message from 'sender' to 'receiver'
  ///
  /// @param sender - from where (user or contact ID)
  /// @param receiver - to where (contact or user/group ID)
  /// @param generate - generate when key not exists
  /// @return cipher key
  Future<SymmetricKey?> getCipherKey(ID sender, ID receiver,
      {bool generate = false});

  ///  Cache cipher key for reusing, with the direction ('sender' => 'receiver')
  ///
  /// @param sender - from where (user or contact ID)
  /// @param receiver - to where (contact or user/group ID)
  /// @param key - cipher key
  Future<void> cacheCipherKey(ID sender, ID receiver, SymmetricKey? key);

}


abstract class Messenger extends Transceiver implements CipherKeyDelegate,
                                                        Packer, Processor {

  // protected
  CipherKeyDelegate? get cipherKeyDelegate;

  // protected
  Packer? get packer;

  // protected
  Processor? get processor;

  //
  //  Interfaces for Cipher Key
  //

  @override
  Future<SymmetricKey?> getCipherKey(ID sender, ID receiver,
      {bool generate = false}) async =>
      await cipherKeyDelegate?.getCipherKey(sender, receiver, generate: generate);

  @override
  Future<void> cacheCipherKey(ID sender, ID receiver,
      SymmetricKey? key) async =>
      await cipherKeyDelegate!.cacheCipherKey(sender, receiver, key);

  //
  //  Interfaces for Packing Message
  //

  @override
  Future<ID?> getOvertGroup(Content content) async =>
      await packer?.getOvertGroup(content);

  @override
  Future<SecureMessage> encryptMessage(InstantMessage iMsg) async =>
      await packer!.encryptMessage(iMsg);

  @override
  Future<ReliableMessage> signMessage(SecureMessage sMsg) async =>
      await packer!.signMessage(sMsg);

  @override
  Future<Uint8List> serializeMessage(ReliableMessage rMsg) async =>
      await packer!.serializeMessage(rMsg);

  @override
  Future<ReliableMessage?> deserializeMessage(Uint8List data) async =>
      await packer?.deserializeMessage(data);

  @override
  Future<SecureMessage?> verifyMessage(ReliableMessage rMsg) async =>
      await packer?.verifyMessage(rMsg);

  @override
  Future<InstantMessage?> decryptMessage(SecureMessage sMsg) async =>
      await packer?.decryptMessage(sMsg);

  //
  //  Interfaces for Processing Message
  //

  @override
  Future<List<Uint8List>> processPackage(Uint8List data) async =>
      await processor!.processPackage(data);

  @override
  Future<List<ReliableMessage>> processReliableMessage(ReliableMessage rMsg) async =>
      await processor!.processReliableMessage(rMsg);

  @override
  Future<List<SecureMessage>> processSecureMessage(SecureMessage sMsg,
      ReliableMessage rMsg) async =>
      await processor!.processSecureMessage(sMsg, rMsg);

  @override
  Future<List<InstantMessage>> processInstantMessage(InstantMessage iMsg,
      ReliableMessage rMsg) async =>
      await processor!.processInstantMessage(iMsg, rMsg);

  @override
  Future<List<Content>> processContent(Content content,
      ReliableMessage rMsg) async =>
      await processor!.processContent(content, rMsg);

  //-------- SecureMessageDelegate

  @override
  Future<SymmetricKey?> deserializeKey(Uint8List? key, ID sender, ID receiver,
      SecureMessage sMsg) async {
    if (key == null) {
      // get key from cache
      return await getCipherKey(sender, receiver, generate: false);
    } else {
      return await super.deserializeKey(key, sender, receiver, sMsg);
    }
  }

  @override
  Future<Content?> deserializeContent(Uint8List data, SymmetricKey password,
      SecureMessage sMsg) async {
    Content? content = await super.deserializeContent(data, password, sMsg);
    assert(content != null, 'content error: ${data.length}');

    if (!isBroadcastMessage(sMsg) && content != null) {
      // check and cache key for reuse
      ID? group = await getOvertGroup(content);
      if (group == null) {
        // personal message or (group) command
        // cache key with direction (sender -> receiver)
        await cacheCipherKey(sMsg.sender, sMsg.receiver, password);
      } else {
        // group message (excludes group command)
        // cache the key with direction (sender -> group)
        await cacheCipherKey(sMsg.sender, group, password);
      }
    }

    // NOTICE: check attachment for File/Image/Audio/Video message content
    //         after deserialize content, this job should be do in subclass
    return content;
  }

}
