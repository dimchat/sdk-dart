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
    var waiting = await task.prepareUpload();
    if (waiting) {
      _tasks.add(task);
    }
    return waiting;
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
    List<UploadTask> array = _tasks.toList();
    for (UploadTask item in array) {
      // 1. check params
      if (item.uploadParams != params) {
        continue;
      }
      try {
        // 2. process the task with same params (upload URL & form data)
        if (await item.prepareUpload()) {
          await item.processResponse(response);
        }
        success += 1;
      } catch (e, st) {
        print('[HTTP] failed to handle response: ${response?.length} bytes, $params, error: $e, $st');
      }
      // 3. remove this task from waiting queue
      _tasks.remove(item);
    }
    return success;
  }

  @override
  void start() {
    /*await */run();
  }

  @override
  Future<bool> process() async {
    // get next task
    UploadTask? next = getTask();
    if (next == null) {
      // nothing to do now, return false to have a rest.
      return false;
    }
    // try to process next task
    try {
      await handleUploadTask(next);
    } catch (e, st) {
      print('[HTTP] failed to process upload task: $e, $next, $st');
      return false;
    }
    // OK, return true to next loop immediately
    return true;
  }

  /// Upload synchronously
  Future<String?> handleUploadTask(UploadTask task) async {
    // prepare the task
    UploadInfo? params;
    if (await task.prepareUpload()) {
      params = task.uploadParams;
      assert(params != null, 'upload params error: $task');
    }
    if (params == null) {
      // this task doesn't need to upload again
      return null;
    }
    // upload to remote URL
    String? text = await upload(params.url, params.data,
      onSendProgress: (count, total) => task.uploadProgress(count, total),
    );
    // upload success, process respond data
    await task.processResponse(text);
    // clear other tasks with same URL & form data
    await removeTasks(params, text);
    // done
    return text;
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
    if (text == null || text.isEmpty) {
      assert(false, 'response text error: $response');
    }
    return text;
  }

}
