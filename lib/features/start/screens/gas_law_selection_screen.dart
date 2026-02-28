import 'package:flutter/material.dart';
import '../../boyles_law/screens/boyles_law_activities_screen.dart';
import '../../charles_law/screens/charles_law_activities_screen.dart';
import '../../combined_gas_law/screens/combined_gas_law_activities_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../shared/services/activity_unlock_service.dart';
import '../../../shared/dialogs/quiz_unlock_dialog.dart';
import '../../../shared/services/quiz_questions.dart';

/// Screen for selecting which gas law to explore.
class GasLawSelectionScreen extends StatefulWidget {
  const GasLawSelectionScreen({super.key});

  @override
  State<GasLawSelectionScreen> createState() => _GasLawSelectionScreenState();
}

class _GasLawSelectionScreenState extends State<GasLawSelectionScreen> {
  bool _boylesUnlocked = false;
  bool _charlesUnlocked = false;
  bool _combinedUnlocked = false;

  @override
  void initState() {
    super.initState();
    _checkUnlockStatus();
  }

  Future<void> _checkUnlockStatus() async {
    final boyles =
        await ActivityUnlockService.isActivityUnlocked('law_boyles');
    final charles =
        await ActivityUnlockService.isActivityUnlocked('law_charles');
    final combined =
        await ActivityUnlockService.isActivityUnlocked('law_combined');

    if (!mounted) return;
    setState(() {
      _boylesUnlocked = boyles;
      _charlesUnlocked = charles;
      _combinedUnlocked = combined;
    });
  }

  Future<void> _handleLawTap({
    required String lawKey,
    required Widget screen,
    required QuizQuestion? question,
    required bool isUnlocked,
  }) async {
    // If already unlocked or no question configured, just navigate.
    if (isUnlocked || question == null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
      return;
    }

    if (!mounted) return;
    final navigatorContext = context;

    final result = await showDialog<bool>(
      context: navigatorContext,
      builder: (context) => QuizUnlockDialog(
        question: question,
        onUnlocked: () async {
          await ActivityUnlockService.unlockActivity(lawKey);
          await _checkUnlockStatus();
        },
      ),
    );

    if (result == true && mounted) {
      Navigator.push(
        navigatorContext,
        MaterialPageRoute(builder: (context) => screen),
      );
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
                    // Home button
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.home, color: Colors.white, size: 24),
                      ),
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
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
              // Main content
              Expanded(
                child: Stack(
                  children: [
                    // Gas law buttons
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GasLawButton(
                            title: "Boyle's Law",
                            isLocked: !_boylesUnlocked,
                            onPressed: () {
                              _handleLawTap(
                                lawKey: 'law_boyles',
                                screen: const BoylesLawActivitiesScreen(),
                                question: QuizQuestions.boylesLawQuestion,
                                isUnlocked: _boylesUnlocked,
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _GasLawButton(
                            title: "Charles Law",
                            isLocked: !_charlesUnlocked,
                            onPressed: () {
                              _handleLawTap(
                                lawKey: 'law_charles',
                                screen: const CharlesLawActivitiesScreen(),
                                question: QuizQuestions.charlesLawQuestion,
                                isUnlocked: _charlesUnlocked,
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _GasLawButton(
                            title: "Combined Gas Law",
                            isLocked: !_combinedUnlocked,
                            onPressed: () {
                              _handleLawTap(
                                lawKey: 'law_combined',
                                screen: const CombinedGasLawActivitiesScreen(),
                                question: QuizQuestions.combinedGasLawQuestion,
                                isUnlocked: _combinedUnlocked,
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

/// Glowing gas law selection button.
class _GasLawButton extends StatefulWidget {
  final String title;
  final VoidCallback onPressed;
  final bool isLocked;

  const _GasLawButton({
    required this.title,
    required this.onPressed,
    this.isLocked = false,
  });

  @override
  State<_GasLawButton> createState() => _GasLawButtonState();
}

class _GasLawButtonState extends State<_GasLawButton>
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
                color: (widget.isLocked ? Colors.grey : Colors.lightBlue)
                    .withValues(alpha: _glowAnimation.value * 0.8),
                blurRadius: 20 * _glowAnimation.value,
                spreadRadius: 5 * _glowAnimation.value,
              ),
            ],
          ),
          child: SizedBox(
            width: 280,
            child: ElevatedButton(
              onPressed: widget.onPressed,
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
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

