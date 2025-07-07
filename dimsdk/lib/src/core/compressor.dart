/* license: https://mit-license.org
 *
 *  DIMP : Decentralized Instant Messaging Protocol
 *
 *                                Written in 2025 by Moky <albert.moky@gmail.com>
 *
 * ==============================================================================
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
 * ==============================================================================
 */
import 'dart:typed_data';

import 'package:dimp/crypto.dart';

import 'compress_keys.dart';


abstract interface class Compressor {

  Uint8List compressContent(Map content, Map key);
  Map? extractContent(Uint8List data, Map key);

  Uint8List compressSymmetricKey(Map key);
  Map? extractSymmetricKey(Uint8List data);

  Uint8List compressReliableMessage(Map msg);
  Map? extractReliableMessage(Uint8List data);

}


class MessageCompressor implements Compressor {
  MessageCompressor(this.shortener);

  // protected
  final Shortener shortener;

  ///
  ///  Compress Content
  ///

  @override
  Uint8List compressContent(Map content, Map key) {
    content = shortener.compressContent(content);
    String json = JSONMap.encode(content);
    return UTF8.encode(json);
  }

  @override
  Map? extractContent(Uint8List data, Map key) {
    var json = UTF8.decode(data);
    if (json == null) {
      assert(false, 'content data error: ${data.length}');
      return null;
    }
    var info = JSONMap.decode(json);
    if (info != null) {
      info = shortener.extractContent(info);
    }
    return info;
  }

  ///
  ///  Compress SymmetricKey
  ///

  @override
  Uint8List compressSymmetricKey(Map key) {
    key = shortener.compressSymmetricKey(key);
    String json = JSONMap.encode(key);
    return UTF8.encode(json);
  }

  @override
  Map? extractSymmetricKey(Uint8List data) {
    var json = UTF8.decode(data);
    if (json == null) {
      assert(false, 'symmetric key error: ${data.length}');
      return null;
    }
    var key = JSONMap.decode(json);
    if (key != null) {
      key = shortener.extractSymmetricKey(key);
    }
    return key;
  }

  ///
  ///  Compress ReliableMessage
  ///

  @override
  Uint8List compressReliableMessage(Map msg) {
    msg = shortener.compressReliableMessage(msg);
    String json = JSONMap.encode(msg);
    return UTF8.encode(json);
  }

  @override
  Map? extractReliableMessage(Uint8List data) {
    var json = UTF8.decode(data);
    if (json == null) {
      assert(false, 'reliable message error: ${data.length}');
      return null;
    }
    var msg = JSONMap.decode(json);
    if (msg != null) {
      msg = shortener.extractReliableMessage(msg);
    }
    return msg;
  }

}
