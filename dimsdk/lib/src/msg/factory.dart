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
import 'dart:math';

import 'package:dimp/dimp.dart';

class MessageFactory implements EnvelopeFactory, InstantMessageFactory, SecureMessageFactory, ReliableMessageFactory {
  MessageFactory() {
    Random random = Random(DateTime.now().microsecondsSinceEpoch);
    _sn = random.nextInt(0x80000000);  // 0 ~ 0x7fffffff
  }

  int _sn = 0;

  ///  next sn
  ///
  /// @return 1 ~ 2^31-1
  /* synchronized */int _next() {
    assert(_sn >= 0, 'serial number error: $_sn');
    if (_sn < 0x7fffffff) {  // 2 ** 31 - 1
      _sn += 1;
    } else {
      _sn = 1;
    }
    return _sn;
  }

  ///
  /// EnvelopeFactory
  ///

  @override
  Envelope createEnvelope({required ID sender, required ID receiver, DateTime? time}) {
    return MessageEnvelope.from(sender: sender, receiver: receiver, time: time);
  }

  @override
  Envelope? parseEnvelope(Map env) {
    // check 'sender'
    if (env['sender'] == null) {
      // env.sender should not empty
      assert(false, 'envelope error: $env');
      return null;
    }
    return MessageEnvelope(env);
  }

  ///
  /// InstantMessageFactory
  ///

  @override
  int generateSerialNumber(String? msgType, DateTime? now) {
    // because we must make sure all messages in a same chat box won't have
    // same serial numbers, so we can't use time-related numbers, therefore
    // the best choice is a totally random number, maybe.
    return _next();
  }

  @override
  InstantMessage createInstantMessage(Envelope head, Content body) {
    return PlainMessage.from(head, body);
  }

  @override
  InstantMessage? parseInstantMessage(Map msg) {
    // check 'sender', 'content'
    if (msg['sender'] == null || msg['content'] == null) {
      // msg.sender should not be empty
      // msg.content should not be empty
      assert(false, 'message error: $msg');
      return null;
    }
    return PlainMessage(msg);
  }

  ///
  /// SecureMessageFactory
  ///

  @override
  SecureMessage? parseSecureMessage(Map msg) {
    // check 'sender', 'data'
    if (msg['sender'] == null || msg['data'] == null) {
      // msg.sender should not be empty
      // msg.data should not be empty
      assert(false, 'message error: $msg');
      return null;
    }
    // check 'signature'
    if (msg['signature'] != null) {
      return NetworkMessage(msg);
    }
    return EncryptedMessage(msg);
  }

  ///
  /// ReliableMessageFactory
  ///

  @override
  ReliableMessage? parseReliableMessage(Map msg) {
    // check 'sender', 'data', 'signature',
    if (msg['sender'] == null || msg['data'] == null || msg['signature'] == null) {
      // msg.sender should not be empty
      // msg.data should not be empty
      // msg.signature should not be empty
      assert(false, 'message error: $msg');
      return null;
    }
    return NetworkMessage(msg);
  }
}
