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

import 'package:dimp/dimp.dart';
import 'package:encrypt/encrypt.dart';

///  AES Key
///
///      keyInfo format: {
///          algorithm: "AES",
///          keySize  : 32,                // optional
///          data     : "{BASE64_ENCODE}}" // password data
///          iv       : "{BASE64_ENCODE}", // initialization vector
///      }
class _AESKey extends BaseSymmetricKey {
  _AESKey(super.dict) : _keyData = null, _ivData = null {
    // TODO: check algorithm parameters
    // 1. check mode = 'CBC'
    // 2. check padding = 'PKCS7Padding'
    if (!containsKey('data')) {
      _generate();
    }
  }

  // static const String AES_CBC_PKCS7 = "AES/CBC/PKCS7Padding";

  TransportableData? _keyData;
  TransportableData? _ivData;

  void _generate() {
    TransportableData ted;

    // random key data
    Uint8List pw = _random(_getKeySize());
    ted = TransportableData.create(pw);
    this['data'] = ted.toObject();
    _keyData = ted;

    // random initialization vector
    Uint8List iv = _random(_getBlockSize());
    ted = TransportableData.create(iv);
    this['iv'] = ted.toObject();
    _ivData = ted;

    // // other parameters
    // this['mod'] = 'CBC';
    // this['padding'] = 'PKCS7';

  }

  int _getKeySize() {
    // TODO: get from key data
    return getInt('keySize', 32)!;
  }

  int _getBlockSize() {
    // TODO: get from iv data
    return getInt('blockSize', 16)!;  // cipher.getBlockSize();
  }

  /// get init vector
  TransportableData _getInitVector() {
    TransportableData? ted = _ivData;
    if (ted == null) {
      var base64 = this['iv'];
      if (base64 == null) {
        // zero iv
        Uint8List zeros = Uint8List(_getBlockSize());
        _ivData = ted = TransportableData.create(zeros);
      } else {
        _ivData = ted = TransportableData.parse(base64);
        assert(ted != null, 'IV error: $base64');
      }
    }
    return ted!;
  }
  void _setInitVector(Object? base64) {
    var ted = TransportableData.parse(base64);
    if (ted != null) {
      _ivData = ted;
    }
  }

  /// get key data
  TransportableData _getKeyData() {
    if (_keyData == null) {
      var base64 = this['data'];
      assert(base64 != null, 'key data not found: $this');
      _keyData = TransportableData.parse(base64);
    }
    return _keyData!;
  }

  String _iv() {
    TransportableData ted = _getInitVector();
    String base64 = ted.toString();
    return AESKeyFactory.trimBase64String(base64);
  }

  String _key() {
    TransportableData ted = _getKeyData();
    String base64 = ted.toString();
    return AESKeyFactory.trimBase64String(base64);
  }

  @override
  Uint8List get data {
    TransportableData ted = _getKeyData();
    return ted.data;
  }

  @override
  Uint8List encrypt(Uint8List plaintext, Map? extra) {
    // 0. TODO: random new 'IV'
    String base64 = _iv();
    extra?['IV'] = base64;
    // 1. get key data & initial vector
    Key key = Key.fromBase64(_key());
    IV iv = IV.fromBase64(base64);
    // 2. try to encrypt
    Encrypter cipher = Encrypter(AES(key, mode: AESMode.cbc));
    return cipher.encryptBytes(plaintext, iv: iv).bytes;
  }

  @override
  Uint8List? decrypt(Uint8List ciphertext, Map? params) {
    // 0. get 'IV' from extra params
    Object? base64 = params?['IV'];
    if (base64 != null) {
      _setInitVector(base64);
    }
    // 1. get key data & initial vector
    Key key = Key.fromBase64(_key());
    IV iv = IV.fromBase64(_iv());
    // 2. try to decrypt
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

Uint8List _random(int size) {
  Uint8List data = Uint8List(size);
  Random r = Random();
  for (int i = 0; i < size; ++i) {
    data[i] = r.nextInt(256);
  }
  return data;
}

class AESKeyFactory implements SymmetricKeyFactory {

  static String trimBase64String(String b64) {
    if (b64.contains('\n')) {
      b64 = b64.replaceAll('\n', '');
      b64 = b64.replaceAll('\r', '');
      b64 = b64.replaceAll('\t', '');
      b64 = b64.replaceAll(' ', '');
    }
    return b64.trim();
  }

  @override
  SymmetricKey generateSymmetricKey() {
    Map key = {'algorithm': SymmetricKey.kAES};
    return _AESKey(key);
  }

  @override
  SymmetricKey? parseSymmetricKey(Map key) {
    return _AESKey(key);
  }
}
