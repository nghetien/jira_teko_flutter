import 'package:jira_teko_flutter/src/main.dart'
    show JiraTekoProjectInfo, JiraTekoFlutter;

void main() async {
  const List<String> issues = [
    'DEMO_TEST_123',
  ];

  JiraTekoFlutter.setProjectInfo(
    const JiraTekoProjectInfo(
      scheme: 'https',
      host: 'jira.teko.vn',
      jiraUserName: '',
      // your jira username here
      jiraPassword: '',
      // your jira password here
      projectKey: '',
      // your project key
      projectId: -1,
      // your project id
      folder: '', // your path of folder you want to push test case
    ),
  );

  final JiraTekoFlutter jiraTekoFlutter = JiraTekoFlutter(
    issues: issues,
  );
  jiraTekoFlutter.run();
}
