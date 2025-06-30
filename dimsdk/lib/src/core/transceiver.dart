/* license: https://mit-license.org
 *
 *  DIMP : Decentralized Instant Messaging Protocol
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
import 'dart:typed_data';

import 'package:dimp/dimp.dart';

import '../dkd/instant.dart';
import '../dkd/reliable.dart';
import '../dkd/secure.dart';
import '../mkm/entity.dart';
import '../mkm/user.dart';

import 'compressor.dart';


///  Message Transceiver
///  ~~~~~~~~~~~~~~~~~~~
///
///  Converting message format between PlainMessage and NetworkMessage
abstract class Transceiver implements InstantMessageDelegate, SecureMessageDelegate, ReliableMessageDelegate {

  // protected
  EntityDelegate get facebook;

  // protected
  Compressor get compressor;

  //-------- InstantMessageDelegate

  @override
  Future<Uint8List> serializeContent(Content content, SymmetricKey password, InstantMessage iMsg) async {
    // NOTICE: check attachment for File/Image/Audio/Video message content
    //         before serialize content, this job should be do in subclass
    return compressor.compressContent(content.toMap(), password.toMap());
  }

  @override
  Future<Uint8List> encryptContent(Uint8List data, SymmetricKey password, InstantMessage iMsg) async {
    // store 'IV' in iMsg for AES decryption
    return password.encrypt(data, iMsg.toMap());
  }

  // @override
  // Future<Object> encodeData(Uint8List data, InstantMessage iMsg) async {
  //   if (BaseMessage.isBroadcast(iMsg)) {
  //     // broadcast message content will not be encrypted (just encoded to JsON),
  //     // so no need to encode to Base64 here
  //     return UTF8.decode(data)!;
  //   }
  //   // message content had been encrypted by a symmetric key,
  //   // so the data should be encoded here (with algorithm 'base64' as default).
  //   return TransportableData.encode(data);
  // }

  @override
  Future<Uint8List?> serializeKey(SymmetricKey password, InstantMessage iMsg) async {
    if (BaseMessage.isBroadcast(iMsg)) {
      // broadcast message has no key
      return null;
    }
    return compressor.compressSymmetricKey(password.toMap());
  }

  @override
  Future<Uint8List?> encryptKey(Uint8List key, ID receiver, InstantMessage iMsg) async {
    assert(!BaseMessage.isBroadcast(iMsg), 'broadcast message has no key: $iMsg');
    assert(receiver.isUser, 'receiver error: $receiver');
    // TODO: make sure the receiver's public key exists
    User? contact = await facebook.getUser(receiver);
    if (contact == null) {
      assert(false, 'failed to encrypt message key for contact: $receiver');
      return null;
    }
    // encrypt with public key of the receiver (or group member)
    return await contact.encrypt(key);
  }

  // @override
  // Future<Object> encodeKey(Uint8List key, InstantMessage iMsg) async {
  //   assert(!BaseMessage.isBroadcast(iMsg), 'broadcast message has no key: $iMsg');
  //   // message key had been encrypted by a public key,
  //   // so the data should be encode here (with algorithm 'base64' as default).
  //   return TransportableData.encode(key);
  // }

  //-------- SecureMessageDelegate

  // @override
  // Future<Uint8List?> decodeKey(Object key, SecureMessage sMsg) async {
  //   assert(!BaseMessage.isBroadcast(sMsg), 'broadcast message has no key: $sMsg');
  //   return TransportableData.decode(key);
  // }

  @override
  Future<Uint8List?> decryptKey(Uint8List key, ID receiver, SecureMessage sMsg) async {
    // NOTICE: the receiver must be a member ID
    //         if it's a group message
    assert(!BaseMessage.isBroadcast(sMsg), 'broadcast message has no key: $sMsg');
    assert(receiver.isUser, 'receiver error: $receiver');
    User? user = await facebook.getUser(receiver);
    if (user == null) {
      assert(false, 'failed to decrypt key: ${sMsg.sender} => $receiver, ${sMsg.group}');
      return null;
    }
    // decrypt with private key of the receiver (or group member)
    return await user.decrypt(key);
  }

  @override
  Future<SymmetricKey?> deserializeKey(Uint8List? key, SecureMessage sMsg) async {
    assert(!BaseMessage.isBroadcast(sMsg), 'broadcast message has no key: $sMsg');
    if (key == null) {
      assert(false, 'reused key? get it from cache: '
          '${sMsg.sender} => ${sMsg.receiver}, ${sMsg.group}');
      return null;
    }
    Object? info = compressor.extractSymmetricKey(key);
    return SymmetricKey.parse(info);
  }

  // @override
  // Future<Uint8List?> decodeData(Object data, SecureMessage sMsg) async {
  //   if (BaseMessage.isBroadcast(sMsg)) {
  //     // broadcast message content will not be encrypted (just encoded to JsON),
  //     // so return the string data directly
  //     if (data is String) {
  //       return UTF8.encode(data);
  //     } else {
  //       assert(false, 'content data error: $data');
  //       return null;
  //     }
  //   }
  //   // message content had been encrypted by a symmetric key,
  //   // so the data should be encoded here (with algorithm 'base64' as default).
  //   return TransportableData.decode(data);
  // }

  @override
  Future<Uint8List?> decryptContent(Uint8List data, SymmetricKey password, SecureMessage sMsg) async {
    // check 'IV' in sMsg for AES decryption
    return password.decrypt(data, sMsg.toMap());
  }

  @override
  Future<Content?> deserializeContent(Uint8List data, SymmetricKey password, SecureMessage sMsg) async {
    // assert(sMsg.data.isNotEmpty, "message data empty");
    Object? info = compressor.extractContent(data, password.toMap());
    return Content.parse(info);
    // NOTICE: check attachment for File/Image/Audio/Video message content
    //         after deserialize content, this job should be do in subclass
  }

  @override
  Future<Uint8List> signData(Uint8List data, SecureMessage sMsg) async {
    User? user = await facebook.getUser(sMsg.sender);
    assert(user != null, 'failed to sign message data for user: ${sMsg.sender}');
    return await user!.sign(data);
  }

  // @override
  // Future<Object> encodeSignature(Uint8List signature, SecureMessage sMsg) async {
  //   return TransportableData.encode(signature);
  // }

  //-------- ReliableMessageDelegate

  // @override
  // Future<Uint8List?> decodeSignature(Object signature, ReliableMessage rMsg) async {
  //   return TransportableData.decode(signature);
  // }

  @override
  Future<bool> verifyDataSignature(Uint8List data, Uint8List signature, ReliableMessage rMsg) async {
    User? contact = await facebook.getUser(rMsg.sender);
    if (contact == null) {
      assert(false, 'failed to verify message signature for contact: ${rMsg.sender}');
      return false;
    }
    return await contact.verify(data, signature);
  }

}
