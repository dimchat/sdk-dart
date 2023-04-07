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
import 'dart:mirrors';

import 'package:dimp/dimp.dart';

class ContentFactoryBuilder implements ContentFactory {
  ContentFactoryBuilder(this._class);

  final Type _class;

  @override
  Content? parseContent(Map content) {
    ClassMirror mirror = reflectClass(_class);
    return mirror.newInstance(Symbol.empty, [content]) as Content;
  }

}

class CommandFactoryBuilder implements CommandFactory {
  CommandFactoryBuilder(this._class);

  final Type _class;

  @override
  Command? parseCommand(Map content) {
    ClassMirror mirror = reflectClass(_class);
    return mirror.newInstance(Symbol.empty, [content]) as Command;
  }

}


///  General Command Factory
///  ~~~~~~~~~~~~~~~~~~~~~~~
class GeneralCommandFactory implements ContentFactory, CommandFactory {

  @override
  Command? parseCommand(Map content) {
    CommandFactoryManager man = CommandFactoryManager();
    String cmd = man.generalFactory.getCmd(content);
    // get factory by command name
    CommandFactory? factory = man.generalFactory.getCommandFactory(cmd);
    if (factory == null) {
      // check for group command
      if (content.containsKey('group')) {
        factory = man.generalFactory.getCommandFactory('group');
      }
      factory ??= this;
    }
    return factory.parseCommand(content);
  }

  @override
  Content? parseContent(Map content) {
    return BaseCommand(content);
  }

}


class HistoryCommandFactory extends GeneralCommandFactory {

  @override
  Content? parseContent(Map content) {
    return BaseHistoryCommand(content);
  }

}


class GroupCommandFactory extends HistoryCommandFactory {

  @override
  Command? parseCommand(Map content) {
    CommandFactoryManager man = CommandFactoryManager();
    String cmd = man.generalFactory.getCmd(content);
    // get factory by command name
    CommandFactory? factory = man.generalFactory.getCommandFactory(cmd);
    factory ??= this;
    return factory.parseCommand(content);
  }

  @override
  Content? parseContent(Map content) {
    return BaseGroupCommand(content);
  }

}


///  Register core message factories
void registerMessageFactories() {

  MessageFactory factory = MessageFactory();

  // Envelope factory
  Envelope.setFactory(factory);

  // Message factories
  InstantMessage.setFactory(factory);
  SecureMessage.setFactory(factory);
  ReliableMessage.setFactory(factory);

}

///  Register core content factories
void registerContentFactories() {

  // Text
  Content.setFactory(ContentType.kText, ContentFactoryBuilder(BaseTextContent));

  // File
  Content.setFactory(ContentType.kFile, ContentFactoryBuilder(BaseFileContent));
  // Image
  Content.setFactory(ContentType.kImage, ContentFactoryBuilder(ImageFileContent));
  // Audio
  Content.setFactory(ContentType.kAudio, ContentFactoryBuilder(AudioFileContent));
  // Video
  Content.setFactory(ContentType.kVideo, ContentFactoryBuilder(VideoFileContent));

  // Web Page
  Content.setFactory(ContentType.kPage, ContentFactoryBuilder(WebPageContent));

  // Money
  Content.setFactory(ContentType.kMoney, ContentFactoryBuilder(BaseMoneyContent));
  Content.setFactory(ContentType.kTransfer, ContentFactoryBuilder(TransferMoneyContent));
  // ...

  // Command
  Content.setFactory(ContentType.kCommand, GeneralCommandFactory());

  // History Command
  Content.setFactory(ContentType.kHistory, HistoryCommandFactory());

  // Content Array
  Content.setFactory(ContentType.kArray, ContentFactoryBuilder(ListContent));

  /*
  // Application Customized
  Content.setFactory(ContentType.kCustomized, ContentFactoryBuilder(AppCustomizedContent));
  Content.setFactory(ContentType.kApplication, ContentFactoryBuilder(AppCustomizedContent));
   */

  // Top-Secret
  Content.setFactory(ContentType.kForward, ContentFactoryBuilder(SecretContent));

  // unknown content type
  Content.setFactory(0, ContentFactoryBuilder(BaseContent));

}

///  Register core command factories
void registerCommandFactories() {

  // Meta Command
  Command.setFactory(Command.kMeta, CommandFactoryBuilder(BaseMetaCommand));

  // Document Command
  Command.setFactory(Command.kDocument, CommandFactoryBuilder(BaseDocumentCommand));

  // Group Commands
  Command.setFactory('group', GroupCommandFactory());
  Command.setFactory(GroupCommand.kInvite, CommandFactoryBuilder(InviteGroupCommand));
  Command.setFactory(GroupCommand.kExpel,  CommandFactoryBuilder(ExpelGroupCommand));
  Command.setFactory(GroupCommand.kJoin,   CommandFactoryBuilder(JoinGroupCommand));
  Command.setFactory(GroupCommand.kQuit,   CommandFactoryBuilder(QuitGroupCommand));
  Command.setFactory(GroupCommand.kQuery,  CommandFactoryBuilder(QueryGroupCommand));
  Command.setFactory(GroupCommand.kReset,  CommandFactoryBuilder(ResetGroupCommand));

}


///  Register All Message/Content/Command Factories
void registerAllFactories() {
  //
  //  Register core factories
  //
  registerMessageFactories();
  registerContentFactories();
  registerCommandFactories();

  //
  //  Register customized factories
  //
  Content.setFactory(ContentType.kCustomized, ContentFactoryBuilder(AppCustomizedContent));
  Content.setFactory(ContentType.kApplication, ContentFactoryBuilder(AppCustomizedContent));
}
