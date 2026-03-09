/* license: https://mit-license.org
 *
 *  DIM-SDK : Decentralized Instant Messaging Software Development Kit
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

import 'group.dart';
import 'user.dart';


// -----------------------------------------------------------------------------
//  Core Entity Interfaces (User/Group Base)
// -----------------------------------------------------------------------------

/// Base interface for all network entities (User/Group).
///
/// Defines the core properties and data access patterns for entities in the communication system.
/// Entities are identified by a unique ID and have associated metadata (Meta) and extended documents
/// (e.g., Visa for Users, Bulletin for Groups).
///
/// Core properties:
/// - `identifier` : Unique ID of the entity (user/group ID)
/// - `type`       : Numeric type identifier for the entity (user = 0, group = 1, etc.)
/// - `meta`       : Cryptographic metadata used to generate the entity ID
/// - `documents`  : Extended information (Visa for users, Bulletin for groups)
abstract interface class Entity {

  /// Unique identifier of the entity (user/group ID).
  ///
  /// Serves as the primary key for identifying the entity in the system.
  ID get identifier;

  /// Numeric type identifier of the entity (EntityType).
  ///
  /// Common values:
  /// - 0 : User entity
  /// - 1 : Group entity
  /// - ...
  int get type;

  /// Data source delegate for retrieving entity data (Meta/Documents).
  ///
  /// If set, the entity will use this delegate to fetch metadata and documents instead of
  /// internal implementation, enabling flexible data sourcing (local/remote).
  EntityDataSource? get dataSource;
  set dataSource(EntityDataSource? delegate);

  /// Cryptographic metadata of the entity (async).
  ///
  /// Contains the core public key and type information used to generate the entity's ID.
  /// Fetched from [dataSource] if available, otherwise from internal storage.
  ///
  /// Returns: Entity's core Meta object
  Future<Meta> get meta;

  /// Extended documents associated with the entity (async).
  ///
  /// - For users: Contains [Visa] documents (identity/authorization info with terminal data)
  /// - For groups: Contains [Bulletin] documents (group info/announcements)
  ///
  /// Returns: List of entity documents (empty list if none)
  Future<List<Document>> get documents;
}


/// Data source interface for retrieving entity metadata and documents.
///
/// Defines the contract for fetching core entity data, enabling separation of data storage
/// (local database, remote API) from entity logic.
///
/// Key data responsibilities:
/// 1. User Meta: Generated from the user's private key (contains public key for verification)
/// 2. Group Meta: Generated from the group founder's private key
/// 3. Meta Public Key: Used to verify messages sent by the user/group founder
/// 4. Visa Public Key: Used to encrypt messages for the user (terminal-specific)
abstract interface class EntityDataSource {

  /// Retrieves the metadata for a specific entity (async).
  ///
  /// Parameters:
  /// - [identifier] : Unique ID of the target entity (user/group)
  ///
  /// Returns: Meta object for the entity (null if not found)
  Future<Meta?> getMeta(ID identifier);

  /// Retrieves the extended documents for a specific entity (async).
  ///
  /// Parameters:
  /// - [identifier] : Unique ID of the target entity (user/group)
  ///
  /// Returns: List of documents (Visa/Bulletin) associated with the entity (empty list if none)
  Future<List<Document>> getDocuments(ID identifier);
}


/// Delegate interface for creating User/Group instances.
///
/// Provides a factory pattern for entity instantiation, enabling centralized management
/// of user/group creation logic (e.g., caching, dependency injection).
abstract interface class EntityDelegate {

  /// Creates/retrieves a User instance for a specific ID (async).
  ///
  /// Parameters:
  /// - [identifier] : Unique ID of the target user
  ///
  /// Returns: User instance (null if the user does not exist)
  Future<User?> getUser(ID identifier);

  /// Creates/retrieves a Group instance for a specific ID (async).
  ///
  /// Parameters:
  /// - [identifier] : Unique ID of the target group
  ///
  /// Returns: Group instance (null if the group does not exist)
  Future<Group?> getGroup(ID identifier);
}

//
//  Base Entity
//

class BaseEntity implements Entity {
  BaseEntity(this._id);

  // entity ID
  final ID _id;

  // facebook
  WeakReference<EntityDataSource>? _facebook;

  @override
  bool operator ==(Object other) {
    if (other is Entity) {
      if (identical(this, other)) {
        // same object
        return true;
      }
      // check with ID
      other = other.identifier;
    }
    return _id == other;
  }

  @override
  int get hashCode => _id.hashCode;

  String get className {
    String name = 'Entity';
    assert(() {
      name = runtimeType.toString();
      return true;
    }());
    return name;
  }

  @override
  String toString() {
    String clazz = className;
    int network = _id.address.network;
    return '<$clazz id="$_id" network=$network />';
  }

  @override
  ID get identifier => _id;

  @override
  int get type => _id.type;

  @override
  EntityDataSource? get dataSource => _facebook?.target;

  @override
  set dataSource(EntityDataSource? facebook) =>
      _facebook = facebook == null ? null : WeakReference(facebook);

  @override
  Future<Meta> get meta async =>
      (await dataSource!.getMeta(_id))!;

  @override
  Future<List<Document>> get documents async =>
      await dataSource!.getDocuments(_id);

}
