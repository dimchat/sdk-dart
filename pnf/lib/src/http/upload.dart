/* license: https://mit-license.org
 *
 *  HyperText Transfer Protocol
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
import 'package:dio/dio.dart';
import 'package:object_key/object_key.dart';
import 'package:startrek/skywalker.dart';

import 'client.dart';
import 'tasks.dart';


/// HTTP Uploader
abstract interface class Uploader {

  /// Add upload task
  Future<bool> addTask(UploadTask task);

  /// Start the uploader in background thread
  void start();

}


class FileUploader extends Runner implements Uploader {
  FileUploader(this.client) : super(Runner.INTERVAL_SLOW * 4);

  final HTTPClient client;

  final List<UploadTask> _tasks = WeakList();

  @override
  Future<bool> addTask(UploadTask task) async {
    var ok = await task.prepare();
    if (ok) {
      _tasks.add(task);
    }
    return ok;
  }
  // private
  UploadTask? getTask() {
    if (_tasks.isNotEmpty) {
      return _tasks.removeAt(0);
    }
    return null;
  }
  // private
  Future<int> removeTasks(UploadInfo params, String? response) async {
    int success = 0;
    List<UploadTask> all = _tasks.toList();
    UploadInfo? that;
    for (UploadTask item in all) {
      if (item.params != params) {
        continue;
      }
      try {
        // try to process the task with same upload params (URL & form data)
        if (await item.prepare()) {
          that = item.params;
        } else {
          that = null;
        }
        // check params
        if (that == null) {
          _tasks.remove(item);
        } else if (that == params) {
          assert(false, 'should not happen: $params');
          await item.process(response);
          _tasks.remove(item);
        } else {
          assert(false, 'should not happen: $params, $that');
        }
      } catch (e, st) {
        print('[HTTP] failed to handle: ${response?.length} bytes, $params, error: $e, $st');
      }
    }
    return success;
  }

  @override
  void start() {
    /*await */run();
  }

  @override
  Future<bool> process() async {
    //
    //  0. get next task
    //
    UploadTask? next = getTask();
    if (next == null) {
      // nothing to do now, return false to have a rest.
      return false;
    }
    //
    //  1. prepare the task
    //
    UploadInfo? params;
    try {
      if (await next.prepare()) {
        params = next.params;
      }
      if (params == null) {
        // this task doesn't need to upload
        // return true for next task immediately
        return true;
      }
    } catch (e, st) {
      print('[HTTP] failed to prepare HTTP task: $next, error: $e, $st');
      return false;
    }
    //
    //  2. do the job
    //
    String? text;
    try {
      text = await upload(params.url, params.data,
        onSendProgress: (count, total) => next.progress(count, total),
      );
    } catch (e, st) {
      print('[HTTP] failed to upload: $params, error: $e, $st');
    }
    //
    //  3. callback with downloaded data
    //
    try {
      await next.process(text);
    } catch (e, st) {
      print('[HTTP] failed to process: ${text?.length} bytes, $params, error: $e, $st');
    }
    if (text != null && text.isNotEmpty) {
      // check other task with same URL
      await removeTasks(params, text);
    }
    return true;
  }

  /// Upload file data onto URL
  Future<String?> upload(Uri url, FormData data, {
    ProgressCallback? onSendProgress,
    // ProgressCallback? onReceiveProgress,
  }) async {
    var options = client.uploadOptions(ResponseType.plain);
    Response<String>? response = await client.upload(url,
      data: data,
      options: options,
      onSendProgress: onSendProgress,
      // onReceiveProgress: onReceiveProgress,
    );
    int? statusCode = response?.statusCode;
    if (response == null || statusCode != 200) {
      assert(false, 'failed to upload $url, status: $statusCode - ${response?.statusMessage}');
      return null;
    }
    String? text = response.data;
    assert(text is String, 'response text error: $response');
    return text;
  }

}
