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
    setContentFactory(ContentType.TEXT, 'text', creator: (dict) => BaseTextContent(dict));

    // File
    setContentFactory(ContentType.FILE, 'file', creator: (dict) => BaseFileContent(dict));
    // Image
    setContentFactory(ContentType.IMAGE, 'image', creator: (dict) => ImageFileContent(dict));
    // Audio
    setContentFactory(ContentType.AUDIO, 'audio', creator: (dict) => AudioFileContent(dict));
    // Video
    setContentFactory(ContentType.VIDEO, 'video', creator: (dict) => VideoFileContent(dict));

    // Web Page
    setContentFactory(ContentType.PAGE, 'page', creator: (dict) => WebPageContent(dict));

    // Name Card
    setContentFactory(ContentType.NAME_CARD, 'card', creator: (dict) => NameCardContent(dict));

    // Quote
    setContentFactory(ContentType.QUOTE, 'quote', creator: (dict) => BaseQuoteContent(dict));

    // Money
    setContentFactory(ContentType.MONEY, 'money', creator: (dict) => BaseMoneyContent(dict));
    setContentFactory(ContentType.TRANSFER, 'transfer', creator: (dict) => TransferMoneyContent(dict));
    // ...

    // Command
    setContentFactory(ContentType.COMMAND, 'command', factory: GeneralCommandFactory());

    // History Command
    setContentFactory(ContentType.HISTORY, 'history', factory: HistoryCommandFactory());

    // Content Array
    setContentFactory(ContentType.ARRAY, 'array', creator: (dict) => ListContent(dict));

    // Combine and Forward
    setContentFactory(ContentType.COMBINE_FORWARD, 'combine', creator: (dict) => CombineForwardContent(dict));

    // Top-Secret
    setContentFactory(ContentType.FORWARD, 'forward', creator: (dict) => SecretContent(dict));

    // unknown content type
    setContentFactory(ContentType.ANY, '*', creator: (dict) => BaseContent(dict));

  }

  // protected
  void setContentFactory(String msgType, String alias, {ContentFactory? factory, ContentCreator? creator}) {
    if (factory != null) {
      Content.setFactory(msgType, factory);
      Content.setFactory(alias, factory);
    }
    if (creator != null) {
      Content.setFactory(msgType, ContentParser(creator));
      Content.setFactory(alias, ContentParser(creator));
    }
  }

  // protected
  void setCommandFactory(String cmd, {CommandFactory? factory, CommandCreator? creator}) {
    if (factory != null) {
      Command.setFactory(cmd, factory);
    }
    if (creator != null) {
      Command.setFactory(cmd, CommandParser(creator));
    }
  }

  ///  Core command factories
  // protected
  void registerCommandFactories() {

    // Meta Command
    setCommandFactory(Command.META, creator: (dict) => BaseMetaCommand(dict));

    // Document Command
    setCommandFactory(Command.DOCUMENTS, creator: (dict) => BaseDocumentCommand(dict));

    // Receipt Command
    setCommandFactory(Command.RECEIPT, creator: (dict) => BaseReceiptCommand(dict));

    // Group Commands
    setCommandFactory('group', factory: GroupCommandFactory());
    setCommandFactory(GroupCommand.INVITE, creator: (dict) => InviteGroupCommand(dict));
    /// 'expel' is deprecated (use 'reset' instead)
    setCommandFactory(GroupCommand.EXPEL,  creator: (dict) => ExpelGroupCommand(dict));
    setCommandFactory(GroupCommand.JOIN,   creator: (dict) => JoinGroupCommand(dict));
    setCommandFactory(GroupCommand.QUIT,   creator: (dict) => QuitGroupCommand(dict));
    setCommandFactory(GroupCommand.QUERY,  creator: (dict) => QueryGroupCommand(dict));
    setCommandFactory(GroupCommand.RESET,  creator: (dict) => ResetGroupCommand(dict));
    // Group Admin Commands
    setCommandFactory(GroupCommand.HIRE,   creator: (dict) => HireGroupCommand(dict));
    setCommandFactory(GroupCommand.FIRE,   creator: (dict) => FireGroupCommand(dict));
    setCommandFactory(GroupCommand.RESIGN, creator: (dict) => ResignGroupCommand(dict));

  }

}


typedef ContentCreator = Content? Function(Map<String, dynamic> dict);
typedef CommandCreator = Command? Function(Map<String, dynamic> dict);

class ContentParser implements ContentFactory {
  ContentParser(this._builder);
  final ContentCreator _builder;

  @override
  Content? parseContent(Map content) {
    if (content is Map<String, dynamic>) {} else {
      assert(false, 'content error: $content');
      return null;
    }
    return _builder(content);
  }

}

class CommandParser implements CommandFactory {
  CommandParser(this._builder);
  final CommandCreator _builder;

  @override
  Command? parseCommand(Map content) {
    if (content is Map<String, dynamic>) {} else {
      assert(false, 'command error: $content');
      return null;
    }
    return _builder(content);
  }

}
