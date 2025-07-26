/* license: https://mit-license.org
 *
 *  LNC : Log, Notification & Cache
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
import 'caller.dart';


class LogPrinter {

  static int chunkLength = 1000;  // split output when it's too long
  static int limitLength = -1;    // max output length, -1 means unlimited

  static String carriageReturn = '↩️';

  /// colorful print
  void output(String body, {
    String head = '', String tail = '',
    required String tag, required LogCaller caller,
  }) {
    int size = body.length;
    if (0 < limitLength && limitLength < size) {
      body = '${body.substring(0, limitLength - 4)} ...';
      size = limitLength;
    }
    String x;
    // print chunks
    int start = 0, end = chunkLength;
    for (; end < size; start = end, end += chunkLength) {
      x = head + body.substring(start, end) + tail + carriageReturn;
      println(x, tag: tag, caller: caller);
    }
    if (start > 0) {
      // print last chunk
      x = head + body.substring(start) + tail;
    } else {
      // too short, print the whole message
      x = head + body + tail;
    }
    println(x, tag: tag, caller: caller);
  }

  /// override for redirecting outputs
  // protected
  void println(String x, {
    required String tag, required LogCaller caller,
  }) => print(x);

}
