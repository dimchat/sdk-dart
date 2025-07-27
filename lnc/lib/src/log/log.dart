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
import '../time.dart';

import 'caller.dart';
import 'printer.dart';


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

  String get className => _runtimeType(this) ?? 'Object';

  void logDebug(String msg) =>
      Log.logger.debug(msg, className: _runtimeType(this));

  void logInfo(String msg) =>
      Log.logger.info(msg, className: _runtimeType(this));

  void logWarning(String msg) =>
      Log.logger.warning(msg, className: _runtimeType(this));

  void logError(String msg) =>
      Log.logger.error(msg, className: _runtimeType(this));

}

String? _runtimeType(Object object, {String? className}) {
  assert(() {
    // Calling `toString` on a runtime type is a non-trivial operation
    // that can negatively impact performance
    className = object.runtimeType.toString();
    return true;
  }());
  return className;
}

class DefaultLogger with LogMixin {
  DefaultLogger([LogPrinter? logPrinter]) {
    _printer = logPrinter ?? LogPrinter();
  }

  late final LogPrinter _printer;

  @override
  LogPrinter get printer => _printer;

}

abstract interface class Logger {

  //
  //  Tags
  //
  static String   DEBUG_TAG = " DEBUG ";
  static String    INFO_TAG = "       ";
  static String WARNING_TAG = "WARNING";
  static String   ERROR_TAG = " ERROR ";

  LogPrinter get printer;

  void   debug(String msg, {String? className});
  void    info(String msg, {String? className});
  void warning(String msg, {String? className});
  void   error(String msg, {String? className});

  /// limit log info
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

}

mixin LogMixin implements Logger {

  static String colorRed    = '\x1B[95m';  // error
  static String colorYellow = '\x1B[93m';  // warning
  static String colorGreen  = '\x1B[92m';  // debug
  static String colorClear  = '\x1B[0m';

  // protected
  String get now => Time.now;

  /// Override for customized caller tracer
  // protected
  LogCaller get caller => LogCaller('lnc/src/log/log.dart', StackTrace.current);

  // protected
  void output(String msg, {String? className, required String tag, required String color}) {
    //
    //  0. shorten message
    //
    int maxLen = Log.MAX_LEN;
    if (maxLen > 0) {
      msg = Logger.shorten(msg, maxLen);
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
    //  2.1. insert caller & class name
    var locate = caller;
    if (Log.showCaller) {
      if (className == null) {
        body = '$locate >\t$msg';
      } else {
        body = '$locate | $className >\t$msg';
      }
    } else {
      if (className == null) {
        body = msg;
      } else {
        body = '$className >\t$msg';
      }
    }
    //  2.2. insert time & tag
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
  void debug(String msg, {String? className}) {
    assert(() {
      var flag = Log.level & Log.DEBUG_FLAG;
      if (flag > 0) {
        output(msg, className: className, tag: Logger.DEBUG_TAG, color: colorGreen);
      }
      return true;
    }());
  }

  @override
  void info(String msg, {String? className}) {
    assert(() {
      var flag = Log.level & Log.INFO_FLAG;
      if (flag > 0) {
        output(msg, className: className, tag: Logger.INFO_TAG, color: '');
      }
      return true;
    }());
  }

  @override
  void warning(String msg, {String? className}) {
    assert(() {
      var flag = Log.level & Log.WARNING_FLAG;
      if (flag > 0) {
        output(msg, className: className, tag: Logger.WARNING_TAG, color: colorYellow);
      }
      return true;
    }());
  }

  @override
  void error(String msg, {String? className}) {
    //assert(() {
      var flag = Log.level & Log.ERROR_FLAG;
      if (flag > 0) {
        output(msg, className: className, tag: Logger.ERROR_TAG, color: colorRed);
      }
    //  return true;
    //}());
  }

}
