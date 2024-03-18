/* license: https://mit-license.org
 *
 *  File System
 *
 *                               Written in 2024 by Moky <albert.moky@gmail.com>
 *
 * =============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2024 Albert Moky
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
import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as lib;


/// The modes in
/// which a [File] can be opened.
class FileMode {
  /// The mode for opening a file only for reading.
  static const read = FileMode._internal(0);

  /// Mode for opening a file for reading and writing. The file is
  /// overwritten if it already exists. The file is created if it does not
  /// already exist.
  static const write = FileMode._internal(1);

  /// Mode for opening a file for reading and writing to the
  /// end of it. The file is created if it does not already exist.
  static const append = FileMode._internal(2);

  /// Mode for opening a file for writing *only*. The file is
  /// overwritten if it already exists. The file is created if it does not
  /// already exist.
  static const writeOnly = FileMode._internal(3);

  /// Mode for opening a file for writing *only* to the
  /// end of it. The file is created if it does not already exist.
  static const writeOnlyAppend = FileMode._internal(4);

  final int value;

  const FileMode._internal(this.value);
}


/// Base class for all IO related exceptions.
abstract class IOException implements Exception {

  @override
  String toString() => "IOException";

}


/// An [Exception] holding information about an error from the
/// operating system.
class OSError implements Exception {
  /// Constant used to indicate that no OS error code is available.
  static const int noErrorCode = -1;

  /// Error message supplied by the operating system. This will be empty if no
  /// message is associated with the error.
  final String message;

  /// Error code supplied by the operating system.
  final int errorCode;

  /// Creates an OSError object from a message and an errorCode.
  const OSError([this.message = "", this.errorCode = noErrorCode]);

  /// Converts an OSError object to a string representation.
  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write("OS Error");
    if (message.isNotEmpty) {
      sb
        ..write(": ")
        ..write(message);
      if (errorCode != noErrorCode) {
        sb
          ..write(", errno = ")
          ..write(errorCode.toString());
      }
    } else if (errorCode != noErrorCode) {
      sb
        ..write(": errno = ")
        ..write(errorCode.toString());
    }
    return sb.toString();
  }
}


/// Exception thrown when a file operation fails.
class FileSystemException implements IOException {
  /// Message describing the error.
  final String message;

  /// The file system path on which the error occurred.
  final String? path;

  /// The underlying OS error.
  final OSError? osError;

  /// Creates a new file system exception with optional parts.
  const FileSystemException([this.message = "", this.path = "", this.osError]);

  @override
  String toString() {
    Type clazz = runtimeType;
    return '<$clazz path="$path" />';
  }

}


/// The common superclass of [File], [Directory], and [Link].
abstract class FileSystemEntity {
  FileSystemEntity(this.path);

  final String path;

  /// A [Uri] representing the file system entity's location.
  Uri get uri => Uri.file(path);

  /// Checks whether the file system entity with this path exists.
  Future<bool> exists();

  /// Deletes this [FileSystemEntity].
  Future<FileSystemEntity> delete({bool recursive = false});

  /// The parent directory of this entity.
  Directory get parent => Directory(lib.dirname(path));

}


/// A reference to a file on the file system.
class File extends FileSystemEntity {
  File(super.path);

  /// Create a [File] object from a URI.
  factory File.fromUri(Uri uri) => File(uri.toFilePath());

  /// Creates the file.
  Future<File> create({bool recursive = false, bool exclusive = false}) async {
    createSync(recursive: recursive, exclusive: exclusive);
    return this;
  }

  /// Synchronously creates the file.
  void createSync({bool recursive = false, bool exclusive = false}) {
    // TODO: implement create
  }

  /// The length of the file.
  Future<int> length() async => readAsBytesSync().length;

  /// Reads the entire file contents as a list of bytes.
  Future<Uint8List> readAsBytes() async => readAsBytesSync();

  /// Synchronously reads the entire file contents as a list of bytes.
  Uint8List readAsBytesSync() {
    Uint8List? data = _fileContents[path];
    if (data == null) {
      throw FileSystemException('File not found', path);
    }
    return data;
  }

  /// Reads the entire file contents as a string using the given
  /// [Encoding].
  Future<String> readAsString({Encoding encoding = utf8}) async =>
      readAsStringSync(encoding: encoding);

  /// Synchronously reads the entire file contents as a string using the
  /// given [Encoding].
  String readAsStringSync({Encoding encoding = utf8}) =>
      encoding.decode(readAsBytesSync());

  /// Reads the entire file contents as lines of text using the given
  /// [Encoding].
  Future<List<String>> readAsLines({Encoding encoding = utf8}) async =>
      readAsLines(encoding: encoding);

  /// Synchronously reads the entire file contents as lines of text
  /// using the given [Encoding].
  List<String> readAsLinesSync({Encoding encoding = utf8}) =>
      LineSplitter().convert(readAsStringSync(encoding: encoding));

  /// Writes a list of bytes to a file.
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) async {
    writeAsBytesSync(bytes, mode: mode, flush: flush);
    return this;
  }

  /// Synchronously writes a list of bytes to a file.
  void writeAsBytesSync(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) =>
      _fileContents[path] = Uint8List.fromList(bytes);

  /// Writes a string to a file.
  Future<File> writeAsString(String contents,
      {FileMode mode = FileMode.write,
        Encoding encoding = utf8,
        bool flush = false}) async {
    writeAsStringSync(contents, mode: mode, encoding: encoding, flush: flush);
    return this;
  }

  /// Synchronously writes a string to a file.
  void writeAsStringSync(String contents,
      {FileMode mode = FileMode.write,
        Encoding encoding = utf8,
        bool flush = false}) =>
      writeAsBytesSync(encoding.encode(contents), mode: mode, flush: flush);

  @override
  Future<bool> exists() async => _fileContents.containsKey(path);

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    _fileContents.remove(path);
    return this;
  }

}


/// A reference to a directory (or _folder_) on the file system.
class Directory extends FileSystemEntity {
  Directory(super.path);

  /// Create a [Directory] from a URI.
  factory Directory.fromUri(Uri uri) => Directory(uri.toFilePath());

  /// Creates the directory if it doesn't exist.
  Future<Directory> create({bool recursive = false}) async {
    createSync(recursive: recursive);
    return this;
  }

  /// Synchronously creates the directory if it doesn't exist.
  void createSync({bool recursive = false}) {
    // TODO: implement create
  }

  @override
  Future<bool> exists() async {
    // TODO: implement exists
    return true;
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    // TODO: implement delete
    return this;
  }

}


Map<String, Uint8List> _fileContents = {};  // path => data
