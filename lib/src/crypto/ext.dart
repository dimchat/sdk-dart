/* license: https://mit-license.org
 *
 *  DIMP : Decentralized Instant Messaging Protocol
 *
 *                                Written in 2026 by Moky <albert.moky@gmail.com>
 *
 * ==============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2026 Albert Moky
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
 * ==============================================================================
 */
import 'dart:typed_data';

import 'package:dimp/crypto.dart';
import 'package:dimp/ext.dart';
import 'package:dimp/mkm.dart';

import 'agent.dart';
import 'bundle.dart';


/// VisaAgent Extensions
/// ~~~~~~~~~~~~~~~~~~~~

VisaAgent _agent = DefaultVisaAgent();

extension VisaAgentExtension on AccountExtensions {

  VisaAgent get visaAgent => _agent;
  set visaAgent(VisaAgent agent) => _agent = agent;

  EncryptedBundleHelper get bundleHelper => _bundleHelper;
  set bundleHelper(EncryptedBundleHelper agent) => _bundleHelper = agent;

}

/// EncryptedBundle Extensions
/// ~~~~~~~~~~~~~~~~~~~~~~~~~~

EncryptedBundleHelper _bundleHelper = DefaultBundleHelper();

abstract interface class EncryptedBundleHelper {

  ///  Encode key data
  ///
  /// @param bundle - encrypted key data with targets (ID terminals)
  /// @param did    - user ID
  /// @return encoded key data with targets (ID + terminals)
  Map<String, Object> encodeBundle(EncryptedBundle bundle, ID did);

  ///  Decode key data from 'message.keys'
  ///
  /// @param encodedKeys - encoded key data with targets (ID + terminals)
  /// @param did         - receiver ID
  /// @param terminals   - visa terminals
  /// @return encrypted key data with targets (ID terminals)
  EncryptedBundle decodeBundle(Map keys, ID did, Iterable<String> terminals);

}

class DefaultBundleHelper implements EncryptedBundleHelper {

  @override
  Map<String, Object> encodeBundle(EncryptedBundle bundle, ID did) {
    assert(did.terminal == null, 'ID should not contain terminal here: $did');
    String identifier = Identifier.concat(name: did.name, address: did.address);
    Map<String, Object> encodedKeys = {};
    String target;
    Object base64;
    var map = bundle.toMap();
    map.forEach((terminal, data) {
      // encode data
      base64 = Base64.encode(data);
      if (terminal.isEmpty || terminal == '*') {
        target = identifier;
      } else {
        target = '$identifier/$terminal';
      }
      // insert to 'message.keys' with ID + terminal
      encodedKeys[target] = base64;
    });
    // OK
    return encodedKeys;
  }

  @override
  EncryptedBundle decodeBundle(Map keys, ID did, Iterable<String> terminals) {
    EncryptedBundle bundle = UserEncryptedBundle();
    //
    //  0. ID string without terminal (base identifier)
    //
    String identifier = Identifier.concat(name: did.name, address: did.address);
    String target;
    Object? base64;
    TransportableData? ted;
    Uint8List? data;
    for (String item in terminals) {
      target = item.isEmpty ? '*' : item;
      //
      //  1. Get encoded data for target (ID + terminal)
      //    - Wildcard (*) uses base ID without terminal suffix
      //    - Specific terminals use "ID/terminal" format
      //
      if (target == '*') {
        base64 = keys[identifier];
      } else {
        base64 = keys['$identifier/$target'];
      }
      if (base64 == null) {
        // Key data not found for this terminal - skip
        continue;
      }
      //
      //  2. Decode base64 data to raw bytes
      //
      ted = TransportableData.parse(base64);
      data = ted?.bytes;
      if (data == null) {
        assert(false, 'key data error: $item -> $base64');
        continue;
      }
      //
      //  3. Store decoded data for the terminal
      //
      bundle[target] = data;
    }
    // OK
    return bundle;
  }

}
