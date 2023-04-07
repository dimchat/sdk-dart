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
  SymmetricKey? getCipherKey(ID sender, ID receiver, {bool generate = false});

  ///  Cache cipher key for reusing, with the direction (from 'sender' to 'receiver')
  ///
  /// @param sender - from where (user or contact ID)
  /// @param receiver - to where (contact or user/group ID)
  /// @param key - cipher key
  void cacheCipherKey(ID sender, ID receiver, SymmetricKey? key);

}


abstract class Messenger extends Transceiver implements CipherKeyDelegate, Packer, Processor {

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
  SymmetricKey? getCipherKey(ID sender, ID receiver, {bool generate = false})
  => cipherKeyDelegate?.getCipherKey(sender, receiver, generate: generate);

  @override
  void cacheCipherKey(ID sender, ID receiver, SymmetricKey? key)
  => cipherKeyDelegate!.cacheCipherKey(sender, receiver, key);

  //
  //  Interfaces for Packing Message
  //

  @override
  ID? getOvertGroup(Content content) => packer?.getOvertGroup(content);

  @override
  SecureMessage encryptMessage(InstantMessage iMsg) => packer!.encryptMessage(iMsg);

  @override
  ReliableMessage signMessage(SecureMessage sMsg) => packer!.signMessage(sMsg);

  @override
  Uint8List serializeMessage(ReliableMessage rMsg) => packer!.serializeMessage(rMsg);

  @override
  ReliableMessage? deserializeMessage(Uint8List data) => packer?.deserializeMessage(data);

  @override
  SecureMessage? verifyMessage(ReliableMessage rMsg) => packer?.verifyMessage(rMsg);

  @override
  InstantMessage? decryptMessage(SecureMessage sMsg) => packer?.decryptMessage(sMsg);

  //
  //  Interfaces for Processing Message
  //

  @override
  List<Uint8List> processPackage(Uint8List data)
  => processor!.processPackage(data);

  @override
  List<ReliableMessage> processReliableMessage(ReliableMessage rMsg)
  => processor!.processReliableMessage(rMsg);

  @override
  List<SecureMessage> processSecureMessage(SecureMessage sMsg, ReliableMessage rMsg)
  => processor!.processSecureMessage(sMsg, rMsg);

  @override
  List<InstantMessage> processInstantMessage(InstantMessage iMsg, ReliableMessage rMsg)
  => processor!.processInstantMessage(iMsg, rMsg);

  @override
  List<Content> processContent(Content content, ReliableMessage rMsg)
  => processor!.processContent(content, rMsg);

  //-------- SecureMessageDelegate

  @override
  SymmetricKey? deserializeKey(Uint8List? key, ID sender, ID receiver, SecureMessage sMsg) {
    if (key == null) {
      // get key from cache
      return getCipherKey(sender, receiver, generate: false);
    } else {
      return super.deserializeKey(key, sender, receiver, sMsg);
    }
  }

  @override
  Content? deserializeContent(Uint8List data, SymmetricKey password, SecureMessage sMsg) {
    Content? content = super.deserializeContent(data, password, sMsg);
    assert(content != null, 'content error: ${data.length}');

    if (!isBroadcastMessage(sMsg) && content != null) {
      // check and cache key for reuse
      ID? group = getOvertGroup(content);
      if (group == null) {
        // personal message or (group) command
        // cache key with direction (sender -> receiver)
        cacheCipherKey(sMsg.sender, sMsg.receiver, password);
      } else {
        // group message (excludes group command)
        // cache the key with direction (sender -> group)
        cacheCipherKey(sMsg.sender, group, password);
      }
    }

    // NOTICE: check attachment for File/Image/Audio/Video message content
    //         after deserialize content, this job should be do in subclass
    return content;
  }

}
