Jira Teko Flutter
===========

* [Introduction](#introduction)
* [Set up](#setup)
* [Run](#run)
* [License and contributors](#license-and-contributors)

Introduction
------------

This library can be used to push testcase from local to project in jira teko.

Setup
-------
After use this library, you must install library from pub dev: [`junitreport`](https://pub.dev/packages/junitreport/install).

    dart pub global activate junitreport

Create file `.env` in project

```env
JIRA_USER_NAME=your_jira_user_name
JIRA_PASSWORD=your_jira_password
JIRA_ISSUES=issue1,issue2,...
```

Create file `jira.dart` in folder `test` of project.

In file `jira.dart` you setup your information project jira and your account jira teko.

```Dart

import 'package:jira_teko_flutter/jira_teko_flutter.dart'
    show JiraTekoProjectInfo, JiraTekoFlutter, JiraTekoRunnerOption, TestCaseStatus;
import 'package:jira_teko_flutter/src/helpers/read_file_env.dart' as read_env;

void main() async {
  /// Use push test to jira
  ///
  /// E.g:you are testing issue P365MOB-434 and want to push to jira.
  /// * add 'P365MOB-434' to issue list: issues = ['P365MOB-434']
  /// * and run file: dart test/jira.dart
  /// * all result test cases will write to file export_result_test.json
  ///
  /// ** Attention: When you commit code, please take issues empty.

  /// Use file .env setup: username, password, issues
  final Map<String, String> dataEnv = await read_env.readFileEnv('.env');

  final List<String> issues = (dataEnv["JIRA_ISSUES"] ?? "").split(",");

  JiraTekoFlutter.setProjectInfo(
    JiraTekoProjectInfo(
      scheme: 'https',
      host: 'jira.teko.vn',
      jiraUserName: dataEnv['JIRA_USER_NAME'] ?? '',

      /// your jira username here
      /// ** Attention: When you commit code, please take jiraPassword empty.
      jiraPassword: dataEnv['JIRA_PASSWORD'] ?? '',

      /// your jira password here
      /// ** Attention: When you commit code, please take projectKey empty.
      projectKey: '', // your project key
      projectId: 12345, // your project id
      folder: '/HN1234/abc/xyz/', // specific redirect URL
    ),
  );
  JiraTekoFlutter.setJiraOptions(
    JiraTekoRunnerOption(
      statusTestCase: TestCaseStatus.draft, /// when creating testcase set default status of its (default: draft)
      createCycle: true, /// auto create test cycle (default: true)
    ),
  );

  final JiraTekoFlutter jiraTekoFlutter = JiraTekoFlutter(
    issues: issues,
  );
  jiraTekoFlutter.run();
}
```

Run
-------
By running

    dart run test/jira.dart

It run all test case with issue in issue list declared in file `.env`.

Inside file *_test.dart
```Dart
/// title test
/// Name: YOUR_TASK_NAME
/// Objective:
/// Precondition:
/// ConfluenceLinks:
/// Folder:
/// WebLinks:
/// TestScript:
void main() {
  group('Group  name : ', () {
    test("test 1", () async {});
 
    test('test 2', () async {});
 
    test('test 3', () async {});
  });
}
```

Results will export to file `export_result_all_test.json` in folder `test`.

```JSON
{
  "YOUR_TASK_NAME": [
    {
      "name": "Group  name : test 1",
      "status": "Pass",
      "id": 1029703
    },
    {
      "name": "Group  name : test 2",
      "status": "Pass",
      "id": 1029703
    },
    {
      "name": "Group  name : test 3",
      "status": "Pass",
      "id": 1029703
    },
  ]
}
```

From file: `export_result_all_test.json`, You can see all test case run with jira issue key you provided.

And all test case push to jira teko with:
- Folder test case
- Test case
- Folder cycles
- Test case in cycles
- Result test case

License and contributors
------------------------

* The MIT License, see [LICENSE](https://github.com/nghetien/jira_teko_flutter/blob/main/LICENSE).
* For contributors, see [AUTHORS](https://github.com/nghetien/jira_teko_flutter/blob/main/AUTHORS).