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

abstract class Time {

  ///  Now()
  ///
  /// @return current time
  static DateTime get currentTime => DateTime.now();

  /// 1 second = 1000 milliseconds
  static int get currentTimeMilliseconds => currentTime.millisecondsSinceEpoch;
  /// 1 second = 1000000 microseconds
  static int get currentTimeMicroseconds => currentTime.microsecondsSinceEpoch;
  // static int get currentTimeMillis => currentTimeMilliseconds;
  static double get currentTimeSeconds => currentTimeMicroseconds / 1000000.0;

  ///  Now() as timestamp
  ///
  /// @return current timestamp in seconds from Jan 1, 1970 UTC
  static double get currentTimestamp => currentTimeSeconds;

  ///  Convert timestamp to date
  ///
  /// @param timestamp - seconds from Jan 1, 1970 UTC
  static DateTime? getTime(Object? timestamp) {
    double? seconds;
    if (timestamp == null) {
      return null;
    } else if (timestamp is DateTime) {
      // exactly
      return timestamp;
    } else if (timestamp is double) {
      seconds = timestamp;
    } else if (timestamp is num) {  // int
      // assert(false, 'not a double value: timestamp');
      seconds = timestamp.toDouble();
    } else if (timestamp is String) {
      seconds = double.parse(timestamp);
    } else {
      assert(false, 'unknown timestamp: $timestamp');
      return null;
    }
    double ms = seconds * 1000000;
    return DateTime.fromMicrosecondsSinceEpoch(ms.toInt());
  }

  ///  Convert date to timestamp
  ///
  /// @param date - time object
  /// @return seconds from Jan 1, 1970 UTC
  static double? getTimestamp(Object? time) {
    if (time == null) {
      return null;
    } else if (time is DateTime) {
      return time.microsecondsSinceEpoch / 1000000.0;
    } else if (time is double) {
      // exactly
      return time;
    } else if (time is num) {  // int
      // assert(false, 'not a double value: time');
      return time.toDouble();
    } else if (time is String) {
      return double.parse(time);
    } else {
      assert(false, 'unknown time: $time');
      return null;
    }
  }

}
