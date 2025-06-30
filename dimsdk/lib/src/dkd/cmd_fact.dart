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
import 'package:dimp/plugins.dart';


///  General Command Factory
///  ~~~~~~~~~~~~~~~~~~~~~~~
class GeneralCommandFactory implements ContentFactory, CommandFactory {

  @override
  Content? parseContent(Map content) {
    var ext = SharedCommandExtensions();
    // get factory by command name
    String cmd = ext.helper!.getCmd(content, null) ?? '';
    CommandFactory? factory = ext.cmdHelper!.getCommandFactory(cmd);
    if (factory == null) {
      // check for group command
      if (content.containsKey('group')/* && cmd != 'group'*/) {
        factory = ext.cmdHelper!.getCommandFactory('group');
      }
      factory ??= this;
    }
    return factory.parseCommand(content);
  }

  @override
  Command? parseCommand(Map content) {
    if (content is Map<String, dynamic>) {
      return BaseCommand(content);
    }
    assert(false, 'command error: $content');
    return null;
  }

}


class HistoryCommandFactory extends GeneralCommandFactory {

  @override
  Command? parseCommand(Map content) {
    if (content is Map<String, dynamic>) {
      return BaseHistoryCommand(content);
    }
    assert(false, 'history command error: $content');
    return null;
  }

}


class GroupCommandFactory extends HistoryCommandFactory {

  @override
  Content? parseContent(Map content) {
    var ext = SharedCommandExtensions();
    // get factory by command name
    String cmd = ext.helper!.getCmd(content, null) ?? '*';
    CommandFactory? factory = ext.cmdHelper!.getCommandFactory(cmd);
    factory ??= this;
    return factory.parseCommand(content);
  }

  @override
  Command? parseCommand(Map content) {
    if (content is Map<String, dynamic>) {
      return BaseGroupCommand(content);
    }
    assert(false, 'group command error: $content');
    return null;
  }

}
