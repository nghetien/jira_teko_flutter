import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// functionNeedTest
/// Name: DEMO_TEST_123
/// Objective:
/// Precondition:
/// ConfluenceLinks:
/// Folder:
/// WebLinks:
/// TestScript:
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  /// need to add jira issue key in group name: [DEMO_TEST_123] + name of function need to test
  group('[DEMO_TEST_123] functionNeedTest :', () {
    test("description test", () async {
      expect(1, 1);
    });
  });
}
