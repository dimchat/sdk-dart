/* license: https://mit-license.org
 *
 *  Cryptography
 *
 *                               Written in 2024 by Moky <albert.moky@gmail.com>
 *
 * =============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2024 Albert Moky
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
import 'dart:math';
import 'dart:typed_data';

import 'package:mkm/digest.dart';
import 'package:mkm/format.dart';
import 'package:mkm/mkm.dart';
import 'package:object_key/object_key.dart';

import 'template.dart';


/// Enigma for MD5 secrets
class Enigma {

  final Set<String> _secrets = <String>{};

  /// Take all items
  Set<String> get all => _secrets;

  /// Take any item
  String get any => _secrets.first;

  /// Update secrets
  void update(Iterable<String> secrets) =>
      _secrets.addAll(secrets);

  /// Remove all secrets
  void clear() =>
      _secrets.clear();

  /// Remove secrets with keys
  void remove(Iterable<String> keys) {
    // check each key
    for (String prefix in keys) {
      if (prefix.isEmpty) {
        assert(false, 'enigma error: $keys');
        continue;
      }
      // remove all items have this prefix
      _secrets.removeWhere(
            (item) => _EnigmaHelper.match(item, enigma: prefix),
      );
    }
  }

  /// Search secret with keys
  Pair<String, String>? lookup([Iterable<String>? keys]) {
    String secret;
    if (keys == null) {
      secret = any;
      String prefix = _EnigmaHelper.digest(secret);
      return Pair(prefix, secret);
    }
    // check each key
    for (String prefix in keys) {
      if (prefix.isEmpty) {
        assert(false, 'enigma error: $keys');
        continue;
      }
      // search a item that has this prefix
      secret = _secrets.firstWhere(
            (item) => _EnigmaHelper.match(item, enigma: prefix),
        orElse:
            () => _EnigmaHelper.notFound,
      );
      if (secret != _EnigmaHelper.notFound) {
        // got it
        return Pair(prefix, secret);
      }
    }
    // secret not found
    return null;
  }

  //
  //  URL
  //

  /// Get enigma secret for this API
  Pair<String, Uint8List>? fetch(String api) {
    // get enigma from URL
    Pair<String, String>? pair;
    String? enigma = _EnigmaHelper.from(api);
    // search secret with enigma
    if (enigma == null || enigma.isEmpty || enigma == '{ENIGMA}') {
      pair = lookup();
    } else {
      pair = lookup([enigma]);
    }
    if (pair == null) {
      assert(false, 'enigma secret not found: $api');
      return null;
    }
    // decode secret
    Uint8List? data = _EnigmaHelper.decode(pair.second);
    if (data == null) {
      assert(false, 'failed to decode enigma secret: $pair, $api');
      return null;
    }
    return Pair(pair.first, data);
  }

  /// Build upload URL
  String? build(String api,
      {required String enigma, required Uint8List secret,
        required Uint8List data, required ID sender}) {
    // hash: md5(data + secret + salt)
    Uint8List salt = _EnigmaHelper.random(16);
    Uint8List temp = _EnigmaHelper.concat(data, secret, salt);
    Uint8List hash = MD5.digest(temp);
    Address address = sender.address;
    // build URL string
    String urlString = api;
    urlString = Template.replace(urlString, 'ID', address.toString());
    urlString = Template.replace(urlString, 'MD5', Hex.encode(hash));
    urlString = Template.replace(urlString, 'SALT', Hex.encode(salt));
    return _EnigmaHelper.replace(api, enigma);
  }

}


/// Enigma secret formats:
///   1. base64,{BASE64_ENCODE}
///   2. hex,{HEX_ENCODE}
///   3. {HEX_ENCODE}
abstract class _EnigmaHelper {

  static final String notFound = '<ENIGMA NOT EXISTS>';

  /// Get enigma for secret
  static String digest(String secret) {
    List<String> pair = secret.split(',');
    assert(pair.length == 1 || pair.length == 2, 'enigma secret error: $secret');
    // get first 6 characters from the encoded string
    String body = pair.last;
    if (body.length > 6) {
      // return the head
      return body.substring(0, 6);
    }
    assert(false, 'enigma secret not safe: $secret');
    return body;
  }

  /// Check whether the enigma matches the secret body
  static bool match(String secret, {required String enigma}) {
    List<String> pair = secret.split(',');
    assert(pair.length == 1 || pair.length == 2, 'enigma secret error: $secret');
    assert(enigma.isNotEmpty, 'should not happen');
    // check with the encoded string
    return pair.last.startsWith(enigma);
  }

  /// Decode secret body
  static Uint8List? decode(String secret) {
    List<String> pair = secret.split(',');
    assert(pair.length == 1 || pair.length == 2, 'enigma secret error: $secret');
    // check algorithm for decoding
    if (pair.length == 2) {
      String algorithm = pair.first;
      if (algorithm == 'base64') {
        return Base64.decode(pair.last);
      // } else if (algorithm == 'base58') {
      //   return Base58.decode(pair.last);
      }
      assert(algorithm == 'hex', 'enigma secret error: $secret');
    }
    return Hex.decode(pair.last);
  }

  //
  //  URL
  //

  /// Get enigma key from URL: 'https://dim.chat/upload?enigma=123456'
  static String? from(String url) =>
      Template.getParams(url)['enigma'];

  /// Set enigma key into URL: 'https://dim.chat/upload?enigma={ENIGMA}'
  /// replace the tag 'enigma' with new key
  static String replace(String url, String enigma) =>
      Template.replace(url, 'ENIGMA', enigma);

  //
  //  Bytes
  //

  static Uint8List concat(Uint8List a, Uint8List b, Uint8List c) =>
      Uint8List.fromList(a + b + c);

  static Uint8List random(int size) {
    Uint8List data = Uint8List(size);
    Random r = Random();
    for (int i = 0; i < size; ++i) {
      data[i] = r.nextInt(256);
    }
    return data;
  }

}
