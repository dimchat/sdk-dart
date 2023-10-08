/* license: https://mit-license.org
 *
 *  Ming-Ke-Ming : Decentralized User Identity Authentication
 *
 *                                Written in 2023 by Moky <albert.moky@gmail.com>
 *
 * ==============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2023 Albert Moky
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
import 'package:dimp/dimp.dart';


///
/// General ID Factory
///
class IdentifierFactory implements IDFactory {

  final Map<String, ID> _identifiers = {};

  /// Call it when received 'UIApplicationDidReceiveMemoryWarningNotification',
  /// this will remove 50% of cached objects
  ///
  /// @return number of survivors
  int reduceMemory() {
    int finger = 0;
    finger = thanos(_identifiers, finger);
    return finger >> 1;
  }

  @override
  ID generateIdentifier(Meta meta, int? network, {String? terminal}) {
    Address address = Address.generate(meta, network);
    return ID.create(name: meta.seed, address: address, terminal: terminal);
  }

  @override
  ID createIdentifier({String? name, required Address address, String? terminal}) {
    String identifier = _concat(name: name, address: address, terminal: terminal);
    ID? res = _identifiers[identifier];
    if (res == null) {
      res = newID(identifier, name: name, address: address, terminal: terminal);
      _identifiers[identifier] = res;
    }
    return res;
  }

  @override
  ID? parseIdentifier(String identifier) {
    ID? res = _identifiers[identifier];
    if (res == null) {
      res = parse(identifier);
      if (res != null) {
        _identifiers[identifier] = res;
      }
    }
    return res;
  }

  // protected
  ID newID(String identifier, {String? name, required Address address, String? terminal}) {
    /// override for customized ID
    return Identifier(identifier, name: name, address: address, terminal: terminal);
  }

  // protected
  ID? parse(String identifier) {
    String? name;
    Address? address;
    String? terminal;
    // split ID string
    List<String> pair = identifier.split('/');
    assert(pair.first.isNotEmpty, 'ID error: $identifier');
    // terminal
    if (pair.length == 1) {
      // no terminal
      terminal = null;
    } else {
      // got terminal
      assert(pair.length == 2, 'ID error: $identifier');
      terminal = pair.last;
      assert(terminal.isNotEmpty, 'ID.terminal error: $identifier');
    }
    // name @ address
    pair = pair.first.split('@');
    assert(pair.first.isNotEmpty, 'ID error: $identifier');
    if (pair.length == 1) {
      // got address without name
      name = null;
      address = Address.parse(pair.last);
    } else if (pair.length == 2) {
      // got name & address
      name = pair.first;
      address = Address.parse(pair.last);
    } else {
      assert(false, 'ID error: $identifier');
      return null;
    }
    if (address == null) {
      assert(false, 'cannot get address from ID: $identifier');
      return null;
    }
    return newID(identifier, name: name, address: address, terminal: terminal);
  }
}

String _concat({String? name, required Address address, String? terminal}) {
  String string = address.toString();
  if (name != null && name.isNotEmpty) {
    string = '$name@$string';
  }
  if (terminal != null && terminal.isNotEmpty) {
    string = '$string/$terminal';
  }
  return string;
}


///
/// Register
///
void registerIDFactory() {
  ID.setFactory(IdentifierFactory());
}
