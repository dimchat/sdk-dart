/* license: https://mit-license.org
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

import 'keys.dart';
import 'rsa_utils.dart';

///  RSA Public Key
///
///      keyInfo format: {
///          algorithm : "RSA",
///          data      : "..." // base64_encode()
///      }
class _RSAPublicKey extends BasePublicKey implements EncryptKey {
  _RSAPublicKey(super.dict);

  @override
  Uint8List get data {
    var publicKey = RSAKeyUtils.decodePublicKey(_key());
    return RSAKeyUtils.encodePublicKeyData(publicKey);
  }

  String _key() {
    return getString('data')!;
  }

  @override
  Uint8List encrypt(Uint8List plaintext) {
    var publicKey = RSAKeyUtils.decodePublicKey(_key());
    return RSAKeyUtils.encrypt(plaintext, publicKey);
  }

  @override
  bool verify(Uint8List data, Uint8List signature) {
    var publicKey = RSAKeyUtils.decodePublicKey(_key());
    return RSAKeyUtils.verify(data, signature, publicKey);
  }
}

///  RSA Private Key
///
///      keyInfo format: {
///          algorithm : "RSA",
///          data      : "..." // base64_encode()
///      }
class _RSAPrivateKey extends BasePrivateKey implements DecryptKey {
  _RSAPrivateKey(super.dict) : _publicKey = null;

  PublicKey? _publicKey;

  @override
  PublicKey get publicKey {
    PublicKey? pubKey = _publicKey;
    if (pubKey == null) {
      var privateKey = RSAKeyUtils.decodePrivateKey(_key());
      var publicKey = RSAKeyUtils.publicKeyFromPrivateKey(privateKey);
      String pem = RSAKeyUtils.encodeKey(publicKey: publicKey);
      Map info = {
        'algorithm': AsymmetricKey.kRSA,
        'data': pem,
      };
      pubKey = PublicKey.parse(info);
      assert(pubKey != null, 'failed to get public key: $info');
      _publicKey = pubKey;
    }
    return pubKey!;
  }

  @override
  Uint8List get data {
    var privateKey = RSAKeyUtils.decodePrivateKey(_key());
    return RSAKeyUtils.encodePrivateKeyData(privateKey);
  }

  String _key() {
    String? pem = getString('data');
    if (pem != null) {
      return pem;
    }

    //
    // key data empty? generate new key info
    //

    var privateKey = RSAKeyUtils.generatePrivateKey();
    pem = RSAKeyUtils.encodeKey(privateKey: privateKey);
    this['data'] = pem;

    return pem;
  }

  @override
  Uint8List? decrypt(Uint8List ciphertext) {
    var privateKey = RSAKeyUtils.decodePrivateKey(_key());
    return RSAKeyUtils.decrypt(ciphertext, privateKey);
  }

  @override
  Uint8List sign(Uint8List data) {
    var privateKey = RSAKeyUtils.decodePrivateKey(_key());
    return RSAKeyUtils.sign(data, privateKey);
  }

  @override
  bool match(EncryptKey pKey) {
    CryptographyKeyFactoryManager man = CryptographyKeyFactoryManager();
    return man.generalFactory.matchSymmetricKeys(pKey, this);
  }
}

//
//  RSA Key Factories
//

class RSAPublicKeyFactory implements PublicKeyFactory {

  @override
  PublicKey parsePublicKey(Map key) {
    return _RSAPublicKey(key);
  }
}

class RSAPrivateKeyFactory implements PrivateKeyFactory {

  @override
  PrivateKey generatePrivateKey() {
    Map key = {'algorithm': AsymmetricKey.kRSA};
    return _RSAPrivateKey(key);
  }

  @override
  PrivateKey? parsePrivateKey(Map key) {
    return _RSAPrivateKey(key);
  }
}
