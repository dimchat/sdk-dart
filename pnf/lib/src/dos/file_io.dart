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
import 'dart:io';
import 'dart:typed_data';


/// Base class for all IO related exceptions.
export 'dart:io' show IOException;

/// An [Exception] holding information about an error from the
/// operating system.
export 'dart:io' show OSError;

/// Exception thrown when a file operation fails.
export 'dart:io' show FileSystemException;


/// The modes in which a [File] can be opened.
export 'dart:io' show FileMode;


/// The common superclass of [File], [Directory], and [Link].
///
/// [FileSystemEntity] objects are returned from directory listing
/// operations. To determine whether a [FileSystemEntity] is a [File], a
/// [Directory], or a [Link] perform a type check:
/// ```dart
/// if (entity is File) (entity as File).readAsStringSync();
/// ```
/// You can also use the [type] or [typeSync] methods to determine
/// the type of a file system object.
///
/// Most methods in this class exist both in synchronous and asynchronous
/// versions, for example, [exists] and [existsSync].
/// Unless you have a specific reason for using the synchronous version
/// of a method, prefer the asynchronous version to avoid blocking your program.
///
/// Here's the exists method in action:
/// ```dart
/// var isThere = await entity.exists();
/// print(isThere ? 'exists' : 'nonexistent');
/// ```
///
/// ## Other resources
///
/// * The [Files and directories](https://dart.dev/guides/libraries/library-tour#files-and-directories)
///   section of the library tour.
///
/// * [Write Command-Line Apps](https://dart.dev/tutorials/server/cmdline),
///   a tutorial about writing command-line apps, includes information about
///   files and directories.
export 'dart:io' show FileSystemEntity;


/// A reference to a file on the file system.
///
/// A `File` holds a [path] on which operations can be performed.
/// You can get the parent directory of the file using [parent],
/// a property inherited from [FileSystemEntity].
///
/// Create a new `File` object with a pathname to access the specified file on the
/// file system from your program.
/// ```dart
/// var myFile = File('file.txt');
/// ```
/// The `File` class contains methods for manipulating files and their contents.
/// Using methods in this class, you can open and close files, read to and write
/// from them, create and delete them, and check for their existence.
///
/// When reading or writing a file, you can use streams (with [openRead]),
/// random access operations (with [open]),
/// or convenience methods such as [readAsString],
///
/// Most methods in this class occur in synchronous and asynchronous pairs,
/// for example, [readAsString] and [readAsStringSync].
/// Unless you have a specific reason for using the synchronous version
/// of a method, prefer the asynchronous version to avoid blocking your program.
///
/// ## If path is a link
///
/// If [path] is a symbolic link, rather than a file,
/// then the methods of `File` operate on the ultimate target of the
/// link, except for [delete] and [deleteSync], which operate on
/// the link.
///
/// ## Read from a file
///
/// The following code sample reads the entire contents from a file as a string
/// using the asynchronous [readAsString] method:
/// ```dart
/// import 'dart:async';
/// import 'dart:io';
///
/// void main() {
///   File('file.txt').readAsString().then((String contents) {
///     print(contents);
///   });
/// }
/// ```
/// A more flexible and useful way to read a file is with a [Stream].
/// Open the file with [openRead], which returns a stream that
/// provides the data in the file as chunks of bytes.
/// Read the stream to process the file contents when available.
/// You can use various transformers in succession to manipulate the
/// file content into the required format, or to prepare it for output.
///
/// You might want to use a stream to read large files,
/// to manipulate the data with transformers,
/// or for compatibility with another API, such as [WebSocket]s.
/// ```dart
/// import 'dart:io';
/// import 'dart:convert';
/// import 'dart:async';
///
/// void main() async {
///   final file = File('file.txt');
///   Stream<String> lines = file.openRead()
///     .transform(utf8.decoder)       // Decode bytes to UTF-8.
///     .transform(LineSplitter());    // Convert stream to individual lines.
///   try {
///     await for (var line in lines) {
///       print('$line: ${line.length} characters');
///     }
///     print('File is now closed.');
///   } catch (e) {
///     print('Error: $e');
///   }
/// }
/// ```
/// ## Write to a file
///
/// To write a string to a file, use the [writeAsString] method:
/// ```dart
/// import 'dart:io';
///
/// void main() async {
///   final filename = 'file.txt';
///   var file = await File(filename).writeAsString('some content');
///   // Do something with the file.
/// }
/// ```
/// You can also write to a file using a [Stream]. Open the file with
/// [openWrite], which returns an [IOSink] to which you can write data.
/// Be sure to close the sink with the [IOSink.close] method.
/// ```dart
/// import 'dart:io';
///
/// void main() {
///   var file = File('file.txt');
///   var sink = file.openWrite();
///   sink.write('FILE ACCESSED ${DateTime.now()}\n');
///
///   // Close the IOSink to free system resources.
///   sink.close();
/// }
/// ```
/// ## The use of asynchronous methods
///
/// To avoid unintentional blocking of the program,
/// several methods are asynchronous and return a [Future]. For example,
/// the [length] method, which gets the length of a file, returns a [Future].
/// Wait for the future to get the result when it's ready.
/// ```dart
/// import 'dart:io';
///
/// void main() async {
///   final file = File('file.txt');
///
///   var length = await file.length();
///   print(length);
/// }
/// ```
/// In addition to length, the [exists], [lastModified], [stat], and
/// other methods, are asynchronous.
///
/// ## Other resources
///
/// * The [Files and directories](https://dart.dev/guides/libraries/library-tour#files-and-directories)
///   section of the library tour.
///
/// * [Write Command-Line Apps](https://dart.dev/tutorials/server/cmdline),
///   a tutorial about writing command-line apps, includes information about
///   files and directories.
export 'dart:io' show File;


