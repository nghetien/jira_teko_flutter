enum TestCaseStatus {
  approved('Approved'),
  draft('Draft'),
  deprecated('Deprecated');

  final String value;

  const TestCaseStatus(this.value);
}

class JiraTekoRunnerOption {
  JiraTekoRunnerOption({
    this.statusTestCase = TestCaseStatus.draft,
    this.createCycle = true,
  });

  final TestCaseStatus statusTestCase;
  final bool createCycle;
}
