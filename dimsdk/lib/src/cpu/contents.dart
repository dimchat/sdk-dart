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

import '../messenger.dart';
import 'content.dart';


class ForwardContentProcessor extends BaseContentProcessor {
  ForwardContentProcessor(super.facebook, super.messenger);

  @override
  Future<List<Content>> process(Content content, ReliableMessage rMsg) async {
    assert(content is ForwardContent, 'forward command error: $content');
    List<ReliableMessage> secrets = (content as ForwardContent).secrets;
    // call messenger to process it
    Messenger transceiver = messenger!;
    List<Content> responses = [];
    Content res;
    List<ReliableMessage> results;
    for (ReliableMessage item in secrets) {
      results = await transceiver.processReliableMessage(item);
      /*if (results.isEmpty) {
        res = ForwardContent.create(secrets: []);
      } else */if (results.length == 1) {
        res = ForwardContent.create(forward: results[0]);
      } else {
        res = ForwardContent.create(secrets: results);
      }
      responses.add(res);
    }
    return responses;
  }

}


class ArrayContentProcessor extends BaseContentProcessor {
  ArrayContentProcessor(super.facebook, super.messenger);

  @override
  Future<List<Content>> process(Content content, ReliableMessage rMsg) async {
    assert(content is ArrayContent, 'array command error: $content');
    List<Content> array = (content as ArrayContent).contents;
    // call messenger to process it
    Messenger transceiver = messenger!;
    List<Content> responses = [];
    Content res;
    List<Content> results;
    for (Content item in array) {
      results = await transceiver.processContent(item, rMsg);
      /*if (results.isEmpty) {
        res = ArrayContent.create([]);
      } else */if (results.length == 1) {
        res = results[0];
      } else {
        res = ArrayContent.create(results);
      }
      responses.add(res);
    }
    return responses;
  }

}
