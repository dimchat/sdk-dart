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

import 'package:path/path.dart' as utils;

/// Get parent directory
String _parentOf(String path) => utils.dirname(path);


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

  String get className => 'FileSystemException';

  @override
  String toString() {
    String clazz = className;
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
  Directory get parent => Directory(_parentOf(path));

}


/// A reference to a file on the file system.
class File extends FileSystemEntity {
  File(super.path);

  /// Create a [File] object from a URI.
  factory File.fromUri(Uri uri) => File(uri.toFilePath());

  /// Creates the file.
  Future<File> create({bool recursive = false, bool exclusive = false}) async {
    var dos = FileSystem().delegate;
    if (dos == null) {
      throw FileSystemException('Cannot create file', path);
    }
    // create by delegate
    return await dos.createFile(this, recursive: recursive, exclusive: exclusive);
  }

  /// The length of the file.
  Future<int> length() async {
    Uint8List data = await readAsBytes();
    return data.length;
  }

  /// The last-accessed time of the file.
  Future<DateTime> lastAccessed() async => DateTime.now();

  /// Get the last-modified time of the file.
  Future<DateTime> lastModified() async => DateTime.now();

  /// Reads the entire file contents as a list of bytes.
  Future<Uint8List> readAsBytes() async {
    var dos = FileSystem().delegate;
    if (dos == null) {
      throw FileSystemException('Cannot read file', path);
    }
    return await dos.readAsBytes(this);
  }

  /// Reads the entire file contents as a string using the given
  /// [Encoding].
  Future<String> readAsString({Encoding encoding = utf8}) async =>
      encoding.decode(await readAsBytes());

  /// Reads the entire file contents as lines of text using the given
  /// [Encoding].
  Future<List<String>> readAsLines({Encoding encoding = utf8}) async =>
      LineSplitter().convert(await readAsString(encoding: encoding));

  /// Writes a list of bytes to a file.
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) async {
    var dos = FileSystem().delegate;
    if (dos == null) {
      throw FileSystemException('Cannot write file', path);
    }
    // write by delegate
    return await dos.writeAsBytes(this, bytes, mode: mode, flush: flush);
  }

  /// Writes a string to a file.
  Future<File> writeAsString(String contents,
      {FileMode mode = FileMode.write,
        Encoding encoding = utf8,
        bool flush = false}) async =>
      writeAsBytes(encoding.encode(contents), mode: mode, flush: flush);

  @override
  Future<bool> exists() async {
    var dos = FileSystem().delegate;
    if (dos == null) {
      throw FileSystemException('Cannot check file', path);
    }
    return await dos.exists(this);
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    var dos = FileSystem().delegate;
    if (dos == null) {
      throw FileSystemException('Cannot remove file', path);
    }
    return await dos.delete(this, recursive: recursive);
  }

}


/// A reference to a directory (or _folder_) on the file system.
class Directory extends FileSystemEntity {
  Directory(super.path);

  /// Create a [Directory] from a URI.
  factory Directory.fromUri(Uri uri) => Directory(uri.toFilePath());

  /// Creates the directory if it doesn't exist.
  Future<Directory> create({bool recursive = false}) async {
    var dos = FileSystem().delegate;
    if (dos == null) {
      throw FileSystemException('Cannot create directory', path);
    }
    return await dos.createDirectory(this, recursive: recursive);
  }

  /// Lists the sub-directories and files of this [Directory].
  Stream<FileSystemEntity> list(
      {bool recursive = false, bool followLinks = true}) {
    var dos = FileSystem().delegate;
    if (dos == null) {
      throw FileSystemException('Cannot read directory', path);
    }
    return dos.list(this, recursive: recursive, followLinks: followLinks);
  }

  @override
  Future<bool> exists() async {
    var dos = FileSystem().delegate;
    if (dos == null) {
      throw FileSystemException('Cannot check directory', path);
    }
    return await dos.exists(this);
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    var dos = FileSystem().delegate;
    if (dos == null) {
      throw FileSystemException('Cannot remove directory', path);
    }
    return await dos.delete(this, recursive: recursive);
  }

}


//
//  File System Controller
//

abstract interface class FileSystemDelegate {

  /// Checks whether the file system entity with this path exists.
  Future<bool> exists(FileSystemEntity entity);

  /// Deletes this [FileSystemEntity].
  Future<FileSystemEntity> delete(FileSystemEntity entity, {bool recursive = false});

  //
  //  File
  //

  /// Creates the file.
  Future<File> createFile(File file, {bool recursive = false, bool exclusive = false});

  /// Reads the entire file contents as a list of bytes.
  Future<Uint8List> readAsBytes(File file);

  /// Writes a list of bytes to a file.
  Future<File> writeAsBytes(File file, List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false});

  //
  //  Directory
  //

  /// Creates the directory if it doesn't exist.
  Future<Directory> createDirectory(Directory dir, {bool recursive = false});

  /// Lists the sub-directories and files of this [Directory].
  Stream<FileSystemEntity> list(Directory dir,
      {bool recursive = false, bool followLinks = true});

}

class _FileCache implements FileSystemDelegate {

  final Map<String, Uint8List> _files = {};  // path => data

  @override
  Future<bool> exists(FileSystemEntity entity) async {
    if (entity is Directory) {
      // TODO: check directory in cache
      return true;
    }
    return _files.containsKey(entity.path);
  }

  @override
  Future<FileSystemEntity> delete(FileSystemEntity entity, {bool recursive = false}) async {
    // TODO: if entity is a directory, remove sub entities recursively
    _files.remove(entity.path);
    return entity;
  }

  @override
  Future<File> createFile(File file, {bool recursive = false, bool exclusive = false}) async {
    // TODO: create empty file
    return file;
  }

  @override
  Future<Uint8List> readAsBytes(File file) async {
    Uint8List? data = _files[file.path];
    if (data == null) {
      throw FileSystemException('File not found', file.toString());
    }
    return data;
  }

  @override
  Future<File> writeAsBytes(File file, List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) async {
    _files[file.path] = Uint8List.fromList(bytes);
    return file;
  }

  @override
  Future<Directory> createDirectory(Directory dir, {bool recursive = false}) async {
    // TODO: implement createDirectory
    return dir;
  }

  @override
  Stream<FileSystemEntity> list(Directory dir,
      {bool recursive = false, bool followLinks = true}) {
    // TODO: implement for sub directories
    List<File> items = [];
    _files.forEach((path, data) {
      if (path.length <= dir.path.length) {
      } else if (path.substring(0, dir.path.length) == dir.path) {
        items.add(File(path));
      }
    });
    return Stream.fromIterable(items);
  }

}

/// Shared File System
class FileSystem {
  factory FileSystem() => _instance;
  static final FileSystem _instance = FileSystem._internal();
  FileSystem._internal();

  FileSystemDelegate? delegate = _FileCache();

}
