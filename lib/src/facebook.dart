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
import 'package:dimp/mkm.dart';

import 'core/barrack.dart';
import 'mkm/entity.dart';
import 'mkm/group.dart';
import 'mkm/user.dart';


// -----------------------------------------------------------------------------
//  Facebook (Unified Entity Management)
// -----------------------------------------------------------------------------

/// Unified manager for user/group entity operations (combines caching + data access).
///
/// Implements core entity management workflows:
/// 1. Selects the correct local user for message decryption
/// 2. Retrieves/creates user/group entities (combines Barrack cache + lazy creation)
/// 3. Integrates with Archivist for persistent data access
///
/// Implements: [EntityDelegate], [UserDataSource], [GroupDataSource]
abstract class Facebook implements EntityDelegate, UserDataSource, GroupDataSource {

  /// Returns the entity cache manager (Barrack) - internal use only.
  ///
  /// Null if the barrack is not initialized/ready for use.
  // protected
  Barrack? get barrack;

  /// Returns the persistent data access layer (Archivist) - internal use only.
  ///
  /// Null if the archivist is not initialized/ready for use.
  // protected
  Archivist? get archivist;

  /// Selects a local user for decrypting messages to a user/broadcast receiver.
  ///
  /// Core logic:
  ///   0. Validates receiver type (only user/broadcast allowed)
  ///   1. If receiver is broadcast → returns first local user (any user can decrypt)
  ///   2. If receiver is user → returns matching local user (personal message target)
  ///   3. Returns null if no matching local user is found
  ///
  /// Parameters:
  /// - [receiver] : Target receiver ID (must be user or broadcast type)
  ///
  /// Returns: Local user ID for decryption (null if no match)
  ///
  /// Throws: Assertion error if receiver is invalid (group) or local users are empty
  Future<ID?> selectUser(ID receiver) async {
    assert(receiver.isUser || receiver.isBroadcast, 'user ID error: $receiver');
    assert(archivist != null, 'archivist not ready');
    List<ID>? allUsers = await archivist?.getLocalUsers();
    if (allUsers == null || allUsers.isEmpty) {
      assert(false, 'local users should not be empty');
      return null;
    } else if (receiver.isBroadcast) {
      // broadcast message can be decrypted by anyone, so
      // just return current user here
      return allUsers.first;
    }
    // personal message
    for (ID item in allUsers) {
      if (receiver == item) {
        // DISCUSS: set this item to be current user?
        return item;
      }
    }
    // not for me?
    return null;
  }

  /// Selects a local user who is a member of a specific group (for group message decryption).
  ///
  /// Core logic:
  ///   0. Validates group member list is non-empty
  ///   1. Finds the first local user that exists in the group member list
  ///   2. Returns null if no local user is a group member
  ///
  /// Parameters:
  /// - [members] : List of group member IDs (must be non-empty)
  ///
  /// Returns: Local user ID who is a group member (null if no match)
  ///
  /// Throws: Assertion error if members are empty or local users are empty
  Future<ID?> selectMember(List<ID> members) async {
    assert(members.isNotEmpty, 'group members not found');
    assert(archivist != null, 'archivist not ready');
    List<ID>? allUsers = await archivist?.getLocalUsers();
    if (allUsers == null || allUsers.isEmpty) {
      assert(false, 'local users should not be empty');
      return null;
    }
    // group message (recipient not designated)
    for (ID item in allUsers) {
      if (members.contains(item)) {
        // DISCUSS: set this item to be current user?
        return item;
      }
    }
    // not for me?
    return null;
  }

  // -------------------------------------------------------------------------
  //  Entity Delegate Implementation (User Management)
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  //  Entity Delegate Implementation (Group Management)
  // -------------------------------------------------------------------------

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
