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

import '../dkd/cmd_fact.dart';
import '../msg/factory.dart';

import 'account.dart';
import 'command.dart';
import 'crypto.dart';
import 'format.dart';
import 'message.dart';


/// Core Extensions Loader
/// ~~~~~~~~~~~~~~~~~~~~~~
class ExtensionLoader {

  bool _loaded = false;

  void run() {
    if (_loaded) {
      // no need to load it again
      return;
    } else {
      // mark it to loaded
      _loaded = true;
    }
    // try to load all extensions
    load();
  }

  /// Register core factories
  // protected
  void load() {

    registerCoreHelpers();

    registerMessageFactories();

    registerContentFactories();
    registerCommandFactories();

  }

  ///  Core extensions
  // protected
  void registerCoreHelpers() {

    registerCryptoHelpers();
    registerFormatHelpers();

    registerAccountHelpers();

    registerMessageHelpers();
    registerCommandHelpers();

  }
  void registerCryptoHelpers() {
    // crypto
    var cryptoHelper = CryptoKeyGeneralFactory();
    var ext = SharedCryptoExtensions();
    ext.symmetricHelper = cryptoHelper;
    ext.privateHelper   = cryptoHelper;
    ext.publicHelper    = cryptoHelper;
    ext.helper          = cryptoHelper;
  }
  void registerFormatHelpers() {
    // format
    var formatHelper = FormatGeneralFactory();
    var ext = SharedFormatExtensions();
    ext.pnfHelper = formatHelper;
    ext.tedHelper = formatHelper;
    ext.helper    = formatHelper;
  }
  void registerAccountHelpers() {
    // mkm
    var accountHelper = AccountGeneralFactory();
    var ext = SharedAccountExtensions();
    ext.addressHelper = accountHelper;
    ext.idHelper      = accountHelper;
    ext.metaHelper    = accountHelper;
    ext.docHelper     = accountHelper;
    ext.helper        = accountHelper;
  }
  void registerMessageHelpers() {
    // dkd
    var msgHelper = MessageGeneralFactory();
    var ext = SharedMessageExtensions();
    ext.contentHelper  = msgHelper;
    ext.envelopeHelper = msgHelper;
    ext.instantHelper  = msgHelper;
    ext.secureHelper   = msgHelper;
    ext.reliableHelper = msgHelper;
    ext.helper         = msgHelper;
  }
  void registerCommandHelpers() {
    // cmd
    var cmdHelper = CommandGeneralFactory();
    var ext = SharedCommandExtensions();
    ext.cmdHelper = cmdHelper;
    ext.helper    = cmdHelper;
  }

  ///  Message factories
  // protected
  void registerMessageFactories() {

    // Envelope factory
    MessageFactory factory = MessageFactory();
    Envelope.setFactory(factory);

    // Message factories
    InstantMessage.setFactory(factory);
    SecureMessage.setFactory(factory);
    ReliableMessage.setFactory(factory);

  }

  ///  Core content factories
  // protected
  void registerContentFactories() {

    // Text
    Content.setFactory(ContentType.TEXT, ContentParser((dict) => BaseTextContent(dict)));

    // File
    Content.setFactory(ContentType.FILE, ContentParser((dict) => BaseFileContent(dict)));
    // Image
    Content.setFactory(ContentType.IMAGE, ContentParser((dict) => ImageFileContent(dict)));
    // Audio
    Content.setFactory(ContentType.AUDIO, ContentParser((dict) => AudioFileContent(dict)));
    // Video
    Content.setFactory(ContentType.VIDEO, ContentParser((dict) => VideoFileContent(dict)));

    // Web Page
    Content.setFactory(ContentType.PAGE, ContentParser((dict) => WebPageContent(dict)));

    // Name Card
    Content.setFactory(ContentType.NAME_CARD, ContentParser((dict) => NameCardContent(dict)));

    // Quote
    Content.setFactory(ContentType.QUOTE, ContentParser((dict) => BaseQuoteContent(dict)));

    // Money
    Content.setFactory(ContentType.MONEY, ContentParser((dict) => BaseMoneyContent(dict)));
    Content.setFactory(ContentType.TRANSFER, ContentParser((dict) => TransferMoneyContent(dict)));
    // ...

    // Command
    Content.setFactory(ContentType.COMMAND, GeneralCommandFactory());

    // History Command
    Content.setFactory(ContentType.HISTORY, HistoryCommandFactory());

    // Content Array
    Content.setFactory(ContentType.ARRAY, ContentParser((dict) => ListContent(dict)));

    // Combine and Forward
    Content.setFactory(ContentType.COMBINE_FORWARD, ContentParser((dict) => CombineForwardContent(dict)));

    // Top-Secret
    Content.setFactory(ContentType.FORWARD, ContentParser((dict) => SecretContent(dict)));

    // unknown content type
    Content.setFactory(ContentType.ANY, ContentParser((dict) => BaseContent(dict)));

  }

  ///  Core command factories
  // protected
  void registerCommandFactories() {

    // Meta Command
    Command.setFactory(Command.META, CommandParser((dict) => BaseMetaCommand(dict)));

    // Document Command
    Command.setFactory(Command.DOCUMENT, CommandParser((dict) => BaseDocumentCommand(dict)));

    // Receipt Command
    Command.setFactory(Command.RECEIPT, CommandParser((dict) => BaseReceiptCommand(dict)));

    // Group Commands
    Command.setFactory('group', GroupCommandFactory());
    Command.setFactory(GroupCommand.INVITE, CommandParser((dict) => InviteGroupCommand(dict)));
    /// 'expel' is deprecated (use 'reset' instead)
    Command.setFactory(GroupCommand.EXPEL,  CommandParser((dict) => ExpelGroupCommand(dict)));
    Command.setFactory(GroupCommand.JOIN,   CommandParser((dict) => JoinGroupCommand(dict)));
    Command.setFactory(GroupCommand.QUIT,   CommandParser((dict) => QuitGroupCommand(dict)));
    Command.setFactory(GroupCommand.QUERY,  CommandParser((dict) => QueryGroupCommand(dict)));
    Command.setFactory(GroupCommand.RESET,  CommandParser((dict) => ResetGroupCommand(dict)));
    // Group Admin Commands
    Command.setFactory(GroupCommand.HIRE,   CommandParser((dict) => HireGroupCommand(dict)));
    Command.setFactory(GroupCommand.FIRE,   CommandParser((dict) => FireGroupCommand(dict)));
    Command.setFactory(GroupCommand.RESIGN, CommandParser((dict) => ResignGroupCommand(dict)));

  }

}


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
