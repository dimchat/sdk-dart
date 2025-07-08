/* license: https://mit-license.org
 *
 *  PNF : Portable Network File
 *
 *                               Written in 2024 by Moky <albert.moky@gmail.com>
 *
 * =============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2024 Albert Moky
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
 * =============================================================================
 */
import 'dart:typed_data';

import 'package:mkm/crypto.dart';
import 'package:mkm/format.dart';
import 'package:mkm/mkm.dart';

import 'crypto/enigma.dart';
import 'dos/paths.dart';
import 'http/client.dart';

import 'cache.dart';
import 'external.dart';
import 'helper.dart';


abstract class NotificationNames {

  static const String kPortableNetworkStatusChanged   = 'PNF_OnStatusChanged';

  static const String kPortableNetworkSendProgress    = 'PNF_OnSendProgress';
  static const String kPortableNetworkReceiveProgress = 'PNF_OnReceiveProgress';

  static const String kPortableNetworkEncrypted       = 'PNF_OnEncrypted';

  static const String kPortableNetworkReceived        = 'PNF_OnReceived';
  static const String kPortableNetworkDecrypted       = 'PNF_OnDecrypted';

  static const String kPortableNetworkUploadSuccess   = 'PNF_OnUploadSuccess';
  static const String kPortableNetworkDownloadSuccess = 'PNF_OnDownloadSuccess';

  static const String kPortableNetworkError           = 'PNF_OnError';

}

enum PortableNetworkStatus {
  //                Upload | Download
  //              ---------|---------
  init,         //    0    |    0
  encrypting,   //    1    |
  waiting,      //    2    |    1
  uploading,    //    3    |
  downloading,  //         |    2
  decrypting,   //         |    3
  success,      //    4    |    4
  error,        //    -    |    -
}


abstract class PortableNetworkWrapper {
  PortableNetworkWrapper(this.pnf);

  final PortableNetworkFile pnf;

  @override
  String toString() {
    Type clazz = runtimeType;
    Uri? url = pnf.url;
    if (url != null) {
      return '<$clazz URL="$url" />';
    }
    String? filename = pnf.filename;
    Uint8List? data = pnf.data;
    return '<$clazz filename="$filename" length="${data?.length}" />';
  }

  /// loader status
  PortableNetworkStatus _status = PortableNetworkStatus.init;
  PortableNetworkStatus get status => _status;
  Future<void> setStatus(PortableNetworkStatus current) async {
    PortableNetworkStatus previous = _status;
    _status = current;
    if (previous != current) {
      await postNotification(NotificationNames.kPortableNetworkStatusChanged, {
        'PNF': pnf,
        'URL': pnf.url,
        'previous': previous,
        'current': current,
      });
    }
  }

  /// "{caches}/files/{AA}/{BB}/{filename}"
  Future<String?> get cacheFilePath async {
    String? name = filename;
    if (name == null) {
      assert(false, 'PNF error: $pnf');
      return null;
    }
    assert(URLHelper.isFilenameEncoded(name), 'filename error: $name, $pnf');
    return await fileCache.getCacheFilePath(name);
  }

  String? get filename;

  Future<Uint8List?> get fileData;

  /// local file cache
  FileCache get fileCache;

  ///  Post a notification with extra info
  ///
  /// @param name   - notification name
  /// @param sender - who post this notification
  /// @param info   - extra info
  Future<void> postNotification(String name, [Map? info]);

}


