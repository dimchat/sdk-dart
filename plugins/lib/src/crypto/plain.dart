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


///  Symmetric key for broadcast message,
///  which will do nothing when en/decoding message data
class PlainKey extends BaseSymmetricKey {
  PlainKey(super.dict);

  @override
  Uint8List get data => Uint8List(0);

  @override
  Uint8List? decrypt(Uint8List ciphertext, Map? params) {
    return ciphertext;
  }

  @override
  Uint8List encrypt(Uint8List plaintext, Map? extra) {
    return plaintext;
  }

  //-------- Singleton --------

  static final PlainKey _instance = PlainKey({'algorithm': SymmetricAlgorithms.PLAIN});
  factory PlainKey.getInstance() => _instance;
}

class PlainKeyFactory implements SymmetricKeyFactory {

  @override
  SymmetricKey generateSymmetricKey() {
    return PlainKey.getInstance();
  }

  @override
  SymmetricKey? parseSymmetricKey(Map key) {
    return PlainKey.getInstance();
  }
}
