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

import 'core/barrack.dart';
import 'mkm/group.dart';
import 'mkm/user.dart';

import 'archivist.dart';


abstract class Facebook extends Barrack implements UserDataSource, GroupDataSource {

  Archivist get archivist;

  @override
  void cacheUser(User user) {
    user.dataSource ??= this;
    super.cacheUser(user);
  }

  @override
  void cacheGroup(Group group) {
    group.dataSource ??= this;
    super.cacheGroup(group);
  }

  //
  //  Entity Delegate
  //

  @override
  Future<User?> getUser(ID identifier) async {
    assert(identifier.isUser, 'user ID error: $identifier');
    // 1. get from user cache
    User? user = await super.getUser(identifier);
    if (user == null) {
      // 2. create user and cache it
      user = await archivist.createUser(identifier);
      if (user != null) {
        cacheUser(user);
      }
    }
    return user;
  }

  @override
  Future<Group?> getGroup(ID identifier) async {
    assert(identifier.isGroup, 'group ID error: $identifier');
    // 1. get from group cache
    Group? group = await super.getGroup(identifier);
    if (group == null) {
      // 2. create group and cache it
      group = await archivist.createGroup(identifier);
      if (group != null) {
        cacheGroup(group);
      }
    }
    return group;
  }

  ///  Select local user for receiver
  ///
  /// @param receiver - user/group ID
  /// @return local user
  Future<User?> selectLocalUser(ID receiver) async {
    if (receiver.isGroup) {
      // group message (recipient not designated)
      // TODO: check members of group
      return null;
    } else {
      assert(receiver.isUser, 'receiver error: $receiver');
    }
    List<User> users = await archivist.localUsers;
    if (users.isEmpty) {
      assert(false, 'local users should not be empty');
      return null;
    } else if (receiver.isBroadcast) {
      // broadcast message can decrypt by anyone, so just return current user
      return users.first;
    }
    // 1. personal message
    // 2. split group message
    for (User item in users) {
      if (item.identifier == receiver) {
        // DISCUSS: set this item to be current user?
        return item;
      }
    }
    // not mine?
    return null;
  }

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

  //
  //  User DataSource
  //

  @override
  Future<EncryptKey?> getPublicKeyForEncryption(ID user) async {
    assert(user.isUser, 'user ID error: $user');
    Archivist db = archivist;
    // 1. get pubic key from visa
    EncryptKey? visaKey = await db.getVisaKey(user);
    if (visaKey != null) {
      // if visa.key exists, use it for encryption
      return visaKey;
    }
    // 2. get pubic key from meta
    VerifyKey? metaKey = await db.getMetaKey(user);
    if (metaKey is EncryptKey) {
      // if visa.key not exists and meta.key is encrypt key,
      // use it for encryption
      return metaKey as EncryptKey;
    }
    // assert(false, 'failed to get encrypt key for user: $user');
    return null;
  }

  @override
  Future<List<VerifyKey>> getPublicKeysForVerification(ID user) async {
    // assert(user.isUser, 'user ID error: $user');
    List<VerifyKey> keys = [];
    Archivist db = archivist;
    // 1. get pubic key from visa
    EncryptKey? visaKey = await db.getVisaKey(user);
    if (visaKey is VerifyKey) {
      // the sender may use communication key to sign message.data,
      // so try to verify it with visa.key first
      keys.add(visaKey as VerifyKey);
    }
    // 2. get pubic key from meta
    VerifyKey? metaKey = await db.getMetaKey(user);
    if (metaKey != null) {
      // the sender may use identity key to sign message.data,
      // try to verify it with meta.key too
      keys.add(metaKey);
    }
    assert(keys.isNotEmpty, 'failed to get verify key for user: $user');
    return keys;
  }

}
