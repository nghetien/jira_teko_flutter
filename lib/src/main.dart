import 'dart:convert';
import 'dart:io';

import 'models/models.dart';
import 'services/services.dart';
import 'utils/utils.dart';

class JiraTekoFlutter {
  static late final JiraTekoProjectInfo _projectInfo;

  static JiraTekoProjectInfo get projectInfo => _projectInfo;

  static void setProjectInfo(JiraTekoProjectInfo info) => _projectInfo = info;

  static late final JiraTekoRunnerOption _jiraOptions;

  static JiraTekoRunnerOption get jiraOptions => _jiraOptions;

  static void setJiraOptions(JiraTekoRunnerOption option) =>
      _jiraOptions = option;

  JiraTekoFlutter({
    required this.issues,
  }) {
    _processHelper = _getProcessHelper();
  }

  final List<String> issues;

  static const String pathFileExportResultTest =
      './test/export_result_test.log';
  static const String pathFileExportAllTest =
      './test/export_result_all_test.json';
  static late final String token;

  static late final int parentIdOfFolderTestCase;
  static late final int parentIdOfFolderCycles;
  static late final List<Map<String, dynamic>> listParentFolderTestCase;
  static late final List<Map<String, dynamic>> listParentFolderCycles;
  static final Map<String, int> mapKeyToIdFolderTestCase = {};
  static final Map<String, int> mapKeyToIdFolderCycles = {};
  static final Map<String, int> mapStatusToIdStatusTestCaseResult = {};
  static final Map<String, int> mapStatusToIdStatusTestCase = {};

  late final ProcessHelper _processHelper;

  ProcessHelper _getProcessHelper() {
    if (Platform.isLinux || Platform.isMacOS) return MacOSProcessHelper();

    return WindowsProcessHelper();
  }

  Map<String, dynamic> findFolder(
      List<dynamic> children, String nameOfFolderFind) {
    for (Map<String, dynamic> child in children) {
      if (child['name'] == nameOfFolderFind) {
        return child;
      }
    }
    return {};
  }

  Map<String, dynamic> findFolderByName(
      List<dynamic> children, String folderName) {
    final List<String> namesFolder = JiraTekoFlutter.projectInfo.folder
        .split('/')
        .where((element) => element.isNotEmpty)
        .toList();
    List<dynamic> flagChildren = children;
    for (int index = 0; index < namesFolder.length; index++) {
      final String currentName = namesFolder[index];
      final Map<String, dynamic> currentFolder =
          findFolder(flagChildren, currentName);
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
    final Map<String, dynamic> projectTrees =
        await JiraTekoTestRunner.getProjectTreesTestcase();
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
      throw Exception(
          'Can not find folder testcase ${JiraTekoFlutter.projectInfo.folder}');
    }
    return folder['id'];
  }

  /// from folder field in JiraTekoProjectInfo
  /// get parent id of last folder in folder field
  /// return -1 if not found, return id of folder [CYCLES] if found
  Future<int> getParentIdCyclesFolder() async {
    final Map<String, dynamic> projectTrees =
        await JiraTekoTestRunner.getProjectTreesCycles();
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
      throw Exception(
          'Can not find folder cycles ${JiraTekoFlutter.projectInfo.folder}');
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

  Map<String, List<Map<String, dynamic>>> convertMapStringToMapList(
      Map<String, dynamic> map) {
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
    final List<String> dataLineOfFile =
        await File(pathFileExportResultTest).readAsLines();
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
        final Map<String, dynamic> dataJsonFromLine =
            json.decode(dataLineOfFile[line]);
        final Map<String, dynamic> resultJsonFromLine =
            json.decode(dataLineOfFile[line + 1]);
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

  Future handleStatusTestCaseResult() async {
    final List<dynamic> status = await JiraTekoTestRunner.getStatusTestResult();
    for (var element in status) {
      mapStatusToIdStatusTestCaseResult[element['name']] = element['id'];
    }
  }

  Future handleStatusTestCase() async {
    final List<dynamic> status = await JiraTekoTestRunner.getStatusTestCase();
    for (var element in status) {
      mapStatusToIdStatusTestCase[element['name']] = element['id'];
    }
  }

  Future run() async {
    token = generateToken(
      projectInfo.jiraUserName,
      projectInfo.jiraPassword,
    );
    parentIdOfFolderTestCase = await getParentIdTestCaseFolder();
    parentIdOfFolderCycles = await getParentIdCyclesFolder();
    await Future.wait([
      handleStatusTestCaseResult(),
      handleStatusTestCase(),
    ]);

    log('=====================================================================================');
    log('*** Run all tests!');
    log('=====================================================================================');

    final Map<String, dynamic> mapIssuesToTestCases = {};
    for (String issue in issues) {
      final String pathFile = await _processHelper.findFileBy(issue: issue);
      if (pathFile.isEmpty) {
        throw FileSystemException('File not found path issue $issue');
      } else {
        final Iterable<String> paths = _processHelper.getPaths(pathFile);

        for (String path in paths) {
          log('path: $path');
          log('run: ${'flutter test $path --reporter json > $pathFileExportResultTest'}');

          await _processHelper.runTestWith(
            path: path,
            pathFileExportResultTest: pathFileExportResultTest,
          );

          final List<Map<String, dynamic>> resultsTestCase =
              await getResultsTestCase(issue);
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

    log('=====================================================================================');
    log('*** Run all tests done!');
    log('=====================================================================================');

    File(pathFileExportResultTest).delete();

    log('*** Handle results!');
    log('=====================================================================================');

    /// Submit all test cast to jira
    final JiraTekoTestHandler jiraTekoTestHandler = JiraTekoTestHandler(
      mapIssuesToTestCases: convertMapStringToMapList(mapIssuesToTestCases),
    );
    final Map<String, List<Map<String, dynamic>>> resultHandle =
        await jiraTekoTestHandler.submitTestJira();

    log('=====================================================================================');
    log('*** Write result to file json!');
    log('=====================================================================================');

    final File allTestCase = await File(pathFileExportAllTest).create();
    allTestCase.writeAsString(json.encode(resultHandle));

    log('*** Push test case to jira finished!');
    log('=====================================================================================');
  }
}
