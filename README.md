Jira Teko Flutter
===========

* [Introduction](#introduction)
* [Set up](#setup)
* [Purpose](#purpose)
* [License and contributors](#license-and-contributors)

Introduction
------------

This library can be used to push testcase from local to project in jira teko.

Setup
-------
After use this library, you must install library from pub dev: [`junitreport`](https://pub.dev/packages/junitreport/install).

    dart pub global activate junitreport

Create file `jira.dart` in folder `test` of project.

In file `jira.dart` you setup your information project jira and your account jira teko.

```Dart

import 'package:jira_teko_flutter/src/main.dart' show JiraTekoProjectInfo, JiraTekoFlutter;

void main() async {
  const List<String> issues = []; // List of issue you want to push to jira teko

  JiraTekoFlutter.setProjectInfo(
    const JiraTekoProjectInfo(
      scheme: 'https',
      host: 'jira.teko.vn',
      jiraUserName: '', // your jira username here
      jiraPassword: '', // your jira password here
      projectKey: '', // your project key
      projectId: , // your project id
      folder: '', // your path of folder you want to push test case
    ),
  );

  final JiraTekoFlutter jiraTekoFlutter = JiraTekoFlutter(
    issues: issues,
  );
  jiraTekoFlutter.run();
}
```

Purpose
-------
By running

    dart run test/jira.dart

It run all test case with issue in issue list declared in file `jira.dart`.

Results will export to file `export_result_all_test.json` in folder `test`.

```JSON
{
  "P365MOB-332": [
    {
      "name": "[P365MOB-332] CastFlowDetailPage : when click item into list cast flow, show detail cast flow",
      "status": "Pass",
      "id": 1029703
    },
    {
      "name": "[P365MOB-332] CastFlowDetailPage : Create new group",
      "status": "Pass",
      "id": 1029701
    },
    {
      "name": "[P365MOB-332] CastFlowDetailPage : Fill empty code and value",
      "status": "Pass",
      "id": 1029699
    },
    {
      "name": "[P365MOB-332] showCreateGroupDialog : When click button show Dialog",
      "status": "Pass",
      "id": 1029704
    },
    {
      "name": "[P365MOB-332] showCreateGroupDialog : Check default value dialog",
      "status": "Pass",
      "id": 1029700
    },
    {
      "name": "[P365MOB-332] showCreateGroupDialog : Check create group success",
      "status": "Pass",
      "id": 1029705
    }
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