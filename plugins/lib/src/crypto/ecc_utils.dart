/* license: https://mit-license.org
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
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:dimp/dimp.dart' as dim;
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart' as pc;

class ECCKeyUtils {

  static bool verify(Uint8List data, Uint8List signature, ECPublicKey publicKey) {
    var params = pc.PublicKeyParameter(publicKey);
    var signer = pc.Signer('SHA-256/ECDSA')..init(false, params);
    var elements = ASN1Sequence.fromBytes(signature).elements!;
    BigInt? r = (elements[0] as ASN1Integer).integer;
    BigInt? s = (elements[1] as ASN1Integer).integer;
    return signer.verifySignature(data, pc.ECSignature(r!, s!));
  }

  static Uint8List sign(Uint8List data, ECPrivateKey privateKey) {
    var params = pc.PrivateKeyParameter(privateKey);
    var paramsWithRandom = pc.ParametersWithRandom(params, getSecureRandom());
    var signer = pc.Signer('SHA-256/ECDSA')..init(true, paramsWithRandom);
    var signature = signer.generateSignature(data) as pc.ECSignature;
    // encode the two signature values in a common format
    return ASN1Sequence(elements: [
      ASN1Integer(signature.r),
      ASN1Integer(signature.s),
    ]).encode();
  }

  static pc.SecureRandom getSecureRandom({String name = 'Fortuna', int length = 32}) {
    var random = Random.secure();
    List<int> seeds = List<int>.generate(32, (_) => random.nextInt(256));
    var secureRandom = pc.SecureRandom(name);
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  /// Generate ECC private key
  static ECPrivateKey generatePrivateKey({String curve = 'secp256k1'}) {
    var domainParams = pc.ECDomainParameters("secp256k1");
    var params = pc.ECKeyGeneratorParameters(domainParams);
    var paramsWithRandom = pc.ParametersWithRandom(params, getSecureRandom());
    var generator = pc.ECKeyGenerator()..init(paramsWithRandom);
    var keypair = generator.generateKeyPair();
    return keypair.privateKey as ECPrivateKey;
  }

  /// Calculate ECC public key from private key
  static ECPublicKey publicKeyFromPrivateKey(ECPrivateKey privateKey) {
    pc.ECDomainParameters params = privateKey.parameters!;
    return ECPublicKey(params.G * privateKey.d, params);
  }

  //
  //  PEM
  //

  /// Decode ECC public key from PEM text
  static ECPublicKey decodePublicKey(String pem) {
    if (pem.length == 130 || pem.length == 66) {
      // hex(4 + Q.x + Q.y)
      // hex(3 + Q.x)
      // hex(2 + Q.x)
      var data = dim.Hex.decode(pem);
      var domainParams = pc.ECDomainParameters("secp256k1");
      var Q = domainParams.curve.decodePoint(data!);
      return ECPublicKey(Q, domainParams);
    }
    return CryptoUtils.ecPublicKeyFromPem(pem);
  }

  /// Decode ECC private key from PEM text
  static ECPrivateKey decodePrivateKey(String pem) {
    if (pem.length == 64) {
      // hex(s)
      var d = BigInt.parse(pem, radix: 16);
      var domainParams = pc.ECDomainParameters("secp256k1");
      return ECPrivateKey(d, domainParams);
    }
    return CryptoUtils.ecPrivateKeyFromPem(pem);
  }

  /// Encode Public/Private key to PEM Format
  static String encodeKey({ECPublicKey? publicKey, ECPrivateKey? privateKey}) {
    if (publicKey != null) {
      return CryptoUtils.encodeEcPublicKeyToPem(publicKey);
    }
    if (privateKey != null) {
      return CryptoUtils.encodeEcPrivateKeyToPem(privateKey);
    }
    throw Exception('parameters error');
  }

  /// Encode ECC private key
  static Uint8List encodePrivateKeyData(ECPrivateKey privateKey) {
    String hex = privateKey.d!.toRadixString(16);
    return dim.Hex.decode(hex)!;
  }

  /// Encode ECC public key
  static Uint8List encodePublicKeyData(ECPublicKey publicKey, {bool compressed = true}) {
    return publicKey.Q!.getEncoded(compressed);
  }
}
