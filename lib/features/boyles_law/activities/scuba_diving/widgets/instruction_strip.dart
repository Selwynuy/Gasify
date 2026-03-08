import 'package:flutter/material.dart';

/// Instruction strip shown at the top of the scuba activity, below the app bar.
/// Displays the current step text and styles the final step in green.
/// Reserves space for [minLines] (default 4 for longest step) so layout below does not resize when text wraps.
class InstructionStrip extends StatelessWidget {
  final String text;
  final bool isFinalStep;
  final int minLines;

  const InstructionStrip({
    super.key,
    required this.text,
    this.isFinalStep = false,
    this.minLines = 4,
  });

  @override
  Widget build(BuildContext context) {
    const double lineHeight = 18.0;
    const double verticalPadding = 16.0;
    final double minHeight = minLines * lineHeight + verticalPadding;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
