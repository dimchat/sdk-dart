/* license: https://mit-license.org
 *
 *  Dao-Ke-Dao: Universal Message Module
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
import 'package:dimp/dkd.dart';
import 'package:dimp/mkm.dart';
import 'package:dimp/plugins.dart';

/// Message GeneralFactory
/// ~~~~~~~~~~~~~~~~~~~~~~
class MessageGeneralFactory implements GeneralMessageHelper,
                                       ContentHelper, EnvelopeHelper,
                                       InstantMessageHelper, SecureMessageHelper, ReliableMessageHelper {

  final Map<String, ContentFactory> _contentFactories = {};

  EnvelopeFactory?        _envelopeFactory;
  InstantMessageFactory?  _instantMessageFactory;
  SecureMessageFactory?   _secureMessageFactory;
  ReliableMessageFactory? _reliableMessageFactory;

  @override
  String? getContentType(Map content, [String? defaultValue]) {
    return Converter.getString(content['type'], defaultValue);
  }

  //
  //  Content
  //

  @override
  void setContentFactory(String msgType, ContentFactory factory) {
    _contentFactories[msgType] = factory;
  }

  @override
  ContentFactory? getContentFactory(String msgType) {
    return _contentFactories[msgType];
  }

  @override
  Content? parseContent(Object? content) {
    if (content == null) {
      return null;
    } else if (content is Content) {
      return content;
    }
    Map? info = Wrapper.getMap(content);
    if (info == null) {
      assert(false, 'content error: $content');
      return null;
    }
    // get factory by content type
    String? type = getContentType(info);
    assert(type != null, 'content error: $content');
    ContentFactory? factory = type == null ? null : getContentFactory(type);
    if (factory == null) {
      // unknown content type, get default content factory
      factory = getContentFactory('*');  // unknown
      assert(factory != null, 'default content factory not found');
    }
    return factory?.parseContent(info);
  }

  //
  //  Envelope
  //

  @override
  void setEnvelopeFactory(EnvelopeFactory factory) {
    _envelopeFactory = factory;
  }

  @override
  EnvelopeFactory? getEnvelopeFactory() {
    return _envelopeFactory;
  }

  @override
  Envelope createEnvelope({required ID sender, required ID receiver, DateTime? time}) {
    EnvelopeFactory? factory = getEnvelopeFactory();
    assert(factory != null, 'envelope factory not ready');
    return factory!.createEnvelope(sender: sender, receiver: receiver, time: time);
  }

  @override
  Envelope? parseEnvelope(Object? env) {
    if (env == null) {
      return null;
    } else if (env is Envelope) {
      return env;
    }
    Map? info = Wrapper.getMap(env);
    if (info == null) {
      assert(false, 'envelope error: $env');
      return null;
    }
    EnvelopeFactory? factory = getEnvelopeFactory();
    assert(factory != null, 'envelope factory not ready');
    return factory?.parseEnvelope(info);
  }

  //
  //  InstantMessage
  //

  @override
  void setInstantMessageFactory(InstantMessageFactory factory) {
    _instantMessageFactory = factory;
  }

  @override
  InstantMessageFactory? getInstantMessageFactory() {
    return _instantMessageFactory;
  }

  @override
  InstantMessage createInstantMessage(Envelope head, Content body) {
    InstantMessageFactory? factory = getInstantMessageFactory();
    assert(factory != null, 'instant message factory not ready');
    return factory!.createInstantMessage(head, body);
  }

  @override
  InstantMessage? parseInstantMessage(Object? msg) {
    if (msg == null) {
      return null;
    } else if (msg is InstantMessage) {
      return msg;
    }
    Map? info = Wrapper.getMap(msg);
    if (info == null) {
      assert(false, 'instant message error: $msg');
      return null;
    }
    InstantMessageFactory? factory = getInstantMessageFactory();
    assert(factory != null, 'instant message factory not ready');
    return factory?.parseInstantMessage(info);
  }

  @override
  int generateSerialNumber(String? msgType, DateTime? now) {
    InstantMessageFactory? factory = getInstantMessageFactory();
    assert(factory != null, 'instant message factory not ready');
    return factory!.generateSerialNumber(msgType, now);
  }

  //
  //  SecureMessage
  //

  @override
  void setSecureMessageFactory(SecureMessageFactory factory) {
    _secureMessageFactory = factory;
  }

  @override
  SecureMessageFactory? getSecureMessageFactory() {
    return _secureMessageFactory;
  }

  @override
  SecureMessage? parseSecureMessage(Object? msg) {
    if (msg == null) {
      return null;
    } else if (msg is SecureMessage) {
      return msg;
    }
    Map? info = Wrapper.getMap(msg);
    if (info == null) {
      assert(false, 'secure message error: $msg');
      return null;
    }
    SecureMessageFactory? factory = getSecureMessageFactory();
    assert(factory != null, 'secure message factory not ready');
    return factory?.parseSecureMessage(info);
  }

  //
  //  ReliableMessage
  //

  @override
  void setReliableMessageFactory(ReliableMessageFactory factory) {
    _reliableMessageFactory = factory;
  }

  @override
  ReliableMessageFactory? getReliableMessageFactory() {
    return _reliableMessageFactory;
  }

  @override
  ReliableMessage? parseReliableMessage(Object? msg) {
    if (msg == null) {
      return null;
    } else if (msg is ReliableMessage) {
      return msg;
    }
    Map? info = Wrapper.getMap(msg);
    if (info == null) {
      assert(false, 'reliable message error: $msg');
      return null;
    }
    ReliableMessageFactory? factory = getReliableMessageFactory();
    assert(factory != null, 'reliable message factory not ready');
    return factory?.parseReliableMessage(info);
  }

}
