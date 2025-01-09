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

import 'dos/paths.dart';
import 'http/tasks.dart';

import 'external.dart';
import 'wrapper.dart';


abstract class PortableNetworkLoader extends PortableNetworkWrapper implements DownloadTask {
  PortableNetworkLoader(super.pnf);

  /// file content received
  Uint8List? _bytes;
  Uint8List? get content => _bytes;

  /// count of bytes received
  int _count = 0;
  int get count => _count;

  /// total bytes receiving
  int _total = 0;
  int get total => _total;

  DownloadInfo? _info;

  @override
  DownloadInfo? get params {
    var info = _info;
    if (info == null) {
      Uri? url = pnf.url;
      if (url != null) {
        info = DownloadInfo(url);
        _info = info;
      }
    }
    return info;
  }

  Future<Uint8List?> _decrypt(Uint8List data, String cachePath) async {
    //
    //  1. check password
    //
    DecryptKey? password = pnf.password;
    if (password == null) {
      // password not found, means the data is not encrypted
      _bytes = data;
    } else {
      await setStatus(PortableNetworkStatus.decrypting);
      // try to decrypt with password
      Uint8List? plaintext = password.decrypt(data, pnf);
      if (plaintext == null || plaintext.isEmpty) {
        await postNotification(NotificationNames.kPortableNetworkError, {
          'URL': params?.url,
          'error': 'Failed to decrypt data',
        });
        await setStatus(PortableNetworkStatus.error);
        return null;
      }
      data = plaintext;
      _bytes = plaintext;
    }
    //
    //  2. save original file content
    //
    int cnt = await ExternalStorage.saveBinary(data, cachePath);
    if (cnt != data.length) {
      assert(false, 'failed to cache file: $cnt/${data.length}, $cachePath');
      await setStatus(PortableNetworkStatus.error);
      return null;
    }
    if (status == PortableNetworkStatus.decrypting) {
      await postNotification(NotificationNames.kPortableNetworkDecrypted, {
        'URL': params?.url,
        'data': data,
        'path': cachePath,
      });
    }
    await postNotification(NotificationNames.kPortableNetworkSuccess, {
      'URL': params?.url,
      'data': data,
    });
    await setStatus(PortableNetworkStatus.success);
    return data;
  }

  //
  //  DownloadTask
  //

  @override
  Future<bool> prepare() async {
    // await setStatus(PortableNetworkStatus.init);

    //
    //  0. check file content
    //
    Uint8List? data = _bytes;
    if (data != null && data.isNotEmpty) {
      // data already loaded
      await postNotification(NotificationNames.kPortableNetworkSuccess, {
        'URL': params?.url,
        'data': data,
      });
      await setStatus(PortableNetworkStatus.success);
      return false;
    } else {
      data = pnf.data;
      if (data != null && data.isNotEmpty) {
        assert(pnf.url == null, 'PNF error: $pnf');
        // assert(status == PortableNetworkStatus.init, 'PNF status: $_status');
        _bytes = data;
        await postNotification(NotificationNames.kPortableNetworkSuccess, {
          // 'URL': pnf.url,
          'data': data,
        });
        await setStatus(PortableNetworkStatus.success);
        return false;
      }
    }
    //
    //  1. check cached file
    //
    String? cachePath = await cacheFilePath;
    if (cachePath == null) {
      await setStatus(PortableNetworkStatus.error);
      assert(false, 'failed to get cache file path');
      return false;
    }
    // try to load cached file
    if (await Paths.exists(cachePath)) {
      data = await ExternalStorage.loadBinary(cachePath);
      if (data != null && data.isNotEmpty) {
        // data loaded from cached file
        _bytes = data;
        await postNotification(NotificationNames.kPortableNetworkSuccess, {
          'URL': params?.url,
          'data': data,
        });
        await setStatus(PortableNetworkStatus.success);
        return false;
      }
    }
    //
    //  2. check temporary file
    //
    String? tmpPath;
    String? down = await downloadFilePath;
    if (down != null && await Paths.exists(down)) {
      // file exists in download directory
      tmpPath = down;
    } else {
      String? up = await uploadFilePath;
      if (up != null && up != down && await Paths.exists(up)) {
        // file exists in upload directory
        tmpPath = up;
      }
    }
    if (tmpPath != null) {
      // try to load temporary file
      data = await ExternalStorage.loadBinary(tmpPath);
      if (data != null && data.isNotEmpty) {
        // data loaded from temporary file
        // encrypted data loaded from temporary file
        // try to decrypt it
        data = await _decrypt(data, cachePath);
        if (data != null && data.isNotEmpty) {
          return false;
        }
      }
    }
    //
    //  3. get remote URL
    //
    Uri? url = params?.url;
    if (url == null) {
      await setStatus(PortableNetworkStatus.error);
      assert(false, 'URL not found: $pnf');
      return false;
    } else {
      await setStatus(PortableNetworkStatus.waiting);
      return true;
    }
  }

  @override
  Future<void> progress(int count, int total) async {
    _count = count;
    _total = total;
    await postNotification(NotificationNames.kPortableNetworkReceiveProgress, {
      'URL': params?.url,
      'count': count,
      'total': total,
    });
    await setStatus(PortableNetworkStatus.downloading);
  }

  @override
  Future<void> process(Uint8List? data) async {
    //
    //  0. check data
    //
    if (data == null || data.isEmpty) {
      await postNotification(NotificationNames.kPortableNetworkError, {
        'URL': params?.url,
        'error': 'Failed to download file',
      });
      await setStatus(PortableNetworkStatus.error);
      return;
    }
    //
    //  1.. save data from remote URL
    //
    String? tmpPath = await downloadFilePath;
    if (tmpPath == null) {
      await setStatus(PortableNetworkStatus.error);
      assert(false, 'failed to get temporary path');
      return;
    }
    int cnt = await ExternalStorage.saveBinary(data, tmpPath);
    if (cnt != data.length) {
      assert(false, 'failed to save temporary file: $cnt/${data.length}, $tmpPath');
      await setStatus(PortableNetworkStatus.error);
      return;
    }
    await postNotification(NotificationNames.kPortableNetworkReceived, {
      'URL': params?.url,
      'data': data,
      'path': tmpPath,
    });
    //
    //  2. decrypt data from remote URL
    //
    String? cachePath = await cacheFilePath;
    if (cachePath == null) {
      await setStatus(PortableNetworkStatus.error);
      assert(false, 'failed to get cache file path');
      return;
    }
    data = await _decrypt(data, cachePath);
  }

}
