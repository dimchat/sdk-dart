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


/// Factory for creating message packers.
///
/// Provides creation methods for the three message packers
/// (instant/secure/reliable), which can be overridden by subclasses.
class MessagePackerFactory {

  /// Creates an [InstantMessagePacker] for the given delegate.
  ///
  /// [delegate] is the instant message delegate (encryption pipeline).
  ///
  /// Returns a new [InstantMessagePacker] instance.
  InstantMessagePacker createInstantMessagePacker(InstantMessageDelegate delegate) =>
      InstantMessagePacker(delegate);

  /// Creates a [SecureMessagePacker] for the given delegate.
  ///
  /// [delegate] is the secure message delegate (decryption/signing pipeline).
  ///
  /// Returns a new [SecureMessagePacker] instance.
  SecureMessagePacker createSecureMessagePacker(SecureMessageDelegate delegate) =>
      SecureMessagePacker(delegate);

  /// Creates a [ReliableMessagePacker] for the given delegate.
  ///
  /// [delegate] is the reliable message delegate (verification pipeline).
  ///
  /// Returns a new [ReliableMessagePacker] instance.
  ReliableMessagePacker createReliableMessagePacker(ReliableMessageDelegate delegate) =>
      ReliableMessagePacker(delegate);

}


/// MessagePacker Extensions
///
/// Global [MessagePackerFactory] instance (shared singleton) for creating
/// message packers, accessible via [MessageExtensions].
MessagePackerFactory _packerFactory = MessagePackerFactory();

extension MessagePackerExtension on MessageExtensions {

  /// The shared [MessagePackerFactory] instance (getter).
  MessagePackerFactory get packerFactory => _packerFactory;

  /// Replaces the shared [MessagePackerFactory] instance (setter).
  set packerFactory(MessagePackerFactory factory) => _packerFactory = factory;

}
