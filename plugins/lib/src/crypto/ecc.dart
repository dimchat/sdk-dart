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

import 'ecc_utils.dart';
import 'keys.dart';

///  ECC Public Key
///
///      keyInfo format: {
///          algorithm    : "ECC",
///          curve        : "secp256k1",
///          data         : "..." // base64_encode()
///      }
class _ECCPublicKey extends BasePublicKey {
  _ECCPublicKey(super.dict);

  @override
  Uint8List get data {
    var publicKey = ECCKeyUtils.decodePublicKey(_key());
    return ECCKeyUtils.encodePublicKeyData(publicKey);
  }

  String _key() {
    return getString('data')!;
  }

  @override
  bool verify(Uint8List data, Uint8List signature) {
    try {
      var publicKey = ECCKeyUtils.decodePublicKey(_key());
      return ECCKeyUtils.verify(data, signature, publicKey);
    } catch (e, st) {
      print('ECC: failed to verify: $e, $st');
      return false;
    }
  }
}

///  ECC Private Key
///
///      keyInfo format: {
///          algorithm    : "ECC",
///          curve        : "secp256k1",
///          data         : "..." // base64_encode()
///      }
class _ECCPrivateKey extends BasePrivateKey {
  _ECCPrivateKey(super.dict) : _publicKey = null;

  PublicKey? _publicKey;

  @override
  PublicKey get publicKey {
    PublicKey? pubKey = _publicKey;
    if (pubKey == null) {
      var privateKey = ECCKeyUtils.decodePrivateKey(_key());
      var publicKey = ECCKeyUtils.publicKeyFromPrivateKey(privateKey);
      String pem = ECCKeyUtils.encodeKey(publicKey: publicKey);
      Map info = {
        'algorithm': AsymmetricKey.kECC,
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
    var privateKey = ECCKeyUtils.decodePrivateKey(_key());
    return ECCKeyUtils.encodePrivateKeyData(privateKey);
  }

  String _key() {
    String? pem = getString('data');
    if (pem != null) {
      return pem;
    }

    //
    // key data empty? generate new key info
    //

    var privateKey = ECCKeyUtils.generatePrivateKey();
    pem = ECCKeyUtils.encodeKey(privateKey: privateKey);
    this['data'] = pem;

    return pem;
  }

  @override
  Uint8List sign(Uint8List data) {
    var privateKey = ECCKeyUtils.decodePrivateKey(_key());
    return ECCKeyUtils.sign(data, privateKey);
  }
}

//
//  ECC Key Factories
//

class ECCPublicKeyFactory implements PublicKeyFactory {

  @override
  PublicKey parsePublicKey(Map key) {
    return _ECCPublicKey(key);
  }
}

class ECCPrivateKeyFactory implements PrivateKeyFactory {

  @override
  PrivateKey generatePrivateKey() {
    Map key = {'algorithm': AsymmetricKey.kECC};
    return _ECCPrivateKey(key);
  }

  @override
  PrivateKey? parsePrivateKey(Map key) {
    return _ECCPrivateKey(key);
  }
}
