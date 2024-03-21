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

  final Map<String, Uint8List> _dictionary = {};

  /// Take all items
  Map<String, Uint8List> get all => _dictionary;

  /// Take any item
  Pair<String, Uint8List>? get any {
    if (_dictionary.isEmpty) {
      assert(false, 'enigma secrets not found');
      return null;
    }
    var entry = _dictionary.entries.first;
    String text = _EnigmaHelper.digest(entry.key);
    return Pair(text, entry.value);
  }

  /// Remove all secrets
  void clear() =>
      _dictionary.clear();

  /// Remove secrets with keys
  void remove(Iterable<String> keys) {
    // check each key
    for (String prefix in keys) {
      if (prefix.isEmpty) {
        assert(false, 'enigma error: $keys');
        continue;
      }
      // remove all items have this prefix
      _dictionary.removeWhere(
            (text, _) => _EnigmaHelper.match(text, enigma: prefix),
      );
    }
  }

  /// Update secrets
  void update(Iterable<String> secrets) {
    Pair<String, Uint8List>? pair;
    for (String text in secrets) {
      pair = _EnigmaHelper.decode(text);
      if (pair == null) {
        assert(false, 'failed to decode secret: $text');
        continue;
      }
      _dictionary[pair.first] = pair.second;
    }
  }

  /// Search secret with keys
  Pair<String, Uint8List>? lookup([Iterable<String>? keys]) {
    if (keys == null) {
      return any;
    }
    // check each key
    for (String prefix in keys) {
      if (prefix.isEmpty) {
        assert(false, 'enigma error: $keys');
        continue;
      }
      // search a item that has this prefix
      for (var entry in _dictionary.entries) {
        // check secret with prefix
        if (_EnigmaHelper.match(entry.key, enigma: prefix)) {
          return Pair(prefix, entry.value);
        }
      }
    }
    // secret not found
    return null;
  }

  //
  //  URL: "https://tfs.dim.chat/{ID}/upload?md5={MD5}&salt={SALT}&enigma=123456"
  //

  /// Get enigma secret for this API
  Pair<String, Uint8List>? fetch(String api) {
    // get enigma from URL
    List<String>? keys;
    String? enigma = _EnigmaHelper.from(api);
    // search secret with enigma
    if (enigma == null || enigma.isEmpty || enigma == '{ENIGMA}') {
      // enigma not specified, choose any one
    } else {
      keys = [enigma];
    }
    return lookup(keys);
  }

  /// Build upload URL
  String build(String api, ID sender,
      {Uint8List? data, Uint8List? secret, String? enigma}) {
    // build URL string with sender
    String urlString = api;
    urlString = Template.replace(urlString, 'ID', sender.address.toString());
    if (data == null || secret == null || enigma == null) {
      assert(data == null && secret == null && enigma == null, 'enigma'
          ' params error: ${data?.length}, ${secret?.length}, $enigma');
      return urlString;
    } else {
      assert(data.isNotEmpty && secret.isNotEmpty && enigma.isNotEmpty, 'enigma'
          ' params error: ${data.length}, ${secret.length}, $enigma');
    }
    // hash: md5(data + secret + salt)
    Uint8List salt = _EnigmaHelper.random(16);
    Uint8List temp = _EnigmaHelper.concat(data, secret, salt);
    Uint8List hash = MD5.digest(temp);
    urlString = Template.replace(urlString, 'MD5', Hex.encode(hash));
    urlString = Template.replace(urlString, 'SALT', Hex.encode(salt));
    return _EnigmaHelper.replace(urlString, enigma);
  }

}


/// Enigma secret formats:
///   1. base64,{BASE64_ENCODE}
///   2. hex,{HEX_ENCODE}
///   3. {HEX_ENCODE}
abstract class _EnigmaHelper {

  /// Get enigma for secret
  static String digest(String secret) {
    List<String> pair = secret.split(',');
    assert(pair.length == 1 || pair.length == 2, 'enigma secret error: $secret');
    String text = pair.last;
    // get first 6 characters from the encoded string
    if (text.length > 6) {
      // return the head
      return text.substring(0, 6);
    }
    assert(false, 'enigma secret not safe: $secret');
    return text;
  }

  /// Check whether the enigma matches the secret body
  static bool match(String secret, {required String enigma}) {
    List<String> pair = secret.split(',');
    assert(pair.length == 1 || pair.length == 2, 'enigma secret error: $secret');
    String text = pair.last;
    // check encoded text with prefix
    String prefix = enigma.split(',').last;
    if (prefix.isEmpty) {
      assert(false, 'enigma error: $enigma');
      return false;
    }
    return text.startsWith(prefix);
  }

  /// Decode secret body
  static Pair<String, Uint8List>? decode(String secret) {
    List<String> pair = secret.split(',');
    assert(pair.length == 1 || pair.length == 2, 'enigma secret error: $secret');
    String text = pair.last;
    // check algorithm for decoding
    Uint8List? data;
    if (pair.length == 2 && pair.first == 'base64') {
      // "base64,..."
      data = Base64.decode(text);
    } else {
      // "hex,..."
      // "..."
      data = Hex.decode(text);
    }
    return data == null ? null : Pair(text, data);
  }

  //
  //  URL: "https://tfs.dim.chat/{ID}/upload?md5={MD5}&salt={SALT}&enigma=123456"
  //

  /// Get enigma key from URL
  static String? from(String url) =>
      Template.getParams(url)['enigma'];

  /// Set enigma key into URL
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
