import 'package:flutter/material.dart';
import '../data/think_and_solve_content.dart';

export '../data/think_and_solve_content.dart' show ThinkAndSolveLaw;

/// Full-screen scrollable handout for Think and Solve (Boyle's, Charles's, or Combined Gas Law).
class ThinkAndSolveScreen extends StatelessWidget {
  final ThinkAndSolveLaw law;

  const ThinkAndSolveScreen({super.key, required this.law});

  @override
  Widget build(BuildContext context) {
    final content = ThinkAndSolveContentProvider.getContent(law);
    return Scaffold(
      appBar: AppBar(
        title: Text(content.screenTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.lightBlue.shade400,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/HomeScreen_Background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...content.sections.map(
                  (s) => _SectionCard(title: s.title, body: s.body),
                ),
                if (content.sampleProblem != null) ...[
                  const SizedBox(height: 16),
                  _SampleProblemCard(problem: content.sampleProblem!),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String body;

  const _SectionCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withValues(alpha: 0.92),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleProblemCard extends StatelessWidget {
  final ThinkAndSolveSampleProblem problem;

  const _SampleProblemCard({required this.problem});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.92),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sample Problem',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlue.shade800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              problem.problemStatement,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            _LabelText('Given:', problem.given),
            if (problem.unknown != null) _LabelText('Unknown:', problem.unknown!),
            _LabelText('Formula:', problem.formula),
            _LabelText('Solution:', problem.solution),
            if (problem.finalAnswer != null) _LabelText('Final answer:', problem.finalAnswer!),
            if (problem.interpretation != null) _LabelText('Interpretation:', problem.interpretation!),
          ],
        ),
      ),
    );
  }
}

class _LabelText extends StatelessWidget {
  final String label;
  final String text;

  const _LabelText(this.label, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}
