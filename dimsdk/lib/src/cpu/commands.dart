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
  Future<List<Content>> process(Content content, ReliableMessage rMsg) async {
    assert(content is MetaCommand, 'meta command error: $content');
    MetaCommand command = content as MetaCommand;
    Meta? meta = command.meta;
    ID identifier = command.identifier;
    if (meta == null) {
      // query meta for ID
      return await _getMeta(identifier, rMsg);
    } else {
      // received a meta for ID
      return await _putMeta(identifier, meta, rMsg);
    }
  }

  Future<List<Content>> _getMeta(ID identifier, ReliableMessage rMsg) async {
    Meta? meta = await facebook?.getMeta(identifier);
    if (meta == null) {
      String text = 'Meta not found.';
      return respondReceipt(text, rMsg, extra: {
        'template': 'Meta not found: \${ID}.',
        'replacements': {
          'ID': identifier.toString(),
        },
      });
    } else {
      return [MetaCommand.response(identifier, meta)];
    }
  }

  Future<List<Content>> _putMeta(ID identifier, Meta meta, ReliableMessage rMsg) async {
    List<Content>? errors;
    // 1. try to save meta
    errors = await saveMeta(identifier, meta, rMsg);
    if (errors != null) {
      // failed
      return errors;
    }
    // 2. success
    String text = 'Meta received.';
    return respondReceipt(text, rMsg, extra: {
      'template': 'Meta received: \${ID}.',
      'replacements': {
        'ID': identifier.toString(),
      },
    });
  }

  // protected
  Future<List<Content>?> saveMeta(ID identifier, Meta meta, ReliableMessage rMsg) async {
    Facebook barrack = facebook!;
    // check meta
    if (!meta.isValid || !meta.matchIdentifier(identifier)) {
      String text = 'Meta not valid.';
      return respondReceipt(text, rMsg, extra: {
        'template': 'Meta not valid: \${ID}.',
        'replacements': {
          'ID': identifier.toString(),
        },
      });
    } else if (await barrack.saveMeta(meta, identifier)) {
      // saved
    } else {
      // DB error?
      String text = 'Meta not accepted.';
      return respondReceipt(text, rMsg, extra: {
        'template': 'Meta not accepted: \${ID}.',
        'replacements': {
          'ID': identifier.toString(),
        },
      });
    }
    // OK
    return null;
  }

}


class DocumentCommandProcessor extends MetaCommandProcessor {
  DocumentCommandProcessor(super.facebook, super.messenger);

  @override
  Future<List<Content>> process(Content content, ReliableMessage rMsg) async {
    assert(content is DocumentCommand, 'document command error: $content');
    DocumentCommand command = content as DocumentCommand;
    ID identifier = command.identifier;
    Document? doc = command.document;
    if (doc == null) {
      // query entity document for ID
      String docType = command.getString('doc_type', '*')!;
      return await _getDoc(identifier, docType, rMsg);
    } else if (identifier == doc.identifier) {
      // received a meta for ID
      return await _putDoc(identifier, command.meta, doc, rMsg);
    }
    // error
    return respondReceipt('Document ID not match.', rMsg);
  }

  Future<List<Content>> _getDoc(ID identifier, String docType, ReliableMessage rMsg) async {
    Facebook barrack = facebook!;
    Document? doc = await barrack.getDocument(identifier, docType);
    if (doc == null) {
      String text = 'Document not found.';
      return respondReceipt(text, rMsg, extra: {
        'template': 'Document not found: \${ID}.',
        'replacements': {
          'ID': identifier.toString(),
        },
      });
    } else {
      Meta? meta = await barrack.getMeta(identifier);
      return [DocumentCommand.response(identifier, meta, doc)];
    }
  }

  Future<List<Content>> _putDoc(ID identifier, Meta? meta, Document doc, ReliableMessage rMsg) async {
    Facebook barrack = facebook!;
    // 0. check meta
    if (meta == null) {
      meta = await barrack.getMeta(identifier);
      if (meta == null) {
        String text = 'Meta not found.';
        return respondReceipt(text, rMsg, extra: {
          'template': 'Meta not found: \${ID}.',
          'replacements': {
            'ID': identifier.toString(),
          },
        });
      }
    }
    List<Content>? errors;
    // 1. try to save meta
    errors = await saveMeta(identifier, meta, rMsg);
    if (errors != null) {
      // failed
      return errors;
    }
    // 2. try to save document
    errors = await saveDocument(identifier, meta, doc, rMsg);
    if (errors != null) {
      // failed
      return errors;
    }
    // 3. success
    String text = 'Document received.';
    return respondReceipt(text, rMsg, extra: {
      'template': 'Document received: \${ID}.',
      'replacements': {
        'ID': identifier.toString(),
      },
    });
  }

  // protected
  Future<List<Content>?> saveDocument(ID identifier, Meta meta, Document doc, ReliableMessage rMsg) async {
    Facebook barrack = facebook!;
    // check document
    if (!checkDocument(doc, meta)) {
      // document error
      String text = 'Document not accepted.';
      return respondReceipt(text, rMsg, extra: {
        'template': 'Document not accepted: \${ID}.',
        'replacements': {
          'ID': identifier.toString(),
        },
      });
    } else if (await barrack.saveDocument(doc)) {
      // saved
    } else {
      // document expired
      String text = 'Document not changed.';
      return respondReceipt(text, rMsg, extra: {
        'template': 'Document not changed: \${ID}.',
        'replacements': {
          'ID': identifier.toString(),
        },
      });
    }
    // OK
    return null;
  }

  // protected
  bool checkDocument(Document doc, Meta meta) {
    if (doc.isValid) {
      return true;
    }
    // NOTICE: if this is a bulletin document for group,
    //             verify it with the group owner's meta.key
    //         else (this is a visa document for user)
    //             verify it with the user's meta.key
    return doc.verify(meta.publicKey);
    // TODO: check for group document
  }
}
