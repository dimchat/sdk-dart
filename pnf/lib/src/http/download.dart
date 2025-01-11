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
    var waiting = await task.prepareDownload();
    if (waiting) {
      _tasks.add(task);
    }
    return waiting;
  }
  // private
  DownloadTask? getTask() {
    if (_tasks.isNotEmpty) {
      return _tasks.removeAt(0);
    }
    return null;
  }
  // private
  Future<int> removeTasks(DownloadInfo params, Uint8List? downData) async {
    int success = 0;
    List<DownloadTask> array = _tasks.toList();
    for (DownloadTask item in array) {
      // 1. check params
      if (item.downloadParams != params) {
        continue;
      }
      try {
        // 2. process the task with same params (download URL)
        if (await item.prepareDownload()) {
          await item.processResponse(downData);
        }
        success += 1;
      } catch (e, st) {
        print('[HTTP] failed to handle data: ${downData?.length} bytes, $params, error: $e, $st');
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
    DownloadTask? next = getTask();
    if (next == null) {
      // nothing to do now, return false to have a rest.
      return false;
    }
    // try to process next task
    try {
      await handleDownloadTask(next);
    } catch (e, st) {
      print('[HTTP] failed to process upload task: $e, $next, $st');
      return false;
    }
    // OK, return true to next loop immediately
    return true;
  }

  /// Download synchronously
  Future<Uint8List?> handleDownloadTask(DownloadTask task) async {
    // prepare the task
    DownloadInfo? params;
    if (await task.prepareDownload()) {
      params = task.downloadParams;
      assert(params != null, 'download params error: $task');
    }
    if (params == null) {
      // this task doesn't need to download again
      return null;
    }
    // download from remote URL
    Uint8List? data = await download(params.url,
      onReceiveProgress: (count, total) => task.downloadProgress(count, total),
    );
    // download success, process respond data
    await task.processResponse(data);
    // clear other tasks with same URL
    await removeTasks(params, data);
    // done
    return data;
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
