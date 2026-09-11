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

import 'package:dimp/protocol.dart';
import 'package:dimp/dkd.dart';

import 'instant_delegate.dart';


/// Packer class for encrypting InstantMessage to SecureMessage.
///
/// Implements the full encryption pipeline for instant messages, including:
/// 1. Content serialization/encryption (symmetric key)
/// 2. Key encryption (asymmetric, receiver's public key)
/// 3. Format conversion to SecureMessage structure
class InstantMessagePacker {
  InstantMessagePacker(InstantMessageDelegate messenger)
      : _transformer = WeakReference(messenger);

  final WeakReference<InstantMessageDelegate> _transformer;

  InstantMessageDelegate? get delegate => _transformer.target;

  /*
   *  Encrypt the Instant Message to Secure Message
   *
   *    +----------+      +----------+
   *    | sender   |      | sender   |
   *    | receiver |      | receiver |
   *    | time     |  ->  | time     |
   *    |          |      |          |
   *    | content  |      | data     |  1. data = encrypt(content, PW)
   *    +----------+      | keys     |  2. key  = encrypt(PW, receiver.PK)
   *                      +----------+
   */

  /// Encrypts an InstantMessage to a SecureMessage (supports personal/group messages).
  ///
  /// Replaces the plaintext 'content' field with encrypted 'data', and encrypts the
  /// symmetric key for target recipients (personal: single user, group: multiple members).
  ///
  /// [iMsg] is the plaintext instant message to encrypt.
  /// [password] is the symmetric key for content encryption.
  /// [members] is the optional group member IDs (required for group messages).
  ///
  /// Returns the encrypted SecureMessage (null if encryption fails/Visa not found).
  Future<SecureMessage?> encryptMessage(InstantMessage iMsg, SymmetricKey password, {List<ID>? members}) async {
    // TODO: check attachment for File/Image/Audio/Video message content
    //      (do it by application)
    InstantMessageDelegate? transformer = delegate;
    assert(transformer != null, 'instant message delegate not found');

    //
    //  1. Serialize 'message.content' to data (JsON / ProtoBuf / ...)
    //
    Uint8List? body = await transformer?.serializeContent(iMsg.content, password, iMsg);
    if (body == null || body.isEmpty) {
      assert(false, 'failed to serialize content: ${iMsg.content}');
      return null;
    }

    //
    //  2. Encrypt content data to 'message.data' with symmetric key
    //
    Uint8List? ciphertext = await transformer?.encryptContent(body, password, iMsg);
    if (ciphertext == null || ciphertext.isEmpty) {
      assert(false, 'failed to encrypt content with key: $password');
      return null;
    }

    //
    //  3. Encode 'message.data' to String (Base64)
    //
    // ... do it in SecureMessage.Factory::createSecureMessage()

    //
    //  4. Serialize message key to data (JsON / ProtoBuf / ...)
    //
    Uint8List? pwd = await transformer?.serializeKey(password, iMsg);
    // NOTICE:
    //    if the key is reused, iMsg must be updated with key digest.

    // check serialized key data,
    // if key data is null here, build the secure message directly.
    if (pwd == null) {
      // A) broadcast message has no key
      // B) reused key
      return SecureMessage.create(iMsg, ciphertext, null);
    }
    // encrypt + encode key

    if (members == null) {
      // personal message
      ID receiver = iMsg.receiver;
      assert(receiver.isUser, 'message.receiver error: $receiver');
      members = [receiver];
    //} else {
    //    // group message
    //    ID receiver = iMsg.receiver;
    //    assert receiver.isGroup() : "message.receiver error: " + receiver;
    //    assert !members.isEmpty() : "group members empty: " + receiver;
    }

    Map<ID, EncryptedBundle> bundleMap = {};
    EncryptedBundle? bundle;
    for (ID receiver in members) {
      //
      //  5. Encrypt key data to 'message.keys' with member's public key
      //
      bundle = await transformer?.encryptKey(pwd, receiver, iMsg);
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
    // ... do it in SecureMessage.Factory::createSecureMessage()

    // OK, pack message
    return SecureMessage.create(iMsg, ciphertext, bundleMap);
    // TODO: put key digest
  }

}
