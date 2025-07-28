/* license: https://mit-license.org
 *
 *  PNF : Portable Network File
 *
 *                               Written in 2025 by Moky <albert.moky@gmail.com>
 *
 * =============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2025 Albert Moky
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

import 'package:dio/dio.dart';
import 'package:mkm/format.dart';
import 'package:pnf/pnf.dart';

import 'dos/paths.dart';
import 'http/client.dart';
import 'http/tasks.dart';


///  Transportable File
///  ~~~~~~~~~~~~~~~~~~
///  PNF - Portable Network File
///
///     {
///         filename : "{md5}.ext",       // hex_encode(md5(plaintext))
///         data     : "...",             // remove after cached
///
///         URL      : "http://...",      // update after uploaded
///         key      : {...},             // update after encrypted
///
///         enigma   : {                  // remove after uploaded
///             API      : "http://...",
///             sender   : "{user}",      // user ID
///             filename : "{md5}.ext"    // hex_encode(md5(ciphertext))
///         }
///     }
abstract class PortableNetworkUpper extends PortableNetworkWrapper
    with UploadMixin implements UploadTask {

  PortableNetworkUpper(super.pnf);

  /// original file content (not encrypted)
  Uint8List? _plaintext;
  /// encrypted data to be sent
  Uint8List? _ciphertext;

  /// count of bytes uploaded
  int _count = 0;
  int get count => _count;

  /// total bytes uploading
  int _total = 0;
  int get total => _total;
  // int get total => _ciphertext?.length ?? 0;

  Uri? _uploadAPI;
  UploadInfo? _info;

  @override
  UploadInfo? get uploadParams {
    var info = _info;
    if (info == null) {
      var form = formData;
      var url = uploadURL;
      if (url != null && form != null) {
        info = UploadInfo(url, form);
        _info = info;
      }
    }
    return info;
  }

  // protected
  Uri? get uploadURL {
    Uri? url = _uploadAPI;
    if (url == null) {
      Uint8List? data = _ciphertext;
      if (data != null) {
        url = buildUploadURL(data);
        _uploadAPI = url;
      }
    }
    return url;
  }

  // protected
  FormData? get formData {
    String? filename = encryptedFilename;
    Uint8List? data = _ciphertext;
    if (filename == null || filename.isEmpty) {
      return null;
    } else if (data == null || data.isEmpty) {
      return null;
    }
    var file = HTTPClient.buildMultipartFile(filename, data);
    return HTTPClient.buildFormData('file', file);
  }

  // protected
  Future<Uint8List?> get plaintext async {
    Uint8List? data = _plaintext;
    if (data == null) {
      data = await fileData;
      _plaintext = data;
    }
    return data;
  }

  // protected
  Future<Uint8List?> get encryptedData async {
    Uint8List? data = _ciphertext;
    if (data == null) {
      String? path = await uploadFilePath;
      if (path != null && await Paths.exists(path)) {
        data = await ExternalStorage.loadBinary(path);
        _ciphertext = data;
      }
    }
    return data;
  }

  //
  //  Upload Task
  //

  @override
  Future<bool> prepareUpload() async {
    // await setStatus(PortableNetworkStatus.init);

    //
    //  0. check file content
    //
    Map? extra = pnf['enigma'];
    Uri? downloadURL = pnf.url;
    if (downloadURL != null) {
      // data already uploaded
      Uint8List? data = pnf.data;
      if (data != null) {
        pnf.data = null;
      }
      if (extra != null) {
        pnf.remove('enigma');
      }
      assert(data == null, 'file content error: $pnf');
      // assert(pnf.password != null, 'should not happen');
      await postNotification(NotificationNames.kPortableNetworkUploadSuccess, {
        'PNF': pnf,
        'URL': downloadURL,
        'data': data,
        'extra': extra,
      });
      await setStatus(PortableNetworkStatus.success);
      return false;
    } else if (extra == null) {
      await postNotification(NotificationNames.kPortableNetworkError, {
        'PNF': pnf,
        'URL': downloadURL,
        'error': 'Cannot encrypt data',
      });
      await setStatus(PortableNetworkStatus.error);
      return false;
    }
    //
    //  1. check encrypted content
    //
    String? filename = encryptedFilename;
    Uint8List? data = await encryptedData;
    if (filename != null && data != null) {
      assert(filename.isNotEmpty && data.isNotEmpty, 'file data error: $filename, $data');
      // already encrypted, waiting to upload
      await setStatus(PortableNetworkStatus.waiting);
      return true;
    }
    assert(filename == null && data == null, 'file data error: $filename, $data');
    //
    //  2. encrypt file content
    //
    filename = pnf.filename;
    data = await plaintext;
    if (filename == null || filename.isEmpty || data == null || data.isEmpty) {
      await setStatus(PortableNetworkStatus.error);
      assert(false, 'failed to get file: $filename');
      return false;
    }
    await setStatus(PortableNetworkStatus.encrypting);
    Uint8List ciphertext = password.encrypt(data, pnf.toMap());
    //
    //  3. save encrypted data
    //
    filename = buildFilename(ciphertext, filename);
    String path = await buildUploadFilePath(filename);
    int cnt = await ExternalStorage.saveBinary(ciphertext, path);
    if (cnt != ciphertext.length) {
      assert(false, 'failed to cache upload file: $cnt/${ciphertext.length}, $path');
      await setStatus(PortableNetworkStatus.error);
      return false;
    }
    // encrypted data cached, waiting to upload
    _ciphertext = ciphertext;
    extra['filename'] = filename;
    await postNotification(NotificationNames.kPortableNetworkEncrypted, {
      'PNF': pnf,
      'path': path,
      'data': ciphertext,
    });
    await setStatus(PortableNetworkStatus.waiting);
    return true;
  }

  @override
  Future<void> uploadProgress(int count, int total) async {
    _count = count;
    _total = total;
    // assert(this.total == total, 'upload length error: $count/$total, ${this.total}');
    await postNotification(NotificationNames.kPortableNetworkSendProgress, {
      'PNF': pnf,
      'count': count,
      'total': total,
    });
    await setStatus(PortableNetworkStatus.uploading);
  }

  @override
  Future<void> processResponse(String? response) async {
    //
    //  0. check response
    //
    if (response == null || response.isEmpty) {
      await postNotification(NotificationNames.kPortableNetworkError, {
        'PNF': pnf,
        'error': 'Upload response error',
      });
      await setStatus(PortableNetworkStatus.error);
      return;
    }
    //
    //  1. decode response
    //
    Map? info;
    try {
      info = JSONMap.decode(response);
    } catch (e, st) {
      print('[HTTP] Response error: $e, $uploadURL -> $response, $st');
      return;
    }
    int? code = info?['code'];
    assert(code == 200, 'response error: $uploadURL -> $response');
    //
    //  2. get download URL
    //
    String? url = info?['url'] ?? info?['URL'];
    Uri? downloadURL = HTTPClient.parseURL(url);
    if (downloadURL == null) {
      await postNotification(NotificationNames.kPortableNetworkError, {
        'PNF': pnf,
        'response': response,
        'error': 'Failed to parse response',
      });
      await setStatus(PortableNetworkStatus.error);
      return;
    }
    //
    //  3. upload success
    //
    pnf.url = downloadURL;
    Map? extra = pnf['enigma'];
    Uint8List? data = pnf.data;
    if (data != null) {
      pnf.data = null;
    }
    if (extra != null) {
      pnf.remove('enigma');
    }
    await postNotification(NotificationNames.kPortableNetworkUploadSuccess, {
      'PNF': pnf,
      'URL': downloadURL,
      'data': data,
      'extra': extra,
    });
    await setStatus(PortableNetworkStatus.success);
  }

}
