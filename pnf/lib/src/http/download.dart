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
import 'package:startrek/skywalker.dart';

import 'client.dart';
import 'queue.dart';
import 'tasks.dart';


/// HTTP Downloader
abstract interface class Downloader {

  /// Add download task
  Future<bool> addTask(DownloadTask task);

  /// Start the downloader in background thread
  void start();

}


class FileDownloader implements Downloader {
  FileDownloader(this.client);

  final HTTPClient client;

  final DownloadQueue queue = DownloadQueue();
  final List<Spider> spiders = [];

  @override
  Future<bool> addTask(DownloadTask task) async {
    var waiting = await task.prepareDownload();
    if (waiting) {
      queue.addTask(task);
    }
    return waiting;
  }

  /// get next task
  DownloadTask? getTask(int maxPriority) => queue.nextTask(maxPriority);

  /// finish same tasks
  Future<int> removeTasks(DownloadTask task, Uint8List? downData) async =>
      await queue.removeTasks(task, downData);

  void setup() {
    spiders.add(Spider(priority: DownloadPriority.URGENT, downloader: this));
    spiders.add(Spider(priority: DownloadPriority.NORMAL, downloader: this));
    spiders.add(Spider(priority: DownloadPriority.SLOWER, downloader: this));
  }

  void run() {
    for (var worker in spiders) {
      /*await */worker.run();
    }
  }

  // void finish() {
  //   for (var worker in spiders) {
  //     /*await */worker.finish();
  //   }
  // }
  //
  // void stop() {
  //   for (var worker in spiders) {
  //     /*await */worker.stop();
  //   }
  // }

  @override
  void start() {
    setup();
    run();
  }

  /// Download synchronously
  Future<Uint8List?> handleDownloadTask(DownloadTask task) async {
    //
    //  0. prepare the task
    //
    DownloadInfo? params;
    try {
      if (await task.prepareDownload()) {
        params = task.downloadParams;
        assert(params != null, 'download params error: $task');
      }
    } catch (e, st) {
      print('[HTTP] failed to prepare download task: $task, error: $e, $st');
    }
    if (params == null) {
      // this task doesn't need to download again
      return null;
    }
    //
    //  1. download from remote URL
    //
    Uint8List? data = await download(params.url,
      onReceiveProgress: (count, total) => task.downloadProgress(count, total),
    );
    //
    //  2. download success, process respond data
    //
    try {
      await task.processResponse(data);
    } catch (e, st) {
      print('[HTTP] failed to handle data: ${data?.length} bytes, $params, error: $e, $st');
    }
    //
    //  3. clear other tasks with same URL
    //
    if (data == null) {
      // FIXME: try again when download failed?
      // return null;
    }
    await removeTasks(task, data);
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
      // assert(false, 'failed to download $url, status: $statusCode - ${response?.statusMessage}');
      print('[HTTP] failed to download $url, status: $statusCode - ${response?.statusMessage}');
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


class Spider extends Runner {
  Spider({
    required this.priority,
    required FileDownloader downloader
  }) : super(Runner.INTERVAL_SLOW * 4) {
    downloaderRef = WeakReference(downloader);
  }

  final int priority;
  late final WeakReference<FileDownloader> downloaderRef;

  FileDownloader? get downloader => downloaderRef.target;

  @override
  bool get isRunning => super.isRunning && downloader != null;

  @override
  Future<bool> process() async {
    // get next task
    DownloadTask? next = downloader?.getTask(priority);
    if (next == null) {
      // nothing to do now, return false to have a rest.
      return false;
    }
    // try to process next task
    try {
      await downloader?.handleDownloadTask(next);
    } catch (e, st) {
      print('[HTTP] failed to process download task: $e, $next, $st');
      return false;
    }
    // OK, return true to next loop immediately
    return true;
  }

}
