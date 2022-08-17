import 'dart:convert';
import 'dart:io';

import 'services/services.dart';

class JiraTekoProjectInfo {
  final String scheme;
  final String host;
  final String jiraUserName;
  final String jiraPassword;
  final int projectId;
  final String projectKey;
  final String folder;

  const JiraTekoProjectInfo({
    required this.scheme,
    required this.host,
    required this.jiraUserName,
    required this.jiraPassword,
    required this.projectId,
    required this.projectKey,
    required this.folder,
  });
}

class JiraTekoFlutter {
  static late final JiraTekoProjectInfo _projectInfo;

  static JiraTekoProjectInfo get projectInfo => _projectInfo;

  static void setProjectInfo(JiraTekoProjectInfo info) => _projectInfo = info;

  static const String pathFileExportResultTest = 'test/export_result_test.log';

  static String _pathFileExportAllTest = 'test/export_result_all_test.json';

  static String get pathFileExportAllTest => _pathFileExportAllTest;

  static void setPathFileExportAllTest(String path) => _pathFileExportAllTest = path;

  JiraTekoFlutter({
    required this.issues,
  });

  final List<String> issues;

  static late final String token;

  static late final int parentIdOfFolderTestCase;
  static late final int parentIdOfFolderCycles;
  static late final List<Map<String, dynamic>> listParentFolderTestCase;
  static late final List<Map<String, dynamic>> listParentFolderCycles;
  static final Map<String, int> mapKeyToIdFolderTestCase = {};
  static final Map<String, int> mapKeyToIdFolderCycles = {};
  static final Map<String, int> mapStatusToIdStatus = {};

  String getCommand(String issue) {
    /// TODO add platform MACOS and Linux
    return 'findstr /s /m /p $issue *_test.dart*';
  }

  Map<String, dynamic> findFolder(List<dynamic> children, String nameOfFolderFind) {
    for (Map<String, dynamic> child in children) {
      if (child['name'] == nameOfFolderFind) {
        return child;
      }
    }
    return {};
  }

  Map<String, dynamic> findFolderByName(
    List<dynamic> children,
    String folderName,
  ) {
    final List<String> namesFolder = JiraTekoFlutter.projectInfo.folder
        .split('/')
        .where((element) => element.isNotEmpty)
        .toList();
    List<dynamic> flagChildren = children;
    for (int index = 0; index < namesFolder.length; index++) {
      final String currentName = namesFolder[index];
      final Map<String, dynamic> currentFolder = findFolder(flagChildren, currentName);
      if (currentFolder.isEmpty) {
        return {};
      }
      if (index == namesFolder.length - 1) {
        return currentFolder;
      }
      flagChildren = currentFolder['children'];
    }
    return {} as Map<String, dynamic>;
  }

  /// from folder field in JiraTekoProjectInfo
  /// get parent id of last folder in folder field
  /// return -1 if not found, return id of folder [TESTCASE] if found
  Future<int> getParentIdTestCaseFolder() async {
    final Map<String, dynamic> projectTrees = await JiraTekoTestRunner.getProjectTreesTestcase();
    final Map<String, dynamic> folder = findFolderByName(
      projectTrees['children'],
      JiraTekoFlutter.projectInfo.folder,
    );
    listParentFolderTestCase = folder['children']
        .map<Map<String, dynamic>>(
          (e) => {
            'name': e['name'] as String,
            'id': e['id'] as int,
          },
        )
        .toList();
    if (folder.isEmpty) {
      throw Exception('Can not find folder testcase ${JiraTekoFlutter.projectInfo.folder}');
    }
    return folder['id'];
  }

  /// from folder field in JiraTekoProjectInfo
  /// get parent id of last folder in folder field
  /// return -1 if not found, return id of folder [CYCLES] if found
  Future<int> getParentIdCyclesFolder() async {
    final Map<String, dynamic> projectTrees = await JiraTekoTestRunner.getProjectTreesCycles();
    final Map<String, dynamic> folder = findFolderByName(
      projectTrees['children'],
      JiraTekoFlutter.projectInfo.folder,
    );
    listParentFolderCycles = folder['children']
        .map<Map<String, dynamic>>(
          (e) => {
            'name': e['name'] as String,
            'id': e['id'] as int,
          },
        )
        .toList();
    if (folder.isEmpty) {
      throw Exception('Can not find folder cycles ${JiraTekoFlutter.projectInfo.folder}');
    }
    return folder['id'];
  }

