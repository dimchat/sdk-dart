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
  }

  Station.fromID(ID identifier) : this(identifier, null, 0);
  Station.fromRemote(String host, int port) : this(kAny, host, port);

  /// Broadcast
  static ID kAny = Identifier('station@anywhere', name: 'station', address: Address.kAnywhere);
  static ID kEvery = Identifier('stations@everywhere', name: 'stations', address: Address.kEverywhere);

  User? _user;

  String? _host;
  int? _port;

  @override
  ID get identifier => _user!.identifier;

  set identifier(ID sid) {
    User inner = BaseUser(sid);
    inner.dataSource = dataSource;
    _user = inner;
  }

  ///  Station IP
  ///
  /// @return IP address
  String? get host {
    if (_host == null) {
      Document? doc = getDocument('*');
      if (doc != null) {
        _host = doc.getProperty('host');
      }
    }
    return _host;
  }

  ///  Station Port
  ///
  /// @return port number
  int? get port {
    if (_port == null) {
      Document? doc = getDocument('*');
      if (doc != null) {
        _port = doc.getProperty('port');
      }
    }
    return _port;
  }

  ///  Get provider ID
  ///
  /// @return ISP ID, station group
  ID? get provider {
    Document? doc = getDocument('*');
    if (doc == null) {
      return null;
    }
    return ID.parse(doc.getProperty('ISP'));
  }
  @override
  bool operator ==(Object other) {
    if (other is Station) {
      if (identical(this, other)) {
        // same object
        return true;
      }
      // check with ID
      return other.port == port && other.host == host;
    }
    return _user == other;
  }

  @override
  int get hashCode {
    if (_user != null) {
      return _user.hashCode;
    }
    if (_host != null && _port != null) {
      return _host.hashCode + _port! * 13;
    }
    return 0;
  }

  @override
  String toString() {
    Type clazz = runtimeType;
    int network = identifier.address.type;
    return '<$clazz id="$identifier" network=$network host="$host" port=$port />';
  }

  //-------- Entity

  @override
  int get type => _user!.type;

  @override
  UserDataSource? get dataSource {
    EntityDataSource? barrack = _user?.dataSource;
    if (barrack == null) {
      return null;
    }
    assert(barrack is UserDataSource, 'user data source error: $barrack');
    return barrack as UserDataSource;
  }

  @override
  set dataSource(EntityDataSource? barrack) {
    _user?.dataSource = barrack;
  }

  @override
  Meta get meta => _user!.meta;

  @override
  Document? getDocument(String? docType) => _user?.getDocument(docType);

  //-------- User

  @override
  Visa? get visa => _user?.visa;

  @override
  List<ID> get contacts => _user!.contacts;

  @override
  bool verify(Uint8List data, Uint8List signature)
  => _user!.verify(data, signature);

  @override
  Uint8List encrypt(Uint8List plaintext) => _user!.encrypt(plaintext);

  @override
  Uint8List sign(Uint8List data) => _user!.sign(data);

  @override
  Uint8List? decrypt(Uint8List ciphertext) => _user?.decrypt(ciphertext);

  @override
  Visa? signVisa(Visa doc) => _user?.signVisa(doc);

  @override
  bool verifyVisa(Visa doc) => _user!.verifyVisa(doc);

}
