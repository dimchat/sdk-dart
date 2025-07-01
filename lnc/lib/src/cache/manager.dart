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
import 'pool.dart';

class CacheManager {
  factory CacheManager() => _instance;
  static final CacheManager _instance = CacheManager._internal();
  CacheManager._internal();

  final Map<String, dynamic> _poolMap = {};

  ///  Get pool with name
  ///
  /// @param name - pool name
  /// @param <K>  - key type
  /// @param <V>  - value type
  /// @return CachePool
  CachePool<K, V> getPool<K, V>(String name) {
    CachePool<K, V>? pool = _poolMap[name];
    if (pool == null) {
      pool = CachePool();
      _poolMap[name] = pool;
    }
    return pool;
  }

  ///  Purge all pools
  ///
  /// @param now - current time
  int purge(double? now) {
    now ??= Time.currentTimestamp;
    int count = 0;
    CachePool? pool;
    Iterable allKeys = _poolMap.keys;
    for (var key in allKeys) {
      pool = _poolMap[key];
      if (pool != null) {
        count += pool.purge(now: now);
      }
    }
    return count;
  }

}
