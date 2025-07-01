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

/// Holder for cache value with times in seconds
class CacheHolder <V> {
  CacheHolder(V? cacheValue, double cacheLifeSpan, {double? now})
      : _value = cacheValue, _life = cacheLifeSpan {
    now ??= Time.currentTimestamp;
    _expired = now + cacheLifeSpan;
    _deprecated = now + cacheLifeSpan * 2;
  }

  V? _value;

  final double _life;      // life span (in seconds)
  double _expired = 0;     // time to expired
  double _deprecated = 0;  // time to deprecated

  V? get value => _value;

  /// update cache value with current time in seconds
  void update(V? newValue, {double? now}) {
    _value = newValue;
    now ??= Time.currentTimestamp;
    _expired = now + _life;
    _deprecated = now + _life * 2;
  }

  /// check whether cache is alive with current time in seconds
  bool isAlive({double? now}) {
    now ??= Time.currentTimestamp;
    return now < _expired;
  }

  /// check whether cache is deprecated with current time in seconds
  bool isDeprecated({double? now}) {
    now ??= Time.currentTimestamp;
    return now > _deprecated;
  }

  /// renewal cache with a temporary life span and current time in seconds
  void renewal(double? duration, {double? now}) {
    duration ??= 120;
    now ??= Time.currentTimestamp;
    _expired = now + duration;
    _deprecated = now + _life * 2;
  }

}
