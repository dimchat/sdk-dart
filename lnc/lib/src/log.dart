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

  static const int kDebugFlag   = 1 << 0;
  static const int kInfoFlag    = 1 << 1;
  static const int kWarningFlag = 1 << 2;
  static const int kErrorFlag   = 1 << 3;

  static const int kDebug   = kDebugFlag|kInfoFlag|kWarningFlag|kErrorFlag;
  static const int kDevelop =            kInfoFlag|kWarningFlag|kErrorFlag;
  static const int kRelease =                      kWarningFlag|kErrorFlag;

  static int level = kRelease;

  static bool colorful = false;  // colored printer
  static bool showTime = true;
  static bool showCaller = false;

  static Logger logger = DefaultLogger();

  static void   debug(String msg) => logger.debug(msg);
  static void    info(String msg) => logger.info(msg);
  static void warning(String msg) => logger.warning(msg);
  static void   error(String msg) => logger.error(msg);

}

class DefaultLogger with LogMixin {
  // override for customized logger

  final LogPrinter _printer = LogPrinter();

  @override
  LogPrinter get printer => _printer;

}

abstract class Logger {

  LogPrinter get printer;

  void   debug(String msg);
  void    info(String msg);
  void warning(String msg);
  void   error(String msg);

}

mixin LogMixin implements Logger {

  static String colorRed    = '\x1B[95m';  // error
  static String colorYellow = '\x1B[93m';  // warning
  static String colorGreen  = '\x1B[92m';  // debug
  static String colorClear  = '\x1B[0m';

  String? get now =>
      Log.showTime ? LogTimer().now : null;

  LogCaller? get caller =>
      Log.showCaller ? LogCaller.parse(StackTrace.current) : null;

  int output(String msg, {LogCaller? caller, String? tag, String color = ''}) {
    String body;
    // insert caller
    if (caller == null) {
      body = msg;
    } else {
      body = '$caller >\t$msg';
    }
    // insert tag
    if (tag != null) {
      body = '$tag | $body';
    }
    // insert time
    String? time = now;
    if (time != null) {
      body = '[$time] $body';
    }
    // colored print
    if (Log.colorful && color.isNotEmpty) {
      printer.output(body, head: color, tail: colorClear);
    } else {
      printer.output(body);
    }
    return body.length;
  }

  @override
  void debug(String msg) => (Log.level & Log.kDebugFlag) > 0 &&
      output(msg, caller: caller, tag: ' DEBUG ', color: colorGreen) > 0;

  @override
  void info(String msg) => (Log.level & Log.kInfoFlag) > 0 &&
      output(msg, caller: caller, tag: '       ', color: '') > 0;

  @override
  void warning(String msg) => (Log.level & Log.kWarningFlag) > 0 &&
      output(msg, caller: caller, tag: 'WARNING', color: colorYellow) > 0;

  @override
  void error(String msg) => (Log.level & Log.kErrorFlag) > 0 &&
      output(msg, caller: caller, tag: ' ERROR ', color: colorRed) > 0;

}

class LogPrinter {

  int chunkLength = 1000;  // split output when it's too long
  int limitLength = -1;    // max output length, -1 means unlimited

  String carriageReturn = '↩️';

  /// colorful print
  void output(String body, {String head = '', String tail = ''}) {
    int size = body.length;
    if (0 < limitLength && limitLength < size) {
      body = '${body.substring(0, limitLength - 3)}...';
      size = limitLength;
    }
    int start = 0, end = chunkLength;
    for (; end < size; start = end, end += chunkLength) {
      _print(head + body.substring(start, end) + tail + carriageReturn);
    }
    if (start >= size) {
      // all chunks printed
      assert(start == size, 'should not happen');
    } else if (start == 0) {
      // body too short
      _print(head + body + tail);
    } else {
      // print last chunk
      _print(head + body.substring(start) + tail);
    }
  }

  /// override for redirecting outputs
  void _print(Object? object) => print(object);

}

class LogTimer {

  /// full string for current time: 'yyyy-mm-dd HH:MM:SS'
  String get now {
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

}

// #0      LogMixin.caller (package:lnc/src/log.dart:85:55)
// #1      LogMixin.debug (package:lnc/src/log.dart:105:41)
// #2      Log.debug (package:lnc/src/log.dart:50:45)
// #3      main.<anonymous closure>.<anonymous closure> (file:///Users/moky/client/test/client_test.dart:14:11)
// #4      Declarer.test.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/declarer.dart:215:19)
// <asynchronous suspension>
// #5      Declarer.test.<anonymous closure> (package:test_api/src/backend/declarer.dart:213:7)
// <asynchronous suspension>
// #6      Invoker._waitForOutstandingCallbacks.<anonymous closure> (package:test_api/src/backend/invoker.dart:258:9)
// <asynchronous suspension>

// #?      function (path:1:2)
// #?      function (path:1)
class LogCaller {
  LogCaller(this.name, this.path, this.line);

  final String name;
  final String path;
  final int line;

  @override
  String toString() => '$path:$line';

  /// locate the real caller: '#3      ...'
  static String? locate(StackTrace current) {
    List<String> array = current.toString().split('\n');
    for (String line in array) {
      if (line.contains('lnc/src/log.dart:')) {
        // skip for Log
        continue;
      }
      // assert(line.startsWith('#3      '), 'unknown stack trace: $current');
      if (line.startsWith('#')) {
        return line;
      }
    }
    // unknown format
    return null;
  }

  /// parse caller info from trace
  static LogCaller? parse(StackTrace current) {
    String? text = locate(current);
    if (text == null) {
      // unknown format
      return null;
    }
    // skip '#0      '
    int pos = text.indexOf(' ');
    text = text.substring(pos + 1).trimLeft();
    // split 'name' & '(path:line:column)'
    pos = text.lastIndexOf(' ');
    String name = text.substring(0, pos);
    String tail = text.substring(pos + 1);
    String path = 'unknown.file';
    String line = '-1';
    int pos1 = tail.indexOf(':');
    if (pos1 > 0) {
      pos = tail.indexOf(':', pos1 + 1);
      if (pos > 0) {
        path = tail.substring(1, pos);
        pos1 = pos + 1;
        pos = tail.indexOf(':', pos1);
        if (pos > 0) {
          line = tail.substring(pos1, pos);
        } else if (pos1 < tail.length) {
          line = tail.substring(pos1, tail.length - 1);
        }
      }
    }
    return LogCaller(name, path, int.parse(line));
  }

}
