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
import 'package:dimp/crypto.dart';
import 'package:dimp/dkd.dart';
import 'package:dimp/plugins.dart';

///  Command GeneralFactory
///  ~~~~~~~~~~~~~~~~~~~~~~
class CommandGeneralFactory implements GeneralCommandHelper, CommandHelper {

  final Map<String, CommandFactory> _commandFactories = {};

  @override
  String? getCommandName(Map content, String? defaultValue) {
    var cmd = content['command'];
    return Converter.getString(cmd, defaultValue);
  }

  //
  //  Command
  //

  @override
  void setCommandFactory(String cmd, CommandFactory factory) {
    _commandFactories[cmd] = factory;
  }

  @override
  CommandFactory? getCommandFactory(String cmd) {
    return _commandFactories[cmd];
  }

  @override
  Command? parseCommand(Object? content) {
    if (content == null) {
      return null;
    } else if (content is Command) {
      return content;
    }
    Map? info = Wrapper.getMap(content);
    if (info == null) {
      assert(false, 'command content error: $content');
      return null;
    }
    // get factory by command name
    String cmd = getCommandName(info, '')!;
    assert(cmd.isNotEmpty, 'command name not found: $content');
    CommandFactory? factory = getCommandFactory(cmd);
    if (factory == null) {
      // unknown command name, get base command factory
      factory = _defaultFactory(info);
      assert(factory != null, 'cannot parse command: $content');
    }
    return factory?.parseCommand(info);
  }

  static CommandFactory? _defaultFactory(Map info) {
    var holder = SharedMessageHolder();
    int type = holder.helper!.getContentType(info, 0)!;
    ContentFactory? factory = holder.contentHelper!.getContentFactory(type);
    if (factory is CommandFactory) {
      return factory as CommandFactory;
    }
    assert(false, 'cannot parse command: $info');
    return null;
  }

}
