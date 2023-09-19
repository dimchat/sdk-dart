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

abstract class TwinsHelper {
  TwinsHelper(Facebook facebook, Messenger messenger)
      : _barrack = WeakReference(facebook),
        _transceiver = WeakReference(messenger);

  final WeakReference<Facebook> _barrack;
  final WeakReference<Messenger> _transceiver;

  Facebook? get facebook => _barrack.target;
  Messenger? get messenger => _transceiver.target;

  //
  //  Convenient responding
  //

  ///  receipt command with text, original envelope, serial number & group
  ///
  /// @param text     - respond message
  /// @param envelope - original message envelope
  /// @param content  - original message content
  /// @param extra    - extra info
  /// @return commands
  List<ReceiptCommand> respondReceipt(String text,
      {required Envelope envelope, Content? content,
        Map<String, Object>? extra}) {
    // check envelope
    if (envelope.containsKey('data')) {
      Map info = envelope.copyMap(false);
      info.remove('data');
      info.remove('key');
      info.remove('keys');
      info.remove('meta');
      info.remove('visa');
      envelope = Envelope.parse(info)!;
    }
    // create base receipt command with text, original envelope & serial number
    ReceiptCommand res = ReceiptCommand.create(text, envelope, sn: content?.sn);
    ID? group = content?.group;
    if (group != null) {
      res.group = group;
    }
    // add extra key-values
    if (extra != null) {
      res.addAll(extra);
    }
    return [res];
  }

}
