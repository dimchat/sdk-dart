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

  /// Compress ReliableMessage
  static final List<String> messageShortKeys = [
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
  ];

  /// Compress Content
  static final List<String> contentShortKeys = [
    "T", "type",
    "N", "sn",
    "W", "time",        // When
    "G", "group",
    "C", "command",     // Command name
  ];

  /// Compress SymmetricKey
  static final List<String> cryptoShortKeys = [
    "A", "algorithm",
    "D", "data",
    "I", "iv",          // Initial Vector
  ];

}


/*  Short Keys

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


/// Concrete implementation of [Shortener] for message/content/key short key mapping.
///
/// Implements fixed key pair conversion with new Map creation (not modifying
/// the original one), including special handling for "K" (short for "keys").
class MessageShortener implements Shortener {
  MessageShortener() {

    // build for message
    final (m2l, m2s) = buildMessageKeyMaps();
    messageShortToLong = m2l;
    messageLongToShort = m2s;

    // build for content
    final (c2l, c2s) = buildContentKeyMaps();
    contentShortToLong = c2l;
    contentLongToShort = c2s;

    // build for symmetric key
    final (k2l, k2s) = buildCryptoKeyMaps();
    cryptoShortToLong = k2l;
    cryptoLongToShort = k2s;

  }

  // protected
  (Map<String, String> s2l, Map<String, String> l2s) buildMessageKeyMaps() =>
      build(Shortener.messageShortKeys);

  // protected
  (Map<String, String> s2l, Map<String, String> l2s) buildContentKeyMaps() =>
      build(Shortener.contentShortKeys);

  // protected
  (Map<String, String> s2l, Map<String, String> l2s) buildCryptoKeyMaps() =>
      build(Shortener.cryptoShortKeys);

  // protected
  (Map<String, String> s2l, Map<String, String> l2s) build(List<String> keys) {
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

  // protected
  Mapping<String, dynamic> translate(Mapping info, Map<String, String> dictionary) {
    Map<String, dynamic> result = {};
    info.forEach((key, value) {
      final name = dictionary[key] ?? key;
      result[name] = value;
    });
    return result.asMapping();
  }

  // -------------------------------------------------------------------------
  //  ReliableMessage Key Mapping
  // -------------------------------------------------------------------------

  late Map<String, String> messageShortToLong;
  late Map<String, String> messageLongToShort;

  @override
  Mapping compressReliableMessage(Mapping msg) => translate(msg, messageLongToShort);

  @override
  Mapping extractReliableMessage(Mapping msg) => translate(msg, messageShortToLong);

  // -------------------------------------------------------------------------
  //  Content Key Mapping
  // -------------------------------------------------------------------------

  late Map<String, String> contentShortToLong;
  late Map<String, String> contentLongToShort;

  @override
  Mapping compressContent(Mapping content) => translate(content, contentLongToShort);

  @override
  Mapping extractContent(Mapping content) => translate(content, contentShortToLong);

  // -------------------------------------------------------------------------
  //  Symmetric Key Mapping
  // -------------------------------------------------------------------------

  late Map<String, String> cryptoShortToLong;
  late Map<String, String> cryptoLongToShort;

  @override
  Mapping compressSymmetricKey(Mapping key) => translate(key, cryptoLongToShort);

  @override
  Mapping extractSymmetricKey(Mapping key) => translate(key, cryptoShortToLong);

}
