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
    Barrack? factory = barrack;
    if (factory == null) {
      assert(false, 'barrack not ready');
      return null;
    }
    // get from user cache
    User? user = factory.getUser(identifier);
    if (user == null) {
      // create user and cache it
      user = factory.createUser(identifier);
      if (user != null) {
        factory.cacheUser(user);
      }
    }
    return user;
  }

  @override
  Future<Group?> getGroup(ID identifier) async {
    assert(identifier.isGroup, 'group ID error: $identifier');
    Barrack? factory = barrack;
    if (factory == null) {
      assert(false, 'barrack not ready');
      return null;
    }
    // get from group cache
    Group? group = factory.getGroup(identifier);
    if (group == null) {
      // create group and cache it
      group = factory.createGroup(identifier);
      if (group != null) {
        factory.cacheGroup(group);
      }
    }
    return group;
  }

}
