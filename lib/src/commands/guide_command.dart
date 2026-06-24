import 'package:args/command_runner.dart';

import '../guide/usage_guide.dart';

class GuideCommand extends Command<void> {
  @override
  final String name = 'guide';

  @override
  final String description = 'Step-by-step walkthrough for using uncle_bob.';

  GuideCommand() {
    argParser.addFlag(
      'feature',
      negatable: false,
      help: 'Show questionnaire examples only.',
    );
  }

  @override
  Future<void> run() async {
    final featureOnly = argResults!['feature'] as bool;
    if (featureOnly) {
      UsageGuide.printFeatureQuestionnaireIntro();
      return;
    }
    UsageGuide.printFull();
  }
}
