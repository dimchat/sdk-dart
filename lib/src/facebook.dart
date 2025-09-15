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
import 'mkm/entity.dart';
import 'mkm/group.dart';
import 'mkm/user.dart';


abstract class Facebook implements EntityDelegate, UserDataSource, GroupDataSource {

  // protected
  Barrack? get barrack;

  Archivist? get archivist;

  ///  Select local user for receiver
  ///
  /// @param receiver - user/group ID
  /// @return local user
  Future<ID?> selectLocalUser(ID receiver) async {
    assert(archivist != null, 'archivist not ready');
    List<ID>? users = await archivist?.getLocalUsers();
    //
    //  1.
    //
    if (users == null || users.isEmpty) {
      assert(false, 'local users should not be empty');
      return null;
    } else if (receiver.isBroadcast) {
      // broadcast message can decrypt by anyone,
      // so just return current user
      return users.first;
    }
    //
    //  2.
    //
    if (receiver.isUser) {
      // personal message
      for (ID item in users) {
        if (receiver == item) {
          // DISCUSS: set this item to be current user?
          return item;
        }
      }
    } else if (receiver.isGroup) {
      // group message (recipient not designated)
      //
      // the messenger will check group info before decrypting message,
      // so we can trust that the group's meta & members MUST exist here.
      List<ID> members = await getMembers(receiver);
      if (members.isEmpty) {
        assert(false, 'members not found: $receiver');
        return null;
      }
      for (ID item in users) {
        if (members.contains(item)) {
          // DISCUSS: set this item to be current user?
          return item;
        }
      }
    } else {
      assert(false, 'receiver error: $receiver');
    }
    // not me?
    return null;
  }

  //
  //  Entity Delegate
  //

  @override
  Future<User?> getUser(ID identifier) async {
    assert(identifier.isUser, 'user ID error: $identifier');
    assert(barrack != null, 'barrack not ready');
    //
    //  1. get from user cache
    //
    User? user = barrack?.getUser(identifier);
    if (user != null) {
      return user;
    }
    //
    //  2. check visa key
    //
    if (identifier.isBroadcast) {
      // no need to check visa key for broadcast user
    } else {
      EncryptKey? visaKey = await getPublicKeyForEncryption(identifier);
      if (visaKey == null) {
        assert(false, 'visa.key not found: $identifier');
        return null;
      }
      // NOTICE: if visa.key exists, then visa & meta must exist too.
    }
    //
    //  3. create user and cache it
    //
    user = barrack?.createUser(identifier);
    if (user != null) {
      barrack?.cacheUser(user);
    }
    return user;
  }

  @override
  Future<Group?> getGroup(ID identifier) async {
    assert(identifier.isGroup, 'group ID error: $identifier');
    assert(barrack != null, 'barrack not ready');
    //
    //  1. get from group cache
    //
    Group? group = barrack?.getGroup(identifier);
    if (group != null) {
      return group;
    }
    //
    //  2. check members
    //
    if (identifier.isBroadcast) {
      // no need to check members for broadcast group
    } else {
      List<ID> members = await getMembers(identifier);
      if (members.isEmpty) {
        assert(false, 'group members not found: $identifier');
        return null;
      }
      // NOTICE: if members exist, then owner (founder) must exist,
      //         and bulletin & meta must exist too.
    }
    //
    //  3. create group and cache it
    //
    group = barrack?.createGroup(identifier);
    if (group != null) {
      barrack?.cacheGroup(group);
    }
    return group;
  }

  //
  //  User DataSource
  //

  @override
  Future<EncryptKey?> getPublicKeyForEncryption(ID user) async {
    assert(user.isUser, 'user ID error: $user');
    assert(archivist != null, 'archivist not ready');
    //
    //  1. get pubic key from visa
    //
    EncryptKey? visaKey = await archivist?.getVisaKey(user);
    if (visaKey != null) {
      // if visa.key exists, use it for encryption
      return visaKey;
    }
    //
    //  2. get key from meta
    //
    VerifyKey? metaKey = await archivist?.getMetaKey(user);
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
    assert(archivist != null, 'archivist not ready');
    List<VerifyKey> keys = [];
    //
    //  1. get pubic key from visa
    //
    EncryptKey? visaKey = await archivist?.getVisaKey(user);
    if (visaKey is VerifyKey) {
      // the sender may use communication key to sign message.data,
      // so try to verify it with visa.key first
      keys.add(visaKey as VerifyKey);
    }
    //
    //  2. get key from meta
    //
    VerifyKey? metaKey = await archivist?.getMetaKey(user);
    if (metaKey != null) {
      // the sender may use identity key to sign message.data,
      // try to verify it with meta.key too
      keys.add(metaKey);
    }
    assert(keys.isNotEmpty, 'failed to get verify key for user: $user');
    return keys;
  }

}
