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

import '../core/twins.dart';

///  CPU: Content Processing Unit
///  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
abstract class ContentProcessor {

  ///  Process message content
  ///
  /// @param content - content received
  /// @param rMsg    - reliable message
  /// @return {Content} response to sender
  Future<List<Content>> process(Content content, ReliableMessage rMsg);

}

///  CPU Creator
///  ~~~~~~~~~~~
abstract class ContentProcessorCreator {

  ///  Create content processor with type
  ///
  /// @param msgType - content type
  /// @return ContentProcessor
  ContentProcessor? createContentProcessor(int msgType);

  ///  Create command processor with name
  ///
  /// @param msgType - content type
  /// @param cmd     - command name
  /// @return CommandProcessor
  ContentProcessor? createCommandProcessor(int msgType, String cmd);

}

///  CPU Factory
///  ~~~~~~~~~~~
abstract class ContentProcessorFactory {

  ///  Get content/command processor
  ///
  /// @param content - Content/Command
  /// @return ContentProcessor
  ContentProcessor? getProcessor(Content content);

  ContentProcessor? getContentProcessor(int msgType);

  ContentProcessor? getCommandProcessor(int msgType, String cmd);

}

//
//  Implementations
//

///  Content Processing Unit
///  ~~~~~~~~~~~~~~~~~~~~~~~
class BaseContentProcessor extends TwinsHelper implements ContentProcessor {
  BaseContentProcessor(super.facebook, super.messenger);

  @override
  Future<List<Content>> process(Content content, ReliableMessage rMsg) async {
    String text = 'Content not support.';
    return respondReceipt(text, content: content, envelope: rMsg.envelope, extra: {
      'template': 'Content (type: \${type}) not support yet!',
      'replacements': {
        'type': content.type,
      },
    });
  }

}

///  Command Processing Unit
///  ~~~~~~~~~~~~~~~~~~~~~~~
class BaseCommandProcessor extends BaseContentProcessor {
  BaseCommandProcessor(super.facebook, super.messenger);

  @override
  Future<List<Content>> process(Content content, ReliableMessage rMsg) async {
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
