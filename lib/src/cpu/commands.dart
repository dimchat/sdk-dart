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

import '../core/barrack.dart';

import 'base.dart';

class MetaCommandProcessor extends BaseCommandProcessor {
  MetaCommandProcessor(super.facebook, super.messenger);

  // protected
  Archivist? get archivist => facebook?.archivist;

  @override
  Future<List<Content>> processContent(Content content, ReliableMessage rMsg) async {
    assert(content is MetaCommand, 'meta command error: $content');
    MetaCommand command = content as MetaCommand;
    Meta? meta = command.meta;
    ID identifier = command.identifier;
    if (meta == null) {
      // query meta for ID
      return await _getMeta(identifier, content: command, envelope: rMsg.envelope);
    }
    // received a meta for ID
    return await _putMeta(meta, identifier: identifier, content: command, envelope: rMsg.envelope);
  }

  Future<List<Content>> _getMeta(ID identifier, {
    required MetaCommand content, required Envelope envelope
  }) async {
    Meta? meta = await facebook?.getMeta(identifier);
    if (meta == null) {
      String text = 'Meta not found.';
      return respondReceipt(text, content: content, envelope: envelope, extra: {
        'template': 'Meta not found: \${did}.',
        'replacements': {
          'did': identifier.toString(),
        },
      });
    }
    // meta got
    return await respondMeta(identifier, meta, receiver: envelope.sender);
  }

  // protected
  Future<List<Content>> respondMeta(ID identifier, Meta meta, {required ID receiver}) async {
    assert(receiver != identifier, 'cycled response: $identifier');
    // TODO: check response expired
    return [
      MetaCommand.response(identifier, meta)
    ];
  }

  Future<List<Content>> _putMeta(Meta meta, {
    required ID identifier, required MetaCommand content, required Envelope envelope
  }) async {
    List<Content>? errors;
    // 1. try to save meta
    errors = await saveMeta(meta, identifier: identifier, content: content, envelope: envelope);
    if (errors != null) {
      // failed
      return errors;
    }
    // 2. success
    String text = 'Meta received.';
    return respondReceipt(text, content: content, envelope: envelope, extra: {
      'template': 'Meta received: \${did}.',
      'replacements': {
        'did': identifier.toString(),
      },
    });
  }

  // protected
  Future<List<Content>?> saveMeta(Meta meta, {
    required ID identifier, required MetaCommand content, required Envelope envelope
  }) async {
    bool? ok;
    // check meta
    ok = checkMeta(meta, identifier: identifier);
    if (ok != true) {
      String text = 'Meta not valid.';
      return respondReceipt(text, content: content, envelope: envelope, extra: {
        'template': 'Meta not valid: \${did}.',
        'replacements': {
          'did': identifier.toString(),
        },
      });
    }
    ok = await archivist?.saveMeta(meta, identifier);
    if (ok != true) {
      // DB error?
      String text = 'Meta not accepted.';
      return respondReceipt(text, content: content, envelope: envelope, extra: {
        'template': 'Meta not accepted: \${did}.',
        'replacements': {
          'did': identifier.toString(),
        },
      });
    }
    // meta saved, return no error
    return null;
  }

  // protected
  bool checkMeta(Meta meta, {required ID identifier}) {
    if (!meta.isValid) {
      return false;
    }
    Address old = identifier.address;
    Address gen = Address.generate(meta, old.network);
    return old == gen;
  }

}


class DocumentCommandProcessor extends MetaCommandProcessor {
  DocumentCommandProcessor(super.facebook, super.messenger);

  @override
  Future<List<Content>> processContent(Content content, ReliableMessage rMsg) async {
    assert(content is DocumentCommand, 'document command error: $content');
    DocumentCommand command = content as DocumentCommand;
    ID identifier = command.identifier;
    List<Document>? documents = command.documents;
    if (documents == null) {
      // query entity documents for ID
      return await _getDocuments(identifier, content: command, envelope: rMsg.envelope);
    }
    // received new documents
    return await _putDocuments(documents, identifier: identifier, content: content, envelope: rMsg.envelope);
  }

  Future<List<Content>> _getDocuments(ID identifier, {
    required DocumentCommand content, required Envelope envelope
  }) async {
    List<Document>? documents = await facebook?.getDocuments(identifier);
    if (documents == null || documents.isEmpty) {
      String text = 'Document not found.';
      return respondReceipt(text, content: content, envelope: envelope, extra: {
        'template': 'Document not found: \${did}.',
        'replacements': {
          'did': identifier.toString(),
        },
      });
    }
    // documents got
    DateTime? queryTime = content.lastTime;
    if (queryTime != null) {
      // check last document time
      Document? last = getLastDocument(documents);
      assert(last != null, 'should not happen');
      DateTime? lastTime = last?.time;
      if (lastTime == null) {
        assert(false, 'document error: $last');
      } else if (!lastTime.isAfter(queryTime)) {
        // document not updated
        String text = 'Document not updated.';
        return respondReceipt(text, content: content, envelope: envelope, extra: {
          'template': 'Document not updated: \${did}, last time: \${time}.',
          'replacements': {
            'did': identifier.toString(),
            'time': lastTime.millisecondsSinceEpoch / 1000.0,
          },
        });
      }
    }
    // documents got
    return await respondDocuments(identifier, documents, receiver: envelope.sender);
  }

