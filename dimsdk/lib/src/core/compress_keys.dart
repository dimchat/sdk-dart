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


abstract interface class Shortener {
  /** Short Keys

    ======+==================================================+==================
          |   Message        Content        Symmetric Key    |    Description
    ------+--------------------------------------------------+------------------
    "A"   |                                 "algorithm"      |
    "C"   |   "content"      "command"                       |
    "D"   |   "data"                        "data"           |
    "F"   |   "sender"                                       |   (From)
    "G"   |   "group"        "group"                         |
    "I"   |                                 "iv"             |
    "K"   |   "key", "keys"                                  |
    "M"   |   "meta"                                         |
    "N"   |                  "sn"                            |   (Number)
    "P"   |   "visa"                                         |   (Profile)
    "R"   |   "receiver"                                     |
    "S"   |   ...                                            |
    "T"   |   "type"         "type"                          |
    "V"   |   "signature"                                    |   (Verification)
    "W"   |   "time"         "time"                          |   (When)
    ======+==================================================+==================

    Note:
        "S" - deprecated (ambiguous for "sender" and "signature")
   */

  ///
  ///  Compress Content
  ///
  Map compressContent(Map content);
  Map extractContent(Map content);

  ///
  ///  Compress SymmetricKey
  ///
  Map compressSymmetricKey(Map key);
  Map extractSymmetricKey(Map key);

  ///
  ///  Compress ReliableMessage
  ///
  Map compressReliableMessage(Map msg);
  Map extractReliableMessage(Map msg);

}


class MessageShortener implements Shortener {

  // protected
  void moveKey(String from, String to, Map info) {
    var value = info[from];
    if (value != null) {
      assert(info[to] == null, 'keys conflicted: "$from" -> "$to", $info');
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
    "W", "time",        // When
    "G", "group",
    "C", "command",
  ];

  @override
  Map compressContent(Map content) {
    shortenKeys(contentShortKeys, content);
    return content;
  }

  @override
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
    "I", "iv",          // Initial Vector
  ];

  @override
  Map compressSymmetricKey(Map key) {
    shortenKeys(cryptoShortKeys, key);
    return key;
  }

  @override
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
    "V", "signature",   // Verification
    //------------------
    "M", "meta",
    "P", "visa",        // Profile
  ];

  @override
  Map compressReliableMessage(Map msg) {
    moveKey("keys", "K", msg);
    shortenKeys(messageShortKeys, msg);
    return msg;
  }

  @override
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
