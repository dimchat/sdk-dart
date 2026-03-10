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
import 'package:dimp/dkd.dart';


// -----------------------------------------------------------------------------
//  ContentProcessor (CPU: Content Processing Unit)
// -----------------------------------------------------------------------------

/// Content processing unit (CPU) - core interface for handling message content.
///
/// Defines the standard interface for processing different types of message content
/// (e.g., text, commands, files, ...) and generating response content.
///
/// Each implementation handles a specific content type or command, following the
/// single responsibility principle.
abstract interface class ContentProcessor {

  /// Processes incoming message content and generates response contents.
  ///
  /// Parameters:
  /// - [content] : Incoming message content to process (e.g., text, command, file, ...)
  /// - [rMsg]    : Original reliable message (provides context: sender, receiver, envelope)
  ///
  /// Returns: List of response content items (empty list if no response is needed)
  Future<List<Content>> processContent(Content content, ReliableMessage rMsg);

}


// -----------------------------------------------------------------------------
//  ContentProcessorCreator (CPU Creator)
// -----------------------------------------------------------------------------

/// Creator interface for instantiating content/command processors.
///
/// Implements the Factory Method pattern to create specific [ContentProcessor]
/// instances based on content type or command name, decoupling creation logic
/// from usage logic.
abstract interface class ContentProcessorCreator {

  /// Creates a content processor for a specific content type.
  ///
  /// Parameters:
  /// - [msgType] : Content type identifier (e.g., "text", "command", "file", ...)
  ///
  /// Returns: Specific [ContentProcessor] instance (null if type is unsupported)
  ContentProcessor? createContentProcessor(String msgType);

  /// Creates a command processor for a specific content type and command name.
  ///
  /// Parameters:
  /// - [msgType] : Content type identifier (typically "command" for command content)
  /// - [cmdName] : Command name (e.g., "meta", "documents", "group", ...)
  ///
  /// Returns: Specific command processor instance (null if command is unsupported)
  ContentProcessor? createCommandProcessor(String msgType, String cmdName);

}


// -----------------------------------------------------------------------------
//  ContentProcessorFactory (CPU Factory)
// -----------------------------------------------------------------------------

/// Factory interface for retrieving cached content/command processors.
///
/// Manages a cache of [ContentProcessor] instances to avoid repeated creation,
/// and provides unified access to processors for different content types/commands.
abstract interface class ContentProcessorFactory {

  /// Retrieves the appropriate processor for a given content instance.
  ///
  /// For command content:
  /// 1. First tries to get a processor for the specific command name
  /// 2. Falls back to group command processor (if applicable)
  /// 3. Finally uses the default content processor for the content type
  ///
  /// Parameters:
  /// - [content] : Content instance to get processor for (can be regular content or command)
  ///
  /// Returns: Matching [ContentProcessor] instance (null if no processor found)
  ContentProcessor? getContentProcessor(Content content);

  /// Retrieves a content processor for a specific content type.
  ///
  /// Parameters:
  /// - [msgType] : Content type identifier (e.g., "text", "command", "file", ...)
  ///
  /// Returns: [ContentProcessor] instance for the type (null if type is unsupported)
  ContentProcessor? getContentProcessorForType(String msgType);

}
