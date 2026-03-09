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


/// Interface for bidirectional short key mapping (long string keys ↔ single-char keys).
///
/// Core function: Replace system-defined long string keys with pre-defined single-character
/// short keys (and vice versa) to reduce the size of JSON-serialized data.
///
/// Key features:
/// - Bi-directional conversion (compress → extract)
/// - Preserves data structure, only replaces key names
/// - Maintains compatibility with core message components
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


/// Concrete implementation of [Shortener] for message/content/key short key mapping.
///
/// Implements fixed key pair conversion with in-place Map modification,
/// including special handling for "K" (supports both "key" and "keys").
class MessageShortener implements Shortener {

  /// Moves value from source key to target key (removes source key).
  ///
  /// Throws assertion error if target key already exists (key conflict).
  ///
  /// Parameters:
  /// - [from] : Source key to move from
  /// - [to]   : Target key to move to
  /// - [info] : Map to modify (in-place)
  // protected
  void moveKey(String from, String to, Map info) {
    var value = info[from];
    if (value != null) {
      assert(info[to] == null, 'keys conflicted: "$from" -> "$to", $info');
      info.remove(from);
      info[to] = value;
    }
  }

  /// Batch shortens keys using a list of (shortKey, longKey) pairs.
  ///
  /// List format: [shortKey1, longKey1, shortKey2, longKey2, ...]
  ///
  /// Parameters:
  /// - [keys] : List of key pairs (short → long)
  /// - [info] : Map to modify (in-place)
  // protected
  void shortenKeys(List<String> keys, Map info) {
    int i = 1;
    while (i < keys.length) {
      moveKey(keys[i], keys[i - 1], info);
      i += 2;
    }
  }

  /// Batch restores keys using a list of (shortKey, longKey) pairs.
  ///
  /// Reverse of [shortenKeys], list format: [shortKey1, longKey1, ...]
  ///
  /// Parameters:
  /// - [keys] : List of key pairs (short → long)
  /// - [info] : Map to modify (in-place)
  // protected
  void restoreKeys(List<String> keys, Map info) {
    int i = 1;
    while (i < keys.length) {
      moveKey(keys[i - 1], keys[i], info);
      i += 2;
    }
  }

  // -------------------------------------------------------------------------
  //  Content Key Mapping
  // -------------------------------------------------------------------------

  List<String> contentShortKeys = [
    "T", "type",
    "N", "sn",
    "W", "time",        // When
    "G", "group",
    "C", "command",     // Command name
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

  // -------------------------------------------------------------------------
  //  Symmetric Key Mapping
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  //  ReliableMessage Key Mapping
  // -------------------------------------------------------------------------

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
