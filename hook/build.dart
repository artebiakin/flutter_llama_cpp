import 'dart:io';

import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    // Build native library using the native_toolchain_c package
    final cbuilder = CBuilder.library(
      name: 'llama_flutter',
      assetName: 'llama_flutter',
      sources: [
        'src/flutter_llama_cpp_stub.c',  // Use stub version for now
      ],
      includes: [
        'src/',
      ],
    );

    await cbuilder.run(
      input: input,
      output: output,
      logger: null,  // Use default logger
    );

    // Log build completion
    final packageRoot = input.packageRoot;
    final logFile = File.fromUri(packageRoot.resolve('build/llama_cpp_flutter_hook_ran.txt'));
    await logFile.create(recursive: true);
    await logFile.writeAsString(
      'Native build completed at ${DateTime.now().toUtc().toIso8601String()} '
      'for ${input.packageName}\n',
      mode: FileMode.write,
      flush: true,
    );
  });
}