  // protected
  Future<List<Content>> respondDocuments(ID identifier, List<Document> docs, {required ID receiver}) async {
    assert(receiver != identifier, 'cycled response: $identifier');
    // TODO: check response expired
    Meta? meta = await facebook?.getMeta(identifier);
    return [
      DocumentCommand.response(identifier, meta, docs)
    ];
  }

  // protected
  Document? getLastDocument(Iterable<Document> documents) {
    Document? lastDoc;
    DateTime? lastTime;
    DateTime? docTime;
    for (Document doc in documents) {
      docTime = doc.time;
      if (lastDoc == null) {
        // first document
        lastDoc = doc;
        lastTime = docTime;
      } else if (lastTime == null) {
        // the first document has no time (old version),
        // if this document has time, use the new one
        if (docTime != null) {
          // first document with time
          lastDoc = doc;
          lastTime = docTime;
        }
      } else if (docTime != null && docTime.isAfter(lastTime)) {
        // new document
        lastDoc = doc;
        lastTime = docTime;
      }
    }
    return lastDoc;
  }

  Future<List<Content>> _putDocuments(List<Document> documents, {
    required ID identifier, required DocumentCommand content, required Envelope envelope
  }) async {
    List<Content>? errors;
    Meta? meta = content.meta;
    // 0. check meta
    if (meta == null) {
      meta = await facebook?.getMeta(identifier);
      if (meta == null) {
        String text = 'Meta not found.';
        return respondReceipt(text, content: content, envelope: envelope, extra: {
          'template': 'Meta not found: \${did}.',
          'replacements': {
            'did': identifier.toString(),
          },
        });
      }
    } else {
      // 1. try to save meta
      errors = await saveMeta(meta, identifier: identifier, content: content, envelope: envelope);
      if (errors != null) {
        // failed
        return errors;
      }
    }
    // 2. try to save document
    errors = [];
    for (var doc in documents) {
      var array = await saveDocument(doc, meta: meta, identifier: identifier, content: content, envelope: envelope);
      if (array != null) {
        errors.addAll(array);
      }
    }
    if (errors.isNotEmpty) {
      // failed
      return errors;
    }
    // 3. success
    String text = 'Document received.';
    return respondReceipt(text, content: content, envelope: envelope, extra: {
      'template': 'Document received: \${did}.',
      'replacements': {
        'did': identifier.toString(),
      },
    });
  }

  // protected
  Future<List<Content>?> saveDocument(Document doc, {
    required Meta meta, required ID identifier,
    required DocumentCommand content, required Envelope envelope
  }) async {
    bool? ok;
    // check document
    ok = checkDocument(doc, meta: meta, identifier: identifier);
    if (ok != true) {
      // document error
      String text = 'Document not accepted.';
      return respondReceipt(text, content: content, envelope: envelope, extra: {
        'template': 'Document not accepted: \${did}.',
        'replacements': {
          'did': identifier.toString(),
        },
      });
    }
    ok = await archivist?.saveDocument(doc, identifier);
    if (ok != true) {
      // document expired
      String text = 'Document not changed.';
      return respondReceipt(text, content: content, envelope: envelope, extra: {
        'template': 'Document not changed: \${did}.',
        'replacements': {
          'did': identifier.toString(),
        },
      });
    }
    // document saved, return no error
    return null;
  }

  // protected
  bool checkDocument(Document doc, {required Meta meta, required ID identifier}) {
    // check meta with ID
    if (!checkMeta(meta, identifier: identifier)) {
      // meta error
      return false;
    }
    // check document ID
    ID? docID = ID.parse(doc['did']);
    if (docID != null) {
      Address inside = docID.address;
      Address outside = identifier.address;
      if (inside != outside) {
        assert(false, 'ID not matched: $identifier, $doc');
        return false;
      }
    } else {
      assert(false, 'document ID not found: $doc');
    }
    // NOTICE: if this is a bulletin document for group,
    //             verify it with the group owner's meta.key
    //         else (this is a visa document for user)
    //             verify it with the user's meta.key
    return doc.verify(meta.publicKey);
    // TODO: check for group document
  }

}
