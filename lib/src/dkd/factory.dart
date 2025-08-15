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
import 'package:dimp/dkd.dart';

import 'proc.dart';


/// General ContentProcessor Factory
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class GeneralContentProcessorFactory implements ContentProcessorFactory {
  GeneralContentProcessorFactory(this.creator);

  // private
  final ContentProcessorCreator creator;

  final Map<String, ContentProcessor> _contentProcessors = {};
  final Map<String, ContentProcessor> _commandProcessors = {};

  @override
  ContentProcessor? getContentProcessor(Content content) {
    ContentProcessor? cpu;
    String msgType = content.type;
    if (content is Command) {
      String cmd = content.cmd;
      // assert(name.isNotEmpty, 'command name error: $name');
      cpu = getCommandProcessor(msgType, cmd);
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
    return getContentProcessorForType(msgType);
  }

  @override
  ContentProcessor? getContentProcessorForType(String msgType) {
    ContentProcessor? cpu = _contentProcessors[msgType];
    if (cpu == null) {
      cpu = creator.createContentProcessor(msgType);
      if (cpu != null) {
        _contentProcessors[msgType] = cpu;
      }
    }
    return cpu;
  }

  // private
  ContentProcessor? getCommandProcessor(String msgType, String cmd) {
    ContentProcessor? cpu = _commandProcessors[cmd];
    if (cpu == null) {
      cpu = creator.createCommandProcessor(msgType, cmd);
      if (cpu != null) {
        _commandProcessors[cmd] = cpu;
      }
    }
    return cpu;
  }

}
