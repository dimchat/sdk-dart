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

import '../dkd/proc.dart';
import '../twins.dart';

import 'base.dart';
import 'commands.dart';
import 'contents.dart';


/// Base ContentProcessor Creator
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class BaseContentProcessorCreator extends TwinsHelper implements ContentProcessorCreator {
  BaseContentProcessorCreator(super.facebook, super.messenger);

  @override
  ContentProcessor? createContentProcessor(int msgType) {
    switch (msgType) {

      // forward content
      case ContentType.FORWARD:
        return ForwardContentProcessor(facebook!, messenger!);

      // array content
      case ContentType.ARRAY:
        return ArrayContentProcessor(facebook!, messenger!);

      // default commands
      case ContentType.COMMAND:
        return BaseCommandProcessor(facebook!, messenger!);

      // case ContentType.ANY:
      case 0:
        // must return a default processor for type==0
        return BaseContentProcessor(facebook!, messenger!);

    }
    // unknown content
    return null;
  }

  @override
  ContentProcessor? createCommandProcessor(int msgType, String cmd) {
    switch (cmd) {

      // meta command
      case Command.META:
        return MetaCommandProcessor(facebook!, messenger!);

      // document command
      case Command.DOCUMENT:
        return DocumentCommandProcessor(facebook!, messenger!);

    }
    // unknown command
    return null;
  }

}
