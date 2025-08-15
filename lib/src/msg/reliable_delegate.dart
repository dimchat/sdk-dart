/* license: https://mit-license.org
 *
 *  Dao-Ke-Dao: Universal Message Module
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
import 'dart:typed_data';

import 'package:dimp/dimp.dart';


///  Reliable Message Delegate
///  ~~~~~~~~~~~~~~~~~~~~~~~~~
abstract interface class ReliableMessageDelegate/* implements SecureMessageDelegate*/ {

  /*
   *  Verify the Reliable Message to Secure Message
   *
   *    +----------+      +----------+
   *    | sender   |      | sender   |
   *    | receiver |      | receiver |
   *    | time     |  ->  | time     |
   *    |          |      |          |
   *    | data     |      | data     |  1. verify(data, signature, sender.PK)
   *    | key/keys |      | key/keys |
   *    | signature|      +----------+
   *    +----------+
   */

  // ///  1. Decode 'message.signature' from String (Base64)
  // ///
  // /// @param signature - base64 string object
  // /// @param rMsg      - reliable message
  // /// @return signature data
  // Future<Uint8List?> decodeSignature(Object signature, ReliableMessage rMsg);

  ///  2. Verify the message data and signature with sender's public key
  ///
  ///  @param data      - message content(encrypted) data
  ///  @param signature - signature for message content(encrypted) data
  ///  @param rMsg      - reliable message object
  ///  @return YES on signature matched
  Future<bool> verifyDataSignature(Uint8List data, Uint8List signature, ReliableMessage rMsg);
}
