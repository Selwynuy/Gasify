import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'models/diving_state.dart';
import 'services/diving_physics_service.dart';
import '../../../settings/screens/settings_screen.dart';
import 'widgets/underwater_background.dart';
import 'widgets/diver_widget.dart';
import 'widgets/action_buttons.dart';
import 'widgets/instruction_strip.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/constants/app_constants.dart';

/// Scuba diving Boyle's Law activity screen.
/// Context: A recreational diver ascending quickly while holding breath.
class ScubaDivingActivity extends StatefulWidget {
  const ScubaDivingActivity({super.key});

  @override
  State<ScubaDivingActivity> createState() => _ScubaDivingActivityState();
}

class _ScubaDivingActivityState extends State<ScubaDivingActivity>
    with TickerProviderStateMixin {
  late DivingState _state;
  late AnimationController _controller;
  AnimationController? _warningFlashController;
  late Animation<double> _depthAnimation;
  double _targetDepth = 10.0;
  bool _showEmergencyWarning = false;
  bool _showO2CriticalWarning = false;
  bool _diverDead = false;
  /// Tracks whether the user has used the DESCEND button (for instruction steps).
  bool _hasUsedDescend = false;

  AnimationController get _warningController {
    _warningFlashController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    return _warningFlashController!;
  }

  final List<Offset> _graphPoints = [];



  @override
  void initState() {
    super.initState();
    _state = DivingState(
      depthMeters: 10.0,
      lungVolumeLiters: 3.0,
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _depthAnimation = Tween<double>(
      begin: _state.depthMeters,
      end: _targetDepth,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() {
          _state.setDepth(_depthAnimation.value);
          _addGraphPoint();
          _checkO2AndDeath();
        });
      });

    _addGraphPoint();
    
    // Start bubbles background music
    SoundService().playBubblesMusic();
  }

  @override
  void dispose() {
    // Stop bubbles music when leaving the activity
    SoundService().stopBubblesMusic();
    _controller.dispose();
    _warningFlashController?.dispose();
    super.dispose();
  }


  void _animateToDepth(double newDepth) {
    _targetDepth = newDepth;
    _depthAnimation = Tween<double>(
      begin: _state.depthMeters,
      end: _targetDepth,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() {
          _state.setDepth(_depthAnimation.value);
          _addGraphPoint();
          _checkO2AndDeath();
        });
      });
    _controller
      ..reset()
      ..forward();
  }

  void _animateToDepthRapid(double newDepth) {
    _targetDepth = newDepth;
    _controller.duration = const Duration(milliseconds: 100);
    _depthAnimation = Tween<double>(
      begin: _state.depthMeters,
      end: _targetDepth,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear))
      ..addListener(() {
        setState(() {
          _state.setDepth(_depthAnimation.value);
          _addGraphPoint();
          _checkO2AndDeath();
        });
      });
    _controller
      ..reset()
      ..forward();
  }

  void _onAscendSlowly() {
    if (_diverDead) return;
    setState(() {
      _state.consumeOxygen(amount: 0.5);
      _checkO2AndDeath();
    });
    final newDepth = DivingPhysicsService.ascendDepthStep(_state.depthMeters);
    
    if (_controller.isAnimating) {
      _animateToDepthRapid(newDepth);
    } else {
      _animateToDepth(newDepth);
    }
  }

  void _onDescend() {
    if (_diverDead) return;
    _hasUsedDescend = true;
    setState(() {
      _state.consumeOxygen(amount: 0.5);
      _checkO2AndDeath();
    });
    final newDepth = DivingPhysicsService.descendDepthStep(_state.depthMeters);
    
    if (_controller.isAnimating) {
      _animateToDepthRapid(newDepth);
    } else {
      _animateToDepth(newDepth);
    }
  }

  void _onEmergencyAscent() {
    if (_diverDead) return;
    setState(() {
      _state.consumeOxygen(amount: 1.0);
      _checkO2AndDeath();
    });
    final newDepth = DivingPhysicsService.emergencyAscentDepth(_state.depthMeters);
    
    setState(() {
      _showEmergencyWarning = true;
    });
    _warningController.repeat(reverse: true);
    
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showEmergencyWarning = false;
        });
        _warningFlashController?.stop();
        _warningFlashController?.reset();
      }
    });
    
    _animateToDepth(newDepth);
  }

  void _onExhale() {
    if (_diverDead) return;
    setState(() {
      _state.exhale(liters: 0.7);
      _state.consumeOxygen(amount: 0.3);
      _addGraphPoint();
      _checkO2AndDeath();
    });
  }

  void _addGraphPoint() {
    _graphPoints.add(Offset(_state.lungVolumeLiters, _state.pressureAtm));
    if (_graphPoints.length > 50) {
      _graphPoints.removeAt(0);
    }
  }

  void _checkO2AndDeath() {
    if (_diverDead) return;
    if (_state.oxygenTankPercent <= AppConstants.minOxygenTankPercent &&
        _state.depthMeters > AppConstants.deathDepthMeters) {
      _diverDead = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showDeathModal();
      });
      return;
    }
    _showO2CriticalWarning = _state.oxygenTankPercent <= AppConstants.criticalOxygenPercent &&
        _state.oxygenTankPercent > AppConstants.minOxygenTankPercent;
  }

  void _showDeathModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Diver Has Died'),
        content: const Text(
          'Oxygen ran out while still deep underwater. '
          'Always monitor your O2 tank and ascend before it runs empty.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _resetActivity();
            },
            child: const Text('Reset & Try Again'),
          ),
        ],
      ),
    );
  }

  /// Current instruction step (0–4) derived from user actions and depth.
  int get _instructionStep {
    final depth = _state.depthMeters;
    if (!_hasUsedDescend) return 0;
    if (depth < 20) return 1;
    if (depth < 30) return 2;
    return 3;
  }

  String _getInstructionText() {
    switch (_instructionStep) {
      case 0:
        return "1. Tap or click and hold the DESCEND button (the large blue circle at the bottom center).";
      case 1:
        return "2. Watch the DEPTH box in the top-left corner as the numbers increase.";
      case 2:
        return "3. Release the button exactly when the depth reaches 30 m.";
      case 3:
        return "4. At 30 m, the parentheses show (4 ATM). Verify on the Pressure-Volume Graph—the orange dot will be at the 4.0 line on the Pressure (atm) axis.";
      default:
        return "Follow the steps to complete the activity.";
    }
  }

  void _resetActivity() {
    _controller.stop();
    _controller.reset();
    _hasUsedDescend = false;
    _diverDead = false;
    _showO2CriticalWarning = false;
    _warningFlashController?.stop();
    _warningFlashController?.reset();
    setState(() {
      _state = DivingState(
        depthMeters: 10.0,
        lungVolumeLiters: 3.0,
      );
      
      _state.pressureAtm = 1.0 + 10.0 / 10.0;
      _state.lungVolumeLiters = 3.0;
      
      _targetDepth = 10.0;
      _graphPoints.clear();
      
      _depthAnimation = Tween<double>(
        begin: 10.0,
        end: 10.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
        ..addListener(() {
          setState(() {
            if ((_depthAnimation.value - _state.depthMeters).abs() > 0.01) {
              _state.setDepth(_depthAnimation.value);
            }
            _addGraphPoint();
          });
        });
      
      _addGraphPoint();
    });
  }



  @override
  Widget build(BuildContext context) {
    final double normalizedLungVolume =
        ((_state.lungVolumeLiters - 2.0) / (6.0 - 2.0)).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings, color: Colors.white, size: 24),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(onResetActivity: _resetActivity),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const UnderwaterBackground(),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                    if (_showEmergencyWarning)
                          Positioned(
                            top: 180,
                            right: 12,
                            child: AnimatedBuilder(
                              animation: _warningController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _warningController.value,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade900,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.yellow,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.8),
                                          blurRadius: 15,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.yellow,
                                          size: 24,
                                        ),
                                        SizedBox(width: 8),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'EMERGENCY ASCENT!',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'EXHALE CONTINUOUSLY!',
                                              style: TextStyle(
                                                color: Colors.yellow,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        Positioned.fill(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          InstructionStrip(
                            text: _getInstructionText(),
                            isFinalStep: _instructionStep == 3,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade700.withOpacity(0.8),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'DEPTH: ${_state.depthMeters.toStringAsFixed(0)}m (${_state.pressureAtm.toStringAsFixed(0)} ATM)',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'LUNG VOLUME: ${_state.lungVolumeLiters.toStringAsFixed(1)} L',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Transform.scale(
                                            scale: 0.85,
                                            alignment: Alignment.topLeft,
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              height: 150,
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade700.withOpacity(0.8),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text(
                                                        'O2 TANK',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${_state.oxygenTankPercent.toStringAsFixed(0)}%',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 35),
                                                  SizedBox(
                                                    height: 35,
                                                    child: _CurvedO2Gauge(
                                                      key: ValueKey(_state.oxygenTankPercent),
                                                      percentage: _state.oxygenTankPercent,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${_state.oxygenTankPercent.toStringAsFixed(0)}%',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          SizedBox(
                                            height: 150,
                                            child: _PressureVolumeGraph(
                                              points: _graphPoints,
                                              currentVolume: _state.lungVolumeLiters,
                                              currentPressure: _state.pressureAtm,
                                            ),
                                          ),
                                          if (_showO2CriticalWarning && !_diverDead) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade900.withValues(alpha: 0.9),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.amber,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.warning_amber_rounded,
                                                    color: Colors.amber,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      'O2 CRITICAL! Ascend soon!',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Expanded(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _controller,
                                      builder: (context, child) {
                                        final depthOffset = (_state.depthMeters - 10.0) * 2.0;
                                        return Transform.translate(
                                          offset: Offset(0, depthOffset),
                                          child: DiverWidget(
                                            normalizedLungVolume: normalizedLungVolume,
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: ActionButton(
                          label: 'ASCEND SLOWLY',
                          onPressed: _onAscendSlowly,
                          color: Colors.lightBlue,
                        ),
                      ),
                      Flexible(
                        child: ActionButton(
                          label: 'EXHALE',
                          onPressed: _onExhale,
                          color: Colors.red,
                          isPrimary: true,
                        ),
                      ),
                      Flexible(
                        child: ActionButton(
                          label: 'EMERGENCY ASCENT',
                          onPressed: _onEmergencyAscent,
                          color: Colors.lightBlue,
                          allowHold: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ActionButton(
                    label: 'DESCEND',
                    onPressed: _onDescend,
                    color: Colors.blue,
                    isSecondary: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ),
      ],
      ),
    );
  }
}

class _PressureVolumeGraph extends StatelessWidget {
  final List<Offset> points;
  final double currentVolume;
  final double currentPressure;

  const _PressureVolumeGraph({
    required this.points,
    required this.currentVolume,
    required this.currentPressure,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Pressure-Volume Graph',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                const RotatedBox(
                  quarterTurns: -1,
                  child: Text(
                    'Pressure (atm)',
                    style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: CustomPaint(
                    painter: _GraphPainter(
                      points: points,
                      currentVolume: currentVolume,
                      currentPressure: currentPressure,
                    ),
                    child: Container(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Volume (L)',
            style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<Offset> points;
  final double currentVolume;
  final double currentPressure;

  _GraphPainter({
    required this.points,
    required this.currentVolume,
    required this.currentPressure,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPadding = 25;
    const double bottomPadding = 15;
    const double rightPadding = 8;
    const double topPadding = 8;

    final double graphWidth = size.width - leftPadding - rightPadding;
    final double graphHeight = size.height - topPadding - bottomPadding;

    final Offset origin = Offset(leftPadding, size.height - bottomPadding);

    final paint = Paint()
      ..color = Colors.orange.shade600
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.deepOrange
      ..style = PaintingStyle.fill;

    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;

    canvas.drawLine(origin, Offset(origin.dx + graphWidth, origin.dy), axisPaint);
    canvas.drawLine(origin, Offset(origin.dx, origin.dy - graphHeight), axisPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    
    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.9),
      fontSize: 8,
    );

    const int numGridLines = 5;
    const maxVolume = 10.0;
    const maxPressure = 8.0;

    for (int i = 0; i <= numGridLines; i++) {
      final y = origin.dy - (i * graphHeight / numGridLines);
      if (i > 0) {
        canvas.drawLine(Offset(origin.dx, y), Offset(origin.dx + graphWidth, y), gridPaint);
      }

      final pressure = (i * maxPressure / numGridLines);
      final textSpan = TextSpan(text: pressure.toStringAsFixed(1), style: textStyle);
      final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(origin.dx - textPainter.width - 4, y - textPainter.height / 2));
    }

    for (int i = 0; i <= numGridLines; i++) {
      final x = origin.dx + (i * graphWidth / numGridLines);
      if (i > 0) {
        canvas.drawLine(Offset(x, origin.dy), Offset(x, origin.dy - graphHeight), gridPaint);
      }

      final volume = (i * maxVolume / numGridLines);
      final textSpan = TextSpan(text: volume.toStringAsFixed(1), style: textStyle);
      final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, origin.dy + 4));
    }

    if (points.length > 1) {
      final path = Path();
      bool isFirst = true;

      for (final point in points) {
        final x = origin.dx + (point.dx / maxVolume) * graphWidth;
        final y = origin.dy - (point.dy / maxPressure) * graphHeight;

        final clampedX = x.clamp(origin.dx, origin.dx + graphWidth);
        final clampedY = y.clamp(origin.dy - graphHeight, origin.dy);

        if (isFirst) {
          path.moveTo(clampedX, clampedY);
          isFirst = false;
        } else {
          path.lineTo(clampedX, clampedY);
        }
      }
      
      final pathPaint = Paint()
        ..color = Colors.orange.shade600
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      
      canvas.drawPath(path, pathPaint);
    }

    if (currentVolume > 0 && currentPressure > 0) {
      final x = origin.dx + (currentVolume / maxVolume) * graphWidth;
      final y = origin.dy - (currentPressure / maxPressure) * graphHeight;

      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      canvas.drawCircle(Offset(x, y), 4, paint..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CurvedO2Gauge extends StatelessWidget {
  final double percentage;

  _CurvedO2Gauge({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _CurvedGaugePainter(percentage: percentage),
        );
      },
    );
  }
}

class _CurvedGaugePainter extends CustomPainter {
  final double percentage;

  _CurvedGaugePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height - 5;
    final radius = size.width * 0.4;
    
    final rect = Rect.fromLTWH(
      centerX - radius,
      centerY - radius,
      radius * 2,
      radius * 2,
    );
    
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, backgroundPaint);
    
    final percentageSweep = (percentage / 100.0) * math.pi;
    
    // Draw yellow portion (0-50%) from left (180°) to top (90°)
    if (percentage > 0) {
      final yellowPaint = Paint()
        ..color = Colors.yellow
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      final yellowSweep = math.min(percentageSweep, math.pi * 0.5);
      if (yellowSweep > 0) {
        canvas.drawArc(rect, startAngle, yellowSweep, false, yellowPaint);
      }
    }
    
    // Draw red portion (50-100%) from top (90°) to right (0°)
    if (percentage > 50) {
      final redPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      // Yellow goes from 180° (left) to 90° (top) = first 50%
      // Red goes from 90° (top) to 0° (right) = second 50%
      const redStartAngle = math.pi *1.5; // 90°, top
      final redSweep = (percentageSweep - math.pi * 0.5).clamp(0.0, math.pi * 0.5);
      if (redSweep > 0) {
        canvas.drawArc(rect, redStartAngle, redSweep, false, redPaint);
      }
    }
    
    final indicatorAngle = startAngle - percentageSweep;
    final indicatorX = centerX + radius * math.cos(indicatorAngle);
    final indicatorY = centerY - radius * math.sin(indicatorAngle);
    
    final indicatorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(indicatorX, indicatorY), 5, indicatorPaint);
    
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(indicatorX, indicatorY), 5, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _CurvedGaugePainter) {
      return oldDelegate.percentage != percentage;
    }
    return true;
  }
}

