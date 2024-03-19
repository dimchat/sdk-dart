/* license: https://mit-license.org
 *
 *  File System
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
import 'dart:io';

import 'dos/paths.dart';

import 'external.dart';


/// Local Storage
class LocalCache {
  factory LocalCache() => _instance;
  static final LocalCache _instance = LocalCache._internal();
  LocalCache._internal();

  ///  Protected caches directory
  ///  (meta/visa/document, image/audio/video, ...)
  ///
  /// Android: "/sdcard/Android/data/chat.dim.sechat/cache"
  ///     iOS: "/Application/{...}/Library/Caches"
  String cachesDirectory = '/var/caches';

  ///  Protected temporary directory
  ///  (uploading, downloaded)
  ///
  /// Android: "/data/data/chat.dim.sechat/cache"
  ///     iOS: "/Application/{...}/tmp"
  String temporaryDirectory = '/tmp';

  ///  Cached file path
  ///  (image, audio, video, ...)
  ///
  /// @param filename - messaged filename: hex(md5(data)) + ext
  /// @return "{caches}/files/{AA}/{BB}/{filename}"
  Future<String?> getCacheFilePath(String filename) async {
    String dir = cachesDirectory;
    if (filename.length < 4) {
      assert(false, 'invalid filename: $filename');
      return Paths.append(dir, filename);
    }
    String aa = filename.substring(0, 2);
    String bb = filename.substring(2, 4);
    return Paths.append(dir, 'files', aa, bb, filename);
  }

  ///  Encrypted data file path
  ///
  /// @param filename - messaged filename: hex(md5(data)) + ext
  /// @return "{tmp}/upload/{filename}"
  Future<String?> getUploadFilePath(String filename) async {
    String dir = temporaryDirectory;
    return Paths.append(dir, 'upload', filename);
  }

  ///  Encrypted data file path
  ///
  /// @param filename - messaged filename: hex(md5(data)) + ext
  /// @return "{tmp}/download/{filename}"
  Future<String?> getDownloadFilePath(String filename) async {
    String dir = temporaryDirectory;
    return Paths.append(dir, 'download', filename);
  }

  ///  Remove expired files
  ///
  /// @param expired - remove files after this time
  /// @return removed count
  Future<int> burnCaches(DateTime expired) async {
    // check last time
    DateTime now = DateTime.now();
    DateTime? last = _lastBurned;
    if (last != null) {
      int elapsed = now.millisecondsSinceEpoch - last.millisecondsSinceEpoch;
      if (elapsed < 15000) {
        // too frequently
        return 0;
      }
    }
    _lastBurned = now;
    // cleanup cached files
    String path = cachesDirectory;
    path = Paths.append(path, 'files');
    Directory dir = Directory(path);
    return await ExternalStorage.cleanupDirectory(dir, expired);
  }

  DateTime? _lastBurned;

}
