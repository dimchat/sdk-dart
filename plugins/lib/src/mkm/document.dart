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
import 'package:dimp/dimp.dart';


///
/// General Document Factory
///
class GeneralDocumentFactory implements DocumentFactory {
  GeneralDocumentFactory(String docType) : _type = docType;

  final String _type;

  @override
  Document createDocument(ID identifier, {String? data, TransportableData? signature}) {
    String docType = _getType(_type, identifier);
    if (data == null || signature == null/* || data.isEmpty || signature.isEmpty*/) {
      // create empty document
      if (docType == Document.VISA) {
        return BaseVisa.from(identifier);
      } else if (docType == Document.BULLETIN) {
        return BaseBulletin.from(identifier);
      } else {
        return BaseDocument.from(identifier, docType);
      }
    } else {
      // create document with data & signature from local storage
      if (docType == Document.VISA) {
        return BaseVisa.from(identifier, data: data, signature: signature);
      } else if (docType == Document.BULLETIN) {
        return BaseBulletin.from(identifier, data: data, signature: signature);
      } else {
        return BaseDocument.from(identifier, docType, data: data, signature: signature);
      }
    }
  }

  @override
  Document? parseDocument(Map doc) {
    ID? identifier = ID.parse(doc['ID']);
    if (identifier == null) {
      // assert(false, 'document ID not found: $doc');
      return null;
    }
    AccountFactoryManager man = AccountFactoryManager();
    String? docType = man.generalFactory.getDocumentType(doc, null);
    docType ??= _getType('*', identifier);
    if (docType == Document.VISA) {
      return BaseVisa(doc);
    } else if (docType == Document.BULLETIN) {
      return BaseBulletin(doc);
    } else {
      return BaseDocument(doc);
    }
  }
}

String _getType(String docType, ID identifier) {
  if (docType != '*') {
    return docType;
  } else if (identifier.isGroup) {
    return Document.BULLETIN;
  } else if (identifier.isUser) {
    return Document.VISA;
  } else {
    return Document.PROFILE;
  }
}


///
/// Register
///
void registerDocumentFactories() {

  Document.setFactory('*', GeneralDocumentFactory('*'));
  Document.setFactory(Document.VISA, GeneralDocumentFactory(Document.VISA));
  Document.setFactory(Document.PROFILE, GeneralDocumentFactory(Document.PROFILE));
  Document.setFactory(Document.BULLETIN, GeneralDocumentFactory(Document.BULLETIN));
}
