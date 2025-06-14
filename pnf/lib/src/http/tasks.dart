/* license: https://mit-license.org
 *
 *  HyperText Transfer Protocol
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

import 'package:dio/dio.dart';


/// Download Parameters
class DownloadInfo {
  DownloadInfo(this.url);

  final Uri url;

  @override
  String toString() => url.toString();

  @override
  bool operator ==(Object other) {
    if (other is DownloadInfo) {
      if (identical(this, other)) {
        // same object
        return true;
      }
      return other.url == url;
    } else if (other is Uri) {
      return other == url;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => url.hashCode;

}

class DownloadPriority {
  // ignore_for_file: constant_identifier_names

  static const int URGENT = -1;
  static const int NORMAL =  0;
  static const int SLOWER =  1;

}

/// HTTP Task
abstract interface class DownloadTask {

  /// Smaller is faster
  int get priority;

  /// Remote URL
  DownloadInfo? get downloadParams;

  /// Prepare the task
  ///
  /// @return false when cached file found
  Future<bool> prepareDownload();

  /// Callback when downloading
  Future<void> downloadProgress(int count, int total);

  /// Callback when download completed or failed
  Future<void> processResponse(Uint8List? data);

}


/// Upload Parameters
class UploadInfo {
  UploadInfo(this.url, this.data);

  final Uri url;
  final FormData data;

  @override
  String toString() => '<$runtimeType url="$url" size=${data.length} />';

  @override
  bool operator ==(Object other) {
    if (other is UploadInfo) {
      if (identical(this, other)) {
        // same object
        return true;
      }
      return other.url == url && _FormUtils.checkData(other.data, data);
    } else {
      return false;
    }
  }

  @override
  int get hashCode => url.hashCode + _FormUtils.hashData(data) * 13;

}

/// Comparing form data
abstract interface class _FormUtils {

  static int hashData(FormData data) {
    return data.hashCode;
  }

  /// check form data
  static bool checkData(FormData a, FormData b) {
    if (identical(a, b)) {
      // same object
      return true;
    }
    return checkFields(a.fields, b.fields) && checkFiles(a.files, b.files);
  }

  static bool checkFields(List<MapEntry<String, String>> a, List<MapEntry<String, String>> b) {
    if (identical(a, b)) {
      // same object
      return true;
    } else if (a.length != b.length) {
      return false;
    }
    for (var item in a) {
      if (containsField(item, b)) {
        continue;
      } else {
        return false;
      }
    }
    return true;
  }
  static bool checkFiles(List<MapEntry<String, MultipartFile>> a, List<MapEntry<String, MultipartFile>> b) {
    if (identical(a, b)) {
      // same object
      return true;
    } else if (a.length != b.length) {
      return false;
    }
    for (var item in a) {
      if (containsFile(item, b)) {
        continue;
      } else {
        return false;
      }
    }
    return true;
  }

  static bool containsField(MapEntry<String, String> field, List<MapEntry<String, String>> array) {
    for (var item in array) {
      if (item.key == field.key && item.value == field.value) {
        return true;
      }
    }
    return false;
  }
  static bool containsFile(MapEntry<String, MultipartFile> file, List<MapEntry<String, MultipartFile>> array) {
    for (var item in array) {
      if (item.key == file.key && checkMultipartFile(item.value, file.value)) {
        return true;
      }
    }
    return false;
  }
  static bool checkMultipartFile(MultipartFile a, MultipartFile b) {
    if (a.filename != b.filename) {
      return false;
    } else if (a.length != b.length) {
      return false;
    }
    // TODO: compare file data?

    // because the filename here is an encode string:
    //
    //      "MD5(file_data).ext"
    //
    // so, if filenames equal, then file data equal too.
    return true;
  }

}

/// HTTP Task
abstract interface class UploadTask {

  /// Remote URL & form data
  UploadInfo? get uploadParams;

  /// Prepare the task
  ///
  /// @return false when same task done
  Future<bool> prepareUpload();

  /// Callback when uploading
  Future<void> uploadProgress(int count, int total);

  /// Callback when upload completed or failed
  Future<void> processResponse(String? response);
}
