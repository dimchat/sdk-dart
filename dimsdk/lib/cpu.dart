/// DIM-SDK
/// ~~~~~~~
/// Decentralized Instant Messaging Software Development Kit
library dimsdk;

export 'src/dkd/proc.dart';        // CPU interfaces

export 'src/cpu/base.dart';        // require 'dkd/proc.dart'
export 'src/cpu/commands.dart';    // require 'base.dart'
export 'src/cpu/contents.dart';    // require 'base.dart'
export 'src/cpu/customized.dart';  // require 'base.dart'
export 'src/cpu/creator.dart';
