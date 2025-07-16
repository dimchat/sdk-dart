import 'dart:typed_data';

import 'package:dimp/dimp.dart';
import 'package:test/test.dart';

import 'package:dimsdk/plugins.dart';

import 'loader.dart';

void debugAssert(bool cond, String msg) {
  if (cond) {
    print('\x1B[97m    OK! | $msg\x1B[0m');
  } else {
    print('\x1B[95m[ERROR] | $msg\x1B[0m');
  }
}

void debugLog(String msg) {
  print('        | $msg');
}

void testHash() {
  debugLog('======== testHash ========');

  String string = 'moky';
  Uint8List data = UTF8.encode(string);

  Uint8List hash;
  String res;
  String exp;

  // MD5 (moky) = d0e5edd3fd12b89154bbe7a5e4c82569
  hash = MD5.digest(data);
  res = Hex.encode(hash);
  exp = 'd0e5edd3fd12b89154bbe7a5e4c82569';
  debugAssert(res == exp, 'MD5 ($string) = "$res"');

  // SHA256（moky）= cb98b739dd699aa44bb6ebba128d20f2d1e10bb3b4aa5ff4e79295b47e9ed76d
  hash = SHA256.digest(data);
  res = Hex.encode(hash);
  exp = 'cb98b739dd699aa44bb6ebba128d20f2d1e10bb3b4aa5ff4e79295b47e9ed76d';
  debugAssert(res == exp, 'SHA256 ($string) = "$res"');

  // Keccak256 (moky) = 96b07f3103d45cc7df2dd6e597922a17f48c86257dffe790d442bbd1ff46514d
  hash = Keccak256.digest(data);
  res = Hex.encode(hash);
  exp = '96b07f3103d45cc7df2dd6e597922a17f48c86257dffe790d442bbd1ff46514d';
  debugAssert(res == exp, 'Keccak256 ($string) = "$res"');

  // Keccak256 (hello) = 1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8
  // Keccak256 (abc) = 4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45

  // ripemd160(moky) = 44bd174123aee452c6ec23a6ab7153fa30fa3b91
  hash = RIPEMD160.digest(data);
  res = Hex.encode(hash);
  exp = '44bd174123aee452c6ec23a6ab7153fa30fa3b91';
  debugAssert(res == exp, 'RIPEMD160 ($string) = "$res"');
}

void testEncode() {
  debugLog('======== testEncode ========');

  String string = 'moky';
  Uint8List data = UTF8.encode(string);

  String res;
  String exp;

  // base58(moky) = 3oF5MJ
  res = Base58.encode(data);
  exp = '3oF5MJ';
  debugAssert(res == exp, 'Base58( $string) = "$res"');

  // base64(moky) = bW9reQ==
  res = Base64.encode(data);
  exp = 'bW9reQ==';
  debugAssert(res == exp, 'Base64 ($string) = "$res"');
}

void testAES() {
  debugLog('======== testAES ========');

  Map extra = {};

  Map dictionary = {
    'algorithm': 'AES',
    'data': 'C2+xGizLL1G1+z9QLPYNdp/bPP/seDvNw45SXPAvQqk=',
    // 'iv': 'SxPwi6u4+ZLXLdAFJezvSQ==',
  };
  SymmetricKey key = SymmetricKey.parse(dictionary)!;
  debugLog('key: $key');
  String json = JSON.encode(key.toMap());
  debugLog('JSON (${json.length} bytes): $json');

  String text;
  Uint8List plaintext;
  Uint8List ciphertext;
  Uint8List data;
  String decrypt;
  String exp;

  text = 'moky';
  plaintext = UTF8.encode(text);
  ciphertext = key.encrypt(plaintext, extra);
  debugLog('encrypt ($text) = ${Hex.encode(ciphertext)}');
  debugLog('encrypt ($text) = ${Base64.encode(ciphertext)}');

  data = key.decrypt(ciphertext, extra)!;
  decrypt = UTF8.decode(data)!;
  debugLog('decrypt to $decrypt');
  debugLog('$text -> ${Base64.encode(ciphertext)} => $decrypt');

  exp = '0xtbqZN6x2aWTZn0DpCoCA==';
  debugAssert(Base64.encode(ciphertext) == exp, 'AES ($text)');

  extra['IV'] = 'SxPwi6u4+ZLXLdAFJezvSQ==';

  SymmetricKey key2 = SymmetricKey.parse(dictionary)!;
  debugAssert(key == key2, 'AES keys equal');

  ciphertext = Base64.decode(exp)!;
  plaintext = key2.decrypt(ciphertext, extra)!;
  debugLog('FIXED: $text -> $plaintext');

  String? res;

  // random key
  key = SymmetricKey.generate(SymmetricAlgorithms.AES)!;
  ciphertext = key.encrypt(data, extra);
  plaintext = key.decrypt(ciphertext, extra)!;
  res = UTF8.decode(plaintext);
  debugAssert(res == text, 'AES ($text) => ${Hex.encode(ciphertext)} => $plaintext = $res');
}

