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


///  Instant Message Delegate
///  ~~~~~~~~~~~~~~~~~~~~~~~~
abstract interface class InstantMessageDelegate {

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

  //
  //  Encrypt Content
  //

  ///  1. Serialize 'message.content' to data (JsON / ProtoBuf / ...)
  ///
  /// @param content  - message.content
  /// @param password - symmetric key (includes data compression algorithm)
  /// @param iMsg     - instant message object
  /// @return serialized content data
  Future<Uint8List> serializeContent(Content content, SymmetricKey password, InstantMessage iMsg);

  ///  2. Encrypt content data to 'message.data' with symmetric key
  ///
  /// @param data     - serialized data of message.content
  /// @param password - symmetric key
  /// @param iMsg     - instant message object
  /// @return encrypted message content data
  Future<Uint8List> encryptContent(Uint8List data, SymmetricKey password, InstantMessage iMsg);

  // ///  3. Encode 'message.data' to String (Base64)
  // ///
  // /// @param data - encrypted content data
  // /// @param iMsg - instant message object
  // /// @return String object
  // Future<Object> encodeData(Uint8List data, InstantMessage iMsg);

  //
  //  Encrypt Key
  //

  ///  4. Serialize message key to data (JsON / ProtoBuf / ...)
  ///
  /// @param password - symmetric key
  /// @param iMsg     - instant message object
  /// @return serialized key data, null for reused (or broadcast message)
  Future<Uint8List?> serializeKey(SymmetricKey password, InstantMessage iMsg);

  ///  5. Encrypt key data to 'message.key' with receiver's public key
  ///
  /// @param key      - serialized data of symmetric key
  /// @param receiver - actual receiver (user, or group member)
  /// @param iMsg     - instant message object
  /// @return encrypted symmetric key data, null on visa not found
  Future<Uint8List?> encryptKey(Uint8List key, ID receiver, InstantMessage iMsg);

  // ///  6. Encode 'message.key' to String (Base64)
  // ///
  // /// @param key  - encrypted symmetric key data
  // /// @param iMsg - instant message object
  // /// @return String object
  // Future<Object> encodeKey(Uint8List key, InstantMessage iMsg);

}
