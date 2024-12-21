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

import 'package:dimp/crypto.dart';
import 'package:pointycastle/export.dart';

Uint8List _hash(Uint8List data, Digest digester) {
  digester.reset();
  return digester.process(data);
}

class MD5Digester implements DataDigester {

  @override
  Uint8List digest(Uint8List data) {
    return _hash(data, MD5Digest());
  }
}

class SHA1Digester implements DataDigester {

  @override
  Uint8List digest(Uint8List data) {
    return _hash(data, SHA1Digest());
  }
}

class SHA256Digester implements DataDigester {

  @override
  Uint8List digest(Uint8List data) {
    return _hash(data, SHA256Digest());
  }
}

class Keccak256Digester implements DataDigester {

  @override
  Uint8List digest(Uint8List data) {
    return _hash(data, KeccakDigest(256));
  }
}

class RIPEMD160Digester implements DataDigester {

  @override
  Uint8List digest(Uint8List data) {
    return _hash(data, RIPEMD160Digest());
  }
}
