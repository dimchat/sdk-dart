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

import '../mkm/group.dart';
import '../mkm/user.dart';


/// Entity pool for managing and caching User/Group instances (account entity manager).
///
/// Core responsibilities:
/// 1. In-memory caching of User/Group entities to avoid repeated creation
/// 2. Lazy creation of User/Group entities when required metadata is available
/// 3. Fast lookup of entities by ID (identifier)
///
/// Key design: Acts as a "barracks" (entity pool) to centralize entity management,
/// ensuring only one instance exists per ID and reducing redundant data loading.
abstract interface class Barrack {

  /// Caches a User entity in memory (overwrites existing entry for the same ID).
  ///
  /// Parameters:
  /// - [user] : User entity to cache (must have a valid ID)
  void cacheUser(User user);

  /// Caches a Group entity in memory (overwrites existing entry for the same ID).
  ///
  /// Parameters:
  /// - [group] : Group entity to cache (must have a valid ID)
  void cacheGroup(Group group);

  /// Retrieves a cached User entity by ID.
  ///
  /// Parameters:
  /// - [uid] : Unique ID of the target user
  ///
  /// Returns: Cached User instance (null if not found in cache)
  User? getUser(ID uid);

  /// Retrieves a cached Group entity by ID.
  ///
  /// Parameters:
  /// - [gid] : Unique ID of the target group
  ///
  /// Returns: Cached Group instance (null if not found in cache)
  Group? getGroup(ID gid);

  /// Creates a User entity if the required visa key metadata exists.
  ///
  /// Lazy creation rule: Only creates a User when the user's visa.key (public key)
  /// is available (entity is "ready" for use). Does not cache the created user automatically.
  ///
  /// Parameters:
  /// - [uid] : Unique ID of the user to create
  ///
  /// Returns: New User instance (null if visa.key is missing/entity not ready)
  User? createUser(ID uid);

  /// Creates a Group entity if the required member list exists.
  ///
  /// Lazy creation rule: Only creates a Group when the group's member list is available
  /// (entity is "ready" for use). Does not cache the created group automatically.
  ///
  /// Parameters:
  /// - [gid]: Unique ID of the group to create
  ///
  /// Returns: New Group instance (null if members are missing/entity not ready)
  Group? createGroup(ID gid);

}


// -----------------------------------------------------------------------------
//  Archivist (Persistent Data Access)
// -----------------------------------------------------------------------------

/// Persistent data access interface for entity metadata and documents.
///
/// Core responsibilities:
/// 1. Saves entity metadata and documents to persistent storage (database)
/// 2. Retrieves local user IDs (critical for message decryption)
/// 3. Enforces pre-verification rule: All save operations require prior validation
abstract interface class Archivist {

  /// Saves entity metadata to persistent storage (must verify metadata first).
  ///
  /// Precondition: Metadata must be validated (authenticity/integrity) before saving.
  ///
  /// Parameters:
  /// - [meta] : Validated metadata of the entity (user/group)
  /// - [did]  : Unique ID of the entity to associate with the metadata
  ///
  /// Returns: True if metadata is saved successfully, false otherwise
  Future<bool> saveMeta(Meta meta, ID did);

  /// Saves an entity document to persistent storage (must verify document first).
  ///
  /// Precondition: Document must be validated (authenticity/integrity) before saving.
  ///
  /// Parameters:
  /// - [doc] : Validated document data of the entity (user/group)
  /// - [did] : Unique ID of the entity to associate with the document
  ///
  /// Returns: True if document is saved successfully, false otherwise
  Future<bool> saveDocument(Document doc, ID did);

  // -------------------------------------------------------------------------
  //  Local User Management (Critical for Message Decryption)
  // -------------------------------------------------------------------------

  /// Retrieves all local user IDs (used for decrypting received messages).
  ///
  /// Local users are accounts logged into the current device with private keys,
  /// required to decrypt incoming personal/group messages targeted to the device.
  ///
  /// Returns: List of local user IDs (non-empty in normal operation)
  Future<List<ID>> getLocalUsers();

}
