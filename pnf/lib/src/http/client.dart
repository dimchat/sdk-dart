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

  Future<String?> upload(Uri url, String key, String filename, Uint8List fileData,
      {ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) async {
    Response<String> response;
    try {
      response = await Dio().postUri<String>(url,
        data: _HTTPHelper.buildFormData(key, filename, fileData),
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        options: _HTTPHelper.uploadOptions(userAgent),
      ).onError((error, stackTrace) {
        print('[DIO] failed to upload ($key, $filename, ${fileData.length} bytes)'
            ' => "$url" error: $error, $stackTrace');
        throw Exception(error);
      });
    } catch (e, st) {
      print('[HTTP] failed to upload ($key, $filename, ${fileData.length} bytes)'
          ' => "$url" error: $e, $st');
      return null;
    }
    int? statusCode = response.statusCode;
    if (statusCode != 200) {
      assert(false, 'failed to upload $url, status: $statusCode - ${response.statusMessage}');
      return null;
    }
    String? data = response.data;
    assert(data is String, 'response text error: $response');
    return data;
  }

  Future<Uint8List?> download(Uri url, {ProgressCallback? onReceiveProgress}) async {
    Response<Uint8List> response;
    try {
      response = await Dio().getUri<Uint8List>(url,
        onReceiveProgress: onReceiveProgress,
        options: _HTTPHelper.downloadOptions(userAgent),
      ).onError((error, stackTrace) {
        print('[DIO] failed to download "$url" error: $error, $stackTrace');
        throw Exception(error);
      });
    } catch (e, st) {
      print('[HTTP] failed to download "$url" error: $e, $st');
      return null;
    }
    int? statusCode = response.statusCode;
    if (statusCode != 200) {
      assert(false, 'failed to download $url, status: $statusCode - ${response.statusMessage}');
      return null;
    }
    int? contentLength = _HTTPHelper.getContentLength(response);
    Uint8List? data = response.data;
    if (data == null) {
      assert(contentLength == 0, 'content length error: $contentLength');
    } else if (contentLength != null && contentLength != data.length) {
      assert(false, 'content length not match: $contentLength, ${data.length}');
    }
    return data;
  }

}

class _HTTPHelper {

  static FormData buildFormData(String key, String filename, Uint8List data) => FormData.fromMap({
    key: MultipartFile.fromBytes(data,
      filename: filename,
      // contentType: MediaType.parse('application/octet-stream'),
    ),
  });

  static Options uploadOptions(String userAgent) => Options(
    responseType: ResponseType.plain,
    headers: {
      'User-Agent': userAgent,
    },
  );

  static Options downloadOptions(String userAgent) => Options(
    responseType: ResponseType.bytes,
    headers: {
      'User-Agent': userAgent,
    },
  );

  static int? getContentLength(Response response) {
    String? value = response.headers.value(Headers.contentLengthHeader);
    return Converter.getInt(value, null);
  }

}
