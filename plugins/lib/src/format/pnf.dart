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
  _BaseNetworkFile(super.dict) : _attachment = null, _remoteURL = null, _password = null;

  /// file content (not encrypted)
  TransportableData? _attachment;

  /// download from CDN
  Uri? _remoteURL;
  // key to decrypt data downloaded from CDN
  DecryptKey? _password;

  _BaseNetworkFile.from({Uint8List? data, String? filename,
                         Uri? url, DecryptKey? password})
      : super(null) {
    //
    //  file data
    //
    if (data == null) {
      _attachment = null;
    } else {
      this.data = data;
    }
    //
    //  filename
    //
    if (filename != null) {
      this['filename'] = filename;
    }
    //
    //  remote URL
    //
    if (url == null) {
      _remoteURL = null;
    } else {
      this.url = url;
    }
    //
    //  decrypt key
    //
    if (password == null) {
      _password = null;
    } else {
      this.password = password;
    }
  }

  @override
  Uint8List? get data {
    TransportableData? ted = _attachment;
    if (ted == null) {
      Object? base64 = this['data'];
      _attachment = ted = TransportableData.parse(base64);
    }
    return ted?.data;
  }

  @override
  set data(Uint8List? fileData) {
    TransportableData? ted;
    if (fileData == null/* || fileData.isEmpty*/) {
      remove('data');
    } else {
      ted = TransportableData.create(fileData);
      // lazy encode
      // this['data'] = ted.toObject();
    }
    _attachment = ted;
  }

  @override
  String? get filename => getString('filename', null);

  @override
  set filename(String? name) {
    if (name == null/* || name.isEmpty*/) {
      remove('filename');
    } else {
      this['filename'] = name;
    }
  }

  @override
  Uri? get url {
    Uri? location = _remoteURL;
    if (location == null) {
      String? remote = getString('URL', null);
      if (remote != null/* && remote.isNotEmpty*/) {
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
  DecryptKey? get password {
    _password ??= SymmetricKey.parse(this['password']);
    return _password;
  }

  @override
  set password(DecryptKey? key) {
    setMap('password', key);
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
    return getString('URL', '')!;
  }

  @override
  Object toObject() => toString();

}

class BaseNetworkFileFactory implements PortableNetworkFileFactory {

  @override
  PortableNetworkFile createPortableNetworkFile(Uint8List? data, String? filename,
                                                Uri? url, DecryptKey? password) {
    return _BaseNetworkFile.from(data: data, filename: filename, url: url, password: password);
  }

  @override
  PortableNetworkFile? parsePortableNetworkFile(Map pnf) {
    return _BaseNetworkFile(pnf);
  }

}
