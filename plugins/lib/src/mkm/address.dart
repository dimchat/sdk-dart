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
import 'package:dimp/mkm.dart';

import 'btc.dart';
import 'eth.dart';


///  Base Address Factory
///  ~~~~~~~~~~~~~~~~~~~~
class BaseAddressFactory implements AddressFactory {

  // protected
  final Map<String, Address> addresses = {};

  @override
  Address generateAddress(Meta meta, int? network) {
    Address address = meta.generateAddress(network);
    addresses[address.toString()] = address;
    return address;
  }

  @override
  Address? parseAddress(String address) {
    Address? res = addresses[address];
    if (res == null) {
      res = Address.create(address);
      if (res != null) {
        addresses[address] = res;
      }
    }
    return res;
  }

  @override
  Address? createAddress(String address) {
    int len = address.length;
    if (len == 0) {
      assert(false, 'address should not be empty');
      return null;
    } else if (len == 8) {
      // "anywhere"
      if (address.toLowerCase() == Address.ANYWHERE.toString()) {
        return Address.ANYWHERE;
      }
    } else if (len == 10) {
      // "everywhere"
      if (address.toLowerCase() == Address.EVERYWHERE.toString()) {
        return Address.EVERYWHERE;
      }
    }
    Address? res;
    if (26 <= len && len <= 35) {
      // BTC
      res = BTCAddress.parse(address);
    } else if (len == 42) {
      // ETH
      res = ETHAddress.parse(address);
    } else {
      assert(false, 'invalid address: $address');
      res = null;
    }
    // TODO: other types of address
    assert(res != null, 'invalid address: $address');
    return res;
  }

}
