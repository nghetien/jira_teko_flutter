import '../main.dart';
import 'jira_teko_test_runner.dart';

class JiraTekoTestHandler {
  JiraTekoTestHandler({
    required this.mapIssuesToTestCases,
  });

  Map<String, List<Map<String, dynamic>>> mapIssuesToTestCases;

  /// get all issues from issue key
  Future<List<String>> getIssuesIdFromIssueKey(String issueKey) async {
    final Map<String, dynamic> issues = await JiraTekoTestRunner.getIssueId(issueKey);
    return (issues['issues'] as List<dynamic>).map<String>((issue) => issue['id']).toList();
  }

  /// handle test cases and create test cases unavailable in Jira
  Future handleMapTestIssuesToTestCases(String issueKey) async {
    if (mapIssuesToTestCases[issueKey] == null) {
      return;
    }
    mapIssuesToTestCases[issueKey] = await Future.wait(
      mapIssuesToTestCases[issueKey]!.map((Map<String, dynamic> element) async {
        final String nameTestCase = element['name'];
        final Map<String, dynamic> findTestCases =
            await JiraTekoTestRunner.getTestsInIssue(nameTestCase);
        if (findTestCases['results'] == null || findTestCases['results'].length == 0) {
          final int idTestCase = await JiraTekoTestRunner.createTest(
            testName: nameTestCase,
            issueKey: issueKey,
            folderId: JiraTekoFlutter.mapKeyToIdFolderTestCase[issueKey]!,
          );
          final List<String> issuesFromIssueKey = await getIssuesIdFromIssueKey(issueKey);
          if (issuesFromIssueKey.isNotEmpty) {
            await JiraTekoTestRunner.addIssueToTest(
              idTestCase,
              await getIssuesIdFromIssueKey(issueKey),
            );
          }
          return {
            'name': element['name'],
            'status': element['status'],
            'id': idTestCase,
          };
        } else {
          return {
            'name': element['name'],
            'status': element['status'],
            'id': findTestCases['results'][0]['id'],
          };
        }
      }).toList(),
    );
  }

  int getIdTestCaseInCycles(List<dynamic> allTestCaseInCycles, int testCaseId) {
    if (allTestCaseInCycles.isEmpty) {
      throw Exception('List test case in cycles is empty');
    }
    try {
      return allTestCaseInCycles.firstWhere(
              (testCase) => testCase['lastTestResult']['testCaseId'] == testCaseId)['lastTestResult']
          ['id'] as int;
    } catch (e) {
      throw Exception('Cant not find id test case in cycles');
    }
  }

  /// create test cycles on Jira
  Future createTestCycle(String issueKey) async {
    /// handle name test cycles
    String nameTestCycle = 'Test Cycle';
    try {
      final Map<String, dynamic> issue = await JiraTekoTestRunner.getIssueId(issueKey);
      nameTestCycle = issue['issues'][0]['fields']['summary'];
    } catch (e) {
      throw Exception('Failed to get issue name');
    }
    try {
      final RegExp regExp = RegExp('^(\\[[0-9a-zA-Z]+\\] ?)*');
      final RegExpMatch? match = regExp.firstMatch(nameTestCycle);
      nameTestCycle =
          nameTestCycle.substring(match!.group(0)?.length ?? 0, nameTestCycle.length).trim();
    } catch (e) {
      print(e);
    }

    /// count round
    final Map<String, dynamic> testCycles = await JiraTekoTestRunner.getAllCyclesOfFolder(
      JiraTekoFlutter.mapKeyToIdFolderCycles[issueKey]!,
    );
    final int round = testCycles['results']?.length ?? 0;

    /// Create cycles
    final Map<String, dynamic> testCycle = await JiraTekoTestRunner.createTestCycle(
      nameCycle: '[$issueKey] $nameTestCycle - round ${round + 1}',
      folderId: JiraTekoFlutter.mapKeyToIdFolderCycles[issueKey]!,
    );

    /// Add test cast to test cycles
    List<Map<String, dynamic>> testcases = [];
    for (int index = 0; index < mapIssuesToTestCases[issueKey]!.length; index++) {
      testcases.add({
        'index': index,
        'lastTestResult': {
          'testCaseId': mapIssuesToTestCases[issueKey]![index]['id'],
        },
      });
    }
    await JiraTekoTestRunner.updateTestCycles(
      cyclesId: testCycle['id'],
      testcases: testcases,
    );

    /// Assign test cycles to issue
    await JiraTekoTestRunner.addIssueToCycles(
      testCycle['id'],
      await getIssuesIdFromIssueKey(issueKey),
    );

    final List<dynamic> allTestCaseInCycles = await JiraTekoTestRunner.getAllTestCaseInCycles(
      testCycle['id'],
    );

    final List<dynamic> testCases = mapIssuesToTestCases[issueKey]!.map((element) => {
      "id": getIdTestCaseInCycles(allTestCaseInCycles, element['id']),
      "testResultStatusId": JiraTekoFlutter.mapStatusToIdStatus[element['status'] ?? 'Fail']!,
    }).toList();
    JiraTekoTestRunner.updateTestStatusInCycles(testCases);
  }

  /// Submit after test
  Future submitAfterTest(String issueKey) async {
    try {
      print('Create $issueKey folder and test cycles!');

      /// Create folder for test cases & test cycle on Jira
      await JiraTekoTestRunner.createTestFolder(issueKey);

      print('Create test case of folder $issueKey!');

      /// Handle test cases available in jira && Create test cases unavailable in jira
      await handleMapTestIssuesToTestCases(issueKey);

      print('Create test cycles of folder $issueKey!');

      /// create test cycle on Jira
      await createTestCycle(issueKey);
    } catch (error) {
      print(error);
      throw Exception('Failed to submit after test');
    }
  }

  /// Submit all test case to jira
  Future<Map<String, List<Map<String, dynamic>>>> submitTestJira() async {
    final List<String> issuesKey = mapIssuesToTestCases.keys.toList();
    if (issuesKey.isNotEmpty) {
      for (String issueKey in issuesKey) {
        if (mapIssuesToTestCases[issueKey] == null || mapIssuesToTestCases[issueKey]!.isEmpty) {
          throw Exception('No test cases found for $issueKey');
        }
        await submitAfterTest(issueKey);
      }
    }
    return mapIssuesToTestCases;
  }
}
