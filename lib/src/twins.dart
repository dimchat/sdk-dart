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

import 'mkm/user.dart';

import 'facebook.dart';
import 'messenger.dart';


abstract class TwinsHelper {

  TwinsHelper(Facebook facebook, Messenger messenger)
      : _barrack = WeakReference(facebook),
        _transceiver = WeakReference(messenger);

  final WeakReference<Facebook> _barrack;
  final WeakReference<Messenger> _transceiver;

  Facebook? get facebook => _barrack.target;
  Messenger? get messenger => _transceiver.target;

  /// Selects the local User entity for decrypting messages to a target receiver (unified entry).
  ///
  /// Orchestration logic (receiver type routing):
  /// 1. Broadcast receiver → use [Facebook.selectUser] (any local user)
  /// 2. User receiver → use [Facebook.selectUser] (matching local user)
  /// 3. Group receiver →
  ///    a. Get group members via Facebook
  ///    b. Use [Facebook.selectMember] (local user in member list)
  /// 4. Convert selected user ID to full User entity (via [Facebook.getUser])
  ///
  /// Precondition: Group member list is guaranteed to exist
  ///
  /// Parameters:
  /// - [receiver] : Target receiver ID (broadcast/user/group)
  ///
  /// Returns: Local User entity for decryption (null if no matching user found)
  ///
  /// Throws: Assertion error if Facebook is unavailable, receiver is invalid, or group members are empty
  // protected
  Future<User?> selectLocalUser(ID receiver) async {
    assert(facebook != null, 'facebook not ready');
    ID? me;
    if (receiver.isBroadcast) {
      // broadcast message can be decrypted by anyone
      me = await facebook?.selectUser(receiver);
    } else if (receiver.isUser) {
      // check local users
      me = await facebook?.selectUser(receiver);
    } else if (receiver.isGroup) {
      // check local users for the group members
      List<ID>? members = await facebook?.getMembers(receiver);
      // the messenger will check group info before decrypting message,
      // so we can trust that the group's meta & members MUST exist here.
      if (members == null || members.isEmpty) {
        assert(false, 'failed to get group members: $receiver');
        return null;
      }
      me = await facebook?.selectMember(members);
    } else {
      assert(false, 'unknown receiver: $receiver');
    }
    if (me == null) {
      // not for me?
      return null;
    }
    return await facebook?.getUser(me);
  }

}
