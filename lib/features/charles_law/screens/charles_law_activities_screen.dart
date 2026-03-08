import 'package:flutter/material.dart';
import '../activities/balloon_bottle/balloon_bottle_activity.dart';
import '../activities/rubber_boat/rubber_boat_activity.dart';
import '../quiz/drag_drop_quiz_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../shared/screens/think_and_solve_screen.dart';

/// Screen for selecting which Charles Law activity to explore.
class CharlesLawActivitiesScreen extends StatefulWidget {
  const CharlesLawActivitiesScreen({super.key});

  @override
  State<CharlesLawActivitiesScreen> createState() => _CharlesLawActivitiesScreenState();
}

class _CharlesLawActivitiesScreenState extends State<CharlesLawActivitiesScreen> {
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
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
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
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Charles's Law states that the volume of a fixed mass of an ideal gas is directly proportional to its absolute temperature (in Kelvin), provided pressure remains constant",
                    style: TextStyle(
                      fontSize: 16,
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RubberBoatActivity()),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _ActivityButton(
                            title: "Drag and Drop Quiz",
                            icon: Icons.quiz,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const DragDropQuizScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _ActivityButton(
                            title: "Think and Solve",
                            icon: Icons.menu_book,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ThinkAndSolveScreen(law: ThinkAndSolveLaw.charles),
                                ),
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

  const _ActivityButton({
    required this.title,
    required this.icon,
    required this.onPressed,
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
              icon: Icon(widget.icon, size: 28),
              label: Text(widget.title),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue.shade400,
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

