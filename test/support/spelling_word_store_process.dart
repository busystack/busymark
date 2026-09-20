import 'dart:io';

import 'package:busymark/src/spellcheck/spelling_word_store.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    stderr.writeln('usage: spelling_word_store_process.dart PATH WORD');
    exitCode = 64;
    return;
  }
  await SpellingWordStore(
    filePath: arguments[0],
    projectStore: true,
  ).addWord('en-US', arguments[1]);
}
