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

  Barrack get barrack;

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
  //  Public Keys
  //

  ///  Get meta.key
  ///
  /// @param user - user ID
  /// @return null on not found
  Future<VerifyKey?> getMetaKey(ID user);

  ///  Get visa.key
  ///
  /// @param user - user ID
  /// @return null on not found
  Future<EncryptKey?> getVisaKey(ID user);

  //
  //  Local Users
  //

  ///  Get all local users (for decrypting received message)
  ///
  /// @return users with private key
  Future<List<User>> getLocalUsers();

  ///  Select local user for receiver
  ///
  /// @param receiver - user/group ID
  /// @return local user
  Future<User?> selectLocalUser(ID receiver) async {
    if (receiver.isUser) {} else {
      assert(receiver.isGroup, 'receiver error: $receiver');
      // group message (recipient not designated)
      // TODO: check members of group
      return null;
    }
    List<User> users = await getLocalUsers();
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

  //
  //  Entity Delegate
  //

  @override
  Future<User?> getUser(ID identifier) async {
    assert(identifier.isUser, 'user ID error: $identifier');
    //
    //  1. get from user cache
    //
    User? user = barrack.getUser(identifier);
    if (user != null) {
      return user;
    }
    //
    //  2. check visa key
    //
    if (identifier.isBroadcast) {} else {
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
    user = barrack.createUser(identifier);
    if (user != null) {
      barrack.cacheUser(user);
    }
    return user;
  }

  @override
  Future<Group?> getGroup(ID identifier) async {
    assert(identifier.isGroup, 'group ID error: $identifier');
    //
    //  1. get from group cache
    //
    Group? group = barrack.getGroup(identifier);
    if (group != null) {
      return group;
    }
    //
    //  2. check members
    //
    if (identifier.isBroadcast) {} else {
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
    group = barrack.createGroup(identifier);
    if (group != null) {
      barrack.cacheGroup(group);
    }
    return group;
  }

  //
  //  User DataSource
  //

  @override
  Future<EncryptKey?> getPublicKeyForEncryption(ID user) async {
    assert(user.isUser, 'user ID error: $user');
    //
    //  1. get pubic key from visa
    //
    EncryptKey? visaKey = await getVisaKey(user);
    if (visaKey != null) {
      // if visa.key exists, use it for encryption
      return visaKey;
    }
    //
    //  2. get key from meta
    //
    VerifyKey? metaKey = await getMetaKey(user);
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
    //
    //  1. get pubic key from visa
    //
    EncryptKey? visaKey = await getVisaKey(user);
    if (visaKey is VerifyKey) {
      // the sender may use communication key to sign message.data,
      // so try to verify it with visa.key first
      keys.add(visaKey as VerifyKey);
    }
    //
    //  2. get key from meta
    //
    VerifyKey? metaKey = await getMetaKey(user);
    if (metaKey != null) {
      // the sender may use identity key to sign message.data,
      // try to verify it with meta.key too
      keys.add(metaKey);
    }
    assert(keys.isNotEmpty, 'failed to get verify key for user: $user');
    return keys;
  }

}
