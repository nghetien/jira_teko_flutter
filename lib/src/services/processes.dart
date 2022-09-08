import 'dart:io';

abstract class ProcessHelper {
  Future<String> findFileBy({required String issue});

  Future<ProcessResult> runTestWith(
      {required String path, required String pathFileExportResultTest});

  Iterable<String> getPaths(String pathFile);
}

class WindowsProcessHelper implements ProcessHelper {
  @override
  Future<String> findFileBy({required String issue}) async {
    final findFile = await Process.run(
      "findstr /s /m /p $issue *_test.dart*",
      [],
      runInShell: true,
    );

    return findFile.stdout;
  }

  @override
  Future<ProcessResult> runTestWith({
    required String path,
    required String pathFileExportResultTest,
  }) =>
      Process.run(
        'flutter test $path --reporter json > $pathFileExportResultTest',
        [],
        runInShell: true,
      );

  @override
  Iterable<String> getPaths(String pathFile) {
    return pathFile.trim().split('\r\n');
  }
}

class MacOSProcessHelper implements ProcessHelper {
  @override
  Future<String> findFileBy({required String issue}) async {
    final findFile = await Process.run(
      "/bin/zsh",
      [
        '-c',
        "find . -name '*_test.dart*' -print0 | xargs -0 grep -l '$issue'",
      ],
    );

    return findFile.stdout;
  }

  @override
  Future<ProcessResult> runTestWith({
    required String path,
    required String pathFileExportResultTest,
  }) =>
      Process.run(
        '/bin/zsh',
        [
          '-c',
          'flutter test $path --reporter json > $pathFileExportResultTest',
        ],
      );

  @override
  Iterable<String> getPaths(String pathFile) {
    final RegExp pathRegex = RegExp(r'.\/(.*)\.dart');

    return pathRegex.allMatches(pathFile.trim()).map((e) => "./${e.group(1)}.dart");
  }
}
