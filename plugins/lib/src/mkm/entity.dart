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

import '../protocol/network.dart';
import 'btc.dart';
import 'eth.dart';

class _EntityID extends Identifier {
  _EntityID(super.string,
      {String? name, required Address address, String? terminal})
      : super(name: name, address: address, terminal: terminal);

  // compatible with MKM 0.9.*
  @override
  int get type => NetworkID.getType(address.type);
}

class _EntityIDFactory extends IdentifierFactory {

  @override // protected
  ID newID(String identifier, {String? name, required Address address, String? terminal}) {
    /// override for customized ID
    return _EntityID(identifier, name: name, address: address, terminal: terminal);
  }

  @override
  ID? parseID(String identifier) {
    assert(identifier.isNotEmpty, 'ID should not be empty');
    String lower = identifier.toLowerCase();
    if (lower == ID.kAnyone.string) {
      return ID.kAnyone;
    } else if (lower == ID.kEveryone.string) {
      return ID.kEveryone;
    } else if (lower == ID.kFounder.string) {
      return ID.kFounder;
    }
    return super.parseID(identifier);
  }
}

class _AddressFactory extends BaseAddressFactory {

  @override
  Address? createAddress(String address) {
    assert(address.isNotEmpty, 'address should not be empty');
    String lower = address.toLowerCase();
    if (lower == Address.kAnywhere.string) {
      return Address.kAnywhere;
    } else if (lower == Address.kEverywhere.string) {
      return Address.kEverywhere;
    }
    Address? res = ETHAddress.parse(address);
    res ??= BTCAddress.parse(address);
    assert(res != null, 'invalid address: $address');
    return res;
  }
}

void registerIDFactory() {
  ID.setFactory(_EntityIDFactory());
}

void registerAddressFactory() {
  Address.setFactory(_AddressFactory());
}
