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
import 'package:path/path.dart' as utils;

import 'files.dart';


class Paths {

  ///  Append all components to the path with separator
  ///
  /// @param path       - root directory
  /// @param components - sub-dir or filename
  /// @return new path
  static String append(String a, [String? b, String? c, String? d, String? e]) {
    return utils.join(a, b, c, d, e);
  }

  ///  Get filename from a URL/Path
  ///
  /// @param path - uri string
  /// @return filename
  static String? filename(String path) {
    return utils.basename(path);
  }

  ///  Get extension from a filename
  ///
  /// @param filename - file name
  /// @return file extension without prefix '.'
  static String? extension(String filename) {
    String ext = utils.extension(filename);
    return ext.isEmpty ? null : trimExtension(ext);
  }

  static String trimExtension(String ext) {
    int start = 0, end = ext.length;
    // seek for start
    for (; start < ext.length; ++start) {
      if (ext.codeUnitAt(start) != dot) {
        break;
      }
    }
    // seek for end
    for (; end > 0; --end) {
      if (ext.codeUnitAt(end - 1) != dot) {
        break;
      }
    }
    if (0 == start && end == ext.length) {
      return ext;
    }
    return ext.substring(start, end);
  }
  static final int dot = '.'.codeUnitAt(0);

  ///  Get parent directory
  ///
  /// @param path - full path
  /// @return parent path
  static String? parent(String path) {
    return utils.dirname(path);
  }

  ///  Get absolute path
  ///
  /// @param relative - relative path
  /// @param base     - base directory
  /// @return absolute path
  static String abs(String relative, {required String base}) {
    if (relative.startsWith('/') || relative.indexOf(':') > 0) {
      // Linux   - "/filename"
      // Windows - "C:\\filename"
      // URL     - "file://filename"
      return relative;
    }
    String path;
    if (base.endsWith('/') || base.endsWith('\\')) {
      path = base + relative;
    } else {
      String separator = base.contains('\\') ? '\\' : '/';
      path = base + separator + relative;
    }
    if (path.contains('./')) {
      return tidy(path, separator: '/');
    } else if (path.contains('.\\')) {
      return tidy(path, separator: '\\');
    } else {
      return path;
    }
  }

  ///  Remove relative components in full path
  ///
  /// @param path      - full path
  /// @param separator - file separator
  /// @return absolute path
  static String tidy(String path, {required String separator}) {
    path = utils.normalize(path);
    if (separator == '/' && path.contains('\\')) {
      path = path.replaceAll('\\', '/');
    }
    return path;
  }

  //
  //  Read
  //

  ///  Check whether file exists
  ///
  /// @param path - file path
  /// @return true on exists
  static Future<bool> exists(String path) async {
    File file = File(path);
    return await file.exists();
  }

  //
  //  Write
  //

  ///  Create directory
  ///
  /// @param path - dir path
  /// @return false on error
  static Future<bool> mkdirs(String path) async {
    Directory dir = Directory(path);
    await dir.create(recursive: true);
    return await dir.exists();
  }

  ///  Delete file
  ///
  /// @param path - file path
  /// @return false on error
  static Future<bool> delete(String path) async {
    File file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    return true;
  }

}
