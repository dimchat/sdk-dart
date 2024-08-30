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

import '../core/proc.dart';
import '../core/twins.dart';
import '../facebook.dart';
import '../messenger.dart';


///  Content Processing Unit
///  ~~~~~~~~~~~~~~~~~~~~~~~
class BaseContentProcessor extends TwinsHelper implements ContentProcessor {
  BaseContentProcessor(Facebook facebook, Messenger messenger)
      : super(facebook, messenger);

  @override
  Facebook? get facebook => super.facebook as Facebook?;

  @override
  Messenger? get messenger => super.messenger as Messenger?;

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
