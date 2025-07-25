import 'dart:typed_data';

import 'package:dimp/crypto.dart';
import 'package:dimp/mkm.dart';
import 'package:dim_plugins/format.dart';
import 'package:dim_plugins/plugins.dart';

import 'address.dart';


class ClientPluginLoader extends PluginLoader {

  @override
  void registerAddressFactory() {
    Address.setFactory(CompatibleAddressFactory());
  }

  @override
  void registerBase64Coder() {
    /// Base64 coding
    Base64.coder = PatchBase64Coder();
  }

}

/// Base-64
class PatchBase64Coder extends Base64Coder {

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
