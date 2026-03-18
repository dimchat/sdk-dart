/* license: https://mit-license.org
 *
 *  DIMP : Decentralized Instant Messaging Protocol
 *
 *                                Written in 2026 by Moky <albert.moky@gmail.com>
 *
 * ==============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2026 Albert Moky
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
import 'package:dimp/ext.dart';

import 'instant_delegate.dart';
import 'secure_delegate.dart';
import 'reliable_delegate.dart';

import 'instant_packer.dart';
import 'secure_packer.dart';
import 'reliable_packer.dart';


/// create message packers (can be overridden by subclasses)
class MessagePackerFactory {

  InstantMessagePacker createInstantMessagePacker(InstantMessageDelegate delegate) =>
      InstantMessagePacker(delegate);

  SecureMessagePacker createSecureMessagePacker(SecureMessageDelegate delegate) =>
      SecureMessagePacker(delegate);

  ReliableMessagePacker createReliableMessagePacker(ReliableMessageDelegate delegate) =>
      ReliableMessagePacker(delegate);

}


/// MessagePacker Extensions
/// ~~~~~~~~~~~~~~~~~~~~~~~~

MessagePackerFactory _packerFactory = MessagePackerFactory();

extension MessagePackerExtension on MessageExtensions {

  MessagePackerFactory get packerFactory => _packerFactory;
  set packerFactory(MessagePackerFactory factory) => _packerFactory = factory;

}
