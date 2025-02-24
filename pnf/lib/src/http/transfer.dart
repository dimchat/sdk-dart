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
import 'client.dart';
import 'download.dart';
import 'tasks.dart';
import 'upload.dart';


class FileTransfer {
  FileTransfer(this.client) {
    downloader = createDownloader();
    uploader = createUploader();
  }

  final HTTPClient client;
  late final Downloader downloader;
  late final Uploader uploader;

  // override for customized downloader
  Downloader createDownloader() {
    var http = FileDownloader(client);
    http.start();
    return http;
  }

  // override for customized uploader
  Uploader createUploader() {
    var http = FileUploader(client);
    http.start();
    return http;
  }

  //  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'
  //  + ' AppleWebKit/537.36 (KHTML, like Gecko)'
  //  + ' Chrome/118.0.0.0 Safari/537.36'
  void setUserAgent(String userAgent) =>
      client.userAgent = userAgent;

  /// Append download task with URL
  Future<bool> addDownloadTask(DownloadTask task) async =>
      downloader.addTask(task);

  /// Append upload task with URL & form data
  Future<bool> addUploadTask(UploadTask task) async =>
      uploader.addTask(task);

}
