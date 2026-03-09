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


/// Delegate interface for decrypting SecureMessage and signing to ReliableMessage.
///
/// Handles two core workflows:
/// 1. Decryption: SecureMessage → InstantMessage (reverse of encryption pipeline)
/// 2. Signing: SecureMessage → ReliableMessage (add sender signature)
abstract interface class SecureMessageDelegate {

  /*
   *  Decryption workflow: SecureMessage → InstantMessage
   *
   *    +----------+      +----------+
   *    | sender   |      | sender   |
   *    | receiver |      | receiver |
   *    | time     |  ->  | time     |
   *    |          |      |          |  1. PW      = decrypt(key, receiver.SK)
   *    | data     |      | content  |  2. content = decrypt(data, PW)
   *    | key/keys |      +----------+
   *    +----------+
   *
   *  PW: Symmetric key (password) for content encryption
   *  receiver.SK: Receiver's private key (for decryption)
   */

  // -------------------------------------------------------------------------
  //  Key Decryption Pipeline (Steps 1-3)
  // -------------------------------------------------------------------------

  /// Decodes encrypted key map to EncryptedBundle (Step 1).
  ///
  /// Converts the SecureMessage's 'key/keys' map back to an EncryptedBundle
  /// containing terminal-specific encrypted key data.
  ///
  /// Parameters:
  /// - [keys]     : Encoded key map (ID+terminal → base64 data) from SecureMessage
  /// - [receiver] : Actual target receiver (user/group member ID)
  /// - [sMsg]     : Parent secure message object (context)
  ///
  /// Returns: Decoded encrypted key bundle (null if decoding fails)
  Future<EncryptedBundle?> decodeKey(Map keys, ID receiver, SecureMessage sMsg);

  /// Decrypts encrypted key bundle with receiver's private key (Step 2).
  ///
  /// Uses the receiver's private key to decrypt the EncryptedBundle,
  /// retrieving the serialized symmetric key data.
  ///
  /// Parameters:
  /// - [bundle]   : Encrypted key bundle with terminal-specific data
  /// - [receiver] : Actual target receiver (user/group member ID)
  /// - [sMsg]     : Parent secure message object (context)
  ///
  /// Returns: Serialized binary data of the symmetric key (null if decryption fails)
  Future<Uint8List?> decryptKey(EncryptedBundle bundle, ID receiver, SecureMessage sMsg);

  /// Deserializes symmetric key from binary data (Step 3).
  ///
  /// Converts serialized key data back to a SymmetricKey object. If key is null,
  /// retrieves the reused key from cache (for broadcast/reused keys).
  ///
  /// Parameters:
  /// - [key]  : Serialized binary data of the symmetric key (null for reused keys)
  /// - [sMsg] : Parent secure message object (context)
  ///
  /// Returns: Deserialized symmetric key (null if key is invalid/missing)
  Future<SymmetricKey?> deserializeKey(Uint8List? key, SecureMessage sMsg);

  // -------------------------------------------------------------------------
  //  Content Decryption Pipeline (Steps 4-6)
  // -------------------------------------------------------------------------

  // /// Decodes Base64 content string to encrypted binary data (Step 4).
  // ///
  // /// Converts the SecureMessage's Base64-encoded 'data' field back to raw
  // /// encrypted binary data for decryption.
  // ///
  // /// Parameters:
  // /// - [data] : Base64-encoded string of the encrypted content
  // /// - [sMsg] : Parent secure message object (context)
  // ///
  // /// Returns: Encrypted binary data of the content (null if decoding fails)
  // Future<Uint8List?> decodeData(Object data, SecureMessage sMsg);

  /// Decrypts encrypted content data with symmetric key (Step 5).
  ///
  /// Uses the symmetric key to decrypt the SecureMessage's 'data' field,
  /// retrieving the serialized content data.
  ///
  /// Parameters:
  /// - [data]     : Encrypted binary data of the content
  /// - [password] : Symmetric key for decryption
  /// - [sMsg]     : Parent secure message object (context)
  ///
  /// Returns: Serialized binary data of the content (null if decryption fails)
  Future<Uint8List?> decryptContent(Uint8List data, SymmetricKey password, SecureMessage sMsg);

  /// Deserializes content from binary data (Step 6).
  ///
  /// Converts decrypted serialized content data back to a structured Content object,
  /// using compression algorithm specified in the symmetric key.
  ///
  /// Parameters:
  /// - [data]     : Serialized binary data of the content
  /// - [password] : Symmetric key (includes compression algorithm metadata)
  /// - [sMsg]     : Parent secure message object (context)
  ///
  /// Returns: Deserialized structured content (null if deserialization fails)
  Future<Content?> deserializeContent(Uint8List data, SymmetricKey password, SecureMessage sMsg);

  /*
   *  Signing workflow: SecureMessage → ReliableMessage
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
   *
   *  sender.SK: Sender's private key (for signing)
   */

  // -------------------------------------------------------------------------
  //  Signature Pipeline (Step 1-2)
  // -------------------------------------------------------------------------

  /// Signs encrypted content data with sender's private key (Step 1).
  ///
  /// Generates a digital signature for the SecureMessage's 'data' field
  /// using the sender's private key (Meta/Visa), for non-repudiation.
  ///
  /// Parameters:
  /// - [data] : Encrypted binary data of the content
  /// - [sMsg] : Parent secure message object (context)
  ///
  /// Returns: Digital signature of the encrypted content data
  Future<Uint8List> signData(Uint8List data, SecureMessage sMsg);

  // /// Encodes signature data to Base64 string (Step 2).
  // ///
  // /// Converts raw signature binary data to a Base64-encoded string for
  // /// transmission/storage in the ReliableMessage's 'signature' field.
  // ///
  // /// Parameters:
  // /// - [signature] : Raw binary signature of the encrypted content data
  // /// - [sMsg]      : Parent secure message object (context)
  // ///
  // /// Returns: Base64-encoded string of the signature data
  // Future<Object> encodeSignature(Uint8List signature, SecureMessage sMsg);

}
