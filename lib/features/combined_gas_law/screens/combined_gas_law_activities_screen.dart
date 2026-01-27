import 'package:flutter/material.dart';
import '../activities/cryo_sim/cryo_sim_activity.dart';
import '../activities/true_false/true_false_activity.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../shared/services/activity_unlock_service.dart';
import '../../../shared/dialogs/quiz_unlock_dialog.dart';
import '../../../shared/services/quiz_questions.dart';

/// Screen for selecting which Combined Gas Law activity to explore.
class CombinedGasLawActivitiesScreen extends StatefulWidget {
  const CombinedGasLawActivitiesScreen({super.key});

  @override
  State<CombinedGasLawActivitiesScreen> createState() => _CombinedGasLawActivitiesScreenState();
}

class _CombinedGasLawActivitiesScreenState extends State<CombinedGasLawActivitiesScreen> {
  bool _trueFalseUnlocked = false;

  @override
  void initState() {
    super.initState();
    _checkUnlockStatus();
  }

  Future<void> _checkUnlockStatus() async {
    final trueFalseUnlocked = await ActivityUnlockService.isActivityUnlocked('combined_true_false');
    setState(() {
      _trueFalseUnlocked = trueFalseUnlocked;
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
      if (!mounted) return;
      final result = await showDialog<bool>(
        context: navigatorContext,
        builder: (context) => QuizUnlockDialog(
          question: QuizQuestions.combinedGasLawQuestion,
          onUnlocked: () async {
            await ActivityUnlockService.unlockActivity(activityKey);
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Combined Gas Law Activities",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ActivityButton(
                            title: "Cryo-sim",
                            icon: Icons.ac_unit,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CryoSimActivity()),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _ActivityButton(
                            title: "True or False",
                            icon: Icons.check_circle_outline,
                            isLocked: !_trueFalseUnlocked,
                            onPressed: () {
                              _handleActivityTap(
                                'combined_true_false',
                                const TrueFalseActivity(),
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

