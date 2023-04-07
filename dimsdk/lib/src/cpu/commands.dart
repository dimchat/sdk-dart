/* license: https://mit-license.org
 *
 *  DIM-SDK : Decentralized Instant Messaging Software Development Kit
 *
 *                               Written in 2023 by Moky <albert.moky@gmail.com>
 *
 * =============================================================================
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
 * =============================================================================
 */
import 'package:dimp/dimp.dart';

import '../facebook.dart';
import 'content.dart';


class MetaCommandProcessor extends BaseCommandProcessor {
  MetaCommandProcessor(super.facebook, super.messenger);

  @override
  List<Content> processContent(Content content, ReliableMessage rMsg) {
    assert(content is MetaCommand, 'meta command error: $content');
    MetaCommand command = content as MetaCommand;
    Meta? meta = command.meta;
    ID identifier = command.identifier;
    if (meta == null) {
      // query meta for ID
      return _getMeta(identifier);
    } else {
      // received a meta for ID
      return _putMeta(identifier, meta);
    }
  }

  List<Content> _getMeta(ID identifier) {
    Meta? meta = facebook?.getMeta(identifier);
    if (meta == null) {
      String text = 'Sorry, meta not found for ID: $identifier';
      return respondText(text);
    } else {
      return [MetaCommand.response(identifier, meta)];
    }
  }

  List<Content> _putMeta(ID identifier, Meta meta) {
    if (facebook!.saveMeta(meta, identifier)) {
      String text = 'Meta received: $identifier';
      return respondText(text);
    } else {
      String text = 'Meta not accepted: $identifier';
      return respondText(text);
    }
  }

}


class DocumentCommandProcessor extends MetaCommandProcessor {
  DocumentCommandProcessor(super.facebook, super.messenger);

  @override
  List<Content> processContent(Content content, ReliableMessage rMsg) {
    assert(content is DocumentCommand, 'document command error: $content');
    DocumentCommand command = content as DocumentCommand;
    ID identifier = command.identifier;
    Document? doc = command.document;
    if (doc == null) {
      // query entity document for ID
      String? docType = command.getString('doc_type');
      docType ??= '*';  // ANY
      return _getDoc(identifier, docType);
    } else {
      // received a meta for ID
      return _putDoc(identifier, command.meta, doc);
    }
  }

  List<Content> _getDoc(ID identifier, String docType) {
    Facebook barrack = facebook!;
    Document? doc = barrack.getDocument(identifier, docType);
    if (doc == null) {
      String text = 'Sorry, document not found for ID: $identifier';
      return respondText(text);
    } else {
      Meta? meta = barrack.getMeta(identifier);
      return [DocumentCommand.response(identifier, meta, doc)];
    }
  }

  List<Content> _putDoc(ID identifier, Meta? meta, Document doc) {
    Facebook barrack = facebook!;
    if (meta != null) {
      // received a meta for ID
      if (!barrack.saveMeta(meta, identifier)) {
        String text = 'Meta not accepted: $identifier';
        return respondText(text);
      }
    }
    // receive a document for ID
    if (barrack.saveDocument(doc)) {
      String text = 'Document received: $identifier';
      return respondText(text);
    } else {
      String text = 'Document not accepted: $identifier';
      return respondText(text);
    }
  }
}
