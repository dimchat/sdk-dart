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

///
/// Base Keys
///

abstract class BaseKey extends Dictionary implements CryptographyKey {
  BaseKey(super.dict);

  @override
  String get algorithm {
    CryptographyKeyFactoryManager man = CryptographyKeyFactoryManager();
    return man.generalFactory.getAlgorithm(dictionary)!;
  }
}

abstract class BaseSymmetricKey extends Dictionary implements SymmetricKey {
  BaseSymmetricKey(super.dict);

  @override
  bool operator ==(Object other) {
    if (other is SymmetricKey) {
      if (identical(this, other)) {
        // same object
        return true;
      }
      return match(other);
    }
    return dictionary == other;
  }

  @override
  int get hashCode => dictionary.hashCode;

  @override
  String get algorithm {
    CryptographyKeyFactoryManager man = CryptographyKeyFactoryManager();
    return man.generalFactory.getAlgorithm(dictionary)!;
  }

  @override
  bool match(EncryptKey pKey) {
    CryptographyKeyFactoryManager man = CryptographyKeyFactoryManager();
    return man.generalFactory.matchSymmetricKeys(pKey, this);
  }
}

abstract class BaseAsymmetricKey extends Dictionary implements AsymmetricKey {
  BaseAsymmetricKey(super.dict);

  @override
  String get algorithm {
    CryptographyKeyFactoryManager man = CryptographyKeyFactoryManager();
    return man.generalFactory.getAlgorithm(dictionary)!;
  }
}

abstract class BasePrivateKey extends Dictionary implements PrivateKey {
  BasePrivateKey(super.dict);

  @override
  bool operator ==(Object other) {
    if (other is SignKey) {
      if (identical(this, other)) {
        // same object
        return true;
      }
      return publicKey.match(other);
    }
    return dictionary == other;
  }

  @override
  int get hashCode => dictionary.hashCode;

  @override
  String get algorithm {
    CryptographyKeyFactoryManager man = CryptographyKeyFactoryManager();
    return man.generalFactory.getAlgorithm(dictionary)!;
  }
}

abstract class BasePublicKey extends Dictionary implements PublicKey {
  BasePublicKey(super.dict);

  @override
  String get algorithm {
    CryptographyKeyFactoryManager man = CryptographyKeyFactoryManager();
    return man.generalFactory.getAlgorithm(dictionary)!;
  }

  @override
  bool match(SignKey sKey) {
    CryptographyKeyFactoryManager man = CryptographyKeyFactoryManager();
    return man.generalFactory.matchAsymmetricKeys(sKey, this);
  }
}
