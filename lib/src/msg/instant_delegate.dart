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


/// Delegate interface for encrypting InstantMessage to SecureMessage.
///
/// Handles the full encryption pipeline for instant messages, including:
/// 1. Serialization/encryption of message content (with symmetric key)
/// 2. Encryption of symmetric key (with receiver's public key)
abstract interface class InstantMessageDelegate {

  /*
   *  Encryption workflow: InstantMessage → SecureMessage
   *
   *    +----------+      +----------+
   *    | sender   |      | sender   |
   *    | receiver |      | receiver |
   *    | time     |  ->  | time     |
   *    |          |      |          |
   *    | content  |      | data     |  1. data = encrypt(content, PW)
   *    +----------+      | key/keys |  2. key  = encrypt(PW, receiver.PK)
   *                      +----------+
   *
   *  PW: Symmetric key (password) for content encryption
   *  receiver.PK: Receiver's public key (Visa/Meta) for key encryption
   */

  // -------------------------------------------------------------------------
  //  Content Encryption Pipeline (Steps 1-3)
  // -------------------------------------------------------------------------

  /// Serializes message content to raw bytes (Step 1).
  ///
  /// Converts structured Content object to binary format (JSON/Protobuf/etc.),
  /// using compression algorithm specified in the symmetric key.
  ///
  /// Parameters:
  /// - [content]  : Structured message content to serialize
  /// - [password] : Symmetric key (includes compression algorithm metadata)
  /// - [iMsg]     : Parent instant message object (context)
  ///
  /// Returns: Serialized binary data of the content
  Future<Uint8List> serializeContent(Content content, SymmetricKey password, InstantMessage iMsg);

  /// Encrypts serialized content data with symmetric key (Step 2).
  ///
  /// Uses the symmetric key to encrypt the serialized content data,
  /// producing the final 'data' field for SecureMessage.
  ///
  /// Parameters:
  /// - [data]     : Serialized binary data of the message content
  /// - [password] : Symmetric key for encryption
  /// - [iMsg]     : Parent instant message object (context)
  ///
  /// Returns: Encrypted binary data of the content
  Future<Uint8List> encryptContent(Uint8List data, SymmetricKey password, InstantMessage iMsg);

  // /// Encodes encrypted content data to Base64 string (Step 3).
  // ///
  // /// Converts raw encrypted binary data to a Base64-encoded string for
  // /// transmission/storage in the SecureMessage's 'data' field.
  // ///
  // /// Parameters:
  // /// - [data] : Encrypted binary data of the content
  // /// - [iMsg] : Parent instant message object (context)
  // ///
  // /// Returns: Base64-encoded string of the encrypted content data
  // Future<Object> encodeData(Uint8List data, InstantMessage iMsg);

  // -------------------------------------------------------------------------
  //  Key Encryption Pipeline (Steps 4-6)
  // -------------------------------------------------------------------------

  /// Serializes symmetric key to raw bytes (Step 4).
  ///
  /// Converts the symmetric key to binary format for encryption. Returns null
  /// if key is reused (e.g., broadcast messages) or not needed.
  ///
  /// Parameters:
  /// - [password] : Symmetric key to serialize
  /// - [iMsg]     : Parent instant message object (context)
  ///
  /// Returns: Serialized binary data of the key (null for reused/broadcast keys)
  Future<Uint8List?> serializeKey(SymmetricKey password, InstantMessage iMsg);

  /// Encrypts serialized key with receiver's public key (Step 5).
  ///
  /// Uses the receiver's public key (from Visa/Meta) to encrypt the symmetric key,
  /// producing terminal-specific encrypted data (EncryptedBundle).
  ///
  /// Parameters:
  /// - [key]      : Serialized binary data of the symmetric key
  /// - [receiver] : Actual target receiver (user/group member ID)
  /// - [iMsg]     : Parent instant message object (context)
  ///
  /// Returns: Encrypted key bundle (null if receiver's Visa is not found)
  Future<EncryptedBundle?> encryptKey(Uint8List key, ID receiver, InstantMessage iMsg);

  /// Encodes encrypted key bundle to message-compatible map (Step 6).
  ///
  /// Converts the EncryptedBundle to a map format (ID+terminal → base64 data)
  /// suitable for inclusion in SecureMessage's 'key/keys' field.
  ///
  /// Parameters:
  /// - [bundle]   : Encrypted key bundle with terminal-specific data
  /// - [receiver] : Actual target receiver (user/group member ID)
  /// - [iMsg]     : Parent instant message object (context)
  ///
  /// Returns: Encoded map (ID+terminal → base64-encoded encrypted key data)
  Future<Map<String, Object>> encodeKey(EncryptedBundle bundle, ID receiver, InstantMessage iMsg);

}
