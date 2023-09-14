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
import 'package:dimp/dimp.dart';

import 'station.dart';

///  DIM Station Owner
class ServiceProvider extends BaseGroup {
  ServiceProvider(super.id);

  Future<List> get stations async {
    Document? doc = await getDocument('*');
    if (doc != null) {
      var stations = doc.getProperty('stations');
      if (stations is List) {
        return stations;
      }
    }
    // TODO: load from local storage
    return [];
  }

  //
  //  Comparison
  //

  static bool sameStation(Station a, Station b) {
    if (identical(a, b)) {
      // same object
      return true;
    }
    return _checkIdentifiers(a.identifier, b.identifier)
        && _checkHosts(a.host, b.host)
        && _checkPorts(a.port, b.port);
  }

}

bool _checkIdentifiers(ID a, ID b) {
  if (identical(a, b)) {
    // same object
    return true;
  } else if (a.isBroadcast || b.isBroadcast) {
    return true;
  }
  return a == b;
}
bool _checkHosts(String? a, String? b) {
  if (a == null || b == null) {
    return true;
  } else if (a.isEmpty || b.isEmpty) {
    return true;
  }
  return a == b;
}
bool _checkPorts(int a, int b) {
  if (a == 0 || b == 0) {
    return true;
  }
  return a == b;
}
