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

import '../protocol/network.dart';

///  Address like BitCoin
///
///      data format: "network+digest+code"
///          network    --  1 byte
///          digest     -- 20 bytes
///          check code --  4 bytes
///
///      algorithm:
///          fingerprint = PK.data
///          digest      = ripemd160(sha256(fingerprint));
///          code        = sha256(sha256(network + digest)).prefix(4);
///          address     = base58_encode(network + digest + code);
class BTCAddress extends ConstantString implements Address {
  BTCAddress(super.string, int network) : _network = network;

  final int _network;

  @override
  int get type => _network;

  @override
  bool get isBroadcast => false;

  @override
  bool get isUser => EntityType.isUser(NetworkID.getType(_network));

  @override
  bool get isGroup => EntityType.isGroup(NetworkID.getType(_network));


  ///  Generate BTC address with fingerprint and network ID
  ///
  /// @param fingerprint - meta.fingerprint or key.data
  /// @param network - address type
  /// @return Address object
  static BTCAddress generate(Uint8List fingerprint, int network) {
    // 1. digest = ripemd160(sha256(fingerprint))
    Uint8List digest = RIPEMD160.digest(SHA256.digest(fingerprint));
    // 2. head = network + digest
    BytesBuilder bb = BytesBuilder(copy: false);
    bb.addByte(network);
    bb.add(digest);
    Uint8List head = bb.toBytes();
    // 3. cc = sha256(sha256(head)).prefix(4)
    Uint8List cc = _checkCode(head);
    // 4. data = base58_encode(head + cc)
    bb = BytesBuilder(copy: false);
    bb.add(head);
    bb.add(cc);
    return BTCAddress(Base58.encode(bb.toBytes()), network);
  }

  ///  Parse a string for BTC address
  ///
  /// @param address - address string
  /// @return null on error
  static BTCAddress? parse(String address) {
    if (address.length < 26 || address.length > 35) {
      return null;
    }
    // decode
    Uint8List? data = Base58.decode(address);
    if (data == null || data.length != 25) {
      return null;
    }
    // check code
    Uint8List prefix = data.sublist(0, 21);
    Uint8List suffix = data.sublist(21, 25);
    Uint8List cc = _checkCode(prefix);
    if (Wrapper.listEquals(cc, suffix)) {
      return BTCAddress(address, data[0]);
    } else {
      return null;
    }
  }
}

Uint8List _checkCode(Uint8List data) {
  return SHA256.digest(SHA256.digest(data)).sublist(0, 4);
}
