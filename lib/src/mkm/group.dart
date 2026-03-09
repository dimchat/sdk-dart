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

import 'entity.dart';


// -----------------------------------------------------------------------------
//  Group Entity
// -----------------------------------------------------------------------------

/// Group entity interface representing a chat group.
///
/// Extends [Entity] with group-specific properties and role management.
///
/// Groups have a hierarchical role structure:
/// - Founder        : Original creator of the group (immutable)
/// - Owner          : Current administrator of the group (can be transferred)
/// - Members        : Regular participants in the group
/// - Administrators : Optional role for privileged members (assistants)
///
/// Important note: The group owner must always be a member of the group (usually the first member).
abstract interface class Group implements Entity {

  /// Founder ID of the group (async).
  ///
  /// The original creator of the group (cannot be changed after group creation).
  /// The founder's private key is used to generate the group's Meta.
  ///
  /// Returns: Group founder's ID
  Future<ID> get founder;

  /// Current owner ID of the group (async).
  ///
  /// The user with administrative control over the group (can be transferred via abdicate command).
  /// Must be a member of the group.
  ///
  /// Returns: Current group owner's ID
  Future<ID> get owner;

  /// List of all member IDs in the group (async).
  ///
  /// Includes the owner and all regular members (excludes founder if not a member).
  ///
  /// Returns: List of group member IDs (empty list if none)
  Future<List<ID>> get members;
  // NOTICE: the owner must be a member
  //         (usually the first one)

}


/// Data source interface for retrieving group-specific data.
///
/// Extends [EntityDataSource] with group role and membership management, defining
/// the contract for fetching group-specific data (founder, owner, members).
///
/// Key rules:
/// 1. Founder's public key matches the group Meta's public key
/// 2. Owner/members must be managed according to the system's consensus algorithm
abstract interface class GroupDataSource implements EntityDataSource {

  /// Retrieves the founder ID of a group (async).
  ///
  /// Parameters:
  /// - [group] : Unique ID of the target group
  ///
  /// Returns: Founder ID (null if the group does not exist)
  Future<ID?> getFounder(ID group);

  /// Retrieves the current owner ID of a group (async).
  ///
  /// Parameters:
  /// - [group] : Unique ID of the target group
  ///
  /// Returns: Owner ID (null if the group does not exist or has no owner)
  Future<ID?> getOwner(ID group);

  /// Retrieves the list of member IDs for a group (async).
  ///
  /// Parameters:
  /// - [group] : Unique ID of the target group
  ///
  /// Returns: List of member IDs (empty list if the group has no members)
  Future<List<ID>> getMembers(ID group);

}

//
//  Base Group
//

class BaseGroup extends BaseEntity implements Group {
  BaseGroup(super.id);

  /// once the group founder is set, it will never change
  ID? _founder;

  @override
  GroupDataSource? get dataSource {
    var facebook = super.dataSource;
    if (facebook is GroupDataSource) {
      return facebook;
    }
    assert(facebook == null, 'group data source error: $facebook');
    return null;
  }

  @override
  Future<ID> get founder async {
    _founder ??= await dataSource!.getFounder(identifier);
    return _founder!;
  }

  @override
  Future<ID> get owner async =>
      (await dataSource!.getOwner(identifier))!;

  @override
  Future<List<ID>> get members async =>
      await dataSource!.getMembers(identifier);

}
