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
import 'package:dimp/dimp.dart';

import 'crypto/aes.dart';
import 'crypto/digest.dart';
import 'crypto/ecc.dart';
import 'crypto/plain.dart';
import 'crypto/rsa.dart';
import 'format/coders.dart';

import 'mkm/address.dart';
import 'mkm/identifier.dart';
import 'mkm/meta.dart';
import 'mkm/document.dart';


void registerKeyFactories() {

  //
  //  register AsymmetricKey Factories
  //

  var rsaPub = RSAPublicKeyFactory();
  var rsaPri = RSAPrivateKeyFactory();
  PublicKey.setFactory(AsymmetricKey.kRSA, rsaPub);
  PublicKey.setFactory('SHA256withRSA', rsaPub);
  PublicKey.setFactory('RSA/ECB/PKCS1Padding', rsaPub);
  PrivateKey.setFactory(AsymmetricKey.kRSA, rsaPri);
  PrivateKey.setFactory('SHA256withRSA', rsaPri);
  PrivateKey.setFactory('RSA/ECB/PKCS1Padding', rsaPri);

  var eccPub = ECCPublicKeyFactory();
  var eccPri = ECCPrivateKeyFactory();
  PublicKey.setFactory(AsymmetricKey.kECC, eccPub);
  PublicKey.setFactory('SHA256withECDSA', eccPub);
  PrivateKey.setFactory(AsymmetricKey.kECC, eccPri);
  PrivateKey.setFactory('SHA256withECDSA', eccPri);

  //
  //  register SymmetricKey Factories
  //

  var aes = AESKeyFactory();
  SymmetricKey.setFactory(SymmetricKey.kAES, aes);
  SymmetricKey.setFactory('AES/CBC/PKCS7Padding', aes);

  SymmetricKey.setFactory(PlainKey.kPLAIN, PlainKeyFactory());
}


void registerPlugins() {

  registerDataCoders();
  registerDataDigesters();

  registerKeyFactories();

  registerIdentifierFactory();
  registerAddressFactory();
  registerMetaFactories();
  registerDocumentFactories();
}
