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
import 'dart:typed_data';

import 'package:dimp/dkd.dart';


// -----------------------------------------------------------------------------
//  Message Processor (Processing Pipeline)
// -----------------------------------------------------------------------------

/// Message processing interface (handles received messages and generates responses).
///
/// Processes messages through a layered pipeline:
/// Binary package → ReliableMessage → SecureMessage → InstantMessage → Content
///
/// Generates response messages by reversing the pipeline.
abstract interface class Processor {

  /// Processes a binary data package to generate response packages.
  ///
  /// [data] is the binary data package to process (received from network).
  ///
  /// Returns the list of binary response packages (empty if no response needed).
  Future<List<Uint8List>> processPackage(Uint8List data);

  /// Processes a reliable message to generate response reliable messages.
  ///
  /// [rMsg] is the reliable message to process (after deserialization).
  ///
  /// Returns the list of reliable response messages (empty if no response needed).
  Future<List<ReliableMessage>> processReliableMessage(ReliableMessage rMsg);

  /// Processes a secure message to generate response secure messages.
  ///
  /// [sMsg] is the secure message to process (after verification).
  /// [rMsg] is the original reliable message (for context).
  ///
  /// Returns the list of secure response messages (empty if no response needed).
  Future<List<SecureMessage>> processSecureMessage(SecureMessage sMsg, ReliableMessage rMsg);

  /// Processes a plain instant message to generate response instant messages.
  ///
  /// [iMsg] is the instant message to process (after decryption).
  /// [rMsg] is the original reliable message (for context).
  ///
  /// Returns the list of instant response messages (empty if no response needed).
  Future<List<InstantMessage>> processInstantMessage(InstantMessage iMsg, ReliableMessage rMsg);

  /// Processes message content to generate response content items.
  ///
  /// [content] is the message content to process (extracted from instant message).
  /// [rMsg] is the original reliable message (for context).
  ///
  /// Returns the list of response content items (empty if no response needed).
  Future<List<Content>> processContent(Content content, ReliableMessage rMsg);
}
