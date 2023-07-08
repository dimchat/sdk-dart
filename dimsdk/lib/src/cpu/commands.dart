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
  Future<List<Content>> processContent(Content content, ReliableMessage rMsg) async {
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
    if (await facebook!.saveMeta(meta, identifier)) {
      String text = 'Meta received.';
      return respondReceipt(text, rMsg, extra: {
        'template': 'Meta received: \${ID}.',
        'replacements': {
          'ID': identifier.toString(),
        },
      });
    } else {
      String text = 'Meta not accepted.';
      return respondReceipt(text, rMsg, extra: {
        'template': 'Meta not accepted: \${ID}.',
        'replacements': {
          'ID': identifier.toString(),
        },
      });
    }
  }

}


class DocumentCommandProcessor extends MetaCommandProcessor {
  DocumentCommandProcessor(super.facebook, super.messenger);

  @override
  Future<List<Content>> processContent(Content content, ReliableMessage rMsg) async {
    assert(content is DocumentCommand, 'document command error: $content');
    DocumentCommand command = content as DocumentCommand;
    ID identifier = command.identifier;
    Document? doc = command.document;
    if (doc == null) {
      // query entity document for ID
      String? docType = command.getString('doc_type');
      docType ??= '*';  // ANY
      return await _getDoc(identifier, docType, rMsg);
    } else {
      // received a meta for ID
      return await _putDoc(identifier, command.meta, doc, rMsg);
    }
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
    // check meta
    if (meta == null) {
      meta = await facebook?.getMeta(identifier);
      if (meta == null) {
        String text = 'Meta not found.';
        return respondReceipt(text, rMsg, extra: {
          'template': 'Meta not found: \${ID}.',
          'replacements': {
            'ID': identifier.toString(),
          },
        });
      }
    } else if (await barrack.saveMeta(meta, identifier)) {
      // meta accepted & saved
    } else {
      // meta error
      String text = 'Meta not accepted.';
      return respondReceipt(text, rMsg, extra: {
        'template': 'Meta not accepted: \${ID}.',
        'replacements': {
          'ID': identifier.toString(),
        },
      });
    }
    // check document
    bool isValid = doc.isValid || doc.verify(meta.key);
    // TODO: check for group document
    if (!isValid) {
      // document error
      String text = 'Document not accepted.';
      return respondReceipt(text, rMsg, extra: {
        'template': 'Document not accepted: \${ID}.',
        'replacements': {
          'ID': identifier.toString(),
        },
      });
    } else if (await barrack.saveDocument(doc)) {
      // document saved
      String text = 'Document received.';
      return respondReceipt(text, rMsg, extra: {
        'template': 'Document received: \${ID}.',
        'replacements': {
          'ID': identifier.toString(),
        },
      });
    }
    // document expired
    String text = 'Document not changed.';
    return respondReceipt(text, rMsg, extra: {
      'template': 'Document not changed: \${ID}.',
      'replacements': {
        'ID': identifier.toString(),
      },
    });
  }
}


class ReceiptCommandProcessor extends BaseCommandProcessor {
  ReceiptCommandProcessor(super.facebook, super.messenger);

  @override
  Future<List<Content>> processContent(Content content, ReliableMessage rMsg) async {
    assert(content is ReceiptCommand, 'receipt command error: $content');
    // no need to response login command
    return [];
  }

}
