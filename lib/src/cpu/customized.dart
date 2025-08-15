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

import '../facebook.dart';
import '../messenger.dart';
import '../twins.dart';

import 'base.dart';


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

/// Default Handler
/// ~~~~~~~~~~~~~~~
class BaseCustomizedHandler extends TwinsHelper implements CustomizedContentHandler {
  BaseCustomizedHandler(super.facebook, super.messenger);

  @override
  Future<List<Content>> handleAction(String act, ID sender, CustomizedContent content,
      ReliableMessage rMsg) async {
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


///  Customized Content Processing Unit
///  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
///  Handle content for application customized
class CustomizedContentProcessor extends BaseContentProcessor {
  CustomizedContentProcessor(Facebook facebook, Messenger messenger) : super(facebook, messenger) {
    defaultHandler = createDefaultHandler(facebook, messenger);
  }

  // protected
  CustomizedContentHandler createDefaultHandler(Facebook facebook, Messenger messenger) =>
      BaseCustomizedHandler(facebook, messenger);

  // protected
  late final CustomizedContentHandler defaultHandler;

  @override
  Future<List<Content>> processContent(Content content, ReliableMessage rMsg) async {
    assert(content is CustomizedContent, 'customized content error: $content');
    CustomizedContent customized = content as CustomizedContent;
    // get handler for 'app' & 'mod'
    String app = customized.application;
    String mod = customized.module;
    CustomizedContentHandler handler = filter(app, mod, customized, rMsg);
    // handle the action
    String act = customized.action;
    ID sender = rMsg.sender;
    return await handler.handleAction(act, sender, customized, rMsg);
  }

  /// override for your modules
  // protected
  CustomizedContentHandler filter(String app, String mod, CustomizedContent content, ReliableMessage rMsg) {
    // if the application has too many modules, I suggest you to
    // use different handler to do the jobs for each module.
    return defaultHandler;
  }

}
