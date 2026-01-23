import 'package:flutter/material.dart';
import '../activities/balloon_bottle/balloon_bottle_activity.dart';
import '../activities/rubber_boat/rubber_boat_activity.dart';
import '../quiz/drag_drop_quiz_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../shared/services/activity_unlock_service.dart';
import '../../../shared/dialogs/quiz_unlock_dialog.dart';
import '../../../shared/services/quiz_questions.dart';

/// Screen for selecting which Charles Law activity to explore.
class CharlesLawActivitiesScreen extends StatefulWidget {
  const CharlesLawActivitiesScreen({super.key});

  @override
  State<CharlesLawActivitiesScreen> createState() => _CharlesLawActivitiesScreenState();
}

class _CharlesLawActivitiesScreenState extends State<CharlesLawActivitiesScreen> {
  bool _rubberBoatUnlocked = false;
  bool _quizUnlocked = false;

  @override
  void initState() {
    super.initState();
    _checkUnlockStatus();
  }

  Future<void> _checkUnlockStatus() async {
    final rubberBoatUnlocked = await ActivityUnlockService.isActivityUnlocked('charles_rubber_boat');
    final quizUnlocked = await ActivityUnlockService.isActivityUnlocked('charles_quiz');
    setState(() {
      _rubberBoatUnlocked = rubberBoatUnlocked;
      _quizUnlocked = quizUnlocked;
    });
  }

  Future<void> _handleActivityTap(String activityKey, Widget activityScreen) async {
    if (!mounted) return;
    final navigatorContext = context;
    
    final isUnlocked = await ActivityUnlockService.isActivityUnlocked(activityKey);
    
    if (isUnlocked && mounted) {
      Navigator.push(
        navigatorContext,
        MaterialPageRoute(builder: (context) => activityScreen),
      );
    } else {
      // Show quiz dialog directly
      if (!mounted) return;
      final result = await showDialog<bool>(
        context: navigatorContext,
        builder: (context) => QuizUnlockDialog(
          question: QuizQuestions.charlesLawQuestion,
          onUnlocked: () async {
            await ActivityUnlockService.unlockActivity(activityKey);
            // Auto-unlock Drag and Drop Quiz when Rubber Boat is unlocked
            if (activityKey == 'charles_rubber_boat') {
              await ActivityUnlockService.unlockActivity('charles_quiz');
            }
            await _checkUnlockStatus();
          },
        ),
      );
      
      if (result == true && mounted) {
        Navigator.push(
          navigatorContext,
          MaterialPageRoute(builder: (context) => activityScreen),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Top bar with icons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.help_outline, color: Colors.white, size: 24),
                      ),
                      onPressed: () {
                        // TODO: Show info dialog
                      },
                    ),
                    // Settings button
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.settings, color: Colors.white, size: 24),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Charles Law Activities",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Main content
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ActivityButton(
                            title: "Balloon and Bottle",
                            icon: Icons.science,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const BalloonBottleActivity()),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _ActivityButton(
                            title: "Rubber Boat",
                            icon: Icons.directions_boat,
                            isLocked: !_rubberBoatUnlocked,
                            onPressed: () {
                              _handleActivityTap(
                                'charles_rubber_boat',
                                const RubberBoatActivity(),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _ActivityButton(
                            title: "Drag and Drop Quiz",
                            icon: Icons.quiz,
                            isLocked: !_quizUnlocked,
                            onPressed: () {
                              _handleActivityTap(
                                'charles_quiz',
                                const DragDropQuizScreen(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glowing activity selection button.
class _ActivityButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLocked;

  const _ActivityButton({
    required this.title,
    required this.icon,
    required this.onPressed,
    this.isLocked = false,
  });

  @override
  State<_ActivityButton> createState() => _ActivityButtonState();
}

class _ActivityButtonState extends State<_ActivityButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.lightBlue.withValues(alpha: _glowAnimation.value * 0.8),
                blurRadius: 20 * _glowAnimation.value,
                spreadRadius: 5 * _glowAnimation.value,
              ),
            ],
          ),
          child: SizedBox(
            width: 280,
            child: ElevatedButton.icon(
              onPressed: widget.onPressed,
              icon: widget.isLocked 
                  ? const Icon(Icons.lock, size: 28)
                  : Icon(widget.icon, size: 28),
              label: Text(widget.title),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isLocked 
                    ? Colors.grey.shade400
                    : Colors.lightBlue.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
            ),
          ),
        );
      },
    );
  }
}

