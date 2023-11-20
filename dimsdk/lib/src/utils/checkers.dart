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


///  Frequency checker for duplicated queries
class FrequencyChecker <K> {
  FrequencyChecker(double lifeSpan) : _expires = (lifeSpan * 1000).toInt();

  final Map<K, int> _records = {};  // ID -> milliseconds
  final int _expires;

  bool _forceExpired(K key, int now) {
    _records[key] = now + _expires;
    return true;
  }
  bool _checkExpired(K key, int now) {
    int? expired = _records[key];
    if (expired != null && expired > now) {
      // record exists and not expired yet
      return false;
    }
    _records[key] = now + _expires;
    return true;
  }

  bool isExpired(K key, {DateTime? current, bool force = false}) {
    current ??= DateTime.now();
    // if force == true:
    //     ignore last updated time, force to update now
    // else:
    //     check last update time
    if (force) {
      return _forceExpired(key, current.millisecondsSinceEpoch);
    } else {
      return _checkExpired(key, current.millisecondsSinceEpoch);
    }
  }

}


/// Recent time checker for querying
class RecentTimeChecker <K> {

  final Map<K, int> _times = {};  // ID -> milliseconds

  bool setLastTime(K key, DateTime? lastTime) {
    if (lastTime == null) {
      assert(false, 'recent time empty: $key');
      return false;
    }
    return _setLastTime(key, lastTime.millisecondsSinceEpoch);
  }
  bool _setLastTime(K key, int now) {
    int? last = _times[key];
    if (last == null || last < now) {
      _times[key] = now;
      return true;
    } else {
      return false;
    }
  }

  bool isExpired(K key, DateTime? current) {
    if (current == null) {
      // assert(false, 'recent time empty: $key');
      return true;
    }
    return _isExpired(key, current.millisecondsSinceEpoch);
  }
  bool _isExpired(K key, int now) {
    int? last = _times[key];
    return last != null && last > now;
  }

}
