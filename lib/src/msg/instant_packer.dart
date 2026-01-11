/* license: https://mit-license.org
 *
 *  DIMP : Decentralized Instant Messaging Protocol
 *
 *                                Written in 2023 by Moky <albert.moky@gmail.com>
 *
 * ==============================================================================
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
 * ==============================================================================
 */
import 'dart:typed_data';

import 'package:dimp/dimp.dart';

import '../crypto/bundle.dart';
import 'instant_delegate.dart';


class InstantMessagePacker {
  InstantMessagePacker(InstantMessageDelegate messenger)
      : _messenger = WeakReference(messenger);

  final WeakReference<InstantMessageDelegate> _messenger;

  InstantMessageDelegate? get delegate => _messenger.target;

  /*
   *  Encrypt the Instant Message to Secure Message
   *
   *    +----------+      +----------+
   *    | sender   |      | sender   |
   *    | receiver |      | receiver |
   *    | time     |  ->  | time     |
   *    |          |      |          |
   *    | content  |      | data     |  1. data = encrypt(content, PW)
   *    +----------+      | key/keys |  2. key  = encrypt(PW, receiver.PK)
   *                      +----------+
   */

  /// 1. Encrypt message, replace 'content' field with encrypted 'data'
  /// 2. Encrypt group message, replace 'content' field with encrypted 'data'
  ///
  /// @param iMsg     - plain message
  /// @param password - symmetric key
  /// @param members  - group members for group message
  /// @return SecureMessage object, null on visa not found
  Future<SecureMessage?> encryptMessage(InstantMessage iMsg, SymmetricKey password, {List<ID>? members}) async {
    // TODO: check attachment for File/Image/Audio/Video message content
    //      (do it by application)
    InstantMessageDelegate? transceiver = delegate;
    if (transceiver == null) {
      assert(false, 'should not happen');
      return null;
    }

    //
    //  1. Serialize 'message.content' to data (JsON / ProtoBuf / ...)
    //
    Uint8List body = await transceiver.serializeContent(iMsg.content, password, iMsg);
    assert(body.isNotEmpty, 'failed to serialize content: ${iMsg.content}');

    //
    //  2. Encrypt content data to 'message.data' with symmetric key
    //
    Uint8List ciphertext = await transceiver.encryptContent(body, password, iMsg);
    assert(ciphertext.isNotEmpty, 'failed to encrypt content with key: $password');

    //
    //  3. Encode 'message.data' to String (Base64)
    //
    Object? encodedData;
    if (BaseMessage.isBroadcast(iMsg)) {
      // broadcast message content will not be encrypted (just encoded to JsON),
      // so no need to encode to Base64 here
      encodedData = UTF8.decode(ciphertext);
    } else {
      // message content had been encrypted by a symmetric key,
      // so the data should be encoded here (with algorithm 'base64' as default).
      encodedData = TransportableData.encode(ciphertext);
    }
    assert(encodedData != null, 'failed to encode content data: $ciphertext');

    //
    //  4. Serialize message key to data (JsON / ProtoBuf / ...)
    //
    Uint8List? pwd = await transceiver.serializeKey(password, iMsg);
    // NOTICE:
    //    if the key is reused, iMsg must be updated with key digest.
    Map info = iMsg.copyMap();

    // replace 'content' with encrypted 'data'
    info.remove('content');
    info['data'] = encodedData;

    // check serialized key data,
    // if key data is null here, build the secure message directly.
    if (pwd == null) {
      // A) broadcast message has no key
      // B) reused key
      return SecureMessage.parse(info);
    }
    // encrypt + encode key

    if (members == null) {
      // personal message
      ID receiver = iMsg.receiver;
      assert(receiver.isUser, 'message.receiver error: $receiver');
      members = [receiver];
    } else {
      // group message
      ID receiver = iMsg.receiver;
      assert(receiver.isGroup, 'message.receiver error: $receiver');
      assert(members.isNotEmpty, 'group members empty: $receiver');
    }

    Map<ID, EncryptedBundle> bundleMap = {};
    EncryptedBundle? bundle;
    for (ID receiver in members) {
      //
      //  5. Encrypt key data to 'message.keys' with member's public key
      //
      bundle = await transceiver.encryptKey(pwd, receiver, iMsg);
      if (bundle == null || bundle.isEmpty) {
        // public key for member not found
        // TODO: suspend this message for waiting member's visa
        continue;
      }
      bundleMap[receiver] = bundle;
    }

    //
    //  6. Encode message key to String (Base64)
    //
    Map<String, Object>? msgKeys = await encodeKeys(bundleMap, iMsg);
    if (msgKeys == null || msgKeys.isEmpty) {
      // public key for member(s) not found
      // TODO: suspend this message for waiting member's visa
      return null;
    }

    // insert as 'keys'
    info['keys'] = msgKeys;

    // OK, pack message
    return SecureMessage.parse(info);
  }

  // protected
  Future<Map<String, Object>?> encodeKeys(Map<ID, EncryptedBundle> bundleMap, InstantMessage iMsg) async {
    InstantMessageDelegate? transceiver = delegate;
    if (transceiver == null) {
      assert(false, 'should not happen');
      return null;
    }
    Map<String, Object> msgKeys = {};
    ID receiver;
    EncryptedBundle bundle;
    Map<String, Object> encodedKeys;
    for (MapEntry<ID, EncryptedBundle> entry in bundleMap.entries) {
      receiver = entry.key;
      bundle = entry.value;
      encodedKeys = await transceiver.encodeKey(bundle, receiver, iMsg);
      if (encodedKeys.isEmpty) {
        assert(false, 'failed to encode key data: $receiver');
        continue;
      }
      // insert to 'message.keys' with ID + terminal
      msgKeys.addAll(encodedKeys);
    }
    // TODO: put key digest
    return msgKeys;
  }

}
