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
// import 'package:dimsdk/core.dart';
import 'package:dim_plugins/mkm.dart';


class CompatibleAddressFactory extends BaseAddressFactory {

  /// Call it when received 'UIApplicationDidReceiveMemoryWarningNotification',
  /// this will remove 50% of cached objects
  ///
  /// @return number of survivors
  int reduceMemory() {
    int finger = 0;
    // finger = Barrack.thanos(addresses, finger);
    return finger >> 1;
  }

  @override
  Address? parse(String address) {
    int len = address.length;
    if (len == 0) {
      assert(false, 'address empty');
      return null;
    } else if (len == 8) {
      // "anywhere"
      String lower = address.toLowerCase();
      if (lower == Address.ANYWHERE.toString()) {
        return Address.ANYWHERE;
      }
    } else if (len == 10) {
      // "everywhere"
      String lower = address.toLowerCase();
      if (lower == Address.EVERYWHERE.toString()) {
        return Address.EVERYWHERE;
      }
    }
    Address? res;
    if (26 <= len && len <= 35) {
      res = BTCAddress.parse(address);
    } else if (len == 42) {
      res = ETHAddress.parse(address);
    } else {
      // throw AssertionError('invalid address: $address');
      res = null;
    }
    //
    //  TODO: parse for other types of address
    //
    if (res == null && 4 <= len && len <= 64) {
      res = _UnknownAddress(address);
    }
    assert(res != null, 'invalid address: $address');
    return res;
  }

}


/// Unsupported Address
/// ~~~~~~~~~~~~~~~~~~~
class _UnknownAddress extends ConstantString implements Address {
  _UnknownAddress(super.string);

  @override
  int get network => 0;

}
