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

///
///   Parsing caller from StackTrace
///   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
///

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

  @override
  String toString() => '$path:$line';

  String? get name => caller?['name'];
  String? get path => caller?['path'];
  int?    get line => caller?['line'];

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
