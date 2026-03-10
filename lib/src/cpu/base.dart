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
import 'package:dimp/dimp.dart';

import '../dkd/proc.dart';
import '../twins.dart';


// -----------------------------------------------------------------------------
//  BaseContentProcessor (Default CPU Implementation)
// -----------------------------------------------------------------------------

/// Base implementation of [ContentProcessor] with common response utilities.
///
/// Provides default handling for unsupported content types (returns "not supported" receipt)
/// and utility methods for creating receipt responses. Serves as the parent class
/// for all concrete content processors.
///
/// Extends [TwinsHelper] to access Facebook (entity management) and Messenger services.
class BaseContentProcessor extends TwinsHelper implements ContentProcessor {

  /// Creates a [BaseContentProcessor] with required twin dependencies.
  ///
  /// Parameters:
  /// - [facebook]  : Entity management service (user/group operations)
  /// - [messenger] : Messaging service (packing/processing)
  BaseContentProcessor(super.facebook, super.messenger);

  @override
  Future<List<Content>> processContent(Content content, ReliableMessage rMsg) async {
    String text = 'Content not support.';
    return respondReceipt(text, content: content, envelope: rMsg.envelope, extra: {
      'template': 'Content (type: \${type}) not support yet!',
      'replacements': {
        'type': content.type,
      },
    });
  }

  // -------------------------------------------------------------------------
  //  Response Utility Methods
  // -------------------------------------------------------------------------

  /// Creates a list containing a single receipt command response.
  ///
  /// Convenience method for consistent response formatting across processors.
  ///
  /// Parameters:
  /// - [text]     : Human-readable response text
  /// - [envelope] : Original message envelope (for sender/receiver context)
  /// - [content]  : Original message content (optional, for additional context)
  /// - [extra]    : Extra key-value data to include in the receipt (optional)
  ///
  /// Returns: List with one [ReceiptCommand] instance
  // protected
  List<ReceiptCommand> respondReceipt(String text, {
    required Envelope envelope, Content? content, Map<String, Object>? extra
  }) => [
    createReceipt(text, envelope: envelope, content: content, extra: extra)
  ];

  /// Creates a receipt command with standardized formatting.
  ///
  /// Includes original message context (envelope, serial number, group ID)
  /// and optional extra data. Static method for use without instantiation.
  ///
  /// Parameters:
  /// - [text]     : Human-readable response text
  /// - [envelope] : Original message envelope (provides sender/receiver/serial number)
  /// - [content]  : Original message content (optional, for group ID or other context)
  /// - [extra]    : Extra key-value data to add to the receipt (optional)
  ///
  /// Returns: Formatted [ReceiptCommand] instance
  static ReceiptCommand createReceipt(String text, {
    required Envelope envelope, Content? content, Map<String, Object>? extra
  }) {
    // create base receipt command with text, original envelope, serial number & group ID
    ReceiptCommand res = ReceiptCommand.create(text, envelope, content);
    // add extra key-values
    if (extra != null) {
      res.addAll(extra);
    }
    return res;
  }

}


// -----------------------------------------------------------------------------
//  BaseCommandProcessor (Default Command CPU)
// -----------------------------------------------------------------------------

/// Base implementation of [ContentProcessor] for command content.
///
/// Specializes [BaseContentProcessor] for command handling, providing default
/// "command not supported" responses for unsupported commands.
class BaseCommandProcessor extends BaseContentProcessor {

  /// Creates a [BaseCommandProcessor] with required twin dependencies.
  ///
  /// Parameters:
  /// - [facebook]  : Entity management service (user/group operations)
  /// - [messenger] : Messaging service (packing/processing)
  BaseCommandProcessor(super.facebook, super.messenger);

  @override
  Future<List<Content>> processContent(Content content, ReliableMessage rMsg) async {
    assert(content is Command, 'command error: $content');
    Command command = content as Command;
    String text = 'Command not support.';
    return respondReceipt(text, content: content, envelope: rMsg.envelope, extra: {
      'template': 'Command (name: \${command}) not support yet!',
      'replacements': {
        'command': command.cmd,
      },
    });
  }

}
