import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    if (input.config.code.linkModePreference == LinkModePreference.static) {
      throw UnsupportedError('LinkModePreference.static is not supported.');
    }

    final directory = input.packageRoot;

    final targetOS = input.config.code.targetOS;
    final targetArchitecture = input.config.code.targetArchitecture;

    final uri = directory.resolve('build/llama_cpp_flutter_hook_ran.txt');
    final file = await File(uri.toFilePath()).create(recursive: true);

    await file.writeAsString(
      'hook ran at ${DateTime.now().toUtc().toIso8601String()} '
      'for ${input.packageName} (target $targetOS-$targetArchitecture)\n',
      mode: FileMode.write,
      flush: true,
    );
  });
}
