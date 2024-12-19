/* license: https://mit-license.org
 *
 *  DIM-SDK : Decentralized Instant Messaging Software Development Kit
 *
 *                                Written in 2024 by Moky <albert.moky@gmail.com>
 *
 * ==============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2024 Albert Moky
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
import 'package:dimp/dimp.dart';


///  Entity Database
///  ~~~~~~~~~~~~~~~
///  Manage meta/document for all entities
abstract interface class Archivist {

  ///  Create user when visa.key exists
  ///
  /// @param identifier - user ID
  /// @return user, null on not ready
  Future<User?> createUser(ID identifier);

  ///  Create group when members exist
  ///
  /// @param identifier - group ID
  /// @return group, null on not ready
  Future<Group?> createGroup(ID identifier);

  ///  Get all local users (for decrypting received message)
  ///
  /// @return users with private key
  Future<List<User>> get localUsers;

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

}
