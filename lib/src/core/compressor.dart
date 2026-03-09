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


// -----------------------------------------------------------------------------
//  Compressor (Short Key + JSON + UTF8 Encoding)
// -----------------------------------------------------------------------------

/// Interface for message data compression (short key mapping + JSON serialization + UTF8 encoding).
///
/// Core workflow:
/// 1. Shorten keys via [Shortener]
/// 2. Serialize to JSON string
/// 3. Encode to UTF8 binary bytes
///
/// Extraction workflow (reverse):
/// 1. Decode UTF8 bytes to JSON string
/// 2. Deserialize to Map
/// 3. Restore long keys via [Shortener]
abstract interface class Compressor {

  // -------------------------------------------------------------------------
  //  Content Compression/Extraction
  // -------------------------------------------------------------------------

  /// Compresses content map to UTF8 binary bytes (short keys + JSON + UTF8).
  ///
  /// Parameters:
  /// - [content] : Original content map with long keys
  /// - [key]     : Symmetric key map (reserved parameter, not used in implementation)
  ///
  /// Returns: UTF8 encoded binary bytes of compressed content
  Uint8List compressContent(Map content, Map key);

  /// Extracts content map from UTF8 binary bytes (UTF8 → JSON → long keys).
  ///
  /// Parameters:
  /// - [data] : UTF8 encoded binary bytes of compressed content
  /// - [key]  : Symmetric key map (reserved parameter, not used in implementation)
  ///
  /// Returns: Restored content map with long keys (null if decoding/deserialization fails)
  Map? extractContent(Uint8List data, Map key);

  // -------------------------------------------------------------------------
  //  Symmetric Key Compression/Extraction
  // -------------------------------------------------------------------------

  /// Compresses symmetric key map to UTF8 binary bytes (short keys + JSON + UTF8).
  ///
  /// Parameters:
  /// - [key] : Original symmetric key map with long keys
  ///
  /// Returns: UTF8 encoded binary bytes of compressed symmetric key
  Uint8List compressSymmetricKey(Map key);

  /// Extracts symmetric key map from UTF8 binary bytes (UTF8 → JSON → long keys).
  ///
  /// Parameters:
  /// - [data] : UTF8 encoded binary bytes of compressed symmetric key
  ///
  /// Returns: Restored symmetric key map with long keys (null if decoding/deserialization fails)
  Map? extractSymmetricKey(Uint8List data);

  // -------------------------------------------------------------------------
  //  ReliableMessage Compression/Extraction
  // -------------------------------------------------------------------------

  /// Compresses ReliableMessage map to UTF8 binary bytes (short keys + JSON + UTF8).
  ///
  /// Parameters:
  /// - [msg] : Original ReliableMessage map with long keys
  ///
  /// Returns: UTF8 encoded binary bytes of compressed message
  Uint8List compressReliableMessage(Map msg);

  /// Extracts ReliableMessage map from UTF8 binary bytes (UTF8 → JSON → long keys).
  ///
  /// Parameters:
  /// - [data] : UTF8 encoded binary bytes of compressed message
  ///
  /// Returns: Restored message map with long keys (null if decoding/deserialization fails)
  Map? extractReliableMessage(Uint8List data);

}


/// Concrete implementation of [Compressor] (Shortener + JSON + UTF8).
///
/// Uses [MessageShortener] for key mapping, JSON for serialization,
/// and UTF8 for binary encoding/decoding.
class MessageCompressor implements Compressor {
  MessageCompressor(this.shortener);

  /// Short key mapper used for key conversion.
  // protected
  final Shortener shortener;

  // -------------------------------------------------------------------------
  //  Content Compression/Extraction
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  //  Symmetric Key Compression/Extraction
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  //  ReliableMessage Compression/Extraction
  // -------------------------------------------------------------------------

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