  /// generate token for header authorization
  String generateToken(String jiraUser, String jiraPassword) {
    final String credentials = "$jiraUser:$jiraPassword";
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String encoded = stringToBase64.encode(credentials);
    return encoded;
  }

  Map<String, List<Map<String, dynamic>>> convertMapStringToMapList(Map<String, dynamic> map) {
    Map<String, List<Map<String, dynamic>>> result = {};
    map.forEach((key, value) {
      result[key] = value
          .map<Map<String, dynamic>>((e) => {
                'name': e['name'],
                'status': e['status'],
              })
          .toList();
    });
    return result;
  }

  Future<List<Map<String, dynamic>>> getResultsTestCase(String issue) async {
    final List<Map<String, dynamic>> result = [];
    final List<String> dataLineOfFile = await File(pathFileExportResultTest).readAsLines();
    if (dataLineOfFile[0] ==
        "More than one device connected; please specify a device with the '-d <deviceId>' flag, or use '-d all' to act on all devices.") {
      throw Exception(
        "More than one device connected; please specify a device with the '-d <deviceId>' flag, or use '-d all' to act on all devices.",
      );
    }
    int line = 0;
    while (line < dataLineOfFile.length) {
      final String findTestCase = '^{"test":{"id":[0-9]+,"name":"\\[$issue\\]';
      final regex = RegExp(findTestCase);
      if (regex.hasMatch(dataLineOfFile[line].trim())) {
        final Map<String, dynamic> dataJsonFromLine = json.decode(dataLineOfFile[line]);
        final Map<String, dynamic> resultJsonFromLine = json.decode(dataLineOfFile[line + 1]);
        line += 2;
        result.add({
          'name': dataJsonFromLine['test']['name'],
          'status': resultJsonFromLine['result'] == 'success' ? "Pass" : "Fail",
        });
      } else {
        line += 1;
      }
    }
    return result;
  }

  Future handleStatusTestCase() async {
    final List<dynamic> status = await JiraTekoTestRunner.getStatusTest();
    for (var element in status) {
      mapStatusToIdStatus[element['name']] = element['id'];
    }
  }

  Future run() async {
    token = generateToken(
      projectInfo.jiraUserName,
      projectInfo.jiraPassword,
    );
    parentIdOfFolderTestCase = await getParentIdTestCaseFolder();
    parentIdOfFolderCycles = await getParentIdCyclesFolder();
    await handleStatusTestCase();

    print('=====================================================================================');
    print('*** Run all tests!');
    print('=====================================================================================');

    final Map<String, dynamic> mapIssuesToTestCases = {};
    for (String issue in issues) {
      final ProcessResult findFile = await Process.run(
        getCommand(issue),
        [],
        runInShell: true,
      );
      final String pathFile = findFile.stdout;
      if (pathFile.isEmpty) {
        throw FileSystemException('File not found path issue $issue');
      } else {
        final List<String> paths = pathFile.trim().split('\r\n');
        for (String path in paths) {
          print('path: $path');
          print('run: ${'flutter test $path --reporter json > $pathFileExportResultTest'}');

          await Process.run(
            'flutter test $path --reporter json > $pathFileExportResultTest',
            [],
            runInShell: true,
          );
          final List<Map<String, dynamic>> resultsTestCase = await getResultsTestCase(issue);
          if (mapIssuesToTestCases[issue] == null) {
            mapIssuesToTestCases[issue] = [];
          }
          mapIssuesToTestCases[issue] = [
            ...mapIssuesToTestCases[issue],
            ...resultsTestCase,
          ];
        }
      }
    }

    print('=====================================================================================');
    print('*** Run all tests done!');
    print('=====================================================================================');

    File(pathFileExportResultTest).delete();

    print('*** Handle results!');
    print('=====================================================================================');

    /// Submit all test cast to jira
    final JiraTekoTestHandler jiraTekoTestHandler = JiraTekoTestHandler(
      mapIssuesToTestCases: convertMapStringToMapList(mapIssuesToTestCases),
    );
    final Map<String, List<Map<String, dynamic>>> resultHandle =
        await jiraTekoTestHandler.submitTestJira();

    print('=====================================================================================');
    print('*** Write result to file json!');
    print('=====================================================================================');

    final File allTestCase = await File(pathFileExportAllTest).create();
    allTestCase.writeAsString(json.encode(resultHandle));

    print('*** Push test case to jira finished!');
    print('=====================================================================================');
  }
}
