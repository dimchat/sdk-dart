/* license: https://mit-license.org
 *
 *  DIMP : Decentralized Instant Messaging Protocol
 *
 *                                Written in 2026 by Moky <albert.moky@gmail.com>
 *
 * ==============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2026 Albert Moky
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

import 'package:dimp/ext.dart';
import 'package:dimp/mkm.dart';

import 'ext.dart';


/// Encrypted data bundle for user-specific key encryption across terminals.
///
/// Represents a collection of encrypted symmetric keys (or other sensitive data)
/// mapped to user terminals (devices/sessions). Enables device-specific encryption
/// so that only the target user's specific terminals can decrypt the data.
///
/// Key features:
/// - Maps terminal identifiers to encrypted byte data
/// - Supports encoding/decoding to/from message key format
/// - Handles wildcard terminal (*) for device-agnostic encryption
abstract interface class EncryptedBundle {

  /// Converts the bundle to a raw map (terminal → encrypted bytes).
  ///
  /// Returns: Map with terminal strings as keys and encrypted Uint8List data
  Map<String, Uint8List> toMap();

  /// Checks if the bundle contains no encrypted data for any terminal.
  ///
  /// @return True if empty, false otherwise
  bool get isEmpty;
  bool get isNotEmpty;

  /// Retrieves encrypted key data for a specific terminal (index operator).
  ///
  /// Parameters:
  /// - [terminal] : Target terminal identifier (e.g., "mobile", "desktop", "*" for wildcard)
  ///
  /// Returns: Encrypted byte data for the terminal (null if not found)
  Uint8List? operator [](String terminal);

  /// Stores encrypted key data for a specific terminal (index assignment operator).
  ///
  /// Parameters:
  /// - [terminal] : Target terminal identifier
  /// - [value]    : Encrypted byte data to store (null removes the entry)
  void operator []=(String terminal, Uint8List? value);

  /// Removes encrypted data for a specific terminal from the bundle.
  ///
  /// Parameters:
  /// - [terminal] : Target terminal identifier to remove
  ///
  /// Returns: Removed encrypted byte data (null if terminal not found)
  Uint8List? remove(String terminal);

  /// Encodes the bundle into a message-compatible map for transmission.
  ///
  /// Formats the encrypted data with user ID + terminal identifiers as keys,
  /// suitable for inclusion in message "keys" field.
  ///
  /// Parameters:
  /// - [did] : User ID associated with this encrypted bundle
  ///
  /// Returns: Encoded map (ID/terminal → base64-encoded encrypted data)
  Map<String, Object> encode(ID did);

  /// Decodes an encrypted bundle from a message's "keys" field (static factory).
  ///
  /// Extracts and parses terminal-specific encrypted data for a target user,
  /// converting base64-encoded data back to raw bytes. Handles wildcard (*)
  /// terminals and validates data integrity.
  ///
  /// Parameters:
  /// - [keys]      : Encoded key map from message (ID+terminal → base64 data)
  /// - [did]       : Target user ID to decode data for
  /// - [terminals] : List of terminals to extract data for
  ///
  /// Returns: Decoded EncryptedBundle with terminal-specific encrypted data
  static EncryptedBundle decode(Map keys, ID did, Iterable<String> terminals) {
    var helper = sharedAccountExtensions.bundleHelper;
    return helper.decodeBundle(keys, did, terminals);
  }

}


class UserEncryptedBundle implements EncryptedBundle {

  final Map<String, Uint8List> _map = {};

  String get className {
    String name = 'EncryptedBundle';
    assert(() {
      name = runtimeType.toString();
      return true;
    }());
    return name;
  }

  @override
  String toString() {
    String clazz = className;
    String text = '';
    _map.forEach((key, value) {
      text += '\t"$key": ${value.length} byte(s)\n';
    });
    return '<$clazz count=${_map.length}>\n$text</$clazz>';
  }

  @override
  Map<String, Uint8List> toMap() => _map;

  @override
  bool get isEmpty => _map.isEmpty;

  @override
  bool get isNotEmpty => _map.isNotEmpty;

  @override
  Uint8List? operator [](String terminal) => _map[terminal];

  @override
  void operator []=(String terminal, Uint8List? value) {
    if (value == null) {
      _map.remove(terminal);
    } else {
      _map[terminal] = value;
    }
  }

  @override
  Uint8List? remove(String terminal) => _map.remove(terminal);

  @override
  Map<String, Object> encode(ID did) {
    var helper = sharedAccountExtensions.bundleHelper;
    return helper.encodeBundle(this, did);
  }

}
