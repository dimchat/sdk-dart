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

import '../mkm/entity.dart';
import '../mkm/user.dart';


///  Message Transceiver
///  ~~~~~~~~~~~~~~~~~~~
///
///  Converting message format between PlainMessage and NetworkMessage
abstract class Transceiver implements InstantMessageDelegate, SecureMessageDelegate, ReliableMessageDelegate {

  // protected
  EntityDelegate? get entityDelegate;  // barrack

  //-------- InstantMessageDelegate

  @override
  Future<Uint8List> serializeContent(Content content, SymmetricKey password, InstantMessage iMsg) async {
    // NOTICE: check attachment for File/Image/Audio/Video message content
    //         before serialize content, this job should be do in subclass
    return UTF8.encode(JSON.encode(content.toMap()));
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
    return UTF8.encode(JSON.encode(password.toMap()));
  }

  @override
  Future<Uint8List?> encryptKey(Uint8List key, ID receiver, InstantMessage iMsg) async {
    assert(!BaseMessage.isBroadcast(iMsg), 'broadcast message has no key: $iMsg');
    EntityDelegate? barrack = entityDelegate;
    assert(barrack != null, "entity delegate not set yet");
    // TODO: make sure the receiver's public key exists
    assert(receiver.isUser, 'receiver error: $receiver');
    User? contact = await barrack?.getUser(receiver);
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
    EntityDelegate? barrack = entityDelegate;
    assert(barrack != null, "entity delegate not set yet");
    assert(receiver.isUser, 'receiver error: $receiver');
    User? user = await barrack?.getUser(receiver);
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
    String? json = UTF8.decode(key);
    if (json == null) {
      assert(false, 'message key data error: $key');
      return null;
    }
    Object? dict = JSON.decode(json);
    // TODO: translate short keys
    //       'A' -> 'algorithm'
    //       'D' -> 'data'
    //       'V' -> 'iv'
    //       'M' -> 'mode'
    //       'P' -> 'padding'
    return SymmetricKey.parse(dict);
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
    String? json = UTF8.decode(data);
    if (json == null) {
      assert(false, 'content data error: $data');
      return null;
    }
    Object? dict = JSON.decode(json);
    // TODO: translate short keys
    //       'T' -> 'type'
    //       'N' -> 'sn'
    //       'W' -> 'time'
    //       'G' -> 'group'
    return Content.parse(dict);
  }

  @override
  Future<Uint8List> signData(Uint8List data, SecureMessage sMsg) async {
    EntityDelegate? barrack = entityDelegate;
    assert(barrack != null, 'entity delegate not set yet');
    ID sender = sMsg.sender;
    User? user = await barrack?.getUser(sender);
    assert(user != null, 'failed to sign message data for user: $sender');
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
    EntityDelegate? barrack = entityDelegate;
    assert(barrack != null, 'entity delegate not set yet');
    ID sender = rMsg.sender;
    User? contact = await barrack?.getUser(sender);
    if (contact == null) {
      assert(false, 'failed to verify message signature for contact: $sender');
      return false;
    }
    return await contact.verify(data, signature);
  }

}
