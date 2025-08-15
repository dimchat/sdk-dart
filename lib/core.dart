/// DIM-SDK
/// ~~~~~~~
/// Decentralized Instant Messaging Software Development Kit
library dimsdk;

export 'src/core/delegate.dart';
export 'src/core/barrack.dart';      // require 'mkm/*'
export 'src/core/compress_keys.dart';
export 'src/core/compressor.dart';
export 'src/core/packer.dart';
export 'src/core/processor.dart';
export 'src/core/transceiver.dart';  // require 'mkm/*'

export 'src/facebook.dart';   // require 'archivist.dart', 'core/*', 'mkm/*'
export 'src/messenger.dart';  // require 'core/*'
export 'src/twins.dart';      // require 'facebook.dart', 'messenger.dart'
export 'src/packer.dart';     // require 'twins.dart', 'msg/*'
export 'src/processor.dart';  // require 'twins.dart', 'dkd/proc.dart'
