/* license: https://mit-license.org
 *
 *  LNC : Local Notification Center
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
import 'package:object_key/object_key.dart';

import '../log/log.dart';

import 'base.dart';


///  Notification center
class NotificationCenter {
  factory NotificationCenter() => _instance;
  static final NotificationCenter _instance = NotificationCenter._internal();
  NotificationCenter._internal();

  BaseCenter center = BaseCenter();

  ///  Add observer with notification name
  ///
  /// @param observer - who will receive notification
  /// @param name     - notification name
  void addObserver(Observer observer, String name) {
    center.addObserver(observer, name);
  }

  ///  Remove observer for notification name
  ///
  /// @param observer - who will receive notification
  /// @param name     - notification name
  void removeObserver(Observer observer, [String? name]) {
    center.removeObserver(observer, name);
  }

  ///  Post a notification with extra info
  ///
  /// @param name   - notification name
  /// @param sender - who post this notification
  /// @param info   - extra info
  Future<void> postNotification(String name, dynamic sender, [Map? info]) async {
    await center.postNotification(name, sender, info);
  }

  ///  Post a notification
  ///
  /// @param notification - notification object
  Future<void> post(Notification notification) async {
    await center.post(notification);
  }

}

class BaseCenter with Logging {

  // name => WeakSet<Observer>
  final Map<String, Set<Observer>> _observers = {};

  ///  Add observer with notification name
  ///
  /// @param observer - listener
  /// @param name     - notification name
  void addObserver(Observer observer, String name) {
    Set<Observer>? listeners = _observers[name];
    if (listeners == null) {
      listeners = WeakSet();
      listeners.add(observer);
      _observers[name] = listeners;
    } else {
      listeners.add(observer);
    }
  }

  ///  Remove observer from notification center
  ///
  /// @param observer - listener
  /// @param name     - notification name
  void removeObserver(Observer observer, [String? name]) {
    if (name == null) {
      // 1. remove from all observer set
      _observers.forEach((key, listeners) {
        listeners.remove(observer);
      });
      // 2. remove empty set
      _observers.removeWhere((key, listeners) => listeners.isEmpty);
    } else {
      // 3. get listeners by name
      Set<Observer>? listeners = _observers[name];
      if (listeners != null && listeners.remove(observer)) {
        // observer removed
        if (listeners.isEmpty) {
          _observers.remove(name);
        }
      }
    }
  }

  ///  Post notification with name
  ///
  /// @param name     - notification name
  /// @param sender   - notification sender
  /// @param info     - extra info
  Future<void> postNotification(String name, dynamic sender, [Map? info]) async {
    return await post(Notification(name, sender, info));
  }

  Future<void> post(Notification notification) async {
    Set<Observer>? listeners = _observers[notification.name]?.toSet();
    if (listeners == null) {
      logDebug('no listeners for notification: ${notification.name}');
      return;
    }
    List<Future> tasks = [];
    for (Observer item in listeners) {
      try {
        tasks.add(item.onReceiveNotification(notification).onError((error, st) =>
            Log.error('observer error: $error, $st, $notification')
        ));
      } catch (ex, stackTrace) {
        logError('observer error: $ex, $stackTrace, $notification');
      }
    }
    // wait all tasks finished
    await Future.wait(tasks);
  }

}
