/* license: https://mit-license.org
 *
 *  Ming-Ke-Ming : Decentralized User Identity Authentication
 *
 *                                Written in 2023 by Moky <albert.moky@gmail.com>
 *
 * ==============================================================================
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
 * ==============================================================================
 */
import 'package:dimp/crypto.dart';
import 'package:dimp/mkm.dart';
import 'package:dimp/plugins.dart';
import 'package:dim_plugins/mkm.dart';


class CompatibleMetaFactory extends BaseMetaFactory {
  CompatibleMetaFactory(super.type);

  @override
  Meta createMeta(VerifyKey pKey, {String? seed, TransportableData? fingerprint}) {
    Meta out;
    switch (type) {

      case Meta.MKM:
        out = DefaultMeta.from('1', pKey, seed!, fingerprint!);
        break;

      case Meta.BTC:
        out = BTCMeta.from('2', pKey);
        break;

      case Meta.ETH:
        out = ETHMeta.from('4', pKey);
        break;

      default:
        // TODO: other types of meta
        throw Exception('unknown meta type: $type');
    }
    assert(out.isValid, 'meta error: $out');
    return out;
  }

  @override
  Meta? parseMeta(Map meta) {
    Meta out;
    var holder = SharedAccountHolder();
    String? version = holder.helper!.getMetaType(meta, '');
    switch (version) {

      case 'MKM':
      case 'mkm':
      case '1':
        out = DefaultMeta(meta);
        break;

      case 'BTC':
      case 'btc':
      case '2':
        out = BTCMeta(meta);
        break;

      case 'ETH':
      case 'eth':
      case '4':
        out = ETHMeta(meta);
        break;

      default:
        // TODO: other types of meta
        throw Exception('unknown meta type: $type');
    }
    return out.isValid ? out : null;
  }

}
