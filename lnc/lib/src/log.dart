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


/// Simple Log
class Log {
  // ignore_for_file: constant_identifier_names

  static const int DEBUG_FLAG   = 1 << 0;
  static const int INFO_FLAG    = 1 << 1;
  static const int WARNING_FLAG = 1 << 2;
  static const int ERROR_FLAG   = 1 << 3;

  static const int DEBUG   = DEBUG_FLAG|INFO_FLAG|WARNING_FLAG|ERROR_FLAG;
  static const int DEVELOP =            INFO_FLAG|WARNING_FLAG|ERROR_FLAG;
  static const int RELEASE =                      WARNING_FLAG|ERROR_FLAG;

  // ignore_for_file: non_constant_identifier_names
  static int MAX_LEN = 1024;

  static int level = RELEASE;

  static bool colorful = false;  // colored printer
  static bool showTime = true;
  static bool showCaller = false;

  static Logger logger = DefaultLogger();

  static void   debug(String msg) => logger.debug(msg);
  static void    info(String msg) => logger.info(msg);
  static void warning(String msg) => logger.warning(msg);
  static void   error(String msg) => logger.error(msg);

}


/// Log with class name
mixin Logging {
  
  void logDebug(String msg) {
    Type clazz = runtimeType;
    Log.debug('$clazz >\t$msg');
  }

  void logInfo(String msg) {
    Type clazz = runtimeType;
    Log.info('$clazz >\t$msg');
  }

  void logWarning(String msg) {
    Type clazz = runtimeType;
    Log.warning('$clazz >\t$msg');
  }

  void logError(String msg) {
    Type clazz = runtimeType;
    Log.error('$clazz >\t$msg');
  }

}


class DefaultLogger with LogMixin {
  DefaultLogger([LogPrinter? logPrinter]) {
    _printer = logPrinter ?? LogPrinter();
  }

  late final LogPrinter _printer;

  @override
  LogPrinter get printer => _printer;

}

abstract class Logger {

  //
  //  Tags
  //
  static String   DEBUG_TAG = " DEBUG ";
  static String    INFO_TAG = "       ";
  static String WARNING_TAG = "WARNING";
  static String   ERROR_TAG = " ERROR ";

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

  String get now => LogTimer().now;

  LogCaller get caller => LogCaller('lnc/src/log.dart', StackTrace.current);

  static String shorten(String text, int maxLen) {
    assert(maxLen > 128, 'too short: $maxLen');
    int size = text.length;
    if (size <= maxLen) {
      return text;
    }
    String desc = 'total $size chars';
    int pos = (maxLen - desc.length - 10) >> 1;
    if (pos <= 0) {
      return text;
    }
    String prefix = text.substring(0, pos);
    String suffix = text.substring(size - pos);
    return '$prefix ... $desc ... $suffix';
  }

  void output(String msg, {required String tag, required String color}) {
    //
    //  0. shorten message
    //
    int maxLen = Log.MAX_LEN;
    if (maxLen > 0) {
      msg = shorten(msg, maxLen);
    }
    //
    //  1. set color
    //
    String clear;
    if (Log.colorful && color.isNotEmpty) {
      clear = colorClear;
    } else {
      color = '';
      clear = '';
    }
    //
    //  2. build body
    //
    String body;
    //  2.1. insert caller
    var locate = caller;
    if (Log.showCaller) {
      body = '$locate >\t$msg';
    } else {
      body = msg;
    }
    //  2.2. insert time
    if (Log.showTime) {
      body = '[$now] $tag | $body';
    } else {
      body = '$tag | $body';
    }
    //
    //  3. colored print
    //
    if (Log.colorful) {
      printer.output(body, head: color, tail: clear, tag: tag, caller: locate);
    } else {
      printer.output(body, tag: tag, caller: locate);
    }
  }

  @override
  void debug(String msg) {
    var flag = Log.level & Log.DEBUG_FLAG;
    if (flag > 0) {
      output(msg, tag: Logger.DEBUG_TAG, color: colorGreen);
    }
  }

  @override
  void info(String msg) {
    var flag = Log.level & Log.INFO_FLAG;
    if (flag > 0) {
      output(msg, tag: Logger.INFO_TAG, color: '');
    }
  }

  @override
  void warning(String msg) {
    var flag = Log.level & Log.WARNING_FLAG;
    if (flag > 0) {
      output(msg, tag: Logger.WARNING_TAG, color: colorYellow);
    }
  }

  @override
  void error(String msg) {
    var flag = Log.level & Log.ERROR_FLAG;
    if (flag > 0) {
      output(msg, tag: Logger.ERROR_TAG, color: colorRed);
    }
  }

}

class LogPrinter {

  int chunkLength = 1000;  // split output when it's too long
  int limitLength = -1;    // max output length, -1 means unlimited

  String carriageReturn = '↩️';

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
    // print chunks
    int start = 0, end = chunkLength;
    for (; end < size; start = end, end += chunkLength) {
      println(head + body.substring(start, end) + tail + carriageReturn,
        tag: tag, caller: caller,
      );
    }
    if (start == 0) {
      // too short, print the whole message
      println(head + body + tail,
        tag: tag, caller: caller,
      );
    } else {
      // print last chunk
      println(head + body.substring(start) + tail,
        tag: tag, caller: caller,
      );
    }
  }

  /// override for redirecting outputs
  void println(String x, {
    required String tag, required LogCaller caller,
  }) => print(x);

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
  LogCaller(this.anchor, this.stacks);

  // private
  final String anchor;      // anchor tag
  final StackTrace stacks;  // stack traces
  Map? _caller;

  // final String name;
  // final String path;
  // final int line;

  @override
  String toString() => '$path:$line';

  String? get name => caller?['name'];
  String? get path => caller?['path'];
  int? get line => caller?['line'];

  //
  //  trace caller
  //

  // private
  Map? get caller {
    Map? info = _caller;
    if (info == null) {
      List<String> traces = stacks.toString().split('\n');
      info = locate(anchor, traces);
      _caller = info;
    }
    return info;
  }

  /// locate the real caller: '#3      ...'
  // protected
  Map? locate(String anchor, List<String> traces) {
    bool flag = false;
    for (var element in traces) {
      if (checkAnchor(anchor, element)) {
        // skip anchor(s)
        flag = true;
      } else if (flag) {
        // get next element of the anchor(s)
        return parseCaller(element);
      }
    }
    assert(false, 'caller not found: $anchor -> $traces');
    return null;
  }

  // protected
  bool checkAnchor(String anchor, String line) {
    if (line.contains(anchor)) {
      // skip for 'lnc/src/log.dart:'
      return true;
    }
    // assert(line.startsWith('#3      '), 'unknown stack trace: $current');
    return !line.startsWith('#');
  }

  /// parse caller info from trace
  // protected
  Map? parseCaller(String text) {
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
    return {
      'name': name,
      'path': path,
      'line': int.tryParse(line),
    };
  }

}
