/* license: https://mit-license.org
 *
 *  DIMP : Decentralized Instant Messaging Protocol
 *
 *                                Written in 2026 by Moky <albert.moky@gmail.com>
 *
 * ==============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2026 Albert Moky
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

import 'package:dimp/crypto.dart';
import 'package:dimp/mkm.dart';
import 'package:dimp/dkd.dart';
import 'package:dimp/ext.dart';


// -----------------------------------------------------------------------------
//  Visa Agent (Visa-based Encryption/Verification)
// -----------------------------------------------------------------------------

/// Agent interface for Visa-based cryptographic operations.
///
/// Provides core functionality for working with user Visa documents:
/// - Encrypting data for multiple user terminals using Visa/Meta public keys
/// - Extracting verification keys from Meta/Visa documents
/// - Collecting terminal identifiers from Visa documents
///
/// Acts as a helper to abstract complex Visa-based encryption logic from User entity.
abstract interface class VisaAgent {

  /// Decrypts key bundle for the receiver.
  ///
  /// [sMsg] is the received message.
  /// [receiver] is the actual receiver (user, or group member).
  ///
  /// Returns the encrypted bundle with terminals.
  EncryptedBundle? decodeBundle(SecureMessage sMsg, ID receiver);

  /// Encrypts plaintext data using all available Visa/Meta public keys.
  ///
  /// Creates an [EncryptedBundle] with terminal-specific encrypted data, using:
  /// 1. Visa public keys for terminal-specific encryption
  /// 2. Meta public key as fallback for wildcard (*) encryption
  ///
  /// [plaintext] is the raw data to encrypt (usually a symmetric message key).
  /// [meta] is the user's core Meta (contains fallback public key).
  /// [documents] is the list of user Visa documents (contains terminal-specific public keys).
  ///
  /// Returns an EncryptedBundle with terminal-specific encrypted data.
  EncryptedBundle encryptBundle(Uint8List plaintext, Meta meta, List<Document> documents);

  /// Extracts all verification keys from Meta and Visa documents.
  ///
  /// Collects public verification keys from:
  /// 1. User's Meta (core identity key)
  /// 2. All Visa documents (terminal-specific keys)
  ///
  /// [meta] is the user's core Meta.
  /// [documents] is the list of user Visa documents.
  ///
  /// Returns the list of VerifyKey instances for signature verification.
  List<VerifyKey> getVerifyKeys(Meta meta, List<Document> documents);

  /// Extracts all terminal identifiers from user Visa documents.
  ///
  /// Collects unique terminal strings (e.g., "mobile", "desktop") from Visa documents,
  /// representing all devices the user is logged into.
  ///
  /// [documents] is the list of user Visa documents.
  ///
  /// Returns the set of unique terminal identifiers (empty set if none).
  Set<String> getTerminals(List<Document> documents);

}


class DefaultVisaAgent implements VisaAgent {

  @override
  EncryptedBundle? decodeBundle(SecureMessage sMsg, ID receiver) {
    // TODO: check key digest
    Mapping? keys = sMsg.encryptedKeys?.asMapping();
    if (keys == null || keys.isEmpty) {
      return null;
    }
    // TODO: get terminal(s) for local user
    String? terminal = receiver.terminal;
    if (terminal == null || terminal.isEmpty) {
      // get full bundle
      return EncryptedBundle.decode(keys, receiver, null);
    }
    // get single bundle
    Set<String> devices = {terminal};
    receiver = receiver.withoutTerminal();
    return EncryptedBundle.decode(keys, receiver, devices);
  }

  @override
  EncryptedBundle encryptBundle(Uint8List plaintext, Meta meta, List<Document> documents) {
    // NOTICE: meta.key will never changed, so use visa.key to encrypt message
    //         is a better way
    EncryptedBundle bundle = UserEncryptedBundle();
    String terminal;
    EncryptKey? pubKey;
    Uint8List ciphertext;
    //
    //  1. encrypt with visa keys
    //
    for (Document doc in documents) {
      // encrypt by public key
      pubKey = getEncryptKey(doc);
      if (pubKey == null) {
        continue;
      }
      // get visa.terminal
      terminal = getTerminal(doc);
      // if (terminal == null || terminal.isEmpty) {
      //   terminal = '/';
      // }
      if (bundle[terminal] != null) {
        assert(false, 'duplicated visa key: "$terminal", bundle: $bundle, ${documents.length} document(s): $doc');
        continue;
      }
      ciphertext = pubKey.encrypt(plaintext);
      bundle[terminal] = ciphertext;
    }
    if (bundle.isEmpty) {
      //
      //  2. encrypt with meta key
      //
      VerifyKey metaKey = meta.publicKey;
      if (metaKey is EncryptKey) {
        pubKey = metaKey as EncryptKey;
        // terminal = '/';
        ciphertext = pubKey.encrypt(plaintext);
        bundle['/'] = ciphertext;
      }
    }
    // OK
    return bundle;
  }

  @override
  List<VerifyKey> getVerifyKeys(Meta meta, List<Document> documents) {
    List<VerifyKey> keys = [];
    VerifyKey? pubKey;
    // the sender may use communication key to sign message.data,
    // try to verify it with visa.key first;
    for (Document doc in documents) {
      pubKey = getVerifyKey(doc);
      if (pubKey != null) {
        keys.add(pubKey);
      } else {
        assert(false, 'failed to get visa key: $doc');
      }
    }
    // the sender may use identity key to sign message.data,
    // try to verify it with meta.key too.
    keys.add(meta.publicKey);
    // OK
    return keys;
  }

  /// Extracts the public verification key from a user document (Visa).
  ///
  /// Parses the "key" property of the document as a [PublicKey].
  ///
  /// [doc] is the user document (Visa) containing the public key.
  ///
  /// Returns the verification key (null if the document has no valid key).
  // protected
  VerifyKey? getVerifyKey(Document doc) {
    // public key in user profile?
    return PublicKey.parse(doc.getProperty('key'));
  }

  /// Extracts the public encryption key from a user document (Visa).
  ///
  /// Parses the "key" property of the document as a [PublicKey]; only keys
  /// implementing [EncryptKey] can be used for encryption.
  ///
  /// [doc] is the user document (Visa) containing the public key.
  ///
  /// Returns the encryption key (null if not an encryptable key).
  // protected
  EncryptKey? getEncryptKey(Document doc) {
    PublicKey? pubKey = PublicKey.parse(doc.getProperty('key'));
    if (pubKey == null) {
      // profile document?
      return null;
    } else if (pubKey is EncryptKey) {
      return pubKey as EncryptKey;
    }
    assert(false, 'visa key error: $pubKey');
    return null;
  }

  /// Determines the terminal identifier for a user document (Visa).
  ///
  /// Reads the "terminal" property from the document; if missing, extracts it
  /// from the document ID. Falls back to "/" (wildcard) when empty or "*".
  ///
  /// [doc] is the user document (Visa) to get terminal from.
  ///
  /// Returns the terminal string ("/" for wildcard).
  // protected
  String getTerminal(Document doc) {
    String? terminal = doc.getString('terminal');
    if (terminal == null) {
      // get from document ID
      final helper = sharedAccountExtensions.handler;
      ID? did = helper?.getDocumentID(doc.toMap());
      if (did != null) {
        terminal = did.terminal;
      } else {
        assert(false, 'document ID not found: $doc');
        // TODO: get from property?
      }
    }
    if (terminal == null || terminal.isEmpty || terminal == '*') {
      terminal = '/';
    }
    return terminal;
  }

  @override
  Set<String> getTerminals(List<Document> documents) {
    Set<String> devices = {};
    String? terminal;
    for (Document doc in documents) {
      terminal = getTerminal(doc);
      // if (terminal == null || terminal.isEmpty) {
      //   terminal = '/';
      // }
      devices.add(terminal);
    }
    return devices;
  }

}
