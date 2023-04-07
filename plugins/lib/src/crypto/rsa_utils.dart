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

import 'package:dimp/dimp.dart' as dim;
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asn1.dart' show ASN1Integer, ASN1Sequence;
import 'package:pointycastle/export.dart' show RSAPrivateKey, RSAPublicKey;
import 'package:pointycastle/export.dart' as pc;

class RSAKeyUtils {

  static Uint8List encrypt(Uint8List plaintext, RSAPublicKey publicKey) {
    Encrypter cipher = Encrypter(RSA(publicKey: publicKey));
    return cipher.encryptBytes(plaintext).bytes;
  }

  static bool verify(Uint8List data, Uint8List signature, RSAPublicKey publicKey) {
    Signer signer = Signer((RSASigner(RSASignDigest.SHA256, publicKey: publicKey)));
    return signer.verifyBytes(data, Encrypted(signature));
  }

  static Uint8List decrypt(Uint8List ciphertext, RSAPrivateKey privateKey) {
    Encrypter cipher = Encrypter(RSA(privateKey: privateKey));
    List<int> result = cipher.decryptBytes(Encrypted(ciphertext));
    return Uint8List.fromList(result);
  }

  static Uint8List sign(Uint8List data, RSAPrivateKey privateKey) {
    Signer signer = Signer((RSASigner(RSASignDigest.SHA256, privateKey: privateKey)));
    return signer.signBytes(data).bytes;
  }

  static pc.SecureRandom getSecureRandom({String name = 'Fortuna', int length = 32}) {
    var random = Random.secure();
    List<int> seeds = List<int>.generate(32, (_) => random.nextInt(256));
    var secureRandom = pc.SecureRandom(name);
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  /// Generate RSA private key
  static RSAPrivateKey generatePrivateKey({int bitLength = 1024}) {
    var params = pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64);
    var paramsWithRandom = pc.ParametersWithRandom(params, getSecureRandom());
    var generator = pc.RSAKeyGenerator()..init(paramsWithRandom);
    var keyPair = generator.generateKeyPair();
    return keyPair.privateKey as RSAPrivateKey;
  }

  /// Calculate RSA public key from private key
  static RSAPublicKey publicKeyFromPrivateKey(RSAPrivateKey privateKey) {
    BigInt n = privateKey.modulus!;
    BigInt e = privateKey.publicExponent!;
    return RSAPublicKey(n, e);
  }

  //
  //  PEM
  //

  /// Decode RSA public key from PEM text
  static RSAPublicKey decodePublicKey(String pem) {
    RSAKeyParser parser = RSAKeyParser();
    return parser.parse(pem) as RSAPublicKey;
  }

  /// Decode RSA private key from PEM text
  static RSAPrivateKey decodePrivateKey(String pem) {
    RSAKeyParser parser = RSAKeyParser();
    return parser.parse(pem) as RSAPrivateKey;
  }

  /// Encode Public/Private key to PEM Format
  static String encodeKey({RSAPublicKey? publicKey, RSAPrivateKey? privateKey}) {
    String pem = '';
    Uint8List data;
    String b64;
    if (publicKey != null) {
      data = encodePublicKeyData(publicKey);
      b64 = dim.Base64.encode(data);
      pem += '-----BEGIN RSA PUBLIC KEY-----\r\n$b64\r\n-----END RSA PUBLIC KEY-----';
    }
    if (privateKey != null) {
      if (publicKey != null) {
        pem += '\r\n';
      }
      data = encodePrivateKeyData(privateKey);
      b64 = dim.Base64.encode(data);
      pem += '-----BEGIN RSA PRIVATE KEY-----\r\n$b64\r\n-----END RSA PRIVATE KEY-----';
    }
    return pem;
  }

  /// Encode RSA private key
  static Uint8List encodePrivateKeyData(RSAPrivateKey privateKey) {
    BigInt n = privateKey.modulus!;
    BigInt e = privateKey.publicExponent!;
    BigInt d = privateKey.privateExponent!;
    BigInt p = privateKey.p!;  // secret prime factors
    BigInt q = privateKey.q!;  // secret prime factors

    BigInt dP = d % (p - _one);
    BigInt dQ = d % (q - _one);
    BigInt iQ = q.modInverse(p);

    ASN1Sequence sequence = ASN1Sequence();
    sequence.add(ASN1Integer(_zero));     // version
    sequence.add(ASN1Integer(n));         // modulus
    sequence.add(ASN1Integer(e));         // publicExponent
    sequence.add(ASN1Integer(d));         // privateExponent
    sequence.add(ASN1Integer(p));
    sequence.add(ASN1Integer(q));
    sequence.add(ASN1Integer(dP));        // exp1: d % (p - 1)
    sequence.add(ASN1Integer(dQ));        // exp2: d % (q - 1)
    sequence.add(ASN1Integer(iQ));

    // GET the BER Stream
    return sequence.encode();
  }

  /// Encode RSA public key
  static Uint8List encodePublicKeyData(RSAPublicKey publicKey) {
    BigInt n = publicKey.modulus!;
    BigInt e = publicKey.publicExponent!;

    ASN1Sequence sequence = ASN1Sequence();
    // sequence.add(ASN1Integer(_zero));     // version
    sequence.add(ASN1Integer(n));         // modulus
    sequence.add(ASN1Integer(e));         // exponent

    // GET the BER Stream
    return sequence.encode();
  }

  static final BigInt _zero = BigInt.from(0);
  static final BigInt _one = BigInt.from(1);
}
