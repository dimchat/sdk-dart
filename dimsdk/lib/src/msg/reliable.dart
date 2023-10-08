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
import 'dart:typed_data';

import 'package:dimp/dimp.dart';

class ReliableMessagePacker {
  ReliableMessagePacker(ReliableMessageDelegate messenger)
      : _transceiver = WeakReference(messenger);

  final WeakReference<ReliableMessageDelegate> _transceiver;

  ReliableMessageDelegate? get delegate => _transceiver.target;

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

  ///  Verify 'data' and 'signature' field with sender's public key
  ///
  /// @return SecureMessage object
  Future<SecureMessage?> verify(ReliableMessage rMsg) async {
    ReliableMessageDelegate transceiver = delegate!;

    //
    //  0. Decode 'message.data' to encrypted content data
    //
    Uint8List ciphertext = await rMsg.data;
    if (ciphertext.isEmpty) {
      assert(false, 'failed to decode message data: '
          '${rMsg.sender} => ${rMsg.receiver}, ${rMsg.group}');
      return null;
    }

    //
    //  1. Decode 'message.signature' from String (Base64)
    //
    Uint8List signature = await rMsg.signature;
    if (signature.isEmpty) {
      assert(false, 'failed to decode message signature: '
          '${rMsg.sender} => ${rMsg.receiver}, ${rMsg.group}');
      return null;
    }

    //
    //  2. Verify the message data and signature with sender's public key
    //
    bool ok = await transceiver.verifyDataSignature(ciphertext, signature, rMsg);
    if (!ok) {
      assert(false, 'message signature not match: '
          '${rMsg.sender} => ${rMsg.receiver}, ${rMsg.group}');
      return null;
    }

    // OK, pack message
    Map info = rMsg.copyMap(false);
    info.remove('signature');
    return SecureMessage.parse(info);
  }

}
