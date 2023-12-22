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

import 'utils/checkers.dart';


abstract class Archivist implements EntityDataSource {

  // each query will be expired after 10 minutes
  static const double kQueryExpires = 600.0;  // seconds

  // query checkers
  final FrequencyChecker<ID> _metaQueries;
  final FrequencyChecker<ID> _docsQueries;
  final FrequencyChecker<ID> _membersQueries;

  // recent time checkers
  final RecentTimeChecker<ID> _lastDocumentTimes = RecentTimeChecker();
  final RecentTimeChecker<ID> _lastHistoryTimes = RecentTimeChecker();

  Archivist(double lifeSpan)
      : _metaQueries = FrequencyChecker(lifeSpan),
        _docsQueries = FrequencyChecker(lifeSpan),
        _membersQueries = FrequencyChecker(lifeSpan);

  // protected
  bool isMetaQueryExpired(ID identifier) => _metaQueries.isExpired(identifier);

  // protected
  bool isDocumentQueryExpired(ID identifier) => _docsQueries.isExpired(identifier);

  // protected
  bool isMembersQueryExpired(ID identifier) => _membersQueries.isExpired(identifier);

  /// check whether need to query meta
  // protected
  Future<bool> needsQueryMeta(ID identifier, Meta? meta) async {
    if (identifier.isBroadcast) {
      // broadcast entity has no meta to query
      return false;
    } else if (meta == null) {
      // meta not found, sure to query
      return true;
    }
    assert(meta.matchIdentifier(identifier), 'meta not match: $identifier, $meta');
    return false;
  }

  //
  //  Last Document Times
  //

  bool setLastDocumentTime(ID identifier, DateTime? lastTime) =>
      _lastDocumentTimes.setLastTime(identifier, lastTime);

  /// check whether need to query documents
  // protected
  Future<bool> needsQueryDocuments(ID identifier, List<Document> documents) async {
    if (identifier.isBroadcast) {
      // broadcast entity has no document to query
      return false;
    } else if (documents.isEmpty) {
      // documents not found, sure to query
      return true;
    }
    DateTime? current = await getLastDocumentTime(identifier, documents);
    return _lastDocumentTimes.isExpired(identifier, current);
  }

  // protected
  Future<DateTime?> getLastDocumentTime(ID identifier, List<Document> documents) async {
    if (documents.isEmpty) {
      return null;
    }
    DateTime? lastTime;
    DateTime? docTime;
    for (Document doc in documents) {
      assert(doc.identifier == identifier, 'document not match: $identifier, $doc');
      docTime = doc.time;
      if (docTime == null) {
        // assert(false, 'document error: $doc');
      } else if (lastTime == null || lastTime.isBefore(docTime)) {
        lastTime = docTime;
      }
    }
    return lastTime;
  }

  //
  //  Last Group History Times
  //

  bool setLastGroupHistoryTime(ID group, DateTime? lastTime) =>
      _lastHistoryTimes.setLastTime(group, lastTime);

  /// check whether need to query group members
  // protected
  Future<bool> needsQueryMembers(ID group, List<ID> members) async {
    if (group.isBroadcast) {
      // broadcast group has no members to query
      return false;
    } else if (members.isEmpty) {
      // members not found, sure to query
      return true;
    }
    DateTime? current = await getLastGroupHistoryTime(group);
    return _lastHistoryTimes.isExpired(group, current);
  }

  // protected
  Future<DateTime?> getLastGroupHistoryTime(ID group);

  ///  Check meta for querying
  ///
  /// @param identifier - entity ID
  /// @param meta       - exists meta
  /// @return true on querying
  Future<bool> checkMeta(ID identifier, Meta? meta) async {
    if (await needsQueryMeta(identifier, meta)) {
      // if (!isMetaQueryExpired(identifier)) {
      //   // query not expired yet
      //   return false;
      // }
      return await queryMeta(identifier);
    } else {
      // no need to query meta again
      return false;
    }
  }

  ///  Check documents for querying/updating
  ///
  /// @param identifier - entity ID
  /// @param documents  - exist documents
  /// @return true on querying
  Future<bool> checkDocuments(ID identifier, List<Document> documents) async {
    if (await needsQueryDocuments(identifier, documents)) {
      // if (!isDocumentQueryExpired(identifier)) {
      //   // query not expired yet
      //   return false;
      // }
      return await queryDocuments(identifier, documents);
    } else {
      // no need to update documents now
      return false;
    }
  }

  ///  Check group members for querying
  ///
  /// @param group   - group ID
  /// @param members - exist members
  /// @return true on querying
  Future<bool> checkMembers(ID group, List<ID> members) async {
    if (await needsQueryMembers(group, members)) {
      // if (!isMembersQueryExpired(identifier)) {
      //   // query not expired yet
      //   return false;
      // }
      return await queryMembers(group, members);
    } else {
      // no need to update group members now
      return false;
    }
  }

  ///  Request for meta with entity ID
  ///  (call 'isMetaQueryExpired()' before sending command)
  ///
  /// @param identifier - entity ID
  /// @return false on duplicated
  Future<bool> queryMeta(ID identifier);

  ///  Request for documents with entity ID
  ///  (call 'isDocumentQueryExpired()' before sending command)
  ///
  /// @param identifier - entity ID
  /// @param documents  - exist documents
  /// @return false on duplicated
  Future<bool> queryDocuments(ID identifier, List<Document> documents);

  ///  Request for group members with group ID
  ///  (call 'isMembersQueryExpired()' before sending command)
  ///
  /// @param group      - group ID
  /// @param members    - exist members
  /// @return false on duplicated
  Future<bool> queryMembers(ID group, List<ID> members);

  ///  Save meta for entity ID (must verify first)
  ///
  /// @param meta - entity meta
  /// @param identifier - entity ID
  /// @return true on success
  Future<bool> saveMeta(Meta meta, ID identifier);

  ///  Save entity document with ID (must verify first)
  ///
  /// @param doc - entity document
  /// @return true on success
  Future<bool> saveDocument(Document doc);

}
