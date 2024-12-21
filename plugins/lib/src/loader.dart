/* license: https://mit-license.org
 * ==============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2024 Albert Moky
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
import 'package:dimp/crypto.dart';
import 'package:dimp/mkm.dart';

import 'crypto/aes.dart';
import 'crypto/digest.dart';
import 'crypto/ecc.dart';
import 'crypto/plain.dart';
import 'crypto/rsa.dart';
import 'format/coders.dart';
import 'format/pnf.dart';
import 'format/ted.dart';

import 'mkm/address.dart';
import 'mkm/identifier.dart';
import 'mkm/meta.dart';
import 'mkm/document.dart';


class PluginLoader {

  bool _loaded = false;

  void run() {
    if (_loaded) {
      // no need to load it again
      return;
    } else {
      // mark it to loaded
      _loaded = true;
    }
    // try to load extensions
    load();
  }

  // protected
  void load() {
    /// Register plugins

    registerDataCoders();
    registerDataDigesters();

    registerSymmetricKeyFactories();
    registerAsymmetricKeyFactories();

    registerIDFactory();
    registerAddressFactory();
    registerMetaFactories();
    registerDocumentFactories();

  }

  // protected
  void registerDataCoders() {
    ///  Data coders

    registerBase58Coder();
    registerBase64Coder();
    registerHexCoder();

    registerUTF8Coder();
    registerJSONCoder();

    registerPNFFactory();
    registerTEDFactory();

  }
  void registerBase58Coder() {
    /// Base58 coding
    Base58.coder = Base58Coder();
  }
  void registerBase64Coder() {
    /// Base64 coding
    Base64.coder = Base64Coder();
  }
  void registerHexCoder() {
    /// HEX coding
    Hex.coder = HexCoder();
  }
  void registerUTF8Coder() {
    /// UTF8
    UTF8.coder = UTF8Coder();
  }
  void registerJSONCoder() {
    /// JSON
    JSON.coder = JSONCoder();
  }
  void registerPNFFactory() {
    /// PNF
    PortableNetworkFile.setFactory(BaseNetworkFileFactory());
  }
  void registerTEDFactory() {
    /// TED
    var tedFactory = Base64DataFactory();
    TransportableData.setFactory(TransportableData.BASE_64, tedFactory);
    TransportableData.setFactory('*', tedFactory);
  }

  // protected
  ///  Data digesters
  void registerDataDigesters() {

    registerMD5Digester();

    registerSHA1Digester();

    registerSHA256Digester();

    registerKeccak256Digester();

    registerRIPEMD160Digester();

  }
  void registerMD5Digester() {
    /// MD5
    MD5.digester = MD5Digester();
  }
  void registerSHA1Digester() {
    /// SHA1
    SHA1.digester = SHA1Digester();
  }
  void registerSHA256Digester() {
    /// SHA256
    SHA256.digester = SHA256Digester();
  }
  void registerKeccak256Digester() {
    /// Keccak256
    Keccak256.digester = Keccak256Digester();
  }
  void registerRIPEMD160Digester() {
    /// RIPEMD160
    RIPEMD160.digester = RIPEMD160Digester();
  }

  // protected
  ///  Symmetric key parsers
  void registerSymmetricKeyFactories() {

    registerAESKeyFactory();

    registerPlainKeyFactory();

  }
  void registerAESKeyFactory() {
    /// AES
    var aes = AESKeyFactory();
    SymmetricKey.setFactory(SymmetricKey.AES, aes);
    SymmetricKey.setFactory('AES/CBC/PKCS7Padding', aes);
  }
  void registerPlainKeyFactory() {
    /// Plain
    SymmetricKey.setFactory(PlainKey.PLAIN, PlainKeyFactory());
  }

  // protected
  ///  Asymmetric key parsers
  void registerAsymmetricKeyFactories() {

    registerRSAKeyFactories();

    registerECCKeyFactories();

  }
  void registerRSAKeyFactories() {
    /// RSA
    var rsaPub = RSAPublicKeyFactory();
    PublicKey.setFactory(AsymmetricKey.RSA, rsaPub);
    PublicKey.setFactory('SHA256withRSA', rsaPub);
    PublicKey.setFactory('RSA/ECB/PKCS1Padding', rsaPub);

    var rsaPri = RSAPrivateKeyFactory();
    PrivateKey.setFactory(AsymmetricKey.RSA, rsaPri);
    PrivateKey.setFactory('SHA256withRSA', rsaPri);
    PrivateKey.setFactory('RSA/ECB/PKCS1Padding', rsaPri);
  }
  void registerECCKeyFactories() {
    /// ECC
    var eccPub = ECCPublicKeyFactory();
    PublicKey.setFactory(AsymmetricKey.ECC, eccPub);
    PublicKey.setFactory('SHA256withECDSA', eccPub);

    var eccPri = ECCPrivateKeyFactory();
    PrivateKey.setFactory(AsymmetricKey.ECC, eccPri);
    PrivateKey.setFactory('SHA256withECDSA', eccPri);
  }

  // protected
  ///  ID factory
  void registerIDFactory() {
    ID.setFactory(IdentifierFactory());
  }

  // protected
  ///  Address factory
  void registerAddressFactory() {
    Address.setFactory(BaseAddressFactory());
  }

  // protected
  ///  Meta factories
  void registerMetaFactories() {
    Meta.setFactory(Meta.MKM, GeneralMetaFactory(Meta.MKM));
    Meta.setFactory(Meta.BTC, GeneralMetaFactory(Meta.BTC));
    Meta.setFactory(Meta.ETH, GeneralMetaFactory(Meta.ETH));
  }

  // protected
  ///  Document factories
  void registerDocumentFactories() {
    Document.setFactory('*', GeneralDocumentFactory('*'));
    Document.setFactory(Document.VISA, GeneralDocumentFactory(Document.VISA));
    Document.setFactory(Document.PROFILE, GeneralDocumentFactory(Document.PROFILE));
    Document.setFactory(Document.BULLETIN, GeneralDocumentFactory(Document.BULLETIN));
  }

}
