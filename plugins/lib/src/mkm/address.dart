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

import 'btc.dart';
import 'eth.dart';


///  Base Address Factory
///  ~~~~~~~~~~~~~~~~~~~~
abstract class BaseAddressFactory implements AddressFactory {

  final Map<String, Address> _addresses = {};

  /// Call it when received 'UIApplicationDidReceiveMemoryWarningNotification',
  /// this will remove 50% of cached objects
  ///
  /// @return number of survivors
  int reduceMemory() {
    int finger = 0;
    finger = thanos(_addresses, finger);
    return finger >> 1;
  }

  @override
  Address generateAddress(Meta meta, int? network) {
    Address address = meta.generateAddress(network);
    _addresses[address.toString()] = address;
    return address;
  }

  @override
  Address? parseAddress(String address) {
    Address? res = _addresses[address];
    if (res == null) {
      res = Address.create(address);
      if (res != null) {
        _addresses[address] = res;
      }
    }
    return res;
  }
}

class _AddressFactory extends BaseAddressFactory {

  @override
  Address? createAddress(String address) {
    assert(address.isNotEmpty, 'address should not be empty');
    String lower = address.toLowerCase();
    if (lower == Address.kAnywhere.toString()) {
      return Address.kAnywhere;
    } else if (lower == Address.kEverywhere.toString()) {
      return Address.kEverywhere;
    }
    Address? res = ETHAddress.parse(address);
    res ??= BTCAddress.parse(address);
    assert(res != null, 'invalid address: $address');
    return res;
  }
}


///
/// Register
///
void registerAddressFactory() {
  Address.setFactory(_AddressFactory());
}
