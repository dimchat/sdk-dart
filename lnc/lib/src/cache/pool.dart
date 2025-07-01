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
import 'holder.dart';

class CachePair <V> {
  CachePair(this.value, this.holder);

  final V? value;
  final CacheHolder<V> holder;

}

/// Pool for cache holders with keys
class CachePool <K, V> {

  final Map<K, CacheHolder<V>> _holderMap = {};

  Iterable<K> get keys => _holderMap.keys;

  /// update cache holder for key
  CacheHolder<V> update(K key, CacheHolder<V> holder) {
    _holderMap[key] = holder;
    return holder;
  }

  /// update cache value for key with timestamp in seconds
  CacheHolder<V> updateValue(K key, V? value, double life, {double? now}) =>
      update(key, CacheHolder(value, life, now: now));

  /// erase cache for key
  CachePair<V>? erase(K key, {double? now}) {
    CachePair<V>? old;
    if (now != null) {
      // get exists value before erasing
      old = fetch(key, now: now);
    }
    _holderMap.remove(key);
    return old;
  }

  /// fetch cache value & its holder
  CachePair<V>? fetch(K key, {double? now}) {
    CacheHolder<V>? holder = _holderMap[key];
    if (holder == null) {
      // holder not found
      return null;
    } else if (holder.isAlive(now: now)) {
      return CachePair(holder.value, holder);
    } else {
      // holder expired
      return CachePair(null, holder);
    }
  }

  /// clear expired cache holders
  int purge({double? now}) {
    now ??= Time.currentTimestamp;
    int count = 0;
    Iterable allKeys = keys;
    CacheHolder? holder;
    for (K key in allKeys) {
      holder = _holderMap[key];
      if (holder == null || holder.isDeprecated(now: now)) {
        // remove expired holders
        _holderMap.remove(key);
        ++count;
      }
    }
    return count;
  }

}
