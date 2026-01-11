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

import 'package:dimp/protocol.dart';


/// User Encrypted Key Data with Terminals
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
abstract interface class EncryptedBundle {

  Map<String, Uint8List> toMap();

  bool get isEmpty;
  bool get isNotEmpty;

  ///  Get encrypted key data for terminal
  ///
  /// @param terminal - ID terminal
  /// @return encrypted key data
  Uint8List? operator [](String terminal);

  ///  Put encrypted key data for terminal
  ///
  /// @param terminal - ID terminal
  /// @param data     - encrypted key data
  void operator []=(String terminal, Uint8List? value);

  ///  Remove encrypted key data for terminal
  ///
  /// @param terminal - ID terminal
  /// @return removed data
  Uint8List? remove(String terminal);

  ///  Encode key data
  ///
  /// @param did - user ID
  /// @return encoded key data with targets (ID + terminals)
  Map<String, Object> encode(ID did);

  ///  Decode key data from 'message.keys'
  ///
  /// @param keys      - encoded key data with targets (ID + terminals)
  /// @param did       - receiver ID
  /// @param terminals - visa terminals
  /// @return decrypted key data with targets (ID terminals)
  static EncryptedBundle decode(Map keys, ID did, Iterable<String> terminals) {
    EncryptedBundle bundle = UserEncryptedBundle();
    //
    //  0. ID string without terminal
    //
    String identifier = Identifier.concat(name: did.name, address: did.address);
    String target;
    Object? base64;
    TransportableData? ted;
    Uint8List? data;
    for (String item in terminals) {
      target = item.isEmpty ? '*' : item;
      //
      //  1. get encoded data with target (ID + terminal)
      //
      if (target == '*') {
        base64 = keys[identifier];
      } else {
        base64 = keys['$identifier/$target'];
      }
      if (base64 == null) {
        // key data not found
        continue;
      }
      //
      //  2. decode data
      //
      ted = TransportableData.parse(base64);
      data = ted?.data;
      if (data == null) {
        assert(false, 'key data error: $item -> $base64');
        continue;
      }
      //
      //  3. put data for target (ID terminal)
      //
      bundle[target] = data;
    }
    // OK
    return bundle;
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
    assert(did.terminal == null, 'ID should not contain terminal here: $did');
    String identifier = Identifier.concat(name: did.name, address: did.address);
    Map<String, Object> bundle = {};
    String target;
    Object base64;
    _map.forEach((terminal, data) {
      // encode data
      base64 = TransportableData.encode(data);
      if (terminal.isEmpty || terminal == '*') {
        target = identifier;
      } else {
        target = '$identifier/$terminal';
      }
      // insert to 'message.keys' with ID + terminal
      bundle[target] = base64;
    });
    // OK
    return bundle;
  }

}
