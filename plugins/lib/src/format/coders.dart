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
import 'dart:convert';
import 'dart:typed_data';

import 'package:dimp/crypto.dart';
import 'package:fast_base58/fast_base58.dart';

/// UTF-8
class UTF8Coder implements StringCoder {

  @override
  Uint8List encode(String string) {
    var array = utf8.encode(string);
    return Uint8List.fromList(array);
  }

  @override
  String? decode(Uint8List data) {
    try {
      return utf8.decode(data);
    } on FormatException {
      return null;
    }
  }
}

/// JsON
class JSONCoder implements ObjectCoder<dynamic> {

  @override
  String encode(dynamic object) {
    return json.encode(object);
  }

  @override
  dynamic decode(String string) {
    return json.decode(string);
  }
}

/// Hex
class HexCoder implements DataCoder {

  @override
  String encode(Uint8List data) {
    StringBuffer sb = StringBuffer();
    int item;
    for (int i = 0; i < data.lengthInBytes; ++i) {
      item = data[i];
      if (item < 16) {
        sb.write('0');
      }
      sb.write(item.toRadixString(16));
    }
    return sb.toString();
  }

  @override
  Uint8List? decode(String string) {
    Uint8List data;
    String item;
    int offset;
    bool odd = string.length & 1 == 1;
    if (odd) {
      data = Uint8List((string.length ~/ 2) + 1);
      item = string.substring(0, 1);
      data.add(int.parse(item, radix: 16));
      offset = 1;
    } else {
      data = Uint8List(string.length ~/ 2);
      offset = 0;
    }
    int? value;
    for (int i = offset; i < string.length; i += 2, offset += 1) {
      item = string.substring(i, i + 2);
      value = int.tryParse(item, radix: 16);
      if (value == null) {
        return null;
      }
      data[offset] = value;
    }
    return data;
  }
}

/// Base-58
class Base58Coder implements DataCoder {

  @override
  String encode(Uint8List data) {
    return Base58Encode(data);
  }

  @override
  Uint8List? decode(String string) {
    return Uint8List.fromList(Base58Decode(string));
  }
}

/// Base-64
class Base64Coder implements DataCoder {

  @override
  String encode(Uint8List data) {
    return base64.encode(data);
  }

  @override
  Uint8List? decode(String string) {
    return base64.decode(string);
  }
}