/// A reference to a directory (or _folder_) on the file system.
///
/// A [Directory] is an object holding a [path] on which operations can
/// be performed. The path to the directory can be [absolute] or relative.
/// It allows access to the [parent] directory,
/// since it is a [FileSystemEntity].
///
/// The [Directory] also provides static access to the system's temporary
/// file directory, [systemTemp], and the ability to access and change
/// the [current] directory.
///
/// Create a new [Directory] to give access the directory with the specified
/// path:
/// ```dart
/// var myDir = Directory('myDir');
/// ```
/// Most instance methods of [Directory] exist in both synchronous
/// and asynchronous variants, for example, [create] and [createSync].
/// Unless you have a specific reason for using the synchronous version
/// of a method, prefer the asynchronous version to avoid blocking your program.
///
/// ## Create a directory
///
/// The following code sample creates a directory using the [create] method.
/// By setting the `recursive` parameter to true, you can create the
/// named directory and all its necessary parent directories,
/// if they do not already exist.
/// ```dart
/// import 'dart:io';
///
/// void main() async {
///   // Creates dir/ and dir/subdir/.
///   var directory = await Directory('dir/subdir').create(recursive: true);
///   print(directory.path);
/// }
/// ```
/// ## List the entries of a directory
///
/// Use the [list] or [listSync] methods to get the files and directories
/// contained in a directory.
/// Set `recursive` to true to recursively list all subdirectories.
/// Set `followLinks` to true to follow symbolic links.
/// The list method returns a [Stream] of [FileSystemEntity] objects.
/// Listen on the stream to access each object as it is found:
/// ```dart
/// import 'dart:io';
///
/// void main() async {
///   // Get the system temp directory.
///   var systemTempDir = Directory.systemTemp;
///
///   // List directory contents, recursing into sub-directories,
///   // but not following symbolic links.
///   await for (var entity in
///       systemTempDir.list(recursive: true, followLinks: false)) {
///     print(entity.path);
///   }
/// }
/// ```
/// ## The use of asynchronous methods
///
/// I/O operations can block a program for some period of time while it waits for
/// the operation to complete. To avoid this, all
/// methods involving I/O have an asynchronous variant which returns a [Future].
/// This future completes when the I/O operation finishes. While the I/O
/// operation is in progress, the Dart program is not blocked,
/// and can perform other operations.
///
/// For example,
/// the [exists] method, which determines whether the directory exists,
/// returns a boolean value asynchronously using a [Future].
/// ```dart
/// import 'dart:io';
///
/// void main() async {
///   final myDir = Directory('dir');
///   var isThere = await myDir.exists();
///   print(isThere ? 'exists' : 'nonexistent');
/// }
/// ```
///
/// In addition to [exists], the [stat], [rename],
/// and other methods are also asynchronous.
///
/// ## Other resources
///
/// * The [Files and directories](https://dart.dev/guides/libraries/library-tour#files-and-directories)
///   section of the library tour.
///
/// * [Write Command-Line Apps](https://dart.dev/tutorials/server/cmdline),
///   a tutorial about writing command-line apps, includes information about
///   files and directories.
export 'dart:io' show Directory;


//
//  File System Controller
//

abstract interface class FileSystemDelegate {

