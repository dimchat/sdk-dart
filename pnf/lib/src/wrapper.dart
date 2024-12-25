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

import 'package:mkm/format.dart';

import 'cache.dart';
import 'helper.dart';


enum PortableNetworkStatus {
  init,
  waiting,
  downloading,
  decrypting,
  success,
  error,
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
        'URL': pnf.url,
        'previous': previous,
        'current': current,
      });
    }
  }

  ///  Post a notification with extra info
  ///
  /// @param name   - notification name
  /// @param sender - who post this notification
  /// @param info   - extra info
  Future<void> postNotification(String name, [Map? info]);

  /// local file cache
  FileCache get fileCache;

  /// "{caches}/files/{AA}/{BB}/{filename}"
  Future<String?> get cacheFilePath async {
    String? name = cacheFilename;
    if (name == null || name.isEmpty) {
      assert(false, 'PNF error: $pnf');
      return null;
    }
    return await fileCache.getCacheFilePath(name);
  }

  /// "{tmp}/upload/{filename}"
  Future<String?> get uploadFilePath async {
    String? name = temporaryFilename;
    if (name == null || name.isEmpty) {
      assert(false, 'PNF error: $pnf');
      return null;
    }
    return await fileCache.getUploadFilePath(name);
  }

  /// "{tmp}/download/{filename}"
  Future<String?> get downloadFilePath async {
    String? name = temporaryFilename;
    if (name == null || name.isEmpty) {
      assert(false, 'PNF error: $pnf');
      return null;
    }
    return await fileCache.getDownloadFilePath(name);
  }

  /// original filename
  String? get cacheFilename {
    String? name = pnf.filename;
    // get name from PNF
    if (name != null && URLHelper.isFilenameEncoded(name)) {
      return name;
    }
    Uri? url = pnf.url;
    if (url != null) {
      return URLHelper.filenameFromURL(url, name);
    }
    assert(name != null && name.isNotEmpty, 'PNF error: $pnf');
    return name;
  }

  /// encrypted filename
  String? get temporaryFilename {
    String? name = pnf.filename;
    // get name from URL
    Uri? url = pnf.url;
    if (url != null) {
      return URLHelper.filenameFromURL(url, name);
    }
    assert(name != null && name.isNotEmpty, 'PNF error: $pnf');
    return name;
  }

}


abstract class NotificationNames {

  static const String kPortableNetworkStatusChanged = 'PNF_OnStatusChanged';

  static const String kPortableNetworkReceiveProgress = 'PNF_OnReceiveProgress';

  static const String kPortableNetworkReceived = 'PNF_OnReceived';
  static const String kPortableNetworkDecrypted = 'PNF_OnDecrypted';
  static const String kPortableNetworkSuccess = 'PNF_OnSuccess';

  static const String kPortableNetworkError = 'PNF_OnError';

}
