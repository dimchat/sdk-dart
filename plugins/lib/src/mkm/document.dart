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
import 'package:dimp/plugins.dart';


///
/// General Document Factory
///
class GeneralDocumentFactory implements DocumentFactory {
  GeneralDocumentFactory(this.type);

  // protected
  final String type;

  // protected
  String getType(String docType, ID identifier) {
    if (docType != '*') {
      return docType;
    } else if (identifier.isGroup) {
      return DocumentType.BULLETIN;
    } else if (identifier.isUser) {
      return DocumentType.VISA;
    } else {
      return DocumentType.PROFILE;
    }
  }

  @override
  Document createDocument(ID identifier, {String? data, TransportableData? signature}) {
    String docType = getType(type, identifier);
    if (data == null || data.isEmpty) {
      assert(signature == null, 'document error: $identifier, data: $data, signature: $signature');
      // create empty document
      switch (docType) {

        case DocumentType.VISA:
          return BaseVisa.from(identifier);

        case DocumentType.BULLETIN:
          return BaseBulletin.from(identifier);

        default:
          return BaseDocument.from(identifier, docType);
      }
    } else {
      assert(signature != null, 'document error: $identifier, data: $data, signature: $signature');
      // create document with data & signature from local storage
      switch (docType) {

        case DocumentType.VISA:
          return BaseVisa.from(identifier, data: data, signature: signature);

        case DocumentType.BULLETIN:
          return BaseBulletin.from(identifier, data: data, signature: signature);

        default:
          return BaseDocument.from(identifier, docType, data: data, signature: signature);
      }
    }
  }

  @override
  Document? parseDocument(Map doc) {
    // check 'did', 'data', 'signature'
    ID? identifier = ID.parse(doc['did']);
    if (identifier == null) {
      assert(false, 'document ID not found: $doc');
      return null;
    } else if (doc['data'] == null || doc['signature'] == null) {
      // doc.data should not be empty
      // doc.signature should not be empty
      assert(false, 'document error: $doc');
      return null;
    }
    var ext = SharedAccountExtensions();
    String? docType = ext.helper!.getDocumentType(doc, null);
    docType ??= getType('*', identifier);
    switch (docType) {

      case DocumentType.VISA:
        return BaseVisa(doc);

      case DocumentType.BULLETIN:
        return BaseBulletin(doc);

      default:
        return BaseDocument(doc);
    }
  }

}
