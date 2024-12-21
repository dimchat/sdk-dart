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
import 'dart:math';
import 'dart:typed_data';

import 'package:dimp/crypto.dart';
import 'package:encrypt/encrypt.dart';

///  AES Key
///
///      keyInfo format: {
///          algorithm: "AES",
///          keySize  : 32,                // optional
///          data     : "{BASE64_ENCODE}}" // password data
///      }
class AESKey extends BaseSymmetricKey {
  AESKey(super.dict) {
    // TODO: check algorithm parameters
    // 1. check mode = 'CBC'
    // 2. check padding = 'PKCS7Padding'

    // check key data
    if (containsKey('data')) {
      // lazy load
      _keyData = null;
    } else {
      // new key
      _keyData = _generateKeyData();
    }
  }

  // static const String AES_CBC_PKCS7 = "AES/CBC/PKCS7Padding";

  TransportableData? _keyData;

  TransportableData _generateKeyData() {
    // random key data
    int keySize = _getKeySize();
    var pwd = _randomData(keySize);
    var ted = TransportableData.create(pwd);

    this['data'] = ted.toObject();
    /**
    // this['mod'] = 'CBC';
    // this['padding'] = 'PKCS7';
    **/

    return ted;
  }

  int _getKeySize() {
    // TODO: get from key data
    return getInt('keySize', 32)!;
  }

  int _getBlockSize() {
    // TODO: get from iv data
    return getInt('blockSize', 16)!;  // cipher.getBlockSize();
  }

  @override
  Uint8List get data {
    var ted = _keyData;
    if (ted == null) {
      var base64 = this['data'];
      assert(base64 != null, 'key data not found: $this');
      ted = _keyData = TransportableData.parse(base64);
      assert(ted != null, 'key data error: $base64');
    }
    return ted!.data!;
  }

  /// get IV from params
  IV _getInitVector(Map? params) {
    // get base64 encoded IV from params
    String? base64;
    if (params == null) {
      assert(false, 'params must provided to fetch IV for AES');
    } else {
      base64 = params['IV'];
      base64 ??= params['iv'];
    }
    if (base64 == null) {
      // compatible with old version
      base64 = getString('iv', null);
      base64 ??= getString('IV', null);
    }
    // decode IV data
    var ted = TransportableData.parse(base64);
    Uint8List? ivData = ted?.data;
    if (ivData == null) {
      assert(base64 == null, 'IV data error: $base64');
      // zero IV
      int blockSize = _getBlockSize();
      ivData = Uint8List(blockSize);
    }
    return IV(ivData);
  }
  IV _newInitVector(Map? extra) {
    // random IV data
    int blockSize = _getBlockSize();
    Uint8List ivData = _randomData(blockSize);
    // put encoded IV into extra
    if (extra == null) {
      assert(false, 'extra dict must provided to store IV for AES');
    } else {
      var ted = TransportableData.create(ivData);
      extra['IV'] = ted.toObject();
    }
    // OK
    return IV(ivData);
  }

  @override
  Uint8List encrypt(Uint8List plaintext, Map? extra) {
    // 1. random new 'IV'
    IV iv = _newInitVector(extra);
    // 2. get key
    Key key = Key(data);
    // 3. try to encrypt
    Encrypter cipher = Encrypter(AES(key, mode: AESMode.cbc));
    return cipher.encryptBytes(plaintext, iv: iv).bytes;
  }

  @override
  Uint8List? decrypt(Uint8List ciphertext, Map? params) {
    // 1. get 'IV' from extra params
    IV iv = _getInitVector(params);
    // 2. get key
    Key key = Key(data);
    // 3. try to decrypt
    try {
      Encrypter cipher = Encrypter(AES(key, mode: AESMode.cbc));
      List<int> result = cipher.decryptBytes(Encrypted(ciphertext), iv: iv);
      return Uint8List.fromList(result);
    } catch (e, st) {
      print('AES: failed to decrypt: $e, $st');
      return null;
    }
  }

}

Uint8List _randomData(int size) {
  Uint8List data = Uint8List(size);
  Random r = Random();
  for (int i = 0; i < size; ++i) {
    data[i] = r.nextInt(256);
  }
  return data;
}

class AESKeyFactory implements SymmetricKeyFactory {

  @override
  SymmetricKey generateSymmetricKey() {
    Map key = {'algorithm': SymmetricKey.AES};
    return AESKey(key);
  }

  @override
  SymmetricKey? parseSymmetricKey(Map key) {
    return AESKey(key);
  }

}
