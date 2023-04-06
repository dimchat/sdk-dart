/* license: https://mit-license.org
 *
 *  Ming-Ke-Ming : Decentralized User Identity Authentication
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
import 'package:dimp/dimp.dart';

///  @enum MKMNetworkID
///
///  @abstract A network type to indicate what kind the entity is.
///
///  @discussion An address can identify a person, a group of people,
///      a team, even a thing.
///
///      MKMNetwork_Main indicates this entity is a person's account.
///      An account should have a public key, which proved by meta data.
///
///      MKMNetwork_Group indicates this entity is a group of people,
///      which should have a founder (also the owner), and some members.
///
///      MKMNetwork_Moments indicates a special personal social network,
///      where the owner can share information and interact with its friends.
///      The owner is the king here, it can do anything and no one can stop it.
///
///      MKMNetwork_Polylogue indicates a virtual (temporary) social network.
///      It's created to talk with multi-people (but not too much, e.g. less than 100).
///      Any member can invite people in, but only the founder can expel member.
///
///      MKMNetwork_Chatroom indicates a massive (persistent) social network.
///      It's usually more than 100 people in it, so we need administrators
///      to help the owner to manage the group.
///
///      MKMNetwork_SocialEntity indicates this entity is a social entity.
///
///      MKMNetwork_Organization indicates an independent organization.
///
///      MKMNetwork_Company indicates this entity is a company.
///
///      MKMNetwork_School indicates this entity is a school.
///
///      MKMNetwork_Government indicates this entity is a government department.
///
///      MKMNetwork_Department indicates this entity is a department.
///
///      MKMNetwork_Thing this is reserved for IoT (Internet of Things).
///
///  Bits:
///      0000 0001 - this entity's branch is independent (clear division).
///      0000 0010 - this entity can contains other group (big organization).
///      0000 0100 - this entity is top organization.
///      0000 1000 - (MAIN) this entity acts like a human.
///
///      0001 0000 - this entity contains members (Group)
///      0010 0000 - this entity needs other administrators (big organization)
///      0100 0000 - this is an entity in reality.
///      1000 0000 - (IoT) this entity is a 'Thing'.
///
///      (All above are just some advices to help choosing numbers :P)
class NetworkID {

  static const int kBTCMain         = (0x00); // 0000 0000
  // static const int kBTCTest      = (0x6f); // 0110 1111

  /*
     *  Person Account
     */
  static const int kMain            = (0x08); // 0000 1000 (Person)

  /*
     *  Virtual Groups
     */
  static const int kGroup           = (0x10); // 0001 0000 (Multi-Persons)

  // static const int kMoments      = (0x18), // 0001 1000 (Twitter)
  static const int kPolylogue       = (0x10); // 0001 0000 (Multi-Persons Chat, N < 100)
  static const int kChatroom        = (0x30); // 0011 0000 (Multi-Persons Chat, N >= 100)

  /*
     *  Social Entities in Reality
     */
  // static const int kSocialEntity = (0x50); // 0101 0000

  // static const int kOrganization = (0x74); // 0111 0100
  // static const int kCompany      = (0x76); // 0111 0110
  // static const int kSchool       = (0x77); // 0111 0111
  // static const int kGovernment   = (0x73); // 0111 0011
  // static const int kDepartment   = (0x52); // 0101 0010

  /*
     *  Network
     */
  static const int kProvider        = (0x76); // 0111 0110 (Service Provider)
  static const int kStation         = (0x88); // 1000 1000 (Server Node)

  // static const int kBotGroup     = (0x74); // 0111 0100 (Content Provider)
  static const int kBot             = (0xC8); // 1100 1000
  static const int kThing           = (0x80); // 1000 0000 (IoT)


  ///  Convert entity type from network ID (MKM 0.9.*)
  ///
  /// @param type - network ID
  /// @return entity type
  static int getType(int type) {
    // compatible with MKM 0.9.*
    switch (type) {
      case kMain:
        return EntityType.kUser;
      case kGroup:
        return EntityType.kGroup;
      case kChatroom:
        return EntityType.kGroup | kChatroom;
      case kStation:
        return EntityType.kStation;
      case kProvider:
        return EntityType.kISP;
      case kBot:
        return EntityType.kBot;
    }
    return type;
  }
}
