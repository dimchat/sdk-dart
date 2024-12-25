# DIM Plugins (Dart)

[![License](https://img.shields.io/github/license/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/blob/master/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/dimchat/sdk-dart/pulls)
[![Platform](https://img.shields.io/badge/Platform-Dart%203-brightgreen.svg)](https://github.com/dimchat/sdk-dart/wiki)
[![Issues](https://img.shields.io/github/issues/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/issues)
[![Version](https://img.shields.io/github/tag/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/tags)
[![Repo Size](https://img.shields.io/github/repo-size/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/archive/refs/heads/main.zip)

[![Watchers](https://img.shields.io/github/watchers/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/watchers)
[![Forks](https://img.shields.io/github/forks/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/forks)
[![Stars](https://img.shields.io/github/stars/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/stargazers)
[![Followers](https://img.shields.io/github/followers/dimchat)](https://github.com/orgs/dimchat/followers)

### Plugins

1. Data Coding
   * Base-58
   * Base-64
   * Hex
   * UTF-8
   * JsON
   * PNF _(Portable Network File)_
   * TED _(Transportable Encoded Data)_
2. Digest Digest
   * MD-5
   * SHA-1
   * SHA-256
   * Keccak-256
   * RipeMD-160
3. Cryptography
   * AES-256 _(AES/CBC/PKCS7Padding)_
   * RSA-1024 _(RSA/ECB/PKCS1Padding)_, _(SHA256withRSA)_
   * ECC _(Secp256k1)_
4. Address
   * BTC
   * ETH
5. Meta
   * MKM _(Default)_
   * BTC
   * ETH
6. Document
   * Visa _(User)_
   * Profile
   * Bulletin _(Group)_

### Extends

* Extends new address

```dart
import 'package:dimp/dimp.dart';
import 'package:dim_plugins/mkm.dart';

class CompatibleAddressFactory extends BaseAddressFactory {

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
```

* Compatible with all metas

```dart
import 'package:dimp/crypto.dart';
import 'package:dimp/mkm.dart';
import 'package:dimp/plugins.dart';
import 'package:dim_plugins/mkm.dart';

class CompatibleMetaFactory extends BaseMetaFactory {
  CompatibleMetaFactory(super.type);

  @override
  Meta createMeta(VerifyKey pKey, {String? seed, TransportableData? fingerprint}) {
    Meta out;
    switch (type) {

      case Meta.MKM:
        out = DefaultMeta.from('1', pKey, seed!, fingerprint!);
        break;

      case Meta.BTC:
        out = BTCMeta.from('2', pKey);
        break;

      case Meta.ETH:
        out = ETHMeta.from('4', pKey);
        break;

      default:
        // TODO: other types of meta
        throw Exception('unknown meta type: $type');
    }
    assert(out.isValid, 'meta error: $out');
    return out;
  }

  @override
  Meta? parseMeta(Map meta) {
    Meta out;
    var holder = SharedAccountHolder();
    String? version = holder.helper!.getMetaType(meta, '');
    switch (version) {

      case 'MKM':
      case 'mkm':
      case '1':
        out = DefaultMeta(meta);
        break;

      case 'BTC':
      case 'btc':
      case '2':
        out = BTCMeta(meta);
        break;

      case 'ETH':
      case 'eth':
      case '4':
        out = ETHMeta(meta);
        break;

      default:
        // TODO: other types of meta
        throw Exception('unknown meta type: $type');
    }
    return out.isValid ? out : null;
  }

}
```

* Extends plugin loader

```dart
import 'dart:typed_data';

import 'package:dimp/mkm.dart';
import 'package:dim_plugins/format.dart';
import 'package:dim_plugins/plugins.dart';

import 'compat_address.dart';
import 'compat_meta.dart';

class CompatiblePluginLoader extends PluginLoader {

  @override
  void registerAddressFactory() {
    Address.setFactory(CompatibleAddressFactory());
  }

  @override
  void registerMetaFactories() {
    var mkm = CompatibleMetaFactory(Meta.MKM);
    var btc = CompatibleMetaFactory(Meta.BTC);
    var eth = CompatibleMetaFactory(Meta.ETH);

    Meta.setFactory('1', mkm);
    Meta.setFactory('2', btc);
    Meta.setFactory('4', eth);

    Meta.setFactory('mkm', mkm);
    Meta.setFactory('btc', btc);
    Meta.setFactory('eth', eth);

    Meta.setFactory('MKM', mkm);
    Meta.setFactory('BTC', btc);
    Meta.setFactory('ETH', eth);
  }

  @override
  void registerBase64Coder() {
    /// Base64 coding
    Base64.coder = _Base64Coder();
  }
}

/// Base-64
class _Base64Coder extends Base64Coder {

  @override
  Uint8List? decode(String string) {
    string = trimBase64String(string);
    return super.decode(string);
  }

  static String trimBase64String(String b64) {
    if (b64.contains('\n')) {
      b64 = b64.replaceAll('\n', '');
      b64 = b64.replaceAll('\r', '');
      b64 = b64.replaceAll('\t', '');
      b64 = b64.replaceAll(' ', '');
    }
    return b64.trim();
  }
}
```

### Usage

```dart
import 'package:dimsdk/plugins.dart';

import 'compat_loader.dart';

void main() {

  ExtensionLoader().run();

  CompatiblePluginLoader().run();
  
  // do your jobs after all extensions & plugins loaded
  
}

```

Copyright &copy; 2023 Albert Moky
