/* license: https://mit-license.org
 *
 *  LNC : Log & Notification Center
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

class Log {

  static const String kRed    = '\x1B[95m';
  static const String kYellow = '\x1B[93m';
  static const String kGreen  = '\x1B[92m';
  static const String kClear  = '\x1B[0m';

  static const int kDebugFlag   = 1 << 0;
  static const int kInfoFlag    = 1 << 1;
  static const int kWarningFlag = 1 << 2;
  static const int kErrorFlag   = 1 << 3;

  static const int kDebug   = kDebugFlag|kInfoFlag|kWarningFlag|kErrorFlag;
  static const int kDevelop =            kInfoFlag|kWarningFlag|kErrorFlag;
  static const int kRelease =                      kWarningFlag|kErrorFlag;

  static int level = kRelease;

  static int chunkLength = 1000;
  static int limitLength = -1;    // -1 means unlimited

  static String get _now {
    DateTime time = DateTime.now();
    String m = _twoDigits(time.month);
    String d = _twoDigits(time.day);
    String h = _twoDigits(time.hour);
    String min = _twoDigits(time.minute);
    String sec = _twoDigits(time.second);
    return '${time.year}-$m-$d $h:$min:$sec';
  }

  static String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  static String get _location {
    List<String> caller = _caller(StackTrace.current);
    // String func = caller[0];
    String file = caller[1];
    String line = caller[2];
    return '$file:$line';
  }

  static void colorPrint(String body, {required String color}) {
    _print(body, head: color, tail: kClear);
  }
  static void _print(String body, {String head = '', String tail = ''}) {
    int size = body.length;
    if (0 < limitLength && limitLength < size) {
      body = '${body.substring(0, limitLength - 3)}...';
      size = limitLength;
    }
    int start = 0, end = chunkLength;
    for (; end < size; start = end, end += chunkLength) {
      print(head + body.substring(start, end) + tail + _chunked);
    }
    if (start >= size) {
      // all chunks printed
      assert(start == size, 'should not happen');
    } else if (start == 0) {
      // body too short
      print(head + body + tail);
    } else {
      // print last chunk
      print(head + body.substring(start) + tail);
    }
  }
  static const String _chunked = '↩️';

  static void debug(String? msg) {
    if ((level & kDebugFlag) == 0) {
      return;
    }
    _print('[$_now]  DEBUG  | $_location >\t$msg', head: kGreen, tail: kClear);
  }

  static void info(String? msg) {
    if ((level & kInfoFlag) == 0) {
      return;
    }
    _print('[$_now]         | $_location >\t$msg');
  }

  static void warning(String? msg) {
    if ((level & kWarningFlag) == 0) {
      return;
    }
    _print('[$_now] WARNING | $_location >\t$msg', head: kYellow, tail: kClear);
  }

  static void error(String? msg) {
    if ((level & kErrorFlag) == 0) {
      return;
    }
    _print('[$_now]  ERROR  | $_location >\t$msg', head: kRed, tail: kClear);
  }

}

// #0      Log._location (package:dim_client/src/common/utils/log.dart:52:46)
// #2      main.<anonymous closure> (file:///.../client_test.dart:16:11)
// #3      Amanuensis.saveInstantMessage (package:sechat/models/conversation.dart:398)
// <asynchronous suspension>
// #?      function (path:1:2)
List<String> _caller(StackTrace current) {
  String text = current.toString().split('\n')[2];
  // skip '#0      '
  int pos = text.indexOf(' ');
  text = text.substring(pos + 1).trimLeft();
  // split 'function' & '(file:line:column)'
  pos = text.lastIndexOf(' ');
  String func = text.substring(0, pos);
  String tail = text.substring(pos + 1);
  String file = 'unknown.file';
  String line = '-1';
  int pos1 = tail.indexOf(':');
  if (pos1 > 0) {
    pos = tail.indexOf(':', pos1 + 1);
    if (pos > 0) {
      file = tail.substring(1, pos);
      pos1 = pos + 1;
      pos = tail.indexOf(':', pos1);
      if (pos > 0) {
        line = tail.substring(pos1, pos);
      } else if (pos1 < tail.length) {
        line = tail.substring(pos1, tail.length - 1);
      }
    }
  }
  return[func, file, line];
}
