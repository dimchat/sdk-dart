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

import 'keys.dart';

///  AES Key
///
///      keyInfo format: {
///          algorithm: "AES",
///          keySize  : 32,                // optional
///          data     : "{BASE64_ENCODE}}" // password data
///          iv       : "{BASE64_ENCODE}", // initialization vector
///      }
class _AESKey extends BaseSymmetricKey {
  _AESKey(super.dict);

  // static const String AES_CBC_PKCS7 = "AES/CBC/PKCS7Padding";

  // TODO: check algorithm parameters
  // 1. check mode = 'CBC'
  // 2. check padding = 'PKCS7Padding'

  int _keySize() {
    // TODO: get from key data
    int? size = getInt('keySize');
    return size ?? 32;
  }

  int _blockSize() {
    // TODO: get from iv data
    int? size = getInt('blockSize');
    return size ?? 16;  // cipher.getBlockSize();
  }

  String _iv() {
    String? b64 = getString('iv');
    if (b64 != null) {
      b64 = AESKeyFactory.trimBase64String(b64);
      return b64;
    }
    // zero iv
    Uint8List iv = Uint8List(_blockSize());
    b64 = Base64.encode(iv);
    this['iv'] = b64;
    return b64;
  }

  String _key() {
    String? b64 = getString('data');
    if (b64 != null) {
      b64 = AESKeyFactory.trimBase64String(b64);
      return b64;
    }

    //
    // key data empty? generate new key info
    //

    // random key data
    Uint8List pw = _random(_keySize());
    b64 = Base64.encode(pw);
    this['data'] = b64;

    // random initialization vector
    Uint8List iv = _random(_blockSize());
    this['iv'] = Base64.encode(iv);

    // // other parameters
    // this['mod'] = 'CBC';
    // this['padding'] = 'PKCS7';

    return b64;
  }

  @override
  Uint8List get data {
    String b64 = _key();
    return Base64.decode(b64)!;
  }

  @override
  Uint8List encrypt(Uint8List plaintext) {
    Key key = Key.fromBase64(_key());
    IV iv = IV.fromBase64(_iv());
    Encrypter cipher = Encrypter(AES(key, mode: AESMode.cbc));
    return cipher.encryptBytes(plaintext, iv: iv).bytes;
  }
  @override
  Uint8List? decrypt(Uint8List ciphertext) {
    Key key = Key.fromBase64(_key());
    IV iv = IV.fromBase64(_iv());
    Encrypter cipher = Encrypter(AES(key, mode: AESMode.cbc));
    List<int> result = cipher.decryptBytes(Encrypted(ciphertext), iv: iv);
    return Uint8List.fromList(result);
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
