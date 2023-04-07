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

///  Permissions Table:
///
///  /=============+=======+=============+=============+=============+=======\
///  |             | Foun- |    Owner    |    Admin    |    Member   | Other |
///  |             | der   | Wai Nor Fre | Wai Nor Fre | Wai Nor Fre |       |
///  +=============+=======+=============+=============+=============+=======+
///  | 1. found    |  YES  |  -   -   -  |  -   -   -  |  -   -   -  |  -    |
///  | 2. abdicate |   -   |  NO YES  NO |  -   -   -  |  -   -   -  |  -    |
///  +-------------+-------+-------------+-------------+-------------+-------+
///  | 3. invite   |   -   | YES YES YES | YES YES YES |  NO YES  NO |  -    |
///  | 4. expel    |   -   |  NO YES YES |  NO YES  NO |  NO  NO  NO |  -    |
///  | 5. join     |   -   |  -   -   -  |  -   -   -  |  -   -   -  | YES   |
///  | 6. quit     |   -   |  NO  NO  NO |  NO  NO  NO | YES YES  -  |  -    |
///  +-------------+-------+-------------+-------------+-------------+-------+
///  | 7. hire     |   -   |  NO YES YES |  NO  NO  NO |  NO  NO  NO |  -    |
///  | 8. fire     |   -   |  NO YES YES |  NO  NO  NO |  NO  NO  NO |  -    |
///  | 9. resign   |   -   |  -   -   -  | YES YES  -  |  -   -   -  |  -    |
///  +-------------+-------+-------------+-------------+-------------+-------+
///  | 10. speak   |   -   | YES YES YES | YES YES YES | YES YES  NO |  NO   |
///  | 11. history |  1st  |  NO YES YES |  NO  NO  NO |  NO  NO  NO |  NO   |
///  \=============+=======+=============+=============+=============+=======/
///                                (Wai: Waiting, Nor: Normal, Fre: Freezing)
///
///  Role Transition Model:
///
///        Founder
///           |      (Freezing) ----+         (Freezing) ------+
///           |        /            |           /              |
///           V       /             V          /               V
///        Owner (Normal)          Member (Normal)         Strangers
///                   \             |  ^   |   \               |
///                    \            |  |   |    \              |
///                  (Waiting) <----+  |   |  (Waiting) <------+
///                     ^              |   |
///                     |      (Freezing)  |
///                     |        /         |
///                   Admin (Normal)       |
///                              \         |
///                            (Waiting) <-+
///
///  Bits:
///      0000 0001 - speak
///      0000 0010 - rename
///      0000 0100 - invite
///      0000 1000 - expel (admin)
///
///      0001 0000 - abdicate/hire/fire (owner)
///      0010 0000 - write history
///      0100 0000 - Waiting
///      1000 0000 - Freezing
///
///      (All above are just some advices to help choosing numbers :P)
class MemberType {

  static const int kFounder  = (0x20); // 0010 0000
  static const int kOwner    = (0x3F); // 0011 1111
  static const int kAdmin    = (0x0F); // 0000 1111
  static const int kMember   = (0x07); // 0000 0111
  static const int kOther    = (0x00); // 0000 0000

  static const int kFreezing = (0x80); // 1000 0000
  static const int kWaiting  = (0x40); // 0100 0000

  static const int kOwnerWaiting   = (kOwner  | kWaiting);
  static const int kOwnerFreezing  = (kOwner  | kFreezing);
  static const int kAdminWaiting   = (kAdmin  | kWaiting);
  static const int kAdminFreezing  = (kAdmin  | kFreezing);
  static const int kMemberWaiting  = (kMember | kWaiting);
  static const int kMemberFreezing = (kMember | kFreezing);

}
