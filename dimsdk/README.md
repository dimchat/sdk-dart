# Decentralized Instant Messaging (Dart SDK)

[![License](https://img.shields.io/github/license/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/blob/master/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/dimchat/sdk-dart/pulls)
[![Platform](https://img.shields.io/badge/Platform-Dart%203-brightgreen.svg)](https://github.com/dimchat/sdk-dart/wiki)
[![Issues](https://img.shields.io/github/issues/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/issues)
[![Version](https://img.shields.io/github/tag/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/tags)
[![Repo Size](https://img.shields.io/github/repo-size/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/archive/refs/heads/main.zip)

[![Watchers](https://img.shields.io/github/watchers/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/watchers)
[![Forks](https://img.shields.io/github/forks/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/forks)
[![Stars](https://img.shields.io/github/stars/dimchat/sdk-dart)](https://github.com/dimchat/sdk-dart/stargazers)
[![Followers](https://img.shields.io/github/followers/dimchat)](https://github.com/orgs/dimchat/followers)

## Dependencies

| Name | Version | Description |
|------|---------|-------------|
| [Ming Ke Ming (名可名)](https://pub.dev/packages/mkm) | ![Version](https://img.shields.io/github/tag/dimchat/mkm-dart) | Decentralized User Identity Authentication |
| [Dao Ke Dao (道可道)](https://pub.dev/packages/dkd) | ![Version](https://img.shields.io/github/tag/dimchat/dkd-dart) | Universal Message Module |
| [DIMP (去中心化通讯协议)](https://pub.dev/packages/dimp) | ![Version](https://img.shields.io/github/tag/dimchat/core-dart) | Decentralized Instant Messaging Protocol |

## Extensions

### 1. extends Content

extends [CustomizedContent](https://github.com/dimchat/core-dart#extends-content)

### 2. extends ContentProcessor

```dart
import 'package:dimsdk/dimsdk.dart';


///  Handler for Customized Content
///  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
abstract interface class CustomizedContentHandler {

  ///  Do your job
  ///
  /// @param act     - action
  /// @param sender  - user ID
  /// @param content - customized content
  /// @param rMsg    - network message
  /// @return responses
  Future<List<Content>> handleAction(String act, ID sender, CustomizedContent content,
      ReliableMessage rMsg);

}


///  Customized Content Processing Unit
///  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class CustomizedContentProcessor extends BaseContentProcessor implements CustomizedContentHandler {
  CustomizedContentProcessor(super.facebook, super.messenger);

  @override
  Future<List<Content>> processContent(Content content, ReliableMessage rMsg) async {
    assert(content is CustomizedContent, 'customized content error: $content');
    CustomizedContent customized = content as CustomizedContent;
    // 1. check app id
    String app = customized.application;
    List<Content>? res = filter(app, content, rMsg);
    if (res != null) {
      // app id not found
      return res;
    }
    // 2. get handler with module name
    String mod = customized.module;
    CustomizedContentHandler? handler = fetch(mod, customized, rMsg);
    if (handler == null) {
      // module not support
      return [];
    }
    // 3. do the job
    String act = customized.action;
    ID sender = rMsg.sender;
    return await handler.handleAction(act, sender, customized, rMsg);
  }

  // protected
  List<Content>? filter(String app, CustomizedContent content, ReliableMessage rMsg) {
    /// override for your application
    String text = 'Content not support.';
    return respondReceipt(text, content: content, envelope: rMsg.envelope, extra: {
      'template': 'Customized content (app: \${app}) not support yet!',
      'replacements': {
        'app': app,
      }
    });
  }

  // protected
  CustomizedContentHandler? fetch(String mod, CustomizedContent content, ReliableMessage rMsg) {
    /// override for your module
    // if the application has too many modules, I suggest you to
    // use different handler to do the jobs for each module.
    return this;
  }

  @override
  Future<List<Content>> handleAction(String act, ID sender, CustomizedContent content, ReliableMessage rMsg) async {
    /// override for customized actions
    String app = content.application;
    String mod = content.module;
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

}
```

### 3. extends ExtensionLoader

```dart
import 'package:dimsdk/plugins.dart';

/// Extensions Loader
/// ~~~~~~~~~~~~~~~~~
class CommonLoader extends ExtensionLoader {

  @override
  void registerContentFactories() {
    super.registerContentFactories();
    
    registerCustomizedFactories();
  }

  void registerCustomizedFactories() {
    
    // Application Customized
    Content.setFactory(ContentType.APPLICATION, ContentParser((dict) => AppCustomizedContent(dict)));
    Content.setFactory(ContentType.CUSTOMIZED, ContentParser((dict) => AppCustomizedContent(dict)));
    
  }

}
```

## Usages

You must load all extensions before your business run:

```dart
import 'common_loader.dart';

void main() {

  var loader = CommonLoader();
  loader.run();
  
  // do your jobs after all extensions loaded.
  
}

```

Also, to let your **CustomizedContentProcessor** start to work,
you must override ```BaseContentProcessorCreator``` for message types:

1. ContentType.APPLICATION 
2. ContentType.CUSTOMIZED

and then set your **creator** for ```GeneralContentProcessorFactory``` in the ```MessageProcessor```.

----

Copyright &copy; 2023 Albert Moky
[![Followers](https://img.shields.io/github/followers/moky)](https://github.com/moky?tab=followers)