//
//  RSA
//

void testRSA() {
  debugLog('======== testRSA ========');

  Map extra = {};

  PrivateKey sKey;
  PublicKey pKey;

  sKey = PrivateKey.generate(AsymmetricAlgorithms.RSA)!;
  debugLog('RSA private key: $sKey');

  pKey = sKey.publicKey;
  debugLog('RSA public key: $pKey');
  debugLog('RSA private key: $sKey');

  String text;
  Uint8List plaintext;
  Uint8List ciphertext;

  text = 'moky';
  plaintext = UTF8.encode(text);
  ciphertext = (pKey as EncryptKey).encrypt(plaintext, extra);
  debugLog('RSA encrypt ($text) = ${Hex.encode(ciphertext)}');

  Uint8List? data;
  String? decrypt;
  data = (sKey as DecryptKey).decrypt(ciphertext, extra);
  decrypt = data == null ? null : UTF8.decode(data);

  debugAssert(text == decrypt, 'decrypt to $decrypt');

  Uint8List signature;
  signature = sKey.sign(plaintext);
  bool ok = pKey.verify(plaintext, signature);
  debugAssert(ok, 'signature ($text) = ${Hex.encode(signature)}');
}

//
//  ECC
//

void _checkKeys(PrivateKey sKey, PublicKey pKey) {
  debugLog('private key: $sKey');
  debugLog('secret data: ${Hex.encode(sKey.data)}');

  debugLog('public key: $pKey');
  debugLog('pub data: ${Hex.encode(pKey.data)}');
  
  final String text = 'moky';
  final Uint8List data = UTF8.encode(text);

  // sign
  Uint8List signature = sKey.sign(data);

  // verify
  bool ok = pKey.verify(data, signature);
  debugAssert(ok, 'signature ($text) = ${Hex.encode(signature)}');
}

PrivateKey _checkECCKeys(String secret, String? pub) {
  PrivateKey sKey = _getECCPrivateKey(secret);
  PublicKey pKey = pub == null ? sKey.publicKey : _getECCPublicKey(pub);
  _checkKeys(sKey, pKey);
  return sKey;
}

PrivateKey _getECCPrivateKey(String pem) {
  return PrivateKey.parse({
    'algorithm': 'ECC',
    'data': pem,
  })!;
}

PublicKey _getECCPublicKey(String pem) {
  return PublicKey.parse({
    'algorithm': 'ECC',
    'data': pem,
  })!;
}

void testECC() {
  debugLog('======== testECC ========');

  PrivateKey sKey;
  PublicKey pKey;

  sKey = _checkECCKeys('5ae4c458c584ab3b3c8b14c7462f295ed6c22d4d376ae625e9d0a93145c3345c',
      '04a34ba8e23e8abc035e238fb70920289d69e130c7779cf432005f0bfc9482282af496e9ae92ad3f7ff68932855d1d6d5bc30eb59dc0a6c579fa134c830ce14ce3');
  debugLog('private key: $sKey');

  pKey = _getECCPublicKey('-----BEGIN PUBLIC KEY-----\n'
      'MFYwEAYHKoZIzj0CAQYFK4EEAAoDQgAEnPfF4seF4dE1qi3a70D2c+vwijAOTU+L\n'
      '7cDZh80ybe7umXESk2c4PvjypfKEfKgJznjG6WqQGz8aYVHkxLTrEA==\n'
      '-----END PUBLIC KEY-----');
  debugLog('pub2: $pKey');
  debugLog('pub2 data: ${Hex.encode(pKey.data)}');
}

void testSymmetric() {
  testAES();
}

void testAsymmetric() {
  testRSA();
  testECC();
}

void main() {
  group('A group of tests', () {

    setUp(() {
      // Additional setup goes here.

      ExtensionLoader().run();

      ClientPluginLoader().run();

    });

    test('First Test', () {
      testHash();
      testEncode();
      testSymmetric();
      testAsymmetric();
    });
  });
}
