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

class Base64Data extends Dictionary implements TransportableData {
  Base64Data([super.dict]);

  late final BaseDataWrapper _wrapper = BaseDataWrapper(toMap());

  Base64Data.fromData(Uint8List binary) {
    // encode algorithm
    _wrapper.algorithm = EncodeAlgorithms.BASE_64;
    // binary data
    if (binary.isNotEmpty) {
      _wrapper.data = binary;
    }
  }

  ///
  /// Encode Algorithm
  ///

  @override
  String? get algorithm => _wrapper.algorithm;

  ///
  /// Binary Data
  ///

  @override
  Uint8List? get data => _wrapper.data;

  ///
  /// Encoding
  ///

  @override
  Object toObject() => toString();

  // 0. "{BASE64_ENCODE}"
  // 1. "base64,{BASE64_ENCODE}"
  @override
  String toString() => _wrapper.toString();

  /// Encode with 'Content-Type'
  // 2. "data:image/png;base64,{BASE64_ENCODE}"
  String encode(String mimeType) => _wrapper.encode(mimeType);

}

class Base64DataFactory implements TransportableDataFactory {

  @override
  TransportableData createTransportableData(Uint8List data) {
    return Base64Data.fromData(data);
  }

  @override
  TransportableData? parseTransportableData(Map ted) {
    // check 'data'
    if (ted['data'] == null) {
      // ted.data should not be empty
      assert(false, 'TED error: $ted');
      return null;
    }
    // TODO: 1. check algorithm
    //       2. check data format
    return Base64Data(ted);
  }

}
