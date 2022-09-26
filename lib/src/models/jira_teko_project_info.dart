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