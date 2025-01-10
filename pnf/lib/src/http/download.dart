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
import 'package:object_key/object_key.dart';
import 'package:startrek/skywalker.dart';

import 'client.dart';
import 'tasks.dart';


/// HTTP Downloader
abstract interface class Downloader {

  /// Add download task
  Future<bool> addTask(DownloadTask task);

  /// Start the downloader in background thread
  void start();

}


class FileDownloader extends Runner implements Downloader {
  FileDownloader(this.client) : super(Runner.INTERVAL_SLOW * 4);

  final HTTPClient client;

  final List<DownloadTask> _tasks = WeakList();

  @override
  Future<bool> addTask(DownloadTask task) async {
    var ok = await task.prepare();
    if (ok) {
      _tasks.add(task);
    }
    return ok;
  }
  // private
  DownloadTask? getTask() {
    if (_tasks.isNotEmpty) {
      return _tasks.removeAt(0);
    }
    return null;
  }
  // private
  Future<int> removeTasks(DownloadInfo params, Uint8List downData) async {
    int success = 0;
    List<DownloadTask> array = _tasks.toList();
    for (DownloadTask item in array) {
      // 1. check params
      if (item.params != params) {
        continue;
      }
      try {
        // 2. process the task with same params (download URL)
        if (await item.prepare()) {
          await item.process(downData);
        }
        // 3. remove this task from waiting queue
        _tasks.remove(item);
      } catch (e, st) {
        print('[HTTP] failed to handle data: ${downData.length} bytes, $params, error: $e, $st');
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
    DownloadTask? next = getTask();
    if (next == null) {
      // nothing to do now, return false to have a rest.
      return false;
    }
    //
    //  1. prepare the task
    //
    DownloadInfo? params;
    try {
      if (await next.prepare()) {
        params = next.params;
      }
      if (params == null) {
        // this task doesn't need to download
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
    Uint8List? data;
    try {
      data = await download(params.url,
        onReceiveProgress: (count, total) => next.progress(count, total),
      );
    } catch (e, st) {
      print('[HTTP] failed to download: $params, error: $e, $st');
    }
    //
    //  3. callback with downloaded data
    //
    try {
      await next.process(data);
    } catch (e, st) {
      print('[HTTP] failed to process: ${data?.length} bytes, $params, error: $e, $st');
    }
    if (data != null && data.isNotEmpty) {
      // check other task with same URL
      await removeTasks(params, data);
    }
    return true;
  }

  /// Download file data from URL
  Future<Uint8List?> download(Uri url, {
    ProgressCallback? onReceiveProgress,
  }) async {
    var options = client.downloadOptions(ResponseType.bytes);
    Response<Uint8List>? response = await client.download(url,
      options: options,
      onReceiveProgress: onReceiveProgress,
    );
    int? statusCode = response?.statusCode;
    if (response == null || statusCode != 200) {
      assert(false, 'failed to download $url, status: $statusCode - ${response?.statusMessage}');
      return null;
    }
    int? contentLength = HTTPClient.getContentLength(response);
    Uint8List? data = response.data;
    if (data == null) {
      assert(contentLength == 0, 'content length error: $contentLength');
    } else if (contentLength != null && contentLength != data.length) {
      assert(false, 'content length not match: $contentLength, ${data.length}');
    }
    return data;
  }

}
