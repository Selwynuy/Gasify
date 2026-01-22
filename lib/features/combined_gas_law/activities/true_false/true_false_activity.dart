import 'package:flutter/material.dart';
import '../../../../core/services/sound_service.dart';

/// True or False Quiz for Combined Gas Law.
class TrueFalseActivity extends StatefulWidget {
  const TrueFalseActivity({super.key});

  @override
  State<TrueFalseActivity> createState() => _TrueFalseActivityState();
}

class _TrueFalseActivityState extends State<TrueFalseActivity> {
  // Questions and their correct answers
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'The distances of gas molecules are far from each other.',
      'answer': true,
    },
    {
      'question': 'There are perfectly inelastic collisions among gas molecules.',
      'answer': false,
    },
    {
      'question': 'Random motions are always constant in gas molecules.',
      'answer': true,
    },
    {
      'question': 'The gas molecules are frequently colliding with one another and also with the walls of the container.',
      'answer': true,
    },
    {
      'question': 'The gas molecules which possess negligible mass and volume can be considered as spherical bodies.',
      'answer': true,
    },
  ];

  // User's answers (null means not answered yet)
  final List<bool?> _userAnswers = [null, null, null, null, null];
  
  // Whether quiz has been submitted
  bool _isSubmitted = false;

  /// Check if all questions are answered
  bool get _allAnswered => _userAnswers.every((answer) => answer != null);

  /// Calculate score
  int get _score {
    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i]['answer']) {
        correct++;
      }
    }
    return correct;
  }

  /// Check if a specific answer is correct
  bool _isCorrect(int index) {
    return _userAnswers[index] == _questions[index]['answer'];
  }

  void _onAnswerSelected(int index, bool value) {
    if (_isSubmitted) return;
    
    setState(() {
      _userAnswers[index] = value;
    });
    SoundService().playTouchSound();
  }

  void _onSubmit() {
    if (!_allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before submitting.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitted = true;
    });
    SoundService().playTouchSound();

    // Play success or fail sound based on score
    final percentage = (_score / _questions.length) * 100;
    if (percentage >= 70) {
      SoundService().playSuccessSound();
    } else {
      SoundService().playFailSound();
    }
  }

  void _onReset() {
    setState(() {
      _userAnswers.fillRange(0, _userAnswers.length, null);
      _isSubmitted = false;
    });
    SoundService().playTouchSound();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("True or False"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Instructions
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade300, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'True or False',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Direction: Write True if the statement is correct and False if the statement is incorrect.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Questions List
                ...List.generate(_questions.length, (index) {
                  final question = _questions[index];
                  final userAnswer = _userAnswers[index];
                  final isCorrect = _isSubmitted ? _isCorrect(index) : null;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isSubmitted
                            ? (isCorrect == true
                                ? Colors.green.shade400
                                : isCorrect == false
                                    ? Colors.red.shade400
                                    : Colors.grey.shade300)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Number and Text
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                question['question'] as String,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // True/False Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildAnswerButton(
                                label: 'True',
                                isSelected: userAnswer == true,
                                isCorrect: _isSubmitted && isCorrect == true && userAnswer == true,
                                isIncorrect: _isSubmitted && isCorrect == false && userAnswer == true,
                                onTap: () => _onAnswerSelected(index, true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildAnswerButton(
                                label: 'False',
                                isSelected: userAnswer == false,
                                isCorrect: _isSubmitted && isCorrect == true && userAnswer == false,
                                isIncorrect: _isSubmitted && isCorrect == false && userAnswer == false,
                                onTap: () => _onAnswerSelected(index, false),
                              ),
                            ),
                          ],
                        ),
                        
                        // Show correct answer if submitted and wrong
                        if (_isSubmitted && !isCorrect!)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade600,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Correct answer: ${question['answer'] ? 'True' : 'False'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: 16),
                
                // Submit/Reset Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitted ? _onReset : _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSubmitted
                          ? Colors.orange.shade600
                          : Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isSubmitted ? 'Reset Quiz' : 'Submit Answers',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Score Display
                if (_isSubmitted) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _score == _questions.length
                            ? Colors.green.shade400
                            : Colors.orange.shade400,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _score == _questions.length
                              ? Icons.check_circle
                              : Icons.info,
                          color: _score == _questions.length
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Score: $_score / ${_questions.length}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _score == _questions.length
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _score == _questions.length
                              ? 'Perfect! All answers are correct!'
                              : 'Keep practicing!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required bool isSelected,
    required bool? isCorrect,
    required bool? isIncorrect,
    required VoidCallback onTap,
  }) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (_isSubmitted) {
      if (isCorrect == true) {
        backgroundColor = Colors.green.shade100;
        borderColor = Colors.green.shade400;
        textColor = Colors.green.shade900;
      } else if (isIncorrect == true) {
        backgroundColor = Colors.red.shade100;
        borderColor = Colors.red.shade400;
        textColor = Colors.red.shade900;
      } else {
        backgroundColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade300;
        textColor = Colors.grey.shade700;
      }
    } else {
      backgroundColor = isSelected
          ? Colors.blue.shade100
          : Colors.grey.shade50;
      borderColor = isSelected
          ? Colors.blue.shade400
          : Colors.grey.shade300;
      textColor = isSelected
          ? Colors.blue.shade900
          : Colors.black87;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSubmitted && isCorrect == true)
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 20,
                ),
              if (_isSubmitted && isIncorrect == true)
                Icon(
                  Icons.cancel,
                  color: Colors.red.shade700,
                  size: 20,
                ),
              if ((_isSubmitted && isCorrect == true) ||
                  (_isSubmitted && isIncorrect == true))
                const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

