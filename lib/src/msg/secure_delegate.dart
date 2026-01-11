/* license: https://mit-license.org
 *
 *  Dao-Ke-Dao: Universal Message Module
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


///  Secure Message Delegate
///  ~~~~~~~~~~~~~~~~~~~~~~~
abstract interface class SecureMessageDelegate {

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

  //
  //  Decrypt Key
  //

  ///  1. Decode 'message.key' to encrypted symmetric key data
  ///
  /// @param keys     - encoded key data and targets (ID + terminals)
  /// @param receiver - actual receiver (user, or group member)
  /// @param sMsg     - secure message object
  /// @return encrypted symmetric key data and targets (ID terminals)
  Future<EncryptedBundle?> decodeKey(Map keys, ID receiver, SecureMessage sMsg);

  ///  2. Decrypt 'message.key' with receiver's private key
  ///
  ///  @param bundle   - encrypted symmetric key data and targets (ID terminals)
  ///  @param receiver - actual receiver (user, or group member)
  ///  @param sMsg     - secure message object
  ///  @return serialized data of symmetric key
  Future<Uint8List?> decryptKey(EncryptedBundle bundle, ID receiver, SecureMessage sMsg);

  ///  3. Deserialize message key from data (JsON / ProtoBuf / ...)
  ///     (if key data is empty, means it should be reused, get it from key cache)
  ///
  /// @param key      - serialized key data, null for reused key
  /// @param sMsg     - secure message object
  /// @return symmetric key
  Future<SymmetricKey?> deserializeKey(Uint8List? key, SecureMessage sMsg);

  //
  //  Decrypt Content
  //

  // ///  4. Decode 'message.data' to encrypted content data
  // ///
  // /// @param data - base64 string object
  // /// @param sMsg - secure message object
  // /// @return encrypted content data
  // Future<Uint8List?> decodeData(Object data, SecureMessage sMsg);

  ///  5. Decrypt 'message.data' with symmetric key
  ///
  ///  @param data     - encrypt content data
  ///  @param password - symmetric key
  ///  @param sMsg     - secure message object
  ///  @return serialized message content
  Future<Uint8List?> decryptContent(Uint8List data, SymmetricKey password, SecureMessage sMsg);

  ///  6. Deserialize message content from data (JsON / ProtoBuf / ...)
  ///
  /// @param data     - serialized content data
  /// @param password - symmetric key (includes data compression algorithm)
  /// @param sMsg     - secure message object
  /// @return message content
  Future<Content?> deserializeContent(Uint8List data, SymmetricKey password, SecureMessage sMsg);

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

  //
  //  Signature
  //

  ///  1. Sign 'message.data' with sender's private key
  ///
  ///  @param data - encrypted message data
  ///  @param sMsg - secure message object
  ///  @return signature of encrypted message data
  Future<Uint8List> signData(Uint8List data, SecureMessage sMsg);

  // ///  2. Encode 'message.signature' to String (Base64)
  // ///
  // /// @param signature - signature of message.data
  // /// @param sMsg      - secure message object
  // /// @return String object
  // Future<Object> encodeSignature(Uint8List signature, SecureMessage sMsg);

}
