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


/// HTTP Task
abstract interface class DownloadTask {

  /// Remote URL
  Uri? get downloadURL;

  /// Prepare the task and get remote URL
  ///
  /// @return null when cached file found
  Future<Uri?> prepare();

  /// Callback when downloading
  Future<void> progress(int count, int total);

  /// Callback when download completed or failed
  Future<void> process(Uint8List? data);

}

/// HTTP Downloader
abstract interface class Downloader {

  /// Add download task
  Future<bool> addTask(DownloadTask task);

  /// Start the downloader in background thread
  void start();

}

abstract class FileDownloader extends Runner implements Downloader {
  FileDownloader() : super(Runner.INTERVAL_SLOW * 4);

  final List<DownloadTask> _tasks = WeakList();

  @override
  Future<bool> addTask(DownloadTask task) async {
    Uri? url = await task.prepare();
    if (url == null) {
      return false;
    }
    _tasks.add(task);
    return true;
  }
  // private
  DownloadTask? getTask() {
    if (_tasks.isNotEmpty) {
      return _tasks.removeAt(0);
    }
    return null;
  }
  // private
  Future<int> removeTasks(Uri downURL, Uint8List downData) async {
    int success = 0;
    List<DownloadTask> all = _tasks.toList();
    Uri? that;
    for (DownloadTask item in all) {
      try {
        if (item.downloadURL != downURL) {
          continue;
        }
        // try to process the task with same download URL
        that = await item.prepare();
        if (that == null) {
          _tasks.remove(item);
        } else if (that == downURL) {
          assert(false, 'should not happen: $downURL');
          await item.process(downData);
          _tasks.remove(item);
        } else {
          assert(false, 'should not happen: $downURL, $that');
        }
      } catch (e, st) {
        print('[HTTP] failed to handle: ${downData.length} bytes, $downURL, error: $e, $st');
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
    Uri? url;
    try {
      url = await next.prepare();
      if (url == null) {
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
      data = await download(url,
        onReceiveProgress: (count, total) => next.progress(count, total),
      );
    } catch (e, st) {
      print('[HTTP] failed to download: $url, error: $e, $st');
    }
    //
    //  3. callback with downloaded data
    //
    try {
      await next.process(data);
    } catch (e, st) {
      print('[HTTP] failed to process: ${data?.length} bytes, $url, error: $e, $st');
    }
    if (data != null && data.isNotEmpty) {
      // check other task with same URL
      await removeTasks(url, data);
    }
    return true;
  }

  /// Download file data from URL
  Future<Uint8List?> download(Uri url, {ProgressCallback? onReceiveProgress});

}