  /// Checks whether the file system entity with this path exists.
  ///
  /// Returns a `Future<bool>` that completes with the result.
  ///
  /// Since [FileSystemEntity] is abstract, every [FileSystemEntity] object
  /// is actually an instance of one of the subclasses [File],
  /// [Directory], and [Link]. Calling [exists] on an instance of one
  /// of these subclasses checks whether the object exists in the file
  /// system object exists *and* is of the correct type (file, directory,
  /// or link). To check whether a path points to an object on the
  /// file system, regardless of the object's type, use the [type]
  /// static method.
  Future<bool> exists(FileSystemEntity entity);

  /// Deletes this [FileSystemEntity].
  ///
  /// If the [FileSystemEntity] is a directory, and if [recursive] is `false`,
  /// the directory must be empty. Otherwise, if [recursive] is true, the
  /// directory and all sub-directories and files in the directories are
  /// deleted. Links are not followed when deleting recursively. Only the link
  /// is deleted, not its target.
  ///
  /// If [recursive] is true, the [FileSystemEntity] is deleted even if the type
  /// of the [FileSystemEntity] doesn't match the content of the file system.
  /// This behavior allows [delete] to be used to unconditionally delete any file
  /// system object.
  ///
  /// Returns a `Future<FileSystemEntity>` that completes with this
  /// [FileSystemEntity] when the deletion is done. If the [FileSystemEntity]
  /// cannot be deleted, the future completes with an exception.
  Future<FileSystemEntity> delete(FileSystemEntity entity, {bool recursive = false});

  //
  //  File
  //

  /// Creates the file.
  ///
  /// Returns a `Future<File>` that completes with
  /// the file when it has been created.
  ///
  /// If [recursive] is `false`, the default, the file is created only if
  /// all directories in its path already exist. If [recursive] is `true`, any
  /// non-existing parent paths are created first.
  ///
  /// If [exclusive] is `true` and to-be-created file already exists, this
  /// operation completes the future with a [PathExistsException].
  ///
  /// If [exclusive] is `false`, existing files are left untouched by [create].
  /// Calling [create] on an existing file still might fail if there are
  /// restrictive permissions on the file.
  ///
  /// Completes the future with a [FileSystemException] if the operation fails.
  Future<File> createFile(File file, {bool recursive = false, bool exclusive = false});

  /// Reads the entire file contents as a list of bytes.
  ///
  /// Returns a `Future<Uint8List>` that completes with the list of bytes that
  /// is the contents of the file.
  Future<Uint8List> readAsBytes(File file);

  /// Writes a list of bytes to a file.
  ///
  /// Opens the file, writes the list of bytes to it, and closes the file.
  /// Returns a `Future<File>` that completes with this [File] object once
  /// the entire operation has completed.
  ///
  /// By default [writeAsBytes] creates the file for writing and truncates the
  /// file if it already exists. In order to append the bytes to an existing
  /// file, pass [FileMode.append] as the optional mode parameter.
  ///
  /// If the argument [flush] is set to `true`, the data written will be
  /// flushed to the file system before the returned future completes.
  Future<File> writeAsBytes(File file, List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false});

  //
  //  Directory
  //

  /// Creates the directory if it doesn't exist.
  ///
  /// If [recursive] is false, only the last directory in the path is
  /// created. If [recursive] is true, all non-existing path components
  /// are created. If the directory already exists nothing is done.
  ///
  /// Returns a `Future<Directory>` that completes with this
  /// directory once it has been created. If the directory cannot be
  /// created the future completes with an exception.
  Future<Directory> createDirectory(Directory dir, {bool recursive = false});

  /// Lists the sub-directories and files of this [Directory].
  ///
  /// Optionally recurses into sub-directories.
  ///
  /// If [followLinks] is `false`, then any symbolic links found
  /// are reported as [Link] objects, rather than as directories or files,
  /// and are not recursed into.
  ///
  /// If [followLinks] is `true`, then working links are reported as
  /// directories or files, depending on what they point to,
  /// and links to directories are recursed into f [recursive] is `true`.
  ///
  /// Broken links are reported as [Link] objects.
  ///
  /// If a symbolic link makes a loop in the file system, then a recursive
  /// listing will not follow a link twice in the
  /// same recursive descent, but will report it as a [Link]
  /// the second time it is seen.
  ///
  /// The result is a [Stream] of [FileSystemEntity] objects for the
  /// directories, files, and links. The [Stream] will be in an arbitrary
  /// order and does not include the special entries `'.'` and `'..'`.
  Stream<FileSystemEntity> list(Directory dir,
      {bool recursive = false, bool followLinks = true});

}

/// Shared File System
class FileSystem {
  factory FileSystem() => _instance;
  static final FileSystem _instance = FileSystem._internal();
  FileSystem._internal();

  FileSystemDelegate? delegate;

}
