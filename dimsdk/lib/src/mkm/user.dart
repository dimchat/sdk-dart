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

import 'package:dimp/crypto.dart';
import 'package:dimp/mkm.dart';

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
  Future<Visa?> get visa async =>
      DocumentHelper.lastVisa(await documents);

  @override
  Future<List<ID>> get contacts async =>
      await dataSource!.getContacts(identifier);

  @override
  Future<bool> verify(Uint8List data, Uint8List signature) async {
    UserDataSource? barrack = dataSource;
    assert(barrack != null, 'user data source not set yet');
    List<VerifyKey> keys = await barrack!.getPublicKeysForVerification(identifier);
    assert(keys.isNotEmpty, 'failed to get verify keys: $identifier');
    for (VerifyKey pKey in keys) {
      if (pKey.verify(data, signature)) {
        // matched!
        return true;
      }
    }
    // signature not match
    // TODO: check whether visa is expired, query new document for this contact
    return false;
  }

  @override
  Future<Uint8List> encrypt(Uint8List plaintext) async {
    UserDataSource? barrack = dataSource;
    assert(barrack != null, 'user data source not set yet');
    // NOTICE: meta.key will never changed, so use visa.key to encrypt message
    //         is a better way
    EncryptKey? pKey = await barrack!.getPublicKeyForEncryption(identifier);
    assert(pKey != null, 'failed to get encrypt key for user: $identifier');
    return pKey!.encrypt(plaintext, null);
  }

  //
  //  Interfaces for Local User
  //

  @override
  Future<Uint8List> sign(Uint8List data) async {
    UserDataSource? barrack = dataSource;
    assert(barrack != null, 'user data source not set yet');
    SignKey? sKey = await barrack!.getPrivateKeyForSignature(identifier);
    assert(sKey != null, 'failed to get sign key for user: $identifier');
    return sKey!.sign(data);
  }

  @override
  Future<Uint8List?> decrypt(Uint8List ciphertext) async {
    UserDataSource? barrack = dataSource;
    assert(barrack != null, 'user data source not set yet');
    // NOTICE: if you provide a public key in visa for encryption,
    //         here you should return the private key paired with visa.key
    List<DecryptKey> keys = await barrack!.getPrivateKeysForDecryption(identifier);
    assert(keys.isNotEmpty, 'failed to get decrypt keys for user: $identifier');
    Uint8List? plaintext;
    for (DecryptKey key in keys) {
      // try decrypting it with each private key
      plaintext = key.decrypt(ciphertext, null);
      if (plaintext != null) {
        // OK!
        return plaintext;
      }
    }
    // decryption failed
    // TODO: check whether my visa key is changed, push new visa to this contact
    return null;
  }

  @override
  Future<Visa?> signVisa(Visa doc) async {
    assert(doc.identifier == identifier, 'visa ID not match: $identifier, ${doc.identifier}');
    UserDataSource? barrack = dataSource;
    assert(barrack != null, 'user data source not set yet');
    // NOTICE: only sign visa with the private key paired with your meta.key
    SignKey? sKey = await barrack!.getPrivateKeyForVisaSignature(identifier);
    assert(sKey != null, 'failed to get sign key for visa: $identifier');
    if (doc.sign(sKey!) == null) {
      assert(false, 'failed to sign visa: $identifier, $doc');
      return null;
    }
    return doc;
  }

  @override
  Future<bool> verifyVisa(Visa doc) async {
    // NOTICE: only verify visa with meta.key
    //         (if meta not exists, user won't be created)
    if (identifier != doc.identifier) {
      // visa ID not match
      return false;
    }
    // if meta not exists, user won't be created
    VerifyKey pKey = (await meta).publicKey;
    return doc.verify(pKey);
  }

}
