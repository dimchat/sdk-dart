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
import 'package:dimp/crypto.dart';


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
    "K"   |   "keys"                                         |
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
  Mapping compressContent(Mapping content);
  Mapping extractContent(Mapping content);

  ///
  ///  Compress SymmetricKey
  ///
  Mapping compressSymmetricKey(Mapping key);
  Mapping extractSymmetricKey(Mapping key);

  ///
  ///  Compress ReliableMessage
  ///
  Mapping compressReliableMessage(Mapping msg);
  Mapping extractReliableMessage(Mapping msg);

}


/// Concrete implementation of [Shortener] for message/content/key short key mapping.
///
/// Implements fixed key pair conversion with in-place Map modification,
/// including special handling for "K" (short for "keys").
class MessageShortener implements Shortener {
  MessageShortener() {

    // build for content
    final (c2l, c2s) = _build([
      "T", "type",
      "N", "sn",
      "W", "time",        // When
      "G", "group",
      "C", "command",     // Command name
    ]);
    contentShortToLong = c2l;
    contentLongToShort = c2s;

    // build for symmetric key
    final (k2l, k2s) = _build([
      "A", "algorithm",
      "D", "data",
      "I", "iv",          // Initial Vector
    ]);
    cryptoShortToLong = k2l;
    cryptoLongToShort = k2s;

    // build for message
    final (m2l, m2s) = _build([
      "F", "sender",      // From
      "R", "receiver",    // Rcpt to
      "W", "time",        // When
      "T", "type",
      "G", "group",
      //------------------
      "K", "keys",
      "D", "data",
      "V", "signature",   // Verification
      //------------------
      "M", "meta",
      "P", "visa",        // Profile
    ]);
    messageShortToLong = m2l;
    messageLongToShort = m2s;
  }

  // -------------------------------------------------------------------------
  //  Content Key Mapping
  // -------------------------------------------------------------------------

  late Map<String, String> contentShortToLong;
  late Map<String, String> contentLongToShort;

  @override
  Mapping compressContent(Mapping content) => _trans(content, contentLongToShort);

  @override
  Mapping extractContent(Mapping content) => _trans(content, contentShortToLong);

  // -------------------------------------------------------------------------
  //  Symmetric Key Mapping
  // -------------------------------------------------------------------------

  late Map<String, String> cryptoShortToLong;
  late Map<String, String> cryptoLongToShort;

  @override
  Mapping compressSymmetricKey(Mapping key) => _trans(key, cryptoLongToShort);

  @override
  Mapping extractSymmetricKey(Mapping key) => _trans(key, cryptoShortToLong);

  // -------------------------------------------------------------------------
  //  ReliableMessage Key Mapping
  // -------------------------------------------------------------------------

  late Map<String, String> messageShortToLong;
  late Map<String, String> messageLongToShort;

  @override
  Mapping compressReliableMessage(Mapping msg) => _trans(msg, messageLongToShort);

  @override
  Mapping extractReliableMessage(Mapping msg) => _trans(msg, messageShortToLong);

}


/// Build key table
(Map<String, String> s2l, Map<String, String> l2s) _build(List<String> keys) {
  Map<String, String> shortToLong = {};
  Map<String, String> longToShort = {};
  int i = 1;
  String k1, k2;
  while (i < keys.length) {
    k1 = keys[i - 1];
    k2 = keys[i];
    assert(k1.length < k2.length, 'key pair error: $k1, $k2');
    shortToLong[k1] = k2;
    longToShort[k2] = k1;
    i += 2;
  }
  return (shortToLong, longToShort);
}


/// Translate
Mapping _trans(Mapping info, Map<String, String> dictionary) {
  Map result = {};
  String? target;
  info.forEach((key, value) {
    target = dictionary[key];
    target ??= key;
    result[target] = value;
  });
  return result.asMapping();
}
