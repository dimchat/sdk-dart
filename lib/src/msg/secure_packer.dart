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
import 'secure_delegate.dart';


/// Packer class for decrypting SecureMessage and signing to ReliableMessage.
///
/// Implements two core workflows:
/// 1. Decryption: SecureMessage → InstantMessage (reverse of encryption)
/// 2. Signing: SecureMessage → ReliableMessage (add sender signature)
class SecureMessagePacker {
  SecureMessagePacker(SecureMessageDelegate messenger)
      : _messenger = WeakReference(messenger);

  final WeakReference<SecureMessageDelegate> _messenger;

  SecureMessageDelegate? get delegate => _messenger.target;

  /*
   *  Decrypt the Secure Message to Instant Message
   *
   *    +----------+      +----------+
   *    | sender   |      | sender   |
   *    | receiver |      | receiver |
   *    | time     |  ->  | time     |
   *    |          |      |          |  1. PW      = decrypt(key, receiver.SK)
   *    | data     |      | content  |  2. content = decrypt(data, PW)
   *    | key/keys |      +----------+
   *    +----------+
   */

  /// Decodes the encrypted key map from a SecureMessage (internal use).
  ///
  /// Extracts the 'key/keys' field and converts it to an EncryptedBundle for decryption.
  ///
  /// Parameters:
  /// - [sMsg]     : Encrypted secure message
  /// - [receiver] : Actual target receiver (local user ID)
  ///
  /// Returns: Decoded EncryptedBundle (null if no key found/broadcast message)
  // protected
  Future<EncryptedBundle?> decodeKey(SecureMessage sMsg, ID receiver) async {
    Map? msgKeys = sMsg.encryptedKeys;
    if (msgKeys == null) {
      // get from 'key'
      var base64 = sMsg['key'];
      if (base64 == null) {
        // broadcast message?
        // reused key?
        return null;
      }
      msgKeys = {
        receiver.toString(): base64,
      };
    }
    SecureMessageDelegate? transformer = delegate;
    assert(transformer != null, 'secure message delegate not found');
    return await transformer?.decodeKey(msgKeys, receiver, sMsg);
  }

  /// Decrypts a SecureMessage back to an InstantMessage (for local user).
  ///
  /// Replaces the encrypted 'data' field with plaintext 'content' by decrypting the
  /// symmetric key (with receiver's private key) and then decrypting the content.
  ///
  /// Parameters:
  /// - [sMsg]     : Encrypted secure message to decrypt
  /// - [receiver] : Actual target receiver (local user ID, must be a user)
  ///
  /// Returns: Decrypted InstantMessage (throws Exception if decryption fails)
  Future<InstantMessage?> decryptMessage(SecureMessage sMsg, ID receiver) async {
    assert(receiver.isUser, 'receiver error: $receiver');
    SecureMessageDelegate? transformer = delegate;
    assert(transformer != null, 'secure message delegate not found');

    Uint8List? pwd;  // serialized symmetric key data

    //
    //  1. Decode 'message.key' to encrypted symmetric key data
    //
    EncryptedBundle? bundle = await decodeKey(sMsg, receiver);
    if (bundle == null || bundle.isEmpty) {
      // broadcast message?
      // reused key?
      pwd = null;
    } else {
      //
      //  2. Decrypt 'message.key' with receiver's private key
      //
      pwd = await transformer?.decryptKey(bundle, receiver, sMsg);
      if (pwd == null || pwd.isEmpty) {
        // A: my visa updated but the sender doesn't got the new one;
        // B: key data error.
        throw Exception('failed to decrypt message key: $bundle '
            '${sMsg.sender} => $receiver, ${sMsg.group}');
        // TODO: check whether my visa key is changed, push new visa to this contact
      }
    }

    //
    //  3. Deserialize message key from data (JsON / ProtoBuf / ...)
    //     (if key is empty, means it should be reused, get it from key cache)
    //
    SymmetricKey? password = await transformer?.deserializeKey(pwd, sMsg);
    if (password == null) {
      // A: key data is empty, and cipher key not found from local storage;
      // B: key data error.
      throw Exception('failed to get message key: ${pwd?.length} byte(s) '
          '${sMsg.sender} => $receiver, ${sMsg.group}');
      // TODO: ask the sender to send again (with new message key)
    }

    //
    //  4. Decode 'message.data' to encrypted content data
    //
    Uint8List? ciphertext = sMsg.data.bytes;
    if (ciphertext == null || ciphertext.isEmpty) {
      assert(false, 'failed to decode message data: '
          '${sMsg.sender} => $receiver, ${sMsg.group}');
      return null;
    }

    //
    //  5. Decrypt 'message.data' with symmetric key
    //
    Uint8List? body = await transformer?.decryptContent(ciphertext, password, sMsg);
    if (body == null || body.isEmpty) {
      // A: password is a reused key loaded from local storage, but it's expired;
      // B: key error.
      throw Exception('failed to decrypt message data with key: $password'
          ', data length: ${ciphertext.length} byte(s) '
          '${sMsg.sender} => $receiver, ${sMsg.group}');
      // TODO: ask the sender to send again
    }
    assert(body.isNotEmpty, 'message data should not be empty: '
        '${sMsg.sender} => $receiver, ${sMsg.group}');

    //
    //  6. Deserialize message content from data (JsON / ProtoBuf / ...)
    //
    Content? content = await transformer?.deserializeContent(body, password, sMsg);
    if (content == null) {
      assert(false, 'failed to deserialize content: ${body.length} byte(s) '
          '${sMsg.sender} => $receiver, ${sMsg.group}');
      return null;
    }

    /// TODO: check attachment for File/Image/Audio/Video message content
    ///      if URL exists, means file data was uploaded to a CDN,
    ///          1. save password as 'content.key';
    ///          2. try to download file data from CDN;
    ///          3. decrypt downloaded data with 'content.key'.
    ///      (do it by application)

    // OK, pack message
    Map info = sMsg.copyMap();
    info.remove('key');
    info.remove('keys');
    info.remove('data');
    info['content'] = content.toMap();
    return InstantMessage.parse(info);
  }

