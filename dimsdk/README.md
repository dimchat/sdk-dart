# Decentralized Instant Messaging (Dart SDK)

[![License](https://img.shields.io/github/license/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/blob/master/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/dimchat/sdk-dart/pulls)
[![Platform](https://img.shields.io/badge/Platform-Dart%203-brightgreen.svg)](https://github.com/dimchat/sdk-dart/wiki)
[![Issues](https://img.shields.io/github/issues/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/issues)
[![Repo Size](https://img.shields.io/github/repo-size/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/archive/refs/heads/main.zip)
[![Tags](https://img.shields.io/github/tag/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/tags)
[![Version](https://img.shields.io/pub/v/dimsdk)](https://pub.dev/packages/dimsdk)

[![Watchers](https://img.shields.io/github/watchers/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/watchers)
[![Forks](https://img.shields.io/github/forks/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/forks)
[![Stars](https://img.shields.io/github/stars/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/stargazers)
[![Followers](https://img.shields.io/github/followers/dimchat)](https://github.com/orgs/dimchat/followers)

## Dependencies

* Latest Versions

| Name | Version | Description |
|------|---------|-------------|
| [Ming Ke Ming (名可名)](https://github.com/dimchat/mkm-dart) | [![Version](https://img.shields.io/pub/v/mkm)](https://pub.dev/packages/mkm) | Decentralized User Identity Authentication |
| [Dao Ke Dao (道可道)](https://github.com/dimchat/dkd-dart) | [![Version](https://img.shields.io/pub/v/dkd)](https://pub.dev/packages/dkd) | Universal Message Module |
| [DIMP (去中心化通讯协议)](https://github.com/dimchat/core-dart) | [![Version](https://img.shields.io/pub/v/dimp)](https://pub.dev/packages/dimp) | Decentralized Instant Messaging Protocol |

## Extensions

### Content

extends [CustomizedContent](https://github.com/dimchat/core-dart#extends-content)

### ContentProcessor

```dart
import 'package:dimsdk/dimsdk.dart';

import '../../common/protocol/groups.dart';


/*  Command Transform:

    +===============================+===============================+
    |      Customized Content       |      Group Query Command      |
    +-------------------------------+-------------------------------+
    |   "type" : i2s(0xCC)          |   "type" : i2s(0x88)          |
    |   "sn"   : 123                |   "sn"   : 123                |
    |   "time" : 123.456            |   "time" : 123.456            |
    |   "app"  : "chat.dim.group"   |                               |
    |   "mod"  : "history"          |                               |
    |   "act"  : "query"            |                               |
    |                               |   "command"   : "query"       |
    |   "group"     : "{GROUP_ID}"  |   "group"     : "{GROUP_ID}"  |
    |   "last_time" : 0             |   "last_time" : 0             |
    +===============================+===============================+
 */
class GroupHistoryHandler extends BaseCustomizedHandler {
  GroupHistoryHandler(super.facebook, super.messenger);

  bool matches(String app, String mod) => app == GroupHistory.APP && mod == GroupHistory.MOD;

  @override
  Future<List<Content>> handleAction(String act, ID sender, CustomizedContent content, ReliableMessage rMsg) async {
    var transceiver = messenger;
    if (transceiver == null) {
      assert(false, 'messenger lost');
      return [];
    } else if (act == GroupHistory.ACT_QUERY) {
      assert(GroupHistory.APP == content.application);
      assert(GroupHistory.MOD == content.module);
      assert(content.group != null, 'group command error: $content, sender: $sender');
    } else {
      assert(false, 'unknown action: $act, $content, sender: $sender');
      return await super.handleAction(act, sender, content, rMsg);
    }
    Map info = content.copyMap(false);
    info['type'] = ContentType.COMMAND;
    info['command'] = GroupCommand.QUERY;
    Content? query = Content.parse(info);
    if (query is QueryCommand) {
      return await transceiver.processContent(query, rMsg);
    }
    assert(false, 'query command error: $query, $content, sender: $sender');
    String text = 'Query command error.';
    return respondReceipt(text, envelope: rMsg.envelope, content: content);
  }

}


///  Customized Content Processing Unit
///  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class AppCustomizedProcessor extends CustomizedContentProcessor {
  AppCustomizedProcessor(Facebook facebook, Messenger messenger) : super(facebook, messenger) {
    groupHistoryHandler = createGroupHistoryHandler(facebook, messenger);
  }

  // protected
  GroupHistoryHandler createGroupHistoryHandler(Facebook facebook, Messenger messenger) =>
      GroupHistoryHandler(facebook, messenger);

  // protected
  late final GroupHistoryHandler groupHistoryHandler;

  /// override for your modules
  @override
  CustomizedContentHandler filter(String app, String mod, CustomizedContent content, ReliableMessage rMsg) {
    if (content.group != null) {
      if (groupHistoryHandler.matches(app, mod)) {
        return groupHistoryHandler;
      }
    }
    return super.filter(app, mod, content, rMsg);
  }

}
```

### ContentProcessorCreator

```dart
import 'package:dimsdk/dimsdk.dart';

import 'customized.dart';
import 'handshake.dart';


class ClientContentProcessorCreator extends BaseContentProcessorCreator {
  ClientContentProcessorCreator(super.facebook, super.messenger);

  @override
  ContentProcessor? createContentProcessor(String msgType) {
    switch (msgType) {

      // application customized
      case ContentType.APPLICATION:
      case ContentType.CUSTOMIZED:
      case 'application':
      case 'customized':
        return AppCustomizedProcessor(facebook!, messenger!);

    }
    // others
    return super.createContentProcessor(msgType);
  }

  @override
  ContentProcessor? createCommandProcessor(String msgType, String cmd) {
    switch (cmd) {
      case HandshakeCommand.HANDSHAKE:
        return HandshakeCommandProcessor(facebook!, messenger!);
      // ...
    }
    // others
    return super.createCommandProcessor(msgType, cmd);
  }

}
```

### ExtensionLoader

```dart
import 'package:dimsdk/plugins.dart';

import '../../common/protocol/handshake.dart';


/// Extensions Loader
/// ~~~~~~~~~~~~~~~~~
class CommonExtensionLoader extends ExtensionLoader {

  @override
  void registerCustomizedFactories() {
    
    // Application Customized
    setContentFactory(ContentType.CUSTOMIZED, 'customized', creator: (dict) => AppCustomizedContent(dict));
    setContentFactory(ContentType.APPLICATION, 'application', creator: (dict) => AppCustomizedContent(dict));
    
  }

  @override
  void registerCommandFactories() {
    super.registerCommandFactories();

    // Handshake
    setCommandFactory(HandshakeCommand.HANDSHAKE, creator: (dict) => BaseHandshakeCommand(dict));

  }

}
```

## Usages

You must load all extensions before your business run:

```dart
import 'package:dim_plugins/plugins.dart';

import 'common_loader.dart';


class LibraryLoader {
  LibraryLoader({ExtensionLoader? extensionLoader, PluginLoader? pluginLoader}) {
    this.extensionLoader = extensionLoader ?? CommonExtensionLoader();
    this.pluginLoader = pluginLoader ?? PluginLoader();
  }

  late final ExtensionLoader extensionLoader;
  late final PluginLoader pluginLoader;

  void run() {
    extensionLoader.run();
    pluginLoader.run();
  }

}

void main() {

  var loader = LibraryLoader();
  loader.run();
  
  // do your jobs after all extensions loaded.
  
}

```

Also, to let your **AppCustomizedProcessor** start to work,
you must override ```BaseContentProcessorCreator``` for message types:

1. ContentType.APPLICATION 
2. ContentType.CUSTOMIZED

and then set your **creator** for ```GeneralContentProcessorFactory``` in the ```MessageProcessor```.

----

Copyright &copy; 2023 Albert Moky
[![Followers](https://img.shields.io/github/followers/moky)](https://github.com/moky?tab=followers)
