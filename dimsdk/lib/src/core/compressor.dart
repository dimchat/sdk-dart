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


abstract interface class Compressor {

  Uint8List compressContent(Map content, Map key);
  Map? extractContent(Uint8List data, Map key);

  Uint8List compressSymmetricKey(Map key);
  Map? extractSymmetricKey(Uint8List data);

  Uint8List compressReliableMessage(Map msg);
  Map? extractReliableMessage(Uint8List data);

}


class MessageCompressor implements Compressor {
  MessageCompressor() {
    shortener = createMessageShortener();
  }

  late final MessageShortener shortener;

  MessageShortener createMessageShortener() => MessageShortener();

  @override
  Uint8List compressContent(Map content, Map key) {
    content = shortener.compressContent(content);
    return UTF8.encode(JSONMap.encode(content));
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

  @override
  Uint8List compressSymmetricKey(Map key) {
    key = shortener.compressSymmetricKey(key);
    return UTF8.encode(JSONMap.encode(key));
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

  @override
  Uint8List compressReliableMessage(Map msg) {
    msg = shortener.compressReliableMessage(msg);
    return UTF8.encode(JSONMap.encode(msg));
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


class MessageShortener {

  // protected
  void moveKey(String from, String to, Map info) {
    var value = info[from];
    if (value != null) {
      info.remove(from);
      info[to] = value;
    }
  }

  // protected
  void shortenKeys(List<String> keys, Map info) {
    int i = 1;
    while (i < keys.length) {
      moveKey(keys[i], keys[i - 1], info);
      i += 2;
    }
  }

  // protected
  void restoreKeys(List<String> keys, Map info) {
    int i = 1;
    while (i < keys.length) {
      moveKey(keys[i - 1], keys[i], info);
      i += 2;
    }
  }

  ///
  ///  Compress Content
  ///
  List<String> contentShortKeys = [
    "T", "type",
    "N", "sn",
    "W", "time",   // When
    "G", "group",
  ];

  Map compressContent(Map content) {
    shortenKeys(contentShortKeys, content);
    return content;
  }

  Map extractContent(Map content) {
    restoreKeys(contentShortKeys, content);
    return content;
  }

  ///
  ///  Compress SymmetricKey
  ///
  List<String> cryptoShortKeys = [
    "A", "algorithm",
    "D", "data",
    "I", "iv",         // Initial Vector
  ];

  Map compressSymmetricKey(Map key) {
    shortenKeys(cryptoShortKeys, key);
    return key;
  }

  Map extractSymmetricKey(Map key) {
    restoreKeys(cryptoShortKeys, key);
    return key;
  }

  ///
  ///  Compress ReliableMessage
  ///
  List<String> messageShortKeys = [
    "F", "sender",      // From
    "R", "receiver",    // Rcpt to
    "W", "time",        // When
    "T", "type",
    "G", "group",
    //------------------
    "K", "key",         // or "keys"
    "D", "data",
    "V", "signature",   // Verify
    //------------------
    "M", "meta",
    "P", "visa",        // Profile
  ];

  Map compressReliableMessage(Map msg) {
    moveKey("keys", "K", msg);
    shortenKeys(messageShortKeys, msg);
    return msg;
  }

  Map extractReliableMessage(Map msg) {
    var keys = msg["K"];
    if (keys == null) {
      // assert(msg["data"] != null, "message data should not empty: $msg");
    } else if (keys is Map) {
      assert(msg["keys"] == null, "message keys duplicated: $msg");
      msg.remove("K");
      msg["keys"] = keys;
    } else if (keys is String) {
      assert(msg["key"] == null, "message key duplicated: $msg");
      msg.remove("K");
      msg["key"] = keys;
    } else {
      assert(false, "message key error: $msg");
    }
    restoreKeys(messageShortKeys, msg);
    return msg;
  }

}
