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

import 'core/twins.dart';
import 'msg/helper.dart';
import 'msg/instant.dart';
import 'msg/reliable.dart';
import 'msg/secure.dart';

import 'facebook.dart';
import 'messenger.dart';

class MessagePacker extends TwinsHelper implements Packer {
  MessagePacker(super.facebook, super.messenger)
      : instantPacker = InstantMessagePacker(messenger),
        securePacker = SecureMessagePacker(messenger),
        reliablePacker = ReliableMessagePacker(messenger);

  // protected
  final InstantMessagePacker instantPacker;
  final SecureMessagePacker securePacker;
  final ReliableMessagePacker reliablePacker;

  @override
  Facebook? get facebook => super.facebook as Facebook?;

  @override
  Messenger? get messenger => super.messenger as Messenger?;

  //
  //  InstantMessage -> SecureMessage -> ReliableMessage -> Data
  //

  @override
  Future<SecureMessage?> encryptMessage(InstantMessage iMsg) async {
    // TODO: check receiver before calling this, make sure the visa.key exists;
    //       otherwise, suspend this message for waiting receiver's visa/meta;
    //       if receiver is a group, query all members' visa too!

    SecureMessage? sMsg;
    // NOTICE: before sending group message, you can decide whether expose the group ID
    //      (A) if you don't want to expose the group ID,
    //          you can split it to multi-messages before encrypting,
    //          replace the 'receiver' to each member and keep the group hidden in the content;
    //          in this situation, the packer will use the personal message key (user to user);
    //      (B) if the group ID is overt, no need to worry about the exposing,
    //          you can keep the 'receiver' being the group ID, or set the group ID as 'group'
    //          when splitting to multi-messages to let the remote packer knows it;
    //          in these situations, the local packer will use the group msg key (user to group)
    //          to encrypt the message, and the remote packer can get the overt group ID before
    //          decrypting to take the right message key.
    ID receiver = iMsg.receiver;

    //
    //  1. get message key with direction (sender -> receiver) or (sender -> group)
    //
    SymmetricKey? password = await messenger?.getEncryptKey(iMsg);
    assert(password != null, 'failed to get msg key: ${iMsg.sender} => $receiver, ${iMsg['group']}');

    //
    //  2. encrypt 'content' to 'data' for receiver/group members
    //
    if (receiver.isGroup) {
      // group message
      List<ID> members = await facebook!.getMembers(receiver);
      assert(members.isNotEmpty, 'group not ready: $receiver');
      // a station will never send group message, so here must be a client;
      // the client messenger should check the group's meta & members before encrypting,
      // so we can trust that the group members MUST exist here.
      sMsg = await instantPacker.encryptMessage(iMsg, password!, members: members);
    } else {
      // personal message (or split group message)
      sMsg = await instantPacker.encryptMessage(iMsg, password!);
    }
    if (sMsg == null) {
      // public key for encryption not found
      assert(false, 'failed to encrypt message: ${iMsg.sender} => $receiver, ${iMsg['group']}');
      // TODO: suspend this message for waiting receiver's meta
      return null;
    }

    // NOTICE: copy content type to envelope
    //         this help the intermediate nodes to recognize message type
    sMsg.envelope.type = iMsg.content.type;

    // OK
    return sMsg;
  }

  @override
  Future<ReliableMessage?> signMessage(SecureMessage sMsg) async {
    assert(sMsg.data.isNotEmpty, 'message data cannot be empty: $sMsg');
    // sign 'data' by sender
    return await securePacker.signMessage(sMsg);
  }

  @override
  Future<Uint8List?> serializeMessage(ReliableMessage rMsg) async =>
      UTF8.encode(JSON.encode(rMsg.toMap()));

  //
  //  Data -> ReliableMessage -> SecureMessage -> InstantMessage
  //

  @override
  Future<ReliableMessage?> deserializeMessage(Uint8List data) async {
    String? json = UTF8.decode(data);
    if (json == null) {
      assert(false, 'message data error: ${data.length}');
      return null;
    }
    Object? dict = JSON.decode(json);
    // TODO: translate short keys
    //       'S' -> 'sender'
    //       'R' -> 'receiver'
    //       'W' -> 'time'
    //       'T' -> 'type'
    //       'G' -> 'group'
    //       ------------------
    //       'D' -> 'data'
    //       'V' -> 'signature'
    //       'K' -> 'key', 'keys'
    //       ------------------
    //       'M' -> 'meta'
    //       'P' -> 'visa'
    return ReliableMessage.parse(dict);
  }

  ///  Check meta & visa
  ///
  /// @param rMsg - received message
  /// @return false on error
  // protected
  Future<bool> checkAttachments(ReliableMessage rMsg) async {
    ID sender = rMsg.sender;
    // [Meta Protocol]
    Meta? meta = MessageHelper.getMeta(rMsg);
    if (meta != null) {
      await facebook?.saveMeta(meta, sender);
    }
    // [Visa Protocol]
    Visa? visa = MessageHelper.getVisa(rMsg);
    if (visa != null) {
      await facebook?.saveDocument(visa);
    }
    //
    //  TODO: check [Visa Protocol] before calling this
    //        make sure the sender's meta(visa) exists
    //        (do it by application)
    //
    return true;
  }

  @override
  Future<SecureMessage?> verifyMessage(ReliableMessage rMsg) async {
    // make sure sender's meta exists before verifying message
    if (await checkAttachments(rMsg)) {} else {
      return null;
    }

    assert(rMsg.signature.isNotEmpty, 'message signature cannot be empty: $rMsg');
    // verify 'data' with 'signature'
    return await reliablePacker.verifyMessage(rMsg);
  }

  @override
  Future<InstantMessage?> decryptMessage(SecureMessage sMsg) async {
    // TODO: check receiver before calling this, make sure you are the receiver,
    //       or you are a member of the group when this is a group message,
    //       so that you will have a private key (decrypt key) to decrypt it.
    ID receiver = sMsg.receiver;
    User? user = await facebook?.selectLocalUser(receiver);
    if (user == null) {
      // not for you?
      throw Exception('receiver error: $receiver, from ${sMsg.sender}, ${sMsg.group}');
    }
    assert(sMsg.data.isNotEmpty, 'message data empty: '
        '${sMsg.sender} => ${sMsg.receiver}, ${sMsg.group}');
    // decrypt 'data' to 'content'
    return await securePacker.decryptMessage(sMsg, user.identifier);

    // TODO: check top-secret message
    //       (do it by application)
  }

}
