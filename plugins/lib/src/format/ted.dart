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

class _Base64Data extends Dictionary implements TransportableData {
  _Base64Data(super.dict) : _data = null;

  Uint8List? _data;

  _Base64Data.fromData(Uint8List binary) : super(null) {
    // algorithm: base64
    this['algorithm'] = TransportableData.kBASE_64;
    // binary data (lazy encode)
    _data = binary;
  }

  @override
  String get algorithm => getString('algorithm', TransportableData.kBASE_64)!;

  @override
  Uint8List get data {
    Uint8List? binary = _data;
    if (binary == null) {
      String? base64 = getString('data', '');
      assert(base64 != null, 'data should not be empty');
      _data = binary = Base64.decode(base64!);
    }
    return binary!;
  }

  String? _encode() {
    String? base64 = getString('data', null);
    if (base64 == null) {
      // field 'data' not exists, check binary data
      Uint8List? binary = _data;
      if (binary != null) {
        // encode data string
        base64 = Base64.encode(binary);
        this['data'] = base64;
      }
      assert(base64 != null, 'TED data should not be empty');
    }
    // return encoded data string
    return base64;
  }

  @override
  String toString() {
    String? base64 = _encode();
    if (base64 != null) {
      return base64;
    }
    // TODO: other field?
    return JSONMap.encode(toMap());
  }

  @override
  Object toObject() => toString();

}

class Base64DataFactory implements TransportableDataFactory {

  @override
  TransportableData createTransportableData(Uint8List data) {
    return _Base64Data.fromData(data);
  }

  @override
  TransportableData? parseTransportableData(Map ted) {
    return _Base64Data(ted);
  }

}
