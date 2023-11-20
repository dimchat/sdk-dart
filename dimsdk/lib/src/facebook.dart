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

import 'mkm/bot.dart';
import 'mkm/provider.dart';
import 'mkm/station.dart';

import 'archivist.dart';

abstract class Facebook extends Barrack {

  Archivist get archivist;

  @override
  Future<User?> createUser(ID identifier) async {
    assert(identifier.isUser, 'user ID error: $identifier');
    // check visa key
    if (!identifier.isBroadcast) {
      if (await getPublicKeyForEncryption(identifier) == null) {
        assert(false, 'visa.key not found: $identifier');
        return null;
      }
      // NOTICE: if visa.key exists, then visa & meta must exist too.
    }
    int network = identifier.type;
    // check user type
    if (network == EntityType.kStation) {
      return Station.fromID(identifier);
    } else if (network == EntityType.kBot) {
      return Bot(identifier);
    }
    // general user, or 'anyone@anywhere'
    return BaseUser(identifier);
  }

  @override
  Future<Group?> createGroup(ID identifier) async {
    assert(identifier.isGroup, 'group ID error: $identifier');
    // check members
    if (!identifier.isBroadcast) {
      List<ID> members = await getMembers(identifier);
      if (members.isEmpty) {
        assert(false, 'group members not found: $identifier');
        return null;
      }
      // NOTICE: if members exist, then owner (founder) must exist,
      //         and bulletin & meta must exist too.
    }
    int network = identifier.type;
    // check group type
    if (network == EntityType.kISP) {
      return ServiceProvider(identifier);
    }
    // general group, or 'everyone@everywhere'
    return BaseGroup(identifier);
  }

  ///  Get all local users (for decrypting received message)
  ///
  /// @return users with private key
  Future<List<User>> get localUsers;

  ///  Select local user for receiver
  ///
  /// @param receiver - user/group ID
  /// @return local user
  Future<User?> selectLocalUser(ID receiver) async {
    List<User> users = await localUsers;
    if (users.isEmpty) {
      assert(false, 'local users should not be empty');
      return null;
    } else if (receiver.isBroadcast) {
      // broadcast message can decrypt by anyone, so just return current user
      return users.first;
    } else if (receiver.isUser) {
      // 1. personal message
      // 2. split group message
      for (User item in users) {
        if (item.identifier == receiver) {
          // DISCUSS: set this item to be current user?
          return item;
        }
      }
      // not me?
      return null;
    }
    // group message (recipient not designated)
    assert(receiver.isGroup, 'receiver error: $receiver');
    // the messenger will check group info before decrypting message,
    // so we can trust that the group's meta & members MUST exist here.
    List<ID> members = await getMembers(receiver);
    assert(members.isNotEmpty, "members not found: $receiver");
    for (User item in users) {
      if (members.contains(item.identifier)) {
        // DISCUSS: set this item to be current user?
        return item;
      }
    }
    return null;
  }

  Future<bool> saveMeta(Meta meta, ID identifier) async {
    if (meta.isValid && meta.matchIdentifier(identifier)) {
      // meta ok
    } else {
      assert(false, 'meta not valid: $identifier');
      return false;
    }
    // check old meta
    Meta? old = await getMeta(identifier);
    if (old != null) {
      assert(meta == old, 'meta should not changed');
      return true;
    }
    // meta not exists yet, save it
    return await archivist.saveMeta(meta, identifier);
  }

  Future<bool> saveDocument(Document doc) async {
    ID identifier = doc.identifier;
    if (!doc.isValid) {
      // try to verify
      Meta? meta = await getMeta(identifier);
      if (meta == null) {
        assert(false, 'meta not found: $identifier');
        return false;
      } else if (doc.verify(meta.publicKey)) {
        // document ok
      } else {
        assert(false, 'failed to verify document: $identifier');
        return false;
      }
    }
    String type = doc.type ?? '*';
    // check old documents with type
    List<Document> documents = await getDocuments(identifier);
    Document? old = DocumentHelper.lastDocument(documents, type);
    if (old != null && DocumentHelper.isExpired(doc, old)) {
      // assert(false, 'drop expired document: $identifier');
      return false;
    }
    return await archivist.saveDocument(doc);
  }

  @override
  Future<Meta?> getMeta(ID identifier) async {
    // if (identifier.isBroadcast) {
    //   // broadcast ID has not meta
    //   return null;
    // }
    Meta? meta = await archivist.getMeta(identifier);
    archivist.checkMeta(identifier, meta);
    return meta;
  }

  @override
  Future<List<Document>> getDocuments(ID identifier) async {
    // if (identifier.isBroadcast) {
    //   // broadcast ID has not documents
    //   return null;
    // }
    List<Document> docs = await archivist.getDocuments(identifier);
    archivist.checkDocuments(identifier, docs);
    return docs;
  }

}
