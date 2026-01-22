import 'package:flutter/material.dart';
import '../../core/services/sound_service.dart';

/// Quiz question data
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex; // 0-based index

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });
}

/// Dialog for unlocking activities with quiz questions
class QuizUnlockDialog extends StatefulWidget {
  final QuizQuestion question;
  final VoidCallback? onUnlocked;

  const QuizUnlockDialog({
    super.key,
    required this.question,
    this.onUnlocked,
  });

  @override
  State<QuizUnlockDialog> createState() => _QuizUnlockDialogState();
}

class _QuizUnlockDialogState extends State<QuizUnlockDialog> {
  int? _selectedAnswer;
  bool _isCorrect = false;
  bool _showResult = false;

  void _checkAnswer() {
    if (_selectedAnswer == null) return;

    setState(() {
      _isCorrect = _selectedAnswer == widget.question.correctAnswerIndex;
      _showResult = true;
    });

    // Play success or fail sound
    if (_isCorrect) {
      SoundService().playSuccessSound();
    } else {
      SoundService().playFailSound();
    }
  }

  void _proceed() {
    if (_isCorrect && widget.onUnlocked != null) {
      widget.onUnlocked!();
    }
    Navigator.pop(context, _isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_showResult && _isCorrect 
                ? 'assets/Succeed.png' 
                : 'assets/Locked.png'),
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 150.0),
            child: _showResult && _isCorrect
                ? _buildSuccessView()
                : _showResult && !_isCorrect
                    ? _buildFailureView()
                    : _buildQuizView(),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 205),
        // Question text
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(
            widget.question.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 4,
                  color: Colors.black54,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        // Option buttons
        ...widget.question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = _selectedAnswer == index;
          
          // Color mapping: A=Red, B=Green, C=Blue
          Color buttonColor;
          if (index == 0) {
            buttonColor = Colors.red.shade600; // A: Red
          } else if (index == 1) {
            buttonColor = Colors.green.shade600; // B: Green
          } else {
            buttonColor = Colors.blue.shade600; // C: Blue
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedAnswer = index;
                });
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? buttonColor : buttonColor.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: isSelected ? 3 : 0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: buttonColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        // Submit button
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedAnswer != null ? _checkAnswer : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedAnswer != null ? Colors.orange.shade600 : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Submit Answer',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 220),
        const Text(
          'Congratulations, you can now proceed!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 4,
                color: Colors.black54,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _proceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Proceed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFailureView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 205),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: const Text(
            'Incorrect answer. Please try again!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 4,
                  color: Colors.black54,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedAnswer = null;
                _showResult = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
