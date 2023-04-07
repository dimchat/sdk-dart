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

abstract class Facebook extends Barrack {

  // memory caches
  final Map<ID, User>   _userMap = {};
  final Map<ID, Group> _groupMap = {};

  /// Call it when received 'UIApplicationDidReceiveMemoryWarningNotification',
  /// this will remove 50% of cached objects
  ///
  /// @return number of survivors
  int reduceMemory() {
    int finger = 0;
    finger = thanos(_userMap, finger);
    finger = thanos(_groupMap, finger);
    return finger >> 1;
  }

  void _cacheUser(User user) {
    user.dataSource ??= this;
    _userMap[user.identifier] = user;
  }
  void _cacheGroup(Group group) {
    group.dataSource ??= this;
    _groupMap[group.identifier] = group;
  }

  ///  Save meta for entity ID (must verify first)
  ///
  /// @param meta - entity meta
  /// @param identifier - entity ID
  /// @return true on success
  bool saveMeta(Meta meta, ID identifier);

  ///  Save entity document with ID (must verify first)
  ///
  /// @param doc - entity document
  /// @return true on success
  bool saveDocument(Document doc);

  ///  Document checking
  ///
  /// @param doc - entity document
  /// @return true on accepted
  bool checkDocument(Document doc) {
    ID identifier = doc.identifier;
    // NOTICE: if this is a bulletin document for group,
    //             verify it with the group owner's meta.key
    //         else (this is a visa document for user)
    //             verify it with the user's meta.key
    Meta? meta;
    if (identifier.isGroup) {
      ID? owner = getOwner(identifier);
      if (owner != null) {
        // check by owner's meta.key
        meta = getMeta(owner);
      } else if (identifier.type == EntityType.kGroup) {
        // NOTICE: if this is a polylogue document,
        //             verify it with the founder's meta.key
        //             (which equals to the group's meta.key)
        meta = getMeta(identifier);
      } else {
        // FIXME: owner not found for this group
        return false;
      }
    } else {
      meta = getMeta(identifier);
    }
    return meta != null && doc.verify(meta.key);
  }

  // protected
  User? createUser(ID identifier) {
    // make sure visa key exists before calling this
    assert(identifier.isBroadcast || getPublicKeyForEncryption(identifier) != null,
    'visa key not found for user: $identifier');
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
  // protected
  Group? createGroup(ID identifier) {
    // make sure visa key exists before calling this
    assert(identifier.isBroadcast || getMeta(identifier) != null,
    'meta not found for group: $identifier');
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
  List<User> getLocalUsers();

  ///  Select local user for receiver
  ///
  /// @param receiver - user/group ID
  /// @return local user
  User? selectLocalUser(ID receiver) {
    List<User> users = getLocalUsers();
    if (users.isEmpty) {
      assert(false, 'local users should not be empty');
      return null;
    } else if (receiver.isBroadcast) {
      // broadcast message can decrypt by anyone, so just return current user
      return users[0];
    } else if (receiver.isUser) {
      // 1. personal message
      // 2. split group message
      for (User item in users) {
        if (item.identifier == receiver) {
          // DISCUSS: set this item to be current user?
          return item;
        }
      }
      return null;
    }
    // group message (recipient not designated)
    assert(receiver.isGroup, 'receiver error: $receiver');
    // the messenger will check group info before decrypting message,
    // so we can trust that the group's meta & members MUST exist here.
    Group? grp = getGroup(receiver);
    if (grp == null) {
      assert(false, "group not ready: $receiver");
      return null;
    }
    List<ID> members = grp.members;
    assert(members.isNotEmpty, "members not found: $receiver");
    for (User item in users) {
      if (members.contains(item.identifier)) {
        // DISCUSS: set this item to be current user?
        return item;
      }
    }
    return null;
  }

  //-------- Entity Delegate

  @override
  User? getUser(ID identifier) {
    // 1. get from user cache
    User? user = _userMap[identifier];
    if (user == null) {
      // 2. create user and cache it
      user = createUser(identifier);
      if (user != null) {
        _cacheUser(user);
      }
    }
    return user;
  }

  @override
  Group? getGroup(ID identifier) {
    // 1. get from group cache
    Group? group = _groupMap[identifier];
    if (group == null) {
      // 2. create group and cache it
      group = createGroup(identifier);
      if (group != null) {
        _cacheGroup(group);
      }
    }
    return group;
  }

}
