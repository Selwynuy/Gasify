import 'package:flutter/material.dart';
import '../../../core/services/sound_service.dart';

/// Drag and Drop Quiz screen for Boyle's Law
class DragDropQuizScreen extends StatefulWidget {
  const DragDropQuizScreen({super.key});

  @override
  State<DragDropQuizScreen> createState() => _DragDropQuizScreenState();
}

class _DragDropQuizScreenState extends State<DragDropQuizScreen> {
  // Correct answers for each blank (1-indexed)
  final Map<int, String> _correctAnswers = {
    1: 'Robert Boyle',
    2: 'volume',
    3: 'pressure',
    4: 'temperature',
    5: 'volume',
    6: 'increased',
    7: 'decreased',
    8: 'volume',
    9: 'pressure',
    10: 'inversely',
    11: 'temperature',
    12: 'pressure',
    13: 'P1V1 = P2V2',
    14: 'initial pressure',
    15: 'final volume',
  };

  // User's answers
  final Map<int, String?> _userAnswers = {};

  // Whether quiz has been submitted
  bool _isSubmitted = false;

  // Available words in the word bank
  final List<String> _wordBank = [
    'Robert Boyle',
    'volume',
    'pressure',
    'temperature',
    'increased',
    'decreased',
    'inversely',
    'P1V1 = P2V2',
    'initial pressure',
    'final volume',
  ];

  // Words that have been used (for tracking)
  final Map<String, int> _wordUsageCount = {};

  @override
  void initState() {
    super.initState();
    // Initialize usage count
    for (var word in _wordBank) {
      _wordUsageCount[word] = 0;
    }
  }

  void _onWordDropped(int blankNumber, String word) {
    if (_isSubmitted) return;

    setState(() {
      // Decrease count of previous word if any
      final previousWord = _userAnswers[blankNumber];
      if (previousWord != null && _wordUsageCount.containsKey(previousWord)) {
        _wordUsageCount[previousWord] = _wordUsageCount[previousWord]! - 1;
      }

      // Set new answer
      _userAnswers[blankNumber] = word;
      _wordUsageCount[word] = (_wordUsageCount[word] ?? 0) + 1;
    });
  }

  void _onSubmit() {
    setState(() {
      _isSubmitted = true;
    });

    // Play success or fail sound based on score
    final score = _calculateScore();
    final percentage = (score / 15) * 100;
    if (percentage >= 70) {
      SoundService().playSuccessSound();
    } else {
      SoundService().playFailSound();
    }
  }

  void _onReset() {
    setState(() {
      _userAnswers.clear();
      _isSubmitted = false;
      for (var word in _wordBank) {
        _wordUsageCount[word] = 0;
      }
    });
  }

  int _calculateScore() {
    int correct = 0;
    for (int i = 1; i <= 15; i++) {
      if (_userAnswers[i]?.trim().toLowerCase() ==
          _correctAnswers[i]?.trim().toLowerCase()) {
        correct++;
      }
    }
    return correct;
  }

  String _getRemarks(int score) {
    final percentage = (score / 15) * 100;
    if (percentage >= 90) {
      return 'Excellent!';
    } else if (percentage >= 80) {
      return 'Very Good!';
    } else if (percentage >= 70) {
      return 'Good!';
    } else if (percentage >= 60) {
      return 'Fair';
    } else {
      return 'Keep Practicing!';
    }
  }

