/* license: https://mit-license.org
 *
 *  DIMP : Decentralized Instant Messaging Protocol
 *
 *                                Written in 2023 by Moky <albert.moky@gmail.com>
 *
 * ==============================================================================
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
 * ==============================================================================
 */
import 'package:dimp/dimp.dart';


/// 1. [Meta Protocol]
/// 2. [Visa Protocol]
abstract interface class MessageUtils {

  ///  Sender's Meta
  ///  ~~~~~~~~~~~~~
  ///  Extends for the first message package of 'Handshake' protocol.

  static Meta? getMeta(Message msg) =>
      Meta.parse(msg['meta']);

  static void setMeta(Meta? meta, Message msg) =>
      msg.setMap('meta', meta);

  ///  Sender's Visa
  ///  ~~~~~~~~~~~~~
  ///  Extends for the first message package of 'Handshake' protocol.

  static Visa? getVisa(Message msg) {
    Document? doc = Document.parse(msg['visa']);
    if (doc is Visa) {
      return doc;
    }
    assert(doc == null, 'visa document error: $doc');
    return null;
  }

  static void setVisa(Visa? visa, Message msg) =>
      msg.setMap('visa', visa);

}
