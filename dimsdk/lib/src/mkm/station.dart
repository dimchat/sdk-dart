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
import 'dart:typed_data';

import 'package:dimp/dimp.dart';

///  DIM Server
class Station implements User {
  Station(ID identifier, String? host, int? port) {
    assert(identifier.type == EntityType.kStation
        || identifier.type == EntityType.kAny, 'station ID error: $identifier');
    _user = BaseUser(identifier);
    _host = host;
    _port = port;
    _isp = null;
  }

  /// Broadcast
  static ID kAny = Identifier('station@anywhere', name: 'station', address: Address.kAnywhere);
  static ID kEvery = Identifier('stations@everywhere', name: 'stations', address: Address.kEverywhere);

  // inner user
  late User _user;

  String? _host;
  int? _port;

  ID? _isp;

  Station.fromID(ID identifier) : this(identifier, null, 0);
  Station.fromRemote(String host, int port) : this(kAny, host, port);

  @override
  ID get identifier => _user.identifier;

  set identifier(ID sid) {
    User inner = BaseUser(sid);
    inner.dataSource = dataSource;
    _user = inner;
  }

  /// Station IP
  String? get host => _host;

  /// Station Port
  int? get port => _port;

  ///  ISP ID, station group
  ID? get provider => _isp;

  @override
  bool operator ==(Object other) {
    if (other is Station) {
      return _sameStation(other, this);
    }
    return _user == other;
  }

  @override
  int get hashCode {
    if (_host != null && _port != null) {
      return _host.hashCode + _port! * 13;
    }
    return _user.hashCode;
  }

  @override
  String toString() {
    Type clazz = runtimeType;
    int network = identifier.address.type;
    // TODO: check (host:port)
    return '<$clazz id="$identifier" network=$network host="$_host" port=$_port />';
  }

  /// Reload station info: host & port, SP ID
  Future<void> reload() async {
    Document? doc = await getDocument('*');
    if (doc != null) {
      String? host = doc.getProperty('host');
      if (host != null) {
        _host = host;
      }
      int? port = doc.getProperty('port');
      if (port != null) {
        _port = port;
      }
      ID? sp = ID.parse(doc.getProperty('ISP'));
      if (sp != null) {
        _isp = sp;
      }
    }
  }

  //-------- Entity

  @override
  int get type => _user.type;

  @override
  UserDataSource? get dataSource {
    EntityDataSource? barrack = _user.dataSource;
    if (barrack == null) {
      return null;
    }
    assert(barrack is UserDataSource, 'user data source error: $barrack');
    return barrack as UserDataSource;
  }

  @override
  set dataSource(EntityDataSource? barrack) {
    _user.dataSource = barrack;
  }

  @override
  Future<Meta> get meta async => await _user.meta;

  @override
  Future<Document?> getDocument(String? docType) async =>
      await _user.getDocument(docType);

  //-------- User

  @override
  Future<Visa?> get visa async => await _user.visa;

  @override
  Future<List<ID>> get contacts async => await _user.contacts;

  @override
  Future<bool> verify(Uint8List data, Uint8List signature) async =>
      await _user.verify(data, signature);

  @override
  Future<Uint8List> encrypt(Uint8List plaintext) async =>
      await _user.encrypt(plaintext);

  @override
  Future<Uint8List> sign(Uint8List data) async => await _user.sign(data);

  @override
  Future<Uint8List?> decrypt(Uint8List ciphertext) async =>
      await _user.decrypt(ciphertext);

  @override
  Future<Visa?> signVisa(Visa doc) async => await _user.signVisa(doc);

  @override
  Future<bool> verifyVisa(Visa doc) async => await _user.verifyVisa(doc);

}

///
/// Comparison
///

bool _sameStation(Station a, Station b) {
  if (identical(a, b)) {
    // same object
    return true;
  }
  return _checkIdentifiers(a.identifier, b.identifier)
      && _checkHosts(a.host, b.host)
      && _checkPorts(a.port, b.port);
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
  }
  return a == b;
}
bool _checkPorts(int? a, int? b) {
  if (a == null || b == null) {
    return true;
  } else if (a == 0 || b == 0) {
    return true;
  }
  return a == b;
}