  Color _getBlankColor(int blankNumber) {
    if (!_isSubmitted) return Colors.transparent;
    final userAnswer = _userAnswers[blankNumber];
    final correctAnswer = _correctAnswers[blankNumber];
    if (userAnswer == null) return Colors.orange.withValues(alpha: 0.3);
    if (userAnswer.trim().toLowerCase() == correctAnswer?.trim().toLowerCase()) {
      return Colors.green.withValues(alpha: 0.3);
    } else {
      return Colors.red.withValues(alpha: 0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _isSubmitted ? _calculateScore() : 0;
    final remarks = _isSubmitted ? _getRemarks(score) : '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/HomeScreen_Background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Activity 3: Drag Me",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer for symmetry
                  ],
                ),
              ),
              // Instructions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Direction: Fill in each blank with the correct word from the pool of words inside the box by dragging the word. You can use some words more than once.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Main content - scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fill in the blanks
                      _FillInBlanksWidget(
                        userAnswers: _userAnswers,
                        correctAnswers: _correctAnswers,
                        onWordDropped: _onWordDropped,
                        getBlankColor: _getBlankColor,
                        isSubmitted: _isSubmitted,
                      ),
                      const SizedBox(height: 20),
                      // Submit button
                      if (!_isSubmitted)
                        Center(
                          child: ElevatedButton(
                            onPressed: _onSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue.shade400,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else
                        // Results - centered horizontally
                        Center(
                          child: _ResultsWidget(
                            score: score,
                            total: 15,
                            remarks: remarks,
                            onReset: _onReset,
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Fixed Word Bank at bottom
              _WordBankWidget(
                wordBank: _wordBank,
                wordUsageCount: _wordUsageCount,
                isSubmitted: _isSubmitted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Word Bank Widget - Fixed at bottom
class _WordBankWidget extends StatelessWidget {
  final List<String> wordBank;
  final Map<String, int> wordUsageCount;
  final bool isSubmitted;

  const _WordBankWidget({
    required this.wordBank,
    required this.wordUsageCount,
    required this.isSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Word Bank:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: 3 rows
              Expanded(
                child: Column(
                  children: [
                    for (int i = 0; i < 3; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: i < 2 ? 8 : 0),
                        child: _DraggableWord(
                          word: wordBank[i],
                          isAvailable: !isSubmitted,
                          usageCount: wordUsageCount[wordBank[i]] ?? 0,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Column 2: 4 rows (center column with last word)
              Expanded(
                child: Column(
                  children: [
                    for (int i = 3; i < 6; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _DraggableWord(
                          word: wordBank[i],
                          isAvailable: !isSubmitted,
                          usageCount: wordUsageCount[wordBank[i]] ?? 0,
                        ),
                      ),
                    // Last word (10th) in center column
                    _DraggableWord(
                      word: wordBank[9],
                      isAvailable: !isSubmitted,
                      usageCount: wordUsageCount[wordBank[9]] ?? 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Column 3: 3 rows
              Expanded(
                child: Column(
                  children: [
                    for (int i = 6; i < 9; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: i < 8 ? 8 : 0),
                        child: _DraggableWord(
                          word: wordBank[i],
                          isAvailable: !isSubmitted,
                          usageCount: wordUsageCount[wordBank[i]] ?? 0,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Draggable Word Widget
class _DraggableWord extends StatelessWidget {
  final String word;
  final bool isAvailable;
  final int usageCount;

  const _DraggableWord({
    required this.word,
    required this.isAvailable,
    required this.usageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: word,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade400,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Text(
            word,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          word,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.blue.shade200 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAvailable ? Colors.blue.shade400 : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  word,
                  style: TextStyle(
                    color: isAvailable ? Colors.black87 : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (usageCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    usageCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fill in the Blanks Widget
class _FillInBlanksWidget extends StatelessWidget {
  final Map<int, String?> userAnswers;
  final Map<int, String> correctAnswers;
  final Function(int, String) onWordDropped;
  final Color Function(int) getBlankColor;
  final bool isSubmitted;

  const _FillInBlanksWidget({
    required this.userAnswers,
    required this.correctAnswers,
    required this.onWordDropped,
    required this.getBlankColor,
    required this.isSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParagraph(
            textParts: [
              "Using a J-shaped piece of glass tubing that was sealed on one end that ",
              " employed, he was able to establish the relationship between ",
              " and ",
              ". He noticed that when ",
              " is held constant, the ",
              " of a given amount of gas decreases as the pressure is ",
              ". On the contrary, if the pressure that is applied is ",
              ", the gas ",
              " becomes larger.",
            ],
            blanks: [1, 2, 3, 4, 5, 6, 7, 8],
          ),
          const SizedBox(height: 20),
          _buildParagraph(
            textParts: [
              "Boyle's experiment proved that the ",
              " is ",
              " proportional to the volume of gas at constant ",
              ", that is the volume decreases with the increasing ",
              " and vice-versa.",
            ],
            blanks: [9, 10, 11, 12],
          ),
          const SizedBox(height: 20),
          _buildParagraph(
            textParts: [
              "Mathematically, Boyle's law can be expressed as ",
              ", where P1 is the ",
              " and V2 is the ",
              " of a given gas.",
            ],
            blanks: [13, 14, 15],
          ),
        ],
      ),
    );
  }

  Widget _buildParagraph({
    required List<String> textParts,
    required List<int> blanks,
  }) {
    final spans = <InlineSpan>[];
    
    for (int i = 0; i < textParts.length; i++) {
      // Add text part
      spans.add(
        TextSpan(
          text: textParts[i],
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      );
      
      // Add blank box if there's a corresponding blank
      if (i < blanks.length) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _BlankBox(
              blankNumber: blanks[i],
              userAnswer: userAnswers[blanks[i]],
              correctAnswer: correctAnswers[blanks[i]],
              onWordDropped: onWordDropped,
              getBlankColor: getBlankColor,
              isSubmitted: isSubmitted,
            ),
          ),
        );
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.justify,
    );
  }
}

/// Blank Box Widget (Drop Target)
class _BlankBox extends StatelessWidget {
  final int blankNumber;
  final String? userAnswer;
  final String? correctAnswer;
  final Function(int, String) onWordDropped;
  final Color Function(int) getBlankColor;
  final bool isSubmitted;

  const _BlankBox({
    required this.blankNumber,
    required this.userAnswer,
    required this.correctAnswer,
    required this.onWordDropped,
    required this.getBlankColor,
    required this.isSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (word) => onWordDropped(blankNumber, word.data),
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        final backgroundColor = getBlankColor(blankNumber);
        final isEmpty = userAnswer == null;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          constraints: const BoxConstraints(
            minWidth: 100,
            minHeight: 32,
            maxHeight: 32,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.blue.shade100
                : isEmpty
                    ? Colors.grey.shade100
                    : backgroundColor != Colors.transparent
                        ? backgroundColor
                        : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isHighlighted
                  ? Colors.blue.shade400
                  : isEmpty
                      ? Colors.grey.shade400
                      : backgroundColor != Colors.transparent
                          ? backgroundColor
                          : Colors.grey.shade300,
              width: isHighlighted ? 2 : 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$blankNumber.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              if (userAnswer != null)
                Flexible(
                  child: Text(
                    userAnswer!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Text(
                  'Drop here',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (isSubmitted && userAnswer != null && correctAnswer != null) ...[
                const SizedBox(width: 4),
                Icon(
                  userAnswer!.trim().toLowerCase() ==
                          correctAnswer!.trim().toLowerCase()
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 14,
                  color: userAnswer!.trim().toLowerCase() ==
                          correctAnswer!.trim().toLowerCase()
                      ? Colors.green
                      : Colors.red,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Results Widget
class _ResultsWidget extends StatelessWidget {
  final int score;
  final int total;
  final String remarks;
  final VoidCallback onReset;

  const _ResultsWidget({
    required this.score,
    required this.total,
    required this.remarks,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / total) * 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300, width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'Results',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Score: $score / $total',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: percentage >= 70 ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: percentage >= 70 ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              remarks,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: percentage >= 70 ? Colors.green.shade900 : Colors.orange.shade900,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
