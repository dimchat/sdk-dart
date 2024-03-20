/* license: https://mit-license.org
 *
 *  PNF : Portable Network File
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

import 'package:mkm/digest.dart';
import 'package:mkm/format.dart';

import 'dos/paths.dart';


class URLHelper {

  ///  Get hashed filename
  ///  1. get ext from URL (or from filename)
  ///  2. filename = hex(md5(url)) + ext
  ///
  /// @return "md5(url) + .ext"
  static String filenameFromURL(Uri url, String? filename) {
    String? urlFilename = Paths.filename(url.toString());
    // check URL extension
    String? urlExt;
    if (urlFilename != null) {
      urlExt = Paths.extension(urlFilename);
      if (_isEncoded(urlFilename, urlExt)) {
        // URL filename already encoded
        return urlFilename;
      }
    }
    // check filename extension
    String? ext;
    if (filename != null) {
      ext = Paths.extension(filename);
      if (_isEncoded(filename, ext)) {
        // filename already encoded
        return filename;
      }
    }
    ext ??= urlExt;
    // get filename from URL
    Uint8List data = UTF8.encode(url.toString());
    filename = Hex.encode(MD5.digest(data));
    return ext == null || ext.isEmpty ? filename : '$filename.$ext';
  }

  ///  Get hashed filename
  ///  1. get ext from filename
  ///  2. filename = hex(md5(data)) + ext
  ///
  /// @return "md5(data) + .ext"
  static String filenameFromData(Uint8List data, String filename) {
    // split file extension
    String? ext = Paths.extension(filename);
    if (_isEncoded(filename, ext)) {
      // already encoded
      return filename;
    }
    // get filename from data
    filename = Hex.encode(MD5.digest(data));
    return ext == null || ext.isEmpty ? filename : '$filename.$ext';
  }

  ///  Check whether it is a hashed filename
  static bool isFilenameEncoded(String filename) {
    String? ext = Paths.extension(filename);
    return _isEncoded(filename, ext);
  }

  static bool _isEncoded(String filename, String? ext) {
    if (ext != null/* && ext.isNotEmpty*/) {
      filename = filename.substring(0, filename.length - ext.length - 1);
    }
    return filename.length == 32 && _hex.hasMatch(filename);
  }
  static final _hex = RegExp(r'^[\dA-Fa-f]+$');

}
