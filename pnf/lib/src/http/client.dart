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
import 'package:mkm/type.dart';


/// Simple HTTP Client for upload/download files
class HTTPClient {

  String userAgent = 'DIMP/1.0 (Linux; U; Android 4.1; zh-CN)'
      ' DIMCoreKit/1.0 (Terminal, like WeChat)'
      ' DIM-by-GSP/1.0.1';

  //
  //  Upload
  //

  Future<Response<T>?> upload<T>(Uri url, {
    FormData? data,
    Options? options,
    ProgressCallback? onSendProgress,
    // ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await Dio().postUri<T>(url,
        data: data,
        options: options,
        onSendProgress: onSendProgress,
        // onReceiveProgress: onReceiveProgress,
      ).onError((error, stackTrace) {
        print('[DIO] failed to upload ${data?.files.length} file(s), ${data?.length} bytes'
            ' => "$url" error: $error, $stackTrace');
        throw Exception(error);
      });
    } catch (e, st) {
      print('[HTTP] failed to upload ${data?.files.length} file(s), ${data?.length} bytes'
          ' => "$url" error: $e, $st');
      return null;
    }
  }

  Options uploadOptions(ResponseType responseType) => Options(
    responseType: responseType,
    headers: {
      'User-Agent': userAgent,
    },
  );

  //
  //  Download
  //

  Future<Response<D>?> download<D>(Uri url, {
    Options? options,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await Dio().getUri<D>(url,
        options: options,
        onReceiveProgress: onReceiveProgress,
      ).onError((error, stackTrace) {
        print('[DIO] failed to download "$url" error: $error, $stackTrace');
        throw Exception(error);
      });
    } catch (e, st) {
      print('[HTTP] failed to download "$url" error: $e, $st');
      return null;
    }
  }

  Options downloadOptions(ResponseType responseType) => Options(
    responseType: responseType,
    headers: {
      'User-Agent': userAgent,
    },
  );

  //
  //  Utils
  //

  static Uri? parseURL(String? url, [int start = 0, int? end]) {
    if (url == null) {
      return null;
    }
    try {
      return Uri.parse(url, start, end);
    } catch (e, st) {
      print('[HTTP] url error: $url, $e, $st');
      return null;
    }
  }

  static FormData buildFormData(String key, MultipartFile file) => FormData.fromMap({
    key: file,
  });

  static MultipartFile buildMultipartFile(String filename, Uint8List data) => MultipartFile.fromBytes(
    data,
    filename: filename,
    // contentType: MediaType.parse('application/octet-stream'),
  );

  static int? getContentLength(Response response) {
    String? value = response.headers.value(Headers.contentLengthHeader);
    return Converter.getInt(value, null);
  }

}