mixin DownloadMixin on PortableNetworkWrapper {

  @override
  String? get filename {
    Uri? url = pnf.url;
    String? name = pnf.filename;
    if (name != null || url == null) {
      return name;
    }
    return URLHelper.filenameFromURL(url, null);
  }

  @override
  Future<Uint8List?> get fileData async {
    Uint8List? data = pnf.data;
    if (data == null || data.isEmpty) {
      // get from local storage
      String? path = await cacheFilePath;
      if (path != null && await Paths.exists(path)) {
        data = await ExternalStorage.loadBinary(path);
      }
    }
    return data;
  }

  // protected
  String? get encryptedFilename {
    String? name = pnf.filename;
    // get name from URL
    Uri? url = pnf.url;
    if (url == null) {
      assert(false, 'PNF error: $pnf');
      return null;
    }
    return URLHelper.filenameFromURL(url, name);
  }

  /// "{tmp}/upload/{filename}"
  Future<String?> get uploadFilePath async {
    String? name = encryptedFilename;
    if (name == null || name.isEmpty) {
      assert(false, 'PNF error: $pnf');
      return null;
    }
    return await fileCache.getUploadFilePath(name);
  }

  /// "{tmp}/download/{filename}"
  Future<String?> get downloadFilePath async {
    String? name = encryptedFilename;
    if (name == null || name.isEmpty) {
      assert(false, 'PNF error: $pnf');
      return null;
    }
    return await fileCache.getDownloadFilePath(name);
  }

}


mixin UploadMixin on PortableNetworkWrapper {

  // protected
  Enigma get enigma;

  @override
  String? get filename => pnf.filename;

  @override
  Future<Uint8List?> get fileData async {
    String? path = await cacheFilePath;
    Uint8List? data = pnf.data;
    if (data == null || data.isEmpty) {
      // get from local storage
      if (path != null && await Paths.exists(path)) {
        data = await ExternalStorage.loadBinary(path);
      }
    } else if (path == null) {
      assert(false, 'failed to get file path: $pnf');
    } else {
      // save to local storage
      int cnt = await ExternalStorage.saveBinary(data, path);
      if (cnt == data.length) {
        // data saved, remove from message content
        pnf.data = null;
      } else {
        assert(false, 'failed to save data: $path');
      }
    }
    return data;
  }

  // protected
  String? get encryptedFilename {
    Map? extra = pnf['enigma'];
    return extra?['filename'];
  }

  /// "{tmp}/upload/{filename}"
  Future<String?> get uploadFilePath async {
    String? name = encryptedFilename;
    if (name == null || name.isEmpty) {
      // assert(false, 'PNF error: $pnf');
      return null;
    }
    return await fileCache.getUploadFilePath(name);
  }

  /// "{tmp}/upload/{filename}"
  Future<String> buildUploadFilePath(String filename) async =>
      await fileCache.getUploadFilePath(filename);

  String buildFilename(Uint8List data, String name) =>
      URLHelper.filenameFromData(data, name);

  /// API -> URL
  Uri? buildUploadURL(Uint8List data) {
    //
    //  0. check cached value
    //
    Map? extra = pnf['enigma'];
    if (extra == null) {
      return null;
    }
    String? url = extra['URL'];
    if (url != null) {
      return HTTPClient.parseURL(url);
    }
    //
    //  1. get extra info for enigma
    //
    String? api = extra['API'];
    ID? sender = ID.parse(extra['sender']);
    if (api == null || sender == null) {
      assert(false, 'upload info error: $pnf');
      return null;
    } else if (api.isEmpty || data.isEmpty) {
      assert(false, 'upload info error: $pnf');
      return null;
    }
    //
    //  2. fet secret key
    //
    var pair = enigma.fetch(api);
    String? prefix = pair?.first;
    Uint8List? secret = pair?.second;
    if (prefix == null || secret == null) {
      assert(false, 'failed to fetch enigma: $api, $enigma');
      return null;
    } else if (prefix.isEmpty || secret.isEmpty) {
      assert(false, 'enigma error: $api, $enigma');
      return null;
    }
    //
    //  3. build upload URL
    //
    url = enigma.build(api,
      sender, data: data, secret: secret, enigma: prefix,
    );
    Uri? remote = HTTPClient.parseURL(url);
    if (remote != null) {
      extra['URL'] = url;
    }
    return remote;
  }

  // protected
  SymmetricKey get password {
    dynamic pwd = pnf.password;
    if (pwd is SymmetricKey) {
      // reuse old key
      return pwd;
    }
    // generate new key
    pwd = SymmetricKey.generate('AES');  // SymmetricAlgorithms.AES
    pnf.password = pwd;
    return pwd;
  }

}
