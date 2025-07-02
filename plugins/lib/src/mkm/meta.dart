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
import 'package:dimp/plugins.dart';

import 'btc.dart';
import 'eth.dart';


///  Default Meta to build ID with 'name@address'
///
///  version:
///      1 = MKM
///
///  algorithm:
///      CT      = fingerprint = sKey.sign(seed);
///      hash    = ripemd160(sha256(CT));
///      code    = sha256(sha256(network + hash)).prefix(4);
///      address = base58_encode(network + hash + code);
class DefaultMeta extends BaseMeta {
  DefaultMeta(super.dict);

  DefaultMeta.from(String type, VerifyKey key, String seed, TransportableData fingerprint)
      : super.from(type, key, seed: seed, fingerprint: fingerprint);

  @override
  bool get hasSeed => true;

  // caches
  final Map<int, Address> _cachedAddresses = {};

  @override
  Address generateAddress(int? network) {
    // assert(type == Meta.MKM || type == '1', 'meta type error: $type');
    assert(network != null, 'address type should not be empty');
    // check caches
    Address? cached = _cachedAddresses[network];
    if (cached == null) {
      // generate and cache it
      var data = fingerprint;
      assert(data != null && data.isNotEmpty, 'meta.fingerprint empty');
      cached = BTCAddress.generate(data!, network!);
      _cachedAddresses[network] = cached;
    }
    return cached;
  }

}


///  Meta to build BTC address for ID
///
///  version:
///      2 = BTC
///
///  algorithm:
///      CT      = key.data;
///      hash    = ripemd160(sha256(CT));
///      code    = sha256(sha256(network + hash)).prefix(4);
///      address = base58_encode(network + hash + code);
class BTCMeta extends BaseMeta {
  BTCMeta(super.dict);

  BTCMeta.from(String type, VerifyKey key, {String? seed, TransportableData? fingerprint})
      : super.from(type, key, seed: seed, fingerprint: fingerprint);

  @override
  bool get hasSeed => false;

  // caches
  final Map<int, Address> _cachedAddresses = {};

  @override
  Address generateAddress(int? network) {
    // assert(type == Meta.BTC || type == '2', 'meta type error: $type');
    assert(network != null, 'address type should not be empty');
    // check caches
    Address? cached = _cachedAddresses[network];
    if (cached == null) {
      // TODO: compress public key?
      VerifyKey key = publicKey;
      Uint8List data = key.data;
      // generate and cache it
      cached = BTCAddress.generate(data, network!);
      _cachedAddresses[network] = cached;
    }
    return cached;
  }
}


///  Meta to build ETH address for ID
///
///  version:
///      4 = ETH
///
///  algorithm:
///      CT      = key.data;  // without prefix byte
///      digest  = keccak256(CT);
///      address = hex_encode(digest.suffix(20));
class ETHMeta extends BaseMeta {
  ETHMeta(super.dict);

  ETHMeta.from(String type, VerifyKey key, {String? seed, TransportableData? fingerprint})
      : super.from(type, key, seed: seed, fingerprint: fingerprint);

  @override
  bool get hasSeed => false;

  // cache
  Address? _cachedAddress;

  @override
  Address generateAddress(int? network) {
    assert(type == MetaType.ETH || type == '4', 'meta type error: $type');
    assert(network == null || network == EntityType.USER, 'address type error: $network');
    // check cache
    Address? cached = _cachedAddress;
    if (cached == null/* || cached.type != network*/) {
      // 64 bytes key data without prefix 0x04
      VerifyKey key = publicKey;
      Uint8List data = key.data;
      // generate and cache it
      cached = ETHAddress.generate(data);
      _cachedAddress = cached;
    }
    return cached;
  }
}


///  Base Meta Factory
///  ~~~~~~~~~~~~~~~~~
class BaseMetaFactory implements MetaFactory {
  BaseMetaFactory(this.type);

  // protected
  final String type;

  @override
  Meta generateMeta(SignKey sKey, {String? seed}) {
    TransportableData? fingerprint;
    if (seed == null || seed.isEmpty) {
      fingerprint = null;
    } else {
      Uint8List data = UTF8.encode(seed);
      Uint8List sig = sKey.sign(data);
      fingerprint = TransportableData.create(sig);
    }
    VerifyKey pKey = (sKey as PrivateKey).publicKey;
    return createMeta(pKey, seed: seed, fingerprint: fingerprint);
  }

  @override
  Meta createMeta(VerifyKey pKey, {String? seed, TransportableData? fingerprint}) {
    Meta out;
    switch (type) {

      case MetaType.MKM:
      case 'mkm':
        out = DefaultMeta.from(type, pKey, seed!, fingerprint!);
        break;

      case MetaType.BTC:
      case 'btc':
        out = BTCMeta.from(type, pKey);
        break;

      case MetaType.ETH:
      case 'eth':
        out = ETHMeta.from(type, pKey);
        break;

      default:
        throw Exception('unknown meta type: $type');
    }
    assert(out.isValid, 'meta error: $out');
    return out;
  }

  @override
  Meta? parseMeta(Map meta) {
    // // check 'type', 'key', 'seed', 'fingerprint'
    // if (meta['type'] == null || meta['key'] == null) {
    //   // meta.type should not be empty
    //   // meta.key should not be empty
    //   assert(false, 'meta error: $meta');
    //   return null;
    // } else if (meta['seed'] == null) {
    //   if (meta['fingerprint'] != null) {
    //     assert(false, 'meta error: $meta');
    //     return null;
    //   }
    // } else if (meta['fingerprint'] == null) {
    //   assert(false, 'meta error: $meta');
    //   return null;
    // }
    Meta out;
    var ext = SharedAccountExtensions();
    String? version = ext.helper!.getMetaType(meta, '');
    switch (version) {

      case MetaType.MKM:
      case 'mkm':
        out = DefaultMeta(meta);
        break;

      case MetaType.BTC:
      case 'btc':
        out = BTCMeta(meta);
        break;

      case MetaType.ETH:
      case 'eth':
        out = ETHMeta(meta);
        break;

      default:
        throw Exception('unknown meta type: $type');
    }
    if (out.isValid) {
      return out;
    }
    assert(false, 'meta error: $meta');
    return null;
  }

}