  /*
   *  Sign the Secure Message to Reliable Message
   *
   *    +----------+      +----------+
   *    | sender   |      | sender   |
   *    | receiver |      | receiver |
   *    | time     |  ->  | time     |
   *    |          |      |          |
   *    | data     |      | data     |
   *    | key/keys |      | key/keys |
   *    +----------+      | signature|  1. signature = sign(data, sender.SK)
   *                      +----------+
   */

  /// Signs a SecureMessage to create a ReliableMessage (adds sender signature).
  ///
  /// Generates a digital signature for the encrypted 'data' field using the sender's
  /// private key, and adds it as the 'signature' field in ReliableMessage.
  ///
  /// Parameters:
  /// - [sMsg] : Encrypted secure message to sign
  ///
  /// Returns: Signed ReliableMessage (null if signing/encoding fails)
  Future<ReliableMessage?> signMessage(SecureMessage sMsg) async {
    SecureMessageDelegate? transformer = delegate;
    assert(transformer != null, 'secure message delegate not found');

    //
    //  0. decode message data
    //
    Uint8List? ciphertext = sMsg.data.bytes;
    if (ciphertext == null || ciphertext.isEmpty) {
      assert(false, 'failed to decode message data: '
          '${sMsg.sender} => ${sMsg.receiver}, ${sMsg.group}');
      return null;
    }

    //
    //  1. Sign 'message.data' with sender's private key
    //
    Uint8List? signature = await transformer?.signData(ciphertext, sMsg);
    if (signature == null || signature.isEmpty) {
      assert(false, 'failed to sign message: '
          '${ciphertext.length} byte(s) '
          '${sMsg.sender} => ${sMsg.receiver}, ${sMsg.group}');
      return null;
    }

    //
    //  2. Encode 'message.signature' to String (Base64)
    //
    TransportableData base64 = Base64Data.createWithBytes(signature);
    if (base64.isEmpty) {
      assert(false, 'failed to encode signature: ${signature.length} byte(s) '
          '${sMsg.sender} => ${sMsg.receiver}, ${sMsg.group}');
      return null;
    }

    // OK, pack message
    Map info = sMsg.copyMap();
    info['signature'] = base64.serialize();
    return ReliableMessage.parse(info)!;
  }

}
