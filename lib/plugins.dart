/// DIMP
/// ~~~~
/// Decentralized Instant Message Plugins
library dimsdk;

export 'package:dimp/plugins.dart';

export 'src/dkd/cmd_fact.dart';     // Command factories
export 'src/msg/factory.dart';      // Message factory

export 'src/plugins/crypto.dart';
export 'src/plugins/format.dart';
export 'src/plugins/account.dart';
export 'src/plugins/message.dart';
export 'src/plugins/command.dart';
export 'src/plugins/loader.dart';   // require 'dkd/cmd_fact.dart', 'msg/factory.dart'
