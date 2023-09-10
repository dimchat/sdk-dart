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

class _BaseNetworkFile extends Dictionary implements PortableNetworkFile {
  _BaseNetworkFile(super.dict) : _remoteURL = null, _attachment = null, _password = null;

  Uri? _remoteURL;                // download from CDN
  TransportableData? _attachment; // file content (not encrypted)
  DecryptKey? _password;          // key to decrypt data

  _BaseNetworkFile.from({Uri? url, DecryptKey? key, Uint8List? data, String? filename})
      : super(null) {
    this.url = url;
    password = key;
    this.data = data;
    this.filename = filename;
  }

  @override
  Uri? get url {
    Uri? location = _remoteURL;
    if (location == null) {
      String? remote = getString('URL', null);
      if (remote != null) {
        _remoteURL = location = Uri.parse(remote);
      }
    }
    return location;
  }
  @override
  set url(Uri? location) {
    if (location == null) {
      remove('URL');
    } else {
      this['URL'] = location.toString();
    }
    _remoteURL = location;
  }

  @override
  Uint8List? get data {
    TransportableData? ted = _attachment;
    if (ted == null) {
      var base64 = this['data'];
      _attachment = ted = TransportableData.parse(base64);
    }
    return ted?.data;
  }
  @override
  set data(Uint8List? fileData) {
    if (fileData == null || fileData.isEmpty) {
      _attachment = null;
      remove('data');
    } else {
      TransportableData ted = TransportableData.create(fileData);
      _attachment = ted;
      // lazy encode
      // this['data'] = ted.toObject();
    }
  }

  @override
  String? get filename => getString('filename', null);
  @override
  set filename(String? name) {
    if (name == null) {
      remove('filename');
    } else {
      this['filename'] = name;
    }
  }

  @override
  DecryptKey? get password {
    _password ??= SymmetricKey.parse(this['key']);
    return _password;
  }
  @override
  set password(DecryptKey? key) {
    setMap('key', key);
    _password = key;
  }

  Object? _encode() {
    var base64 = this['data'];
    if (base64 == null) {
      // 'data' not exists, check attachment
      TransportableData? ted = _attachment;
      if (ted != null) {
        // encode data string
        base64 = ted.toObject();
        this['data'] = base64;
      }
    }
    // return encoded data string
    return base64;
  }

  @override
  String toString() {
    // check 'data' and 'key'
    if (_encode() != null || password != null) {
      // not a single URL, encode the entire dictionary
      return JSONMap.encode(toMap());
    }
    // field 'data' not exists, means this file was uploaded onto a CDN,
    // if 'key' not exists too, just return 'URL' string here.
    assert(this['filename'] == null, 'PNF error: $this');
    String? url = getString('URL', '');
    return url!;
  }

  @override
  Object toObject() => toString();

}

class BaseNetworkFileFactory implements PortableNetworkFileFactory {

  @override
  PortableNetworkFile createPortableNetworkFile(Uri? url, DecryptKey? key, {Uint8List? data, String? filename}) {
    return _BaseNetworkFile.from(url: url, key: key, data: data, filename: filename);
  }

  @override
  PortableNetworkFile? parsePortableNetworkFile(Map pnf) {
    return _BaseNetworkFile(pnf);
  }

}
