/* license: https://mit-license.org
 *
 *  Ming-Ke-Ming : Decentralized User Identity Authentication
 *
 *                                Written in 2023 by Moky <albert.moky@gmail.com>
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
import 'package:dimp/plugins.dart';

/// Format GeneralFactory
/// ~~~~~~~~~~~~~~~~~~~~~
class FormatGeneralFactory implements GeneralFormatHelper,
                                      PortableNetworkFileHelper,
                                      TransportableDataHelper {

  final Map<String, TransportableDataFactory> _tedFactories = {};

  PortableNetworkFileFactory? _pnfFactory;

  /// split text string to array: ["{TEXT}", "{algorithm}", "{content-type}"]
  List<String> split(String text) {
    // "{TEXT}", or
    // "base64,{BASE64_ENCODE}", or
    // "data:image/png;base64,{BASE64_ENCODE}"
    int pos1 = text.indexOf('://');
    if (pos1 > 0) {
      // [URL]
      return [text];
    } else {
      // skip 'data:'
      pos1 = text.indexOf(':') + 1;
    }
    List<String> array = [];
    // seeking for 'content-type'
    int pos2 = text.indexOf(';', pos1);
    if (pos2 > pos1) {
      array.add(text.substring(pos1, pos2));
      pos1 = pos2 + 1;
    }
    // seeking for 'algorithm'
    pos2 = text.indexOf(',', pos1);
    if (pos2 > pos1) {
      array.insert(0, text.substring(pos1, pos2));
      pos1 = pos2 + 1;
    }
    if (pos1 == 0) {
      // [data]
      array.insert(0, text);
    } else {
      // [data, algorithm, type]
      array.insert(0, text.substring(pos1));
    }
    return array;
  }

  Map? decode(Object data, {required String defaultKey}) {
    if (data is Mapper) {
      return data.toMap();
    } else if (data is Map) {
      return data;
    }
    String text = data is String ? data : data.toString();
    if (text.isEmpty) {
      return null;
    } else if (text.startsWith('{') && text.endsWith('}')) {
      return JSONMap.decode(text);
    }
    Map info = {};
    List<String> array = split(text);
    int size = array.length;
    if (size == 1) {
      info[defaultKey] = array[0];
    } else {
      assert(size > 1, 'split error: $text => $array');
      info['data'] = array[0];
      info['algorithm'] = array[1];
      if (size > 2) {
        // 'data:...;...,...'
        info['content-type'] = array[2];
        if (text.startsWith('data:')) {
          info['URL'] = text;
        }
      }
    }
    return info;
  }

  @override
  String? getFormatAlgorithm(Map ted, String? defaultValue) {
    return Converter.getString(ted['algorithm'], defaultValue);
  }

  ///
  ///   TED - Transportable Encoded Data
  ///

  @override
  void setTransportableDataFactory(String algorithm, TransportableDataFactory factory) {
    _tedFactories[algorithm] = factory;
  }

  @override
  TransportableDataFactory? getTransportableDataFactory(String algorithm) {
    if (algorithm.isEmpty) {
      return null;
    }
    return _tedFactories[algorithm];
  }

  @override
  TransportableData createTransportableData(Uint8List data, String? algorithm) {
    algorithm ??= EncodeAlgorithms.DEFAULT;
    TransportableDataFactory? factory = getTransportableDataFactory(algorithm);
    assert(factory != null, 'TED algorithm not support: $algorithm');
    return factory!.createTransportableData(data);
  }

  @override
  TransportableData? parseTransportableData(Object? ted) {
    if (ted == null) {
      return null;
    } else if (ted is TransportableData) {
      return ted;
    }
    // unwrap
    Map? info = decode(ted, defaultKey: 'data');
    if (info == null) {
      // assert(false, 'TED error: $ted');
      return null;
    }
    String algorithm = getFormatAlgorithm(info, null) ?? '';
    assert(algorithm.isNotEmpty, 'TED error: $ted');
    TransportableDataFactory? factory = getTransportableDataFactory(algorithm);
    if (factory == null) {
      factory = getTransportableDataFactory('*');  // unknown
      assert(factory != null, 'default TED factory not found');
    }
    return factory?.parseTransportableData(info);
  }

  ///
  ///   PNF - Portable Network File
  ///

  @override
  void setPortableNetworkFileFactory(PortableNetworkFileFactory factory) {
    _pnfFactory = factory;
  }

  @override
  PortableNetworkFileFactory? getPortableNetworkFileFactory() {
    return _pnfFactory;
  }

  @override
  PortableNetworkFile createPortableNetworkFile(TransportableData? data, String? filename,
      Uri? url, DecryptKey? password) {
    PortableNetworkFileFactory? factory = getPortableNetworkFileFactory();
    assert(factory != null, 'PNF factory not ready');
    return factory!.createPortableNetworkFile(data, filename, url, password);
  }

  @override
  PortableNetworkFile? parsePortableNetworkFile(Object? pnf) {
    if (pnf == null) {
      return null;
    } else if (pnf is PortableNetworkFile) {
      return pnf;
    }
    // unwrap
    Map? info = decode(pnf, defaultKey: 'URL');
    if (info == null) {
      // assert(false, 'PNF error: $pnf');
      return null;
    }
    PortableNetworkFileFactory? factory = getPortableNetworkFileFactory();
    assert(factory != null, 'PNF factory not ready');
    return factory?.parsePortableNetworkFile(info);
  }

}
