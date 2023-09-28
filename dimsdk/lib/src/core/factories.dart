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

import '../msg/factory.dart';

typedef ContentCreator = Content? Function(Map dict);
typedef CommandCreator = Command? Function(Map dict);

class ContentParser implements ContentFactory {
  ContentParser(this._builder);
  final ContentCreator _builder;

  @override
  Content? parseContent(Map content) {
    return _builder(content);
  }

}

class CommandParser implements CommandFactory {
  CommandParser(this._builder);
  final CommandCreator _builder;

  @override
  Command? parseCommand(Map content) {
    return _builder(content);
  }

}


///  General Command Factory
///  ~~~~~~~~~~~~~~~~~~~~~~~
class GeneralCommandFactory implements ContentFactory, CommandFactory {

  @override
  Content? parseContent(Map content) {
    // get factory by command name
    CommandFactoryManager man = CommandFactoryManager();
    String cmd = man.generalFactory.getCmd(content, '*')!;
    CommandFactory? factory = man.generalFactory.getCommandFactory(cmd);
    if (factory == null) {
      // check for group command
      if (content.containsKey('group')/* && cmd != 'group'*/) {
        factory = man.generalFactory.getCommandFactory('group');
      }
      factory ??= this;
    }
    return factory.parseCommand(content);
  }

  @override
  Command? parseCommand(Map content) {
    return BaseCommand(content);
  }

}


class HistoryCommandFactory extends GeneralCommandFactory {

  @override
  Command? parseCommand(Map content) {
    return BaseHistoryCommand(content);
  }

}


class GroupCommandFactory extends HistoryCommandFactory {

  @override
  Content? parseContent(Map content) {
    // get factory by command name
    CommandFactoryManager man = CommandFactoryManager();
    String cmd = man.generalFactory.getCmd(content, '*')!;
    CommandFactory? factory = man.generalFactory.getCommandFactory(cmd);
    factory ??= this;
    return factory.parseCommand(content);
  }

  @override
  Command? parseCommand(Map content) {
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
  Content.setFactory(ContentType.kText, ContentParser((dict) => BaseTextContent(dict)));

  // File
  Content.setFactory(ContentType.kFile, ContentParser((dict) => BaseFileContent(dict)));
  // Image
  Content.setFactory(ContentType.kImage, ContentParser((dict) => ImageFileContent(dict)));
  // Audio
  Content.setFactory(ContentType.kAudio, ContentParser((dict) => AudioFileContent(dict)));
  // Video
  Content.setFactory(ContentType.kVideo, ContentParser((dict) => VideoFileContent(dict)));

  // Web Page
  Content.setFactory(ContentType.kPage, ContentParser((dict) => WebPageContent(dict)));

  // Name Card
  // TODO: set factory for name card

  // Money
  Content.setFactory(ContentType.kMoney, ContentParser((dict) => BaseMoneyContent(dict)));
  Content.setFactory(ContentType.kTransfer, ContentParser((dict) => TransferMoneyContent(dict)));
  // ...

  // Command
  Content.setFactory(ContentType.kCommand, GeneralCommandFactory());

  // History Command
  Content.setFactory(ContentType.kHistory, HistoryCommandFactory());

  /*
  // Application Customized
  Content.setFactory(ContentType.kCustomized, ContentParser((dict) => AppCustomizedContent(dict)));
  Content.setFactory(ContentType.kApplication, ContentParser((dict) => AppCustomizedContent(dict)));
   */

  // Content Array
  Content.setFactory(ContentType.kArray, ContentParser((dict) => ListContent(dict)));

  // Top-Secret
  Content.setFactory(ContentType.kForward, ContentParser((dict) => SecretContent(dict)));

  // unknown content type
  Content.setFactory(0, ContentParser((dict) => BaseContent(dict)));

}

///  Register core command factories
void registerCommandFactories() {

  // Meta Command
  Command.setFactory(Command.kMeta, CommandParser((dict) => BaseMetaCommand(dict)));

  // Document Command
  Command.setFactory(Command.kDocument, CommandParser((dict) => BaseDocumentCommand(dict)));

  // Receipt Command
  Command.setFactory(Command.kReceipt, CommandParser((dict) => BaseReceiptCommand(dict)));

  // Group Commands
  Command.setFactory('group', GroupCommandFactory());
  Command.setFactory(GroupCommand.kInvite, CommandParser((dict) => InviteGroupCommand(dict)));
  /// 'expel' is deprecated (use 'reset' instead)
  Command.setFactory(GroupCommand.kExpel,  CommandParser((dict) => ExpelGroupCommand(dict)));
  Command.setFactory(GroupCommand.kJoin,   CommandParser((dict) => JoinGroupCommand(dict)));
  Command.setFactory(GroupCommand.kQuit,   CommandParser((dict) => QuitGroupCommand(dict)));
  Command.setFactory(GroupCommand.kQuery,  CommandParser((dict) => QueryGroupCommand(dict)));
  Command.setFactory(GroupCommand.kReset,  CommandParser((dict) => ResetGroupCommand(dict)));
  // Group Admin Commands
  Command.setFactory(GroupCommand.kHire,  CommandParser((dict) => HireGroupCommand(dict)));
  Command.setFactory(GroupCommand.kFire,  CommandParser((dict) => FireGroupCommand(dict)));
  Command.setFactory(GroupCommand.kResign,  CommandParser((dict) => ResignGroupCommand(dict)));

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
  Content.setFactory(ContentType.kCustomized, ContentParser((dict) => AppCustomizedContent(dict)));
  Content.setFactory(ContentType.kApplication, ContentParser((dict) => AppCustomizedContent(dict)));
}
