/* license: https://mit-license.org
 *
 *  DIMP : Decentralized Instant Messaging Protocol
 *
 *                                Written in 2023 by Moky <albert.moky@gmail.com>
 *
 * ==============================================================================
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
 * ==============================================================================
 */
import 'package:dimp/mkm.dart';

import '../mkm/bot.dart';
import '../mkm/group.dart';
import '../mkm/provider.dart';
import '../mkm/station.dart';
import '../mkm/user.dart';


///  Entity Factory
///  ~~~~~~~~~~~~~~
///  Entity pool to manage User/Group instances
abstract class Barrack {

  void cacheUser(User user);

  void cacheGroup(Group group);

  User? getUser(ID identifier);

  Group? getGroup(ID identifier);

  ///  Create user when visa.key exists
  ///
  /// @param identifier - user ID
  /// @return user, null on not ready
  User? createUser(ID identifier) {
    assert(identifier.isUser, 'user ID error: $identifier');
    int network = identifier.type;
    // check user type
    if (network == EntityType.STATION) {
      return Station.fromID(identifier);
    } else if (network == EntityType.BOT) {
      return Bot(identifier);
    }
    // general user, or 'anyone@anywhere'
    return BaseUser(identifier);
  }

  ///  Create group when members exist
  ///
  /// @param identifier - group ID
  /// @return group, null on not ready
  Group? createGroup(ID identifier) {
    assert(identifier.isGroup, 'group ID error: $identifier');
    int network = identifier.type;
    // check group type
    if (network == EntityType.ISP) {
      return ServiceProvider(identifier);
    }
    // general group, or 'everyone@everywhere'
    return BaseGroup(identifier);
  }

}


abstract interface class Archivist {

  ///  Save meta for entity ID (must verify first)
  ///
  /// @param meta       - entity meta
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
  /// @param identifier - entity ID
  /// @return null on not found
  Future<VerifyKey?> getMetaKey(ID identifier);

  ///  Get visa.key
  ///
  /// @param identifier - entity ID
  /// @return null on not found
  Future<EncryptKey?> getVisaKey(ID identifier);

  //
  //  Local Users
  //

  ///  Get all local users (for decrypting received message)
  ///
  /// @return users with private key
  Future<List<ID>> getLocalUsers();

}
