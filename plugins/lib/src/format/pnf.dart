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

class BaseNetworkFile extends Dictionary implements PortableNetworkFile {
  BaseNetworkFile(super.dict) {
    _wrapper = BaseFileWrapper(toMap());
  }

  late final BaseFileWrapper _wrapper;

  BaseNetworkFile.from(TransportableData? data, String? filename,
      Uri? url, DecryptKey? password) : super(null) {
    _wrapper = BaseFileWrapper(toMap());
    // file data
    if (data != null) {
      _wrapper.data = data;
    }
    // file name
    if (filename != null) {
      _wrapper.filename = filename;
    }
    // remote URL
    if (url != null) {
      _wrapper.url = url;
    }
    // decrypt key
    if (password != null) {
      _wrapper.password = password;
    }
  }

  ///
  /// file data
  ///

  @override
  Uint8List? get data => _wrapper.data?.data;

  @override
  set data(Uint8List? binary) => _wrapper.setDate(binary);

  ///
  /// file name
  ///

  @override
  String? get filename => _wrapper.filename;

  @override
  set filename(String? name) => _wrapper.filename = name;

  ///
  /// download URL
  ///

  @override
  Uri? get url => _wrapper.url;

  @override
  set url(Uri? remote) => _wrapper.url = remote;

  ///
  /// decrypt key
  ///

  @override
  DecryptKey? get password => _wrapper.password;

  @override
  set password(DecryptKey? key) => _wrapper.password = key;

  ///
  /// encoding
  ///

  @override
  String toString() {
    String? urlString = _getURLString();
    if (urlString != null) {
      // only contains 'URL', return the URL string directly
      return urlString;
    }
    // not a single URL, encode the entire dictionary
    return JSONMap.encode(toMap());
  }

  @override
  Object toObject() {
    String? urlString = _getURLString();
    if (urlString != null) {
      // only contains 'URL', return the URL string directly
      return urlString;
    }
    // not a single URL, return the entire dictionary
    return toMap();
  }

  String? _getURLString() {
    String? urlString = getString(r'URL', null);
    if (urlString == null) {
      return null;
    } else if (urlString.startsWith(r'data:')) {
      // 'data:...;...,...'
      return urlString;
    }
    int count = length;
    if (count == 1) {
      // if only contains 'URL' field, return the URL string directly
      return urlString;
    } else if (count == 2 && containsKey(r'filename')) {
      // ignore 'filename' field
      return urlString;
    } else {
      // not a single URL
      return null;
    }
  }

}

class BaseNetworkFileFactory implements PortableNetworkFileFactory {

  @override
  PortableNetworkFile createPortableNetworkFile(TransportableData? data, String? filename,
                                                Uri? url, DecryptKey? password) {
    return BaseNetworkFile.from(data, filename, url, password);
  }

  @override
  PortableNetworkFile? parsePortableNetworkFile(Map pnf) {
    // check 'data', 'URL'
    if (pnf['data'] == null && pnf['URL'] == null) {
      // pnf.data and pnf.URL should not be empty at the same time
      assert(false, 'PNF error: $pnf');
      return null;
    }
    return BaseNetworkFile(pnf);
  }

}
