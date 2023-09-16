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

abstract class CipherKeyDelegate {

  /*
   *                +-----------------+-----------------+-----------------+-----------------+
   *                |     is user     |    is group     | broadcast user  | broadcast group |
   *      +---------+-----------------+-----------------+-----------------+-----------------+
   *      |         |                 |    receiver     |                 |                 |
   *      |   (A)   +-----------------+-----------------+-----------------+-----------------+
   *      |         |                 |                 |                 |    receiver     |
   *      +---------+-----------------+-----------------+-----------------+-----------------+
   *      |         |    receiver     |                 |                 |                 |
   *      |   (B)   +-----------------+-----------------+-----------------+-----------------+
   *      |         |                 |                 |    receiver     |                 |
   *      +---------+-----------------+-----------------+-----------------+-----------------+
   *      |   (C)   |    receiver     |                 |                 |                 |
   *      +---------+-----------------+-----------------+-----------------+-----------------+
   *      |         |    receiver     |                 |                 |      group      |
   *      |   (D)   +-----------------+-----------------+-----------------+-----------------+
   *      |         |                 |                 |    receiver     |      group      |
   *      +---------+-----------------+-----------------+-----------------+-----------------+
   *      |   (E)   |                 |      group      |    receiver     |                 |
   *      +---------+-----------------+-----------------+-----------------+-----------------+
   *      |   (F)   |    receiver     |      group      |                 |                 |
   *      +---------+-----------------+-----------------+-----------------+-----------------+
   */
  static ID getDestination({required ID receiver, required ID? group}) {
    if (receiver.isGroup) {
      // (A)  group message, not split yet (maybe broadcast)
      //      'group' field must be empty here
      return receiver;
    } else if (group == null) {
      // (B)  personal message (maybe broadcast)
      // (C)  group message split for its member, and needs to hide the group ID
      return receiver;
    } else if (group.isBroadcast) {
      // (D)  broadcast group message, split for special user
      //      'sender' field must be user here
      return group;
    } else if (receiver.isBroadcast) {
      // (E)  group message, broadcast to all members
      return receiver;
    } else {
      // (F)  group message, split for special member
      return group;
    }
  }

  ///  Get cipher key for encrypt message from 'sender' to 'receiver'
  ///
  /// @param sender - from where (user or contact ID)
  /// @param receiver - to where (contact or user/group ID)
  /// @param generate - generate when key not exists
  /// @return cipher key
  Future<SymmetricKey?> getCipherKey({required ID sender, required ID receiver,
                                      bool generate = false});

  ///  Cache cipher key for reusing, with the direction ('sender' => 'receiver')
  ///
  /// @param sender - from where (user or contact ID)
  /// @param receiver - to where (contact or user/group ID)
  /// @param key - cipher key
  Future<void> cacheCipherKey({required ID sender, required ID receiver,
                               required SymmetricKey key});

}
