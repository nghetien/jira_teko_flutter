import 'dart:convert';

import 'package:http/http.dart' as http;

import '../main.dart';

class JiraTekoTestRunner {
  const JiraTekoTestRunner();

  static Uri getUrlWith({String suffix = '', Map<String, dynamic>? query}) {
    final Uri uri = Uri(
      scheme: JiraTekoFlutter.projectInfo.scheme,
      host: JiraTekoFlutter.projectInfo.host,
      path: '/rest$suffix',
      queryParameters: query,
    );
    return uri;
  }

  static Future<List<dynamic>> getStatusTestResult() async {
    final response = await http.get(
      getUrlWith(
        suffix:
            '/tests/1.0/project/${JiraTekoFlutter.projectInfo.projectId}/testresultstatus',
      ),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to get status test case result');
    }
  }

  static Future<List<dynamic>> getStatusTestCase() async {
    final response = await http.get(
      getUrlWith(
        suffix:
            '/tests/1.0/project/${JiraTekoFlutter.projectInfo.projectId}/testcasestatus',
      ),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to get status test case');
    }
  }

  /// headers for request to Jira
  static Map<String, String> headers = <String, String>{
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Basic ${JiraTekoFlutter.token}',
  };

  /// Get issues info from Jira
  static Future<Map<String, dynamic>> getIssueId(String issueKey) async {
    final http.Response response = await http.post(
      getUrlWith(suffix: '/api/2/search'),
      headers: headers,
      body: jsonEncode({
        "jql":
            "project = ${JiraTekoFlutter.projectInfo.projectId} AND key = $issueKey",
        "startAt": 0,
        "fields": [
          "summary",
          "resolution",
          "issuetype",
          "status",
          "reporter",
          "assignee",
        ]
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load issues');
    }
  }

  static Future addIssueToTest(int testCaseId, List<String> issuesId) async {
    final List<Map<String, dynamic>> data = issuesId
        .map<Map<String, dynamic>>((e) => {
              "testCaseId": testCaseId,
              "issueId": e,
              "typeId": 1,

              /// 1 is coverage
            })
        .toList();
    final response = await http.post(
      getUrlWith(suffix: '/tests/1.0/tracelink/bulk/create'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add issue to test');
    }
  }

  static Future addIssueToCycles(int cyclesId, List<String> issuesId) async {
    final List<Map<String, dynamic>> data = issuesId
        .map<Map<String, dynamic>>((e) => {
              "testRunId": cyclesId,
              "issueId": e,
              "typeId": 2,

              /// 2 is related
            })
        .toList();
    final response = await http.post(
      getUrlWith(suffix: '/tests/1.0/tracelink/bulk/create'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add issue to cycles');
    }
  }

  /// Get all cycles of folder cycle in Jira
  static Future<Map<String, dynamic>> getAllCyclesOfFolder(int folderId) async {
    final response = await http.get(
      getUrlWith(
        suffix: '/tests/1.0/testrun/search',
        query: {
          'query':
              "testRun.projectKey IN ('${JiraTekoFlutter.projectInfo.projectKey}') AND testRun.folderTreeId = $folderId"
        },
      ),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load cycles');
    }
  }

  /// Get project trees from Jira
  static Future<Map<String, dynamic>> getProjectTreesTestcase() async {
    final response = await http.get(
      getUrlWith(
          suffix:
              '/tests/1.0/project/${JiraTekoFlutter.projectInfo.projectId}/foldertree/testcase'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load project trees');
    }
  }

  /// Get project trees cycles from Jira
  static Future<Map<String, dynamic>> getProjectTreesCycles() async {
    final response = await http.get(
      getUrlWith(
          suffix:
              '/tests/1.0/project/${JiraTekoFlutter.projectInfo.projectId}/foldertree/testrun'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load project trees');
    }
  }

  /// Get all test cases of a task
  static Future<Map<String, dynamic>> getTestsInIssue(issueKey) async {
    final response = await http.get(
      getUrlWith(suffix: '/tests/1.0/testcase/search', query: {
        'query':
            'testCase.projectId IN (${JiraTekoFlutter.projectInfo.projectId}) AND testCase.keyName LIKE "$issueKey"',
      }),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get all test cases');
    }
  }

  /// Create test case on Jira
  static Future<int> createTest({
    required String testName,
    required String issueKey,
    required int folderId,
  }) async {
    final response = await http.post(
      getUrlWith(suffix: '/tests/1.0/testcase'),
      body: jsonEncode({
        "folderId": folderId,
        "name": testName,
        "projectId": JiraTekoFlutter.projectInfo.projectId,
        'statusId': JiraTekoFlutter
            .mapStatusToIdStatusTestCase['Approved'] // status is approved
      }),
      headers: headers,
    );

    /// 200: success & 201: created
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body)['id'] as int;
    } else {
      throw Exception('Failed to create test case');
    }
  }

  /// Create test cycle on Jira
  static Future<Map<String, dynamic>> createTestCycle({
    required String nameCycle,
    required int folderId,
  }) async {
    final response = await http.post(
      getUrlWith(suffix: '/tests/1.0/testrun'),
      body: jsonEncode({
        "folderId": folderId,
        "name": nameCycle,
        "projectId": JiraTekoFlutter.projectInfo.projectId,
      }),
      headers: headers,
    );

    /// 200: success & 201: created
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create test cycles');
    }
  }

  static Future updateTestCycles({
    required int cyclesId,
    required List<Map<String, dynamic>> testcases,
  }) async {
    final response = await http.put(
      getUrlWith(suffix: '/tests/1.0/testrunitem/bulk/save'),
      body: jsonEncode({
        "addedTestRunItems": testcases,
        "testRunId": cyclesId,
        "deletedTestRunItems": [],
        "updatedTestRunItems": [],
        "updatedTestRunItemsIndexes": []
      }),
      headers: headers,
    );

    /// 200: success & 201: created
    if (response.statusCode != 200) {
      throw Exception('Failed to update test cycles');
    }
  }

  /// Create test folder on Jira
  static Future createTestFolder(String issueKey) async {
    late int? idFolderTestCase;
    try {
      idFolderTestCase = JiraTekoFlutter.listParentFolderTestCase.firstWhere(
        (element) => element['name'] == issueKey,
      )['id'];
    } catch (e) {
      idFolderTestCase = null;
    }
    if (idFolderTestCase == null) {
      /// Create folder for test cases
      final response = await http.post(
        getUrlWith(suffix: '/tests/1.0/folder/testcase'),
        body: jsonEncode({
          "name": issueKey,
          "parentId": JiraTekoFlutter.parentIdOfFolderTestCase,
          "projectId": JiraTekoFlutter.projectInfo.projectId
        }),
        headers: headers,
      );
      JiraTekoFlutter.mapKeyToIdFolderTestCase[issueKey] =
          json.decode(response.body)['id'] as int;
    } else {
      JiraTekoFlutter.mapKeyToIdFolderTestCase[issueKey] = idFolderTestCase;
    }

    /// --------------------------------------------------------------------------------------------
    late int? idFolderCycles;
    try {
      idFolderCycles = JiraTekoFlutter.listParentFolderCycles.firstWhere(
        (element) => element['name'] == issueKey,
      )['id'];
    } catch (e) {
      idFolderCycles = null;
    }
    if (idFolderCycles == null) {
      /// Create folder for test cycle
      final response = await http.post(
        getUrlWith(suffix: '/tests/1.0/folder/testrun'),
        body: jsonEncode({
          "name": issueKey,
          "parentId": JiraTekoFlutter.parentIdOfFolderCycles,
          "projectId": JiraTekoFlutter.projectInfo.projectId
        }),
        headers: headers,
      );
      JiraTekoFlutter.mapKeyToIdFolderCycles[issueKey] =
          json.decode(response.body)['id'] as int;
    } else {
      JiraTekoFlutter.mapKeyToIdFolderCycles[issueKey] = idFolderCycles;
    }
  }

  /// Update status test case in cycle
  static Future updateTestStatusInCycles(List<dynamic> testCases) async {
    final response = await http.put(
      getUrlWith(suffix: '/tests/1.0/testresult'),
      body: jsonEncode(testCases),
      headers: headers,
    );

    /// 200: success & 201: created
    if (response.statusCode != 200) {
      throw Exception('Failed to update test cycles');
    }
  }

  /// Get all test case in cycles
  static Future<List<dynamic>> getAllTestCaseInCycles(int cycleId) async {
    final response = await http.get(
      getUrlWith(
        suffix: '/tests/1.0/testrun/$cycleId/testrunitems/lasttestresults',
      ),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to get all test cases in cycles');
    }
  }
}
