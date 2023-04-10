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
import 'facebook.dart';
import 'messenger.dart';

class MessagePacker extends TwinsHelper implements Packer {
  MessagePacker(super.facebook, super.messenger);

  @override
  Future<ID?> getOvertGroup(Content content) async {
    ID? group = content.group;
    if (group == null) {
      return null;
    }
    if (group.isBroadcast) {
      // broadcast message is always overt
      return group;
    }
    if (content is Command) {
      // group command should be sent to each member directly, so
      // don't expose group ID
      return null;
    }
    return group;
  }

  //
  //  InstantMessage -> SecureMessage -> ReliableMessage -> Data
  //

  @override
  Future<SecureMessage> encryptMessage(InstantMessage iMsg) async {
    Messenger transceiver = messenger!;
    // check message delegate
    iMsg.delegate ??= transceiver;

    ID sender = iMsg.sender;
    ID receiver = iMsg.receiver;
    // if 'group' exists and the 'receiver' is a group ID,
    // they must be equal

    // NOTICE: while sending group message, don't split it before encrypting.
    //         this means you could set group ID into message content, but
    //         keep the "receiver" to be the group ID;
    //         after encrypted (and signed), you could split the message
    //         with group members before sending out, or just send it directly
    //         to the group assistant to let it split messages for you!
    //    BUT,
    //         if you don't want to share the symmetric key with other members,
    //         you could split it (set group ID into message content and
    //         set contact ID to the "receiver") before encrypting, this usually
    //         for sending group command to assistant bot, which should not
    //         share the symmetric key (group msg key) with other members.

    // 1. get symmetric key
    ID? group = await transceiver.getOvertGroup(iMsg.content);
    SymmetricKey? password;
    if (group == null) {
      // personal message or (group) command
      password = await transceiver.getCipherKey(sender, receiver, generate: true);
      assert(password != null, 'failed to get msg key: $sender -> $receiver');
    } else {
      // group message (excludes group command)
      password = await transceiver.getCipherKey(sender, group, generate: true);
      assert(password != null, 'failed to get group msg key: $sender -> $group');
    }

    // 2. encrypt 'content' to 'data' for receiver/group members
    SecureMessage? sMsg;
    if (receiver.isGroup) {
      // group message
      Group? grp = facebook?.getGroup(receiver);
      // a station will never send group message, so here must be a client;
      // and the client messenger should check the group's meta & members
      // before encrypting message, so we can trust that the group can be
      // created and its members MUST exist here.
      assert(grp != null, 'group not ready: $receiver');
      List<ID> members = await grp!.members;
      assert(members.isNotEmpty, 'group members not found: $receiver');
      sMsg = await iMsg.encrypt(password!, members: members);
    } else {
      // personal message (or split group message)
      sMsg = await iMsg.encrypt(password!);
    }
    if (sMsg == null) {
      // public key for encryption not found
      // TODO: suspend this message for waiting receiver's meta
      throw Exception('failed to encrypt message: $iMsg');
    }

    // overt group ID
    if (group != null && group != receiver) {
      // NOTICE: this help the receiver knows the group ID
      //         when the group message separated to multi-messages,
      //         if don't want the others know you are the group members,
      //         remove it.
      sMsg.envelope.group = group;
    }

    // NOTICE: copy content type to envelope
    //         this help the intermediate nodes to recognize message type
    sMsg.envelope.type = iMsg.content.type;

    // OK
    return sMsg;
  }

  @override
  Future<ReliableMessage> signMessage(SecureMessage sMsg) async {
    // check message delegate
    sMsg.delegate ??= messenger;
    // sign 'data' by sender
    return await sMsg.sign();
  }

  @override
  Future<Uint8List> serializeMessage(ReliableMessage rMsg) async
  => UTF8.encode(JSON.encode(rMsg));

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

  @override
  Future<SecureMessage?> verifyMessage(ReliableMessage rMsg) async {
    // TODO: make sure meta exists before verifying message
    Facebook barrack = facebook!;
    ID sender = rMsg.sender;
    // [Meta Protocol]
    Meta? meta = rMsg.meta;
    if (meta != null) {
      await barrack.saveMeta(meta, sender);
    }
    // [Visa Protocol]
    Visa? visa = rMsg.visa;
    if (visa != null) {
      await barrack.saveDocument(visa);
    }
    // check message delegate
    rMsg.delegate ??= messenger;
    //
    //  TODO: check [Visa Protocol] before calling this
    //        make sure the sender's meta(visa) exists
    //        (do in by application)
    //

    assert((await rMsg.signature).isNotEmpty, 'message signature cannot be empty');
    // verify 'data' with 'signature'
    return rMsg.verify();
  }

  @override
  Future<InstantMessage?> decryptMessage(SecureMessage sMsg) async {
    // TODO: make sure private key (decrypt key) exists before decrypting message
    Facebook barrack = facebook!;
    ID receiver = sMsg.receiver;
    User? user = await barrack.selectLocalUser(receiver);
    SecureMessage? trimmed;
    if (user == null) {
      // local users not match
      trimmed = null;
    } else if (receiver.isGroup) {
      // trim group message
      trimmed = sMsg.trim(user.identifier);
    } else {
      trimmed = sMsg;
    }
    if (trimmed == null) {
      // not for you?
      throw Exception('receiver error: $sMsg');
    }
    // check message delegate
    sMsg.delegate ??= messenger;
    //
    //  NOTICE: make sure the receiver is YOU!
    //          which means the receiver's private key exists;
    //          if the receiver is a group ID, split it first
    //

    assert((await sMsg.data).isNotEmpty, 'message data cannot be empty');
    // decrypt 'data' to 'content'
    return sMsg.decrypt();

    // TODO: check top-secret message
    //       (do it by application)
  }

}
