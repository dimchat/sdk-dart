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
import 'package:dimp/dkd.dart';


// -----------------------------------------------------------------------------
//  Message Packer (Encryption/Signature/Serialization)
// -----------------------------------------------------------------------------

/// Message packing/unpacking interface (encryption → signature → serialization).
///
/// Core workflow (packing):
/// `InstantMessage` (plain) → `SecureMessage` (encrypted) → `ReliableMessage` (signed) → `Uint8List` (binary)
///
/// Core workflow (unpacking):
/// `Uint8List` (binary) → `ReliableMessage` (signed) → `SecureMessage` (encrypted) → `InstantMessage` (plain)
abstract interface class Packer {

  //
  //  InstantMessage -> SecureMessage -> ReliableMessage -> Data
  //

  /// Encrypts the content of a plain instant message to create a secure message.
  ///
  /// Parameters:
  /// - [iMsg] : Plain instant message to encrypt (contains unencrypted content)
  ///
  /// Returns: Encrypted secure message (null if encryption fails)
  Future<SecureMessage?> encryptMessage(InstantMessage iMsg);

  /// Signs the encrypted data of a secure message to create a reliable message.
  ///
  /// Parameters:
  /// - [sMsg] : Encrypted secure message to sign (contains encrypted data)
  ///
  /// Returns: Signed reliable message (null if signing fails)
  Future<ReliableMessage?> signMessage(SecureMessage sMsg);

  // /// Serializes a signed reliable message to binary data (network transport format).
  // ///
  // /// Parameters:
  // /// - [rMsg] : Signed reliable message to serialize
  // ///
  // /// Returns: Binary data package (null if serialization fails)
  // Future<Uint8List?> serializeMessage(ReliableMessage rMsg);

  //
  //  Data -> ReliableMessage -> SecureMessage -> InstantMessage
  //

  // /// Deserializes binary data back to a reliable message (reverse of serialize).
  // ///
  // /// Parameters:
  // /// - [data] : Binary data package to deserialize
  // ///
  // /// Returns: Deserialized reliable message (null if deserialization fails)
  // Future<ReliableMessage?> deserializeMessage(Uint8List data);

  /// Verifies the signature of a reliable message to retrieve the secure message.
  ///
  /// Parameters:
  /// - [rMsg] : Reliable message to verify (checks signature validity)
  ///
  /// Returns: Verified secure message (null if verification fails)
  Future<SecureMessage?> verifyMessage(ReliableMessage rMsg);

  /// Decrypts the data of a secure message to retrieve the plain instant message.
  ///
  /// Parameters:
  /// - [sMsg] : Encrypted secure message to decrypt
  ///
  /// Returns: Decrypted plain instant message (null if decryption fails)
  Future<InstantMessage?> decryptMessage(SecureMessage sMsg);
}
