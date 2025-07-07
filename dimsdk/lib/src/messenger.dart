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

import 'core/delegate.dart';
import 'core/packer.dart';
import 'core/processor.dart';
import 'core/transceiver.dart';


abstract class Messenger extends Transceiver implements Packer, Processor {

  // protected
  CipherKeyDelegate? get cipherKeyDelegate;

  // protected
  Packer? get packer;

  // protected
  Processor? get processor;

  //-------- SecureMessageDelegate

  @override
  Future<SymmetricKey?> deserializeKey(Uint8List? key, SecureMessage sMsg) async {
    if (key == null) {
      // get key from cache with direction: sender -> receiver(group)
      return await getDecryptKey(sMsg);
    }
    SymmetricKey? password = await super.deserializeKey(key, sMsg);
    // cache decrypt key when success
    if (password != null) {
      // cache the key with direction: sender -> receiver(group)
      await cacheDecryptKey(password, sMsg);
    }
    return password;
  }

  //
  //  Interfaces for Cipher Key
  //

  Future<SymmetricKey?> getEncryptKey(InstantMessage iMsg) async {
    ID sender = iMsg.sender;
    ID target = CipherKeyDelegate.getDestinationForMessage(iMsg);
    var db = cipherKeyDelegate;
    return await db?.getCipherKey(sender: sender, receiver: target, generate: true);
  }
  Future<SymmetricKey?> getDecryptKey(SecureMessage sMsg) async {
    ID sender = sMsg.sender;
    ID target = CipherKeyDelegate.getDestinationForMessage(sMsg);
    var db = cipherKeyDelegate;
    return await db?.getCipherKey(sender: sender, receiver: target, generate: false);
  }

  Future<void> cacheDecryptKey(SymmetricKey key, SecureMessage sMsg) async {
    ID sender = sMsg.sender;
    ID target = CipherKeyDelegate.getDestinationForMessage(sMsg);
    var db = cipherKeyDelegate;
    await db?.cacheCipherKey(sender: sender, receiver: target, key: key);
  }

  //
  //  Interfaces for Packing Message
  //

  @override
  Future<SecureMessage?> encryptMessage(InstantMessage iMsg) async =>
      packer?.encryptMessage(iMsg);

  @override
  Future<ReliableMessage?> signMessage(SecureMessage sMsg) async =>
      await packer?.signMessage(sMsg);

  @override
  Future<SecureMessage?> verifyMessage(ReliableMessage rMsg) async =>
      await packer?.verifyMessage(rMsg);

  @override
  Future<InstantMessage?> decryptMessage(SecureMessage sMsg) async =>
      await packer?.decryptMessage(sMsg);

  //
  //  Interfaces for Processing Message
  //

  @override
  Future<List<Uint8List>> processPackage(Uint8List data) async =>
      await processor!.processPackage(data);

  @override
  Future<List<ReliableMessage>> processReliableMessage(ReliableMessage rMsg) async =>
      await processor!.processReliableMessage(rMsg);

  @override
  Future<List<SecureMessage>> processSecureMessage(SecureMessage sMsg, ReliableMessage rMsg) async =>
      await processor!.processSecureMessage(sMsg, rMsg);

  @override
  Future<List<InstantMessage>> processInstantMessage(InstantMessage iMsg, ReliableMessage rMsg) async =>
      await processor!.processInstantMessage(iMsg, rMsg);

  @override
  Future<List<Content>> processContent(Content content, ReliableMessage rMsg) async =>
      await processor!.processContent(content, rMsg);

}
