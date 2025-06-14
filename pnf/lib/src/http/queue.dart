/* license: https://mit-license.org
 *
 *  HyperText Transfer Protocol
 *
 *                               Written in 2025 by Moky <albert.moky@gmail.com>
 *
 * =============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2025 Albert Moky
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
import 'dart:typed_data';

import 'package:object_key/object_key.dart';

import 'tasks.dart';


class DownloadQueue {

  final List<int> _priorities = [];
  final Map<int, List<DownloadTask>> _fleets = {};

  Future<int> removeTasks(DownloadInfo params, Uint8List? downData) async {
    int success = 0;
    List<DownloadTask>? fleet;
    List<DownloadTask> array;
    for (int priority in _priorities) {
      fleet = _fleets[priority];
      if (fleet == null || fleet.isEmpty) {
        // task not found on this priority
        continue;
      }
      array = fleet.toList();  // copy
      for (DownloadTask item in array) {
        // 1. check params
        if (item.downloadParams != params) {
          continue;
        }
        try {
          // 2. process the task with same params (download URL)
          if (await item.prepareDownload()) {
            await item.processResponse(downData);
          }
          success += 1;
        } catch (e, st) {
          print('[HTTP] failed to handle data: ${downData?.length} bytes, $params, error: $e, $st');
        }
        // 3. remove this task from waiting queue
        fleet.remove(item);
      }
    }
    return success;
  }

  /// Get next download task,
  /// that its priority not larger than the maxPriority
  DownloadTask? nextTask(int maxPriority) {
    List<DownloadTask>? fleet;
    for (int priority in _priorities) {
      if (priority > maxPriority) {
        // ignore the slower tasks
        continue;
        // break;
      }
      fleet = _fleets[priority];
      if (fleet == null || fleet.isEmpty) {
        // task not found on this priority
        continue;
      }
      return fleet.removeAt(0);
    }
    return null;
  }

  /// Append download task with priority
  void addTask(DownloadTask task) {
    int priority = task.priority;
    List<DownloadTask>? fleet = _fleets[priority];
    if (fleet == null) {
      // create new array for this priority
      fleet = WeakList();
      _fleets[priority] = fleet;
      // insert the priority in a sorted list
      _insertPriority(priority);
    }
    // append to the tail, and build index for it
    fleet.add(task);
  }
  void _insertPriority(int priority) {
    int index = 0, value;
    // seeking position for new priority
    for (; index < _priorities.length; ++index) {
      value = _priorities[index];
      if (value == priority) {
        // duplicated
        return;
      } else if (value > priority) {
        // got it
        break;
      }
      // current value is smaller than the new value,
      // keep going
    }
    // insert new value before the bigger one
    _priorities.insert(index, priority);
  }

}
