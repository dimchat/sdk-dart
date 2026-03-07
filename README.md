# Decentralized Instant Messaging (Dart SDK)

[![License](https://img.shields.io/github/license/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/blob/main/LICENSE)
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
///  Customized Content Processing Unit
///  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
///  Handle content for application customized
class CustomizedContentProcessor extends BaseContentProcessor {
  CustomizedContentProcessor(super.facebook, super.messenger);

  @override
  Future<List<Content>> processContent(Content content, ReliableMessage rMsg) async {
    assert(content is CustomizedContent, 'customized content error: $content');
    CustomizedContent customized = content as CustomizedContent;
    var filter = sharedMessageExtensions.customizedFilter;
    // get handler for 'app' & 'mod'
    CustomizedContentHandler handler = filter.filterContent(content, rMsg);
    // handle the action
    return await handler.handleAction(customized, rMsg, messenger!);
  }

}
```

- CustomizedContentHandler

```dart
///  Handler for Customized Content
///  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
abstract interface class CustomizedContentHandler {

  ///  Do your job
  ///
  /// @param content   - customized content
  /// @param rMsg      - network message
  /// @param messenger - message transceiver
  /// @return responses
  Future<List<Content>> handleAction(CustomizedContent content, ReliableMessage rMsg, Messenger messenger);

}

/// Default Handler
/// ~~~~~~~~~~~~~~~
class BaseCustomizedContentHandler implements CustomizedContentHandler {

  @override
  Future<List<Content>> handleAction(CustomizedContent content, ReliableMessage rMsg, Messenger messenger) async {
    // String app = content.application;
    String app = content.getString('app') ?? '';
    String mod = content.module;
    String act = content.action;
    String text = 'Content not support.';
    return respondReceipt(text, content: content, envelope: rMsg.envelope, extra: {
      'template': 'Customized content (app: \${app}, mod: \${mod}, act: \${act}) not support yet!',
      'replacements': {
        'app': app,
        'mod': mod,
        'act': act,
      }
    });
  }

  //
  //  Convenient responding
  //

  // protected
  List<ReceiptCommand> respondReceipt(String text, {
    required Envelope envelope, Content? content, Map<String, Object>? extra
  }) => [
    // create base receipt command with text & original envelope
    BaseContentProcessor.createReceipt(text, envelope: envelope, content: content, extra: extra)
  ];

}
```

- CustomizedContentFilter

```dart
/// Factory for CustomizedContentHandler
abstract interface class CustomizedContentFilter {

  ///  Get CustomizedContentHandler for the CustomizedContent
  ///
  /// @param content - customized content
  /// @param rMsg    - network message
  /// @return CustomizedContentHandler
  CustomizedContentHandler filterContent(CustomizedContent content, ReliableMessage rMsg);

}


/// CustomizedContent Extensions
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CustomizedContentFilter _filter = AppCustomizedFilter();

extension CustomizedContentExtension on MessageExtensions {

  CustomizedContentFilter get customizedFilter => _filter;
  set customizedFilter(CustomizedContentFilter filter) => _filter = filter;

}


/// General CustomizedContent Filter
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class AppCustomizedFilter implements CustomizedContentFilter {

  CustomizedContentHandler defaultHandler = BaseCustomizedContentHandler();

  final Map<String, CustomizedContentHandler> _handlers = {};

  void setContentHandler({
    required String app, required String mod,
    required CustomizedContentHandler handler
  }) => _handlers['$app:$mod'] = handler;

  // protected
  CustomizedContentHandler? getContentHandler({
    required String app, required String mod,
  }) => _handlers['$app:$mod'];

  @override
  CustomizedContentHandler filterContent(CustomizedContent content, ReliableMessage rMsg) {
    // String app = content.application;
    String app = content.getString('app') ?? '';
    String mod = content.module;
    var handler = getContentHandler(app: app, mod: mod);
    if (handler != null) {
      return handler;
    }
    // if the application has too many modules, I suggest you to
    // use different handler to do the jobs for each module.
    throw defaultHandler;
  }

}
```

- Example for group querying

```dart
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
class GroupHistoryHandler extends BaseCustomizedContentHandler {

  @override
  Future<List<Content>> handleAction(CustomizedContent content, ReliableMessage rMsg, Messenger messenger) async {
    if (content.group == null) {
      assert(false, 'group command error: $content, sender: ${rMsg.sender}');
      String text = 'Group command error.';
      return respondReceipt(text, envelope: rMsg.envelope, content: content);
    }
    String act = content.action;
    if (act == GroupHistory.ACT_QUERY) {
      // assert(GroupHistory.APP == content.application);
      assert(GroupHistory.MOD == content.module);
      return await transformQueryCommand(content, rMsg, messenger);
    }
    assert(false, 'unknown action: $act, $content, sender: ${rMsg.sender}');
    return await super.handleAction(content, rMsg, messenger);
  }

  // private
  Future<List<Content>> transformQueryCommand(CustomizedContent content, ReliableMessage rMsg, Messenger messenger) async {
    Map info = content.copyMap(false);
    info['type'] = ContentType.COMMAND;
    info['command'] = QueryCommand.QUERY;
    Content? query = Content.parse(info);
    if (query is QueryCommand) {
      return await messenger.processContent(query, rMsg);
    }
    assert(false, 'query command error: $query, $content, sender: ${rMsg.sender}');
    String text = 'Query command error.';
    return respondReceipt(text, envelope: rMsg.envelope, content: content);
  }

}


//  void registerCustomizedHandlers() {
//    var filter = AppCustomizedFilter();
//    // 'chat.dim.group:history'
//    filter.setContentHandler(
//      app: GroupHistory.APP,
//      mod: GroupHistory.MOD,
//      handler: GroupHistoryHandler(),
//    );
//    sharedMessageExtensions.customizedFilter = filter;
//  }

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
        return CustomizedContentProcessor(facebook!, messenger!);

      // ...
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

## Usage

To let your **AppCustomizedProcessor** start to work,
you must override ```BaseContentProcessorCreator``` for message types:

1. ContentType.APPLICATION 
2. ContentType.CUSTOMIZED

and then set your **creator** for ```GeneralContentProcessorFactory``` in the ```MessageProcessor```.

----

Copyright &copy; 2023-2026 Albert Moky
[![Followers](https://img.shields.io/github/followers/moky)](https://github.com/moky?tab=followers)
