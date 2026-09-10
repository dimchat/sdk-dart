/* license: https://mit-license.org
 *
 *  DIM-SDK : Decentralized Instant Messaging Software Development Kit
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

import 'package:dkd/dkd.dart';  // FIXME:

import 'package:dimp/crypto.dart';
import 'package:dimp/mkm.dart';
import 'package:dimp/ext.dart';

import '../crypto/agent.dart';
import '../crypto/ext.dart';

import 'entity.dart';


// -----------------------------------------------------------------------------
//  User Entity (with Visa-based Crypto)
// -----------------------------------------------------------------------------

/// User account interface for secure communication (with Visa terminal support).
///
/// Extends [Entity] with user-specific cryptographic operations, contact management,
/// and Visa-based terminal encryption.
///
/// Supports core secure communication functions:
///   1. Verification : Verify message signatures using Meta/Visa public keys
///   2. Encryption   : Encrypt data for specific user terminals (via EncryptedBundle)
///   3. Signing      : Generate message signatures (local user only)
///   4. Decryption   : Decrypt terminal-specific data (local user only)
abstract interface class User implements Entity {

  /// List of contact IDs associated with the user (async).
  ///
  /// Represents the user's address book/contacts list in the communication system.
  ///
  /// Returns the list of user contact IDs (empty list if none).
  Future<List<ID>> get contacts;

  /// Set of terminal identifiers associated with the user's Visa documents (async).
  ///
  /// Terminals represent different devices/sessions the user is logged into (e.g., "mobile", "desktop").
  /// Retrieved via [VisaAgent.getTerminals] from the user's Visa documents.
  ///
  /// Returns the set of unique terminal identifiers (empty set if none).
  Future<Set<String>> get terminals;

  /// Verifies data and its signature using the user's Meta/Visa public keys (async).
  ///
  /// Uses verification keys from [VisaAgent.getVerifyKeys] to validate message authenticity.
  ///
  /// [data] is the raw message data to verify.
  /// [signature] is the digital signature of the data.
  ///
  /// Returns true if the signature is valid, false otherwise.
  Future<bool> verify(Uint8List data, Uint8List signature);

  /// Encrypts plaintext data for the user's terminals (async).
  ///
  /// Uses [VisaAgent.encryptBundle] to create terminal-specific encrypted data:
  /// 1. Tries Visa public keys first (terminal-specific encryption)
  /// 2. Falls back to Meta public key (wildcard/* encryption)
  ///
  /// [plaintext] is the raw data to encrypt (usually a symmetric message key).
  ///
  /// Returns an EncryptedBundle with terminal-specific encrypted data.
  Future<EncryptedBundle> encryptBundle(Uint8List plaintext);

  // -------------------------------------------------------------------------
  //  Local User Only Interfaces (Private Key Operations)
  // -------------------------------------------------------------------------

  /// Signs data with the user's private key (async, local user only).
  ///
  /// Generates a digital signature for the data using the private key paired with
  /// the user's Visa/Meta public key (non-repudiation).
  ///
  /// [data] is the raw message data to sign.
  ///
  /// Returns the digital signature of the data.
  Future<Uint8List> sign(Uint8List data);

  /// Decrypts a terminal-specific EncryptedBundle (async, local user only).
  ///
  /// Uses private keys from [UserDataSource.getPrivateKeysForDecryption] to decrypt
  /// the bundle, extracting the original plaintext data for the user's terminals.
  ///
  /// [bundle] is the encrypted data bundle with terminal-specific data.
  ///
  /// Returns the decrypted plaintext (null if decryption fails).
  Future<Uint8List?> decryptBundle(EncryptedBundle bundle);

  // -------------------------------------------------------------------------
  //  Visa Document Management
  // -------------------------------------------------------------------------

  /// Signs a Visa document with the user's Meta private key (async).
  ///
  /// Uses [UserDataSource.getPrivateKeyForVisaSignature] to sign the Visa,
  /// verifying the document's authenticity (only Meta key is used for Visa signing).
  ///
  /// [visa] is the visa document to sign.
  ///
  /// Returns the signed Visa document (null if signing fails).
  Future<Document?> signDocument(Document visa);

  /// Verifies the signature of a Visa document (async).
  ///
  /// Uses the user's Meta public key (only) to verify the Visa signature,
  /// ensuring the document was signed by the user's Meta private key.
  ///
  /// [visa] is the visa document to verify.
  ///
  /// Returns true if the Visa signature is valid, false otherwise.
  Future<bool> verifyDocument(Document visa);
}


/// Data source interface for user-specific data and cryptographic keys.
///
/// Extends [EntityDataSource] with user-specific key management, defining the contract
/// for fetching private keys (local user only) and contact information.
///
/// Core cryptographic responsibilities (Visa/Meta key pairs):
/// 1. Encryption        : Use Visa public key (terminal-specific) or Meta key (fallback)
/// 2. Decryption        : Use private keys paired with Visa/Meta public keys
/// 3. Signing           : Use private key paired with Visa/Meta public key
/// 4. Verification      : Use Visa/Meta public keys
/// 5. Visa Signing      : Use private key paired with Meta public key (only)
/// 6. Visa Verification : Use Meta public key (only)
abstract interface class UserDataSource implements EntityDataSource {

  /// Retrieves the contact list for a user (async).
  ///
  /// [user] is the unique ID of the target user.
  ///
  /// Returns the list of contact IDs (empty list if the user has no contacts).
  Future<List<ID>> getContacts(ID user);

  /// Retrieves private keys for decryption (async, local user only).
  ///
  /// Returns the private keys paired with the user's Visa/Meta public keys, used to
  /// decrypt terminal-specific [EncryptedBundle] data.
  ///
  /// [user] is the unique ID of the target user.
  ///
  /// Returns the list of decryption keys (empty list if no keys are available).
  Future<List<DecryptKey>> getPrivateKeysForDecryption(ID user);

  /// Retrieves the private key for message signing (async, local user only).
  ///
  /// Returns the private key paired with the user's Visa/Meta public key, used to
  /// generate digital signatures for messages.
  ///
  /// [user] is the unique ID of the target user.
  ///
  /// Returns the signing key (null if no key is available).
  Future<SignKey?> getPrivateKeyForSignature(ID user);

  /// Retrieves the private key for Visa signing (async, local user only).
  ///
  /// Returns the private key paired with the user's Meta public key (only), used to
  /// sign the user's Visa documents (identity verification).
  ///
  /// [user] is the unique ID of the target user.
  ///
  /// Returns the signing key for Visa documents (null if no key is available).
  Future<SignKey?> getPrivateKeyForVisaSignature(ID user);
}

//
//  Base User
//

class BaseUser extends BaseEntity implements User {
  BaseUser(super.id);

  @override
  UserDataSource? get dataSource {
    final facebook = super.dataSource;
    if (facebook is UserDataSource) {
      return facebook;
    }
    assert(facebook == null, 'user data source error: $facebook');
    return null;
  }

  @override
  Future<List<ID>> get contacts async =>
      await dataSource!.getContacts(identifier);

  @override
  Future<Set<String>> get terminals async {
    List<Document> docs = await documents;
    assert(docs.isNotEmpty, 'failed to get documents: $identifier');
    final agent = sharedAccountExtensions.visaAgent;
    return agent.getTerminals(docs);
  }

  @override
  Future<bool> verify(Uint8List data, Uint8List signature) async {
    final agent = sharedAccountExtensions.visaAgent;
    List<VerifyKey> keys = agent.getVerifyKeys(await meta, await documents);
    assert(keys.isNotEmpty, 'failed to get verify keys: $identifier');
    for (VerifyKey pubKey in keys) {
      if (pubKey.verify(data, signature)) {
        // matched!
        return true;
      }
    }
    // signature not match
    // TODO: check whether visa is expired, query new document for this contact
    return false;
  }

  @override
  Future<EncryptedBundle> encryptBundle(Uint8List plaintext) async {
    // NOTICE: meta.key will never changed, so use visa.key to encrypt message
    //         is a better way
    final agent = sharedAccountExtensions.visaAgent;
    return agent.encryptBundle(plaintext, await meta, await documents);
  }

  //
  //  Interfaces for Local User
  //

  @override
  Future<Uint8List> sign(Uint8List data) async {
    SignKey? sKey = await privateKeyForSignature;
    assert(sKey != null, 'failed to get sign key for user: $identifier');
    return sKey!.sign(data);
  }

  @override
  Future<Uint8List?> decryptBundle(EncryptedBundle bundle) async {
    // NOTICE: if you provide a public key in visa for encryption,
    //         here you should return the private key paired with visa.key
    Map<String, Uint8List> map = bundle.toMap();
    assert(map.isNotEmpty, 'key data empty: $bundle');
    String terminal;
    Uint8List ciphertext;
    Uint8List? plaintext;
    List<DecryptKey>? keys;
    for (MapEntry<String, Uint8List> entry in map.entries) {
      terminal = entry.key;
      ciphertext = entry.value;
      // get private keys for terminal
      keys = await getPrivateKeysForDecryption(terminal);
      if (keys == null) {
        assert(false, 'failed to get decrypt keys for user: $identifier, terminal: $terminal');
        continue;
      }
      // try decrypting it with each private key
      for (DecryptKey priKey in keys) {
        plaintext = priKey.decrypt(ciphertext);
        if (plaintext != null && plaintext.isNotEmpty) {
          // OK
          return plaintext;
        }
      }
    }
    // decryption failed
    // TODO: check whether my visa key is changed, push new visa to this contact
    return null;
  }

  @override
  Future<Document?> signDocument(Document visa) async {
    final helper = sharedAccountExtensions.handler;
    ID? did = helper?.getDocumentID(visa.toMap());
    assert(did == null || did.isSameAs(identifier), 'visa ID not match: $did, $identifier');
    // NOTICE: only sign visa with the private key paired with your meta.key
    SignKey? sKey = await privateKeyForVisaSignature;
    if (sKey == null) {
      assert(false, 'failed to get sign key for visa: $identifier');
      return null;
    }
    if (visa.sign(sKey) == null) {
      assert(false, 'failed to sign visa: $identifier, $visa');
      return null;
    }
    return visa;
  }

  @override
  Future<bool> verifyDocument(Document visa) async {
    // NOTICE: only verify visa with meta.key
    //         (if meta not exists, user won't be created)
    final helper = sharedAccountExtensions.handler;
    ID? did = helper?.getDocumentID(visa.toMap());
    assert(did == null || did.isSameAs(identifier), 'visa ID not match: $did, $identifier');
    // if meta not exists, user won't be created
    VerifyKey pKey = (await meta).publicKey;
    return visa.verify(pKey);
  }

  //
  //  Private Keys
  //

  /// Retrieves the decryption private keys for a specific terminal (async).
  ///
  /// Queries the [UserDataSource] for private keys paired with the public keys
  /// in the user's Visa/Meta documents, targeting the given terminal.
  ///
  /// [terminal] is the device terminal string (empty or "/" for wildcard).
  ///
  /// Returns the list of decryption private keys (null if data source is missing).
  // protected
  Future<List<DecryptKey>?> getPrivateKeysForDecryption(String terminal) async {
    UserDataSource? facebook = dataSource;
    if (facebook == null) {
      assert(false, 'user data source not set yet');
      return null;
    }
    ID uid = identifier;
    if (terminal.isEmpty || terminal == '/') {
      uid = uid.withoutTerminal();
    } else {
      uid = uid.withTerminal(terminal);
    }
    return await facebook.getPrivateKeysForDecryption(uid);
  }

  /// Retrieves the private key for message signing (async).
  ///
  /// Returns the private key paired with the user's Visa/Meta public key,
  /// used to generate digital signatures for outgoing messages.
  ///
  /// Returns the signing key (null if data source is missing).
  // protected
  Future<SignKey?> get privateKeyForSignature async {
    UserDataSource? facebook = dataSource;
    assert(facebook != null, 'user data source not set yet');
    return await facebook?.getPrivateKeyForSignature(identifier);
  }

  /// Retrieves the private key for Visa document signing (async).
  ///
  /// Returns the private key paired with the user's Meta public key (only),
  /// used to sign the user's Visa documents (identity verification).
  ///
  /// Returns the signing key for Visa documents (null if data source is missing).
  // protected
  Future<SignKey?> get privateKeyForVisaSignature async {
    UserDataSource? facebook = dataSource;
    assert(facebook != null, 'user data source not set yet');
    return await facebook?.getPrivateKeyForVisaSignature(identifier);
  }

}
