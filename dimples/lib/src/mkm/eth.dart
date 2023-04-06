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
import 'dart:typed_data';

import 'package:dimp/dimp.dart';

///  Address like Ethereum
///
///      data format: "0x{address}"
///
///      algorithm:
///          fingerprint = PK.data;
///          digest      = keccak256(fingerprint);
///          address     = hex_encode(digest.suffix(20));
class ETHAddress extends ConstantString implements Address {
  ETHAddress(super.string);

  @override
  int get type => EntityType.kUser;

  @override
  bool get isBroadcast => false;

  @override
  bool get isUser => true;

  @override
  bool get isGroup => false;

  static String? getValidateAddress(String address) {
    if (!_ETH.isETH(address)) {
      // not a ETH address
      return null;
    }
    String lower = address.substring(2).toLowerCase();
    return '0x${_ETH.eip55(lower)}';
  }

  static bool isValidate(String address) {
    String? validate = getValidateAddress(address);
    return validate != null && validate == address;
  }

  ///  Generate ETH address with key.data
  ///
  /// @param fingerprint = key.data
  /// @return Address object
  static ETHAddress generate(Uint8List fingerprint) {
    if (fingerprint.length == 65) {
      // skip first char
      fingerprint = fingerprint.sublist(1);
    }
    assert(fingerprint.length == 64, 'key data error: ${fingerprint.length}');
    // 1. digest = keccak256(fingerprint);
    Uint8List digest = Keccak256.digest(fingerprint);
    // 2. address = hex_encode(digest.suffix(20));
    Uint8List tail = digest.sublist(digest.length - 20);
    String address = _ETH.eip55(Hex.encode(tail));
    return ETHAddress('0x$address');
  }

  ///  Parse a string for ETH address
  ///
  /// @param address - address string
  /// @return null on error
  static ETHAddress? parse(String address) {
    if (!_ETH.isETH(address)) {
      // not a ETH address
      return null;
    }
    return ETHAddress(address);
  }
}

class _ETH {

  // https://eips.ethereum.org/EIPS/eip-55
  static String eip55(String hex) {
    StringBuffer sb = StringBuffer();
    Uint8List hash = Keccak256.digest(UTF8.encode(hex));
    int ch;
    for (int i = 0; i < 40; ++i) {
      ch = hex.codeUnitAt(i);
      if (ch > _9) {
        // check for each 4 bits in the hash table
        // if the first bit is '1',
        //     change the character to uppercase
        ch -= (hash[i >> 1] << (i << 2 & 4) & 0x80) >> 2;
      }
      sb.writeCharCode(ch);
    }
    return sb.toString();
  }

  static bool isETH(String address) {
    if (address.length != 42) {
      return false;
    }
    if (address.codeUnitAt(0) != _0 || address.codeUnitAt(1) != _x) {
      return false;
    }
    int ch;
    for (int i = 2; i < 42; ++i) {
      ch = address.codeUnitAt(i);
      if (ch >= _0 && ch <= _9) {
        continue;
      }
      if (ch >= _A && ch <= _Z) {
        continue;
      }
      if (ch >= _a && ch <= _z) {
        continue;
      }
      // unexpected character
      return false;
    }
    return true;
  }

  static final int _0 = '0'.codeUnitAt(0);
  static final int _9 = '9'.codeUnitAt(0);
  static final int _A = 'A'.codeUnitAt(0);
  static final int _Z = 'Z'.codeUnitAt(0);
  static final int _a = 'a'.codeUnitAt(0);
  static final int _x = 'x'.codeUnitAt(0);
  static final int _z = 'z'.codeUnitAt(0);
}
