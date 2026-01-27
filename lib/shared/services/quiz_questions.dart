import '../dialogs/quiz_unlock_dialog.dart';

/// Quiz questions for each gas law
class QuizQuestions {
  static const boylesLawQuestion = QuizQuestion(
    question: "What relationship is described by Boyle's Law",
    options: [
      "A. temperature+pressure+volume",
      "B. volume+pressure at constant temperature",
      "C. volume+temperature at constant pressure",
    ],
    correctAnswerIndex: 1, // B
  );

  static const charlesLawQuestion = QuizQuestion(
    question: "What relationship is described by Charles's Law",
    options: [
      "A. volume+temperature at constant pressure",
      "B. temperature+pressure+volume",
      "C. volume+pressure at constant temperature",
    ],
    correctAnswerIndex: 0, // A
  );

  static const combinedGasLawQuestion = QuizQuestion(
    question: "What relationship is described by Mixed Gas Law",
    options: [
      "A. volume+pressure at constant temperature",
      "B. volume+temperature at constant pressure",
      "C. temperature+pressure+volume",
    ],
    correctAnswerIndex: 2, // C
  );
}

