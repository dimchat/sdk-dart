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

import 'content.dart';


///  Handler for Customized Content
///  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
abstract class CustomizedContentHandler {

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
    return respondText(text, group: content.group, extra: {
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
    return respondText(text, group: content.group, extra: {
      'template': 'Customized content (app: \${app}, mod: \${mod}, act: \${act}) not support yet!',
      'replacements': {
        'app': app,
        'mod': mod,
        'act': act,
      }
    });
  }

}
