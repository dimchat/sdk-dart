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
import 'commands.dart';
import 'content.dart';
import 'contents.dart';


/// Base ContentProcessor Creator
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class BaseContentProcessorCreator extends TwinsHelper implements ContentProcessorCreator {
  BaseContentProcessorCreator(super.facebook, super.messenger);

  @override
  ContentProcessor? createContentProcessor(int msgType) {
    switch (msgType) {
      // forward content
      case ContentType.kForward:
        return ForwardContentProcessor(facebook!, messenger!);
      // array content
      case ContentType.kArray:
        return ArrayContentProcessor(facebook!, messenger!);

        /*
      // application customized
      case ContentType.kApplication:
      case ContentType.kCustomized:
        return CustomizedContentProcessor(facebook!, messenger!);
         */

      // default commands
      case ContentType.kCommand:
        return BaseCommandProcessor(facebook!, messenger!);
        /*
      // default contents
      case 0:
        return BaseContentProcessor(facebook!, messenger!);
         */

      // unknown
      default:
        return null;
    }
  }

  @override
  ContentProcessor? createCommandProcessor(int msgType, String cmd) {
    switch (cmd) {
      // meta command
      case Command.kMeta:
        return MetaCommandProcessor(facebook!, messenger!);
      // document command
      case Command.kDocument:
        return DocumentCommandProcessor(facebook!, messenger!);

      // unknown
      default:
        return null;
    }
  }

}


/// Base ContentProcessor Factory
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class BaseContentProcessorFactory extends TwinsHelper implements ContentProcessorFactory {
  BaseContentProcessorFactory(super.facebook, super.messenger, this._creator);

  final ContentProcessorCreator _creator;

  final Map<int,    ContentProcessor> _contentProcessors = {};
  final Map<String, ContentProcessor> _commandProcessors = {};

  @override
  ContentProcessor? getProcessor(Content content) {
    ContentProcessor? cpu;
    int msgType = content.type;
    if (content is Command) {
      String name = content.cmd;
      // assert(name.isNotEmpty, 'command name error: $name');
      cpu = getCommandProcessor(msgType, name);
      if (cpu != null) {
        return cpu;
      } else if (content is GroupCommand/* || content.containsKey('group')*/) {
        // assert(name != 'group', 'command name error: $content');
        cpu = getCommandProcessor(msgType, 'group');
        if (cpu != null) {
          return cpu;
        }
      }
    }
    // content processor
    return getContentProcessor(msgType);
  }

  @override
  ContentProcessor? getContentProcessor(int msgType) {
    ContentProcessor? cpu = _contentProcessors[msgType];
    if (cpu == null) {
      cpu = _creator.createContentProcessor(msgType);
      if (cpu != null) {
        _contentProcessors[msgType] = cpu;
      }
    }
    return cpu;
  }

  @override
  ContentProcessor? getCommandProcessor(int msgType, String cmd) {
    ContentProcessor? cpu = _commandProcessors[cmd];
    if (cpu == null) {
      cpu = _creator.createCommandProcessor(msgType, cmd);
      if (cpu != null) {
        _commandProcessors[cmd] = cpu;
      }
    }
    return cpu;
  }

}
