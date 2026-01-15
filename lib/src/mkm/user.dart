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

import 'package:dimp/mkm.dart';

import '../crypto/agent.dart';
import '../crypto/bundle.dart';
import 'entity.dart';


///  User account for communication
///  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
///  This class is for creating user account
///
///  functions:
///      (User)
///      1. verify(data, signature) - verify (encrypted content) data and signature
///      2. encrypt(data)           - encrypt (symmetric key) data
///      (LocalUser)
///      3. sign(data)    - calculate signature of (encrypted content) data
///      4. decrypt(data) - decrypt (symmetric key) data
abstract interface class User implements Entity {

  ///  Get all contacts of the user
  ///
  /// @return contact list
  Future<List<ID>> get contacts;

  ///  Get visa.terminal
  ///
  /// @return terminal list
  Future<Set<String>> get terminals;

  ///  Verify data and signature with user's public keys
  ///
  /// @param data - message data
  /// @param signature - message signature
  /// @return true on correct
  Future<bool> verify(Uint8List data, Uint8List signature);

  ///  Encrypt data, try visa.key first, if not found, use meta.key
  ///
  /// @param plaintext - message data
  /// @return encrypted data with targets (ID terminals)
  Future<EncryptedBundle> encryptBundle(Uint8List plaintext);

  //
  //  Interfaces for Local User
  //

  ///  Sign data with user's private key
  ///
  /// @param data - message data
  /// @return signature
  Future<Uint8List> sign(Uint8List data);

  ///  Decrypt data with user's private key(s)
  ///
  /// @param bundle - encrypted data with targets (ID terminals)
  /// @return plain text
  Future<Uint8List?> decryptBundle(EncryptedBundle bundle);

  //
  //  Interfaces for Visa
  //
  Future<Visa?> signVisa(Visa doc);
  Future<bool> verifyVisa(Visa doc);
}

///  This interface is for getting information for user
///  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
///
///  (Encryption/decryption)
///  1. public key for encryption
///     if visa.key not exists, means it is the same key with meta.key
///  2. private keys for decryption
///     the private keys paired with [visa.key, meta.key]
///
///  (Signature/Verification)
///  3. private key for signature
///     the private key paired with visa.key or meta.key
///  4. public keys for verification
///     [visa.key, meta.key]
///
///  (Visa Document)
///  5. private key for visa signature
///     the private key paired with meta.key
///  6. public key for visa verification
///     meta.key only
abstract interface class UserDataSource implements EntityDataSource {

  ///  Get contacts list
  ///
  /// @param user - user ID
  /// @return contacts list (ID)
  Future<List<ID>> getContacts(ID user);

  ///  Get user's private keys for decryption
  ///  (which paired with [visa.key, meta.key])
  ///
  /// @param user - user ID
  /// @return private keys
  Future<List<DecryptKey>> getPrivateKeysForDecryption(ID user);

  ///  Get user's private key for signature
  ///  (which paired with visa.key or meta.key)
  ///
  /// @param user - user ID
  /// @return private key
  Future<SignKey?> getPrivateKeyForSignature(ID user);

  ///  Get user's private key for signing visa
  ///
  /// @param user - user ID
  /// @return private key
  Future<SignKey?> getPrivateKeyForVisaSignature(ID user);
}

//
//  Base User
//

class BaseUser extends BaseEntity implements User {
  BaseUser(super.id);

  @override
  UserDataSource? get dataSource {
    var facebook = super.dataSource;
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
    VisaAgent visaAgent = SharedVisaAgent().agent;
    return visaAgent.getTerminals(docs);
  }

  @override
  Future<bool> verify(Uint8List data, Uint8List signature) async {
    VisaAgent visaAgent = SharedVisaAgent().agent;
    List<VerifyKey> keys = visaAgent.getVerifyKeys(await meta, await documents);
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
    VisaAgent visaAgent = SharedVisaAgent().agent;
    return visaAgent.encryptedBundle(plaintext, await meta, await documents);
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
  Future<Visa?> signVisa(Visa doc) async {
    ID? did = ID.parse(doc['did']);
    assert(did == null || did.address == identifier.address, 'visa ID not match: $did, $identifier');
    // NOTICE: only sign visa with the private key paired with your meta.key
    SignKey? sKey = await privateKeyForVisaSignature;
    if (sKey == null) {
      assert(false, 'failed to get sign key for visa: $did');
      return null;
    }
    if (doc.sign(sKey) == null) {
      assert(false, 'failed to sign visa: $did, $doc');
      return null;
    }
    return doc;
  }

  @override
  Future<bool> verifyVisa(Visa doc) async {
    // NOTICE: only verify visa with meta.key
    //         (if meta not exists, user won't be created)
    ID? did = ID.parse(doc['did']);
    assert(did == null || did.address == identifier.address, 'visa ID not match: $did, $identifier');
    // if meta not exists, user won't be created
    VerifyKey pKey = (await meta).publicKey;
    return doc.verify(pKey);
  }

  //
  //  Private Keys
  //

  // protected
  Future<List<DecryptKey>?> getPrivateKeysForDecryption(String terminal) async {
    UserDataSource? facebook = dataSource;
    if (facebook == null) {
      assert(false, 'user data source not set yet');
      return null;
    }
    if (terminal.isEmpty || terminal == '*') {
      return await facebook.getPrivateKeysForDecryption(identifier);
    }
    ID uid = ID.create(name: identifier.name, address: identifier.address, terminal: terminal);
    return await facebook.getPrivateKeysForDecryption(uid);
}

  // protected
  Future<SignKey?> get privateKeyForSignature async {
    UserDataSource? facebook = dataSource;
    assert(facebook != null, 'user data source not set yet');
    return await facebook?.getPrivateKeyForSignature(identifier);
  }

  // protected
  Future<SignKey?> get privateKeyForVisaSignature async {
    UserDataSource? facebook = dataSource;
    assert(facebook != null, 'user data source not set yet');
    return await facebook?.getPrivateKeyForVisaSignature(identifier);
  }

}
