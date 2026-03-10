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


/// Base helper class that provides unified access to Facebook and Messenger dependencies.
///
/// "Twins" refers to the paired core services:
/// - **Facebook**: Entity management (user/group metadata, local user selection)
/// - **Messenger**: Messaging core (packing/unpacking, encryption/decryption, key management)
///
/// Key design features:
/// 1. Uses **WeakReference** to hold dependencies, preventing memory leaks (avoids circular references)
/// 2. Provides a unified entry point for local user selection (critical for message decryption)
/// 3. Serves as the parent class for all core messaging components (Packer/Processor/ContentProcessor)
///
/// All subclasses inherit access to Facebook/Messenger and the local user selection logic,
/// ensuring consistent dependency management across the messaging system.
abstract class TwinsHelper {

  /// Creates a [TwinsHelper] with references to the core Facebook and Messenger services.
  ///
  /// Parameters:
  /// - [facebook]  : Entity management service (user/group operations)
  /// - [messenger] : Core messaging service (packing/processing/key management)
  ///
  /// Note: Uses WeakReference to store dependencies to avoid memory leaks.
  TwinsHelper(Facebook facebook, Messenger messenger)
      : _facebook = WeakReference(facebook),
        _messenger = WeakReference(messenger);

  final WeakReference<Facebook> _facebook;
  final WeakReference<Messenger> _messenger;

  /// Retrieves the Facebook service instance (nullable - may be GC'd).
  ///
  /// Returns: Facebook instance (null if garbage collected or not initialized)
  Facebook? get facebook => _facebook.target;

  /// Retrieves the Messenger service instance (nullable - may be GC'd).
  ///
  /// Returns: Messenger instance (null if garbage collected or not initialized)
  Messenger? get messenger => _messenger.target;

  /// Selects the local User entity for decrypting messages to a target receiver (unified entry).
  ///
  /// Orchestration logic (receiver type routing):
  /// 1. Broadcast receiver → use [Facebook.selectUser] (any local user can decrypt)
  /// 2. User receiver → use [Facebook.selectUser] (matching local user for personal message)
  /// 3. Group receiver →
  ///    a. Get group members via Facebook (guaranteed to exist per precondition)
  ///    b. Use [Facebook.selectMember] (find local user in group member list)
  /// 4. Convert selected user ID to full User entity (via [Facebook.getUser])
  ///
  /// Precondition: Group member list is guaranteed to exist
  ///
  /// Parameters:
  /// - [receiver] : Target receiver ID (supports broadcast/user/group types)
  ///
  /// Returns: Local User entity for decryption (null if no matching local user found)
  ///
  /// Throws: Assertion error if:
  /// - Facebook service is unavailable (null)
  /// - Receiver type is invalid (not broadcast/user/group)
  /// - Group member list is empty/missing (violates precondition)
  // protected - intended for use by subclasses only
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
