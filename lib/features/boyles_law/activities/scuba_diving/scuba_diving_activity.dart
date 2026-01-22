import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'models/diving_state.dart';
import 'services/diving_physics_service.dart';
import '../../../settings/screens/settings_screen.dart';
import 'widgets/underwater_background.dart';
import 'widgets/diver_widget.dart';
import 'widgets/action_buttons.dart';

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

  AnimationController get _warningController {
    _warningFlashController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    return _warningFlashController!;
  }

  // Graph data
  final List<Offset> _graphPoints = [];



  @override
  void initState() {
    super.initState();
    _state = DivingState(
      depthMeters: 10.0,
      lungVolumeLiters: 3.0, // At 10m (2 ATA), lungs = 3L (from 6L at surface)
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
        });
      });

    _addGraphPoint();
  }

  @override
  void dispose() {
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
        });
      });
    _controller
      ..reset()
      ..forward();
  }

  void _animateToDepthRapid(double newDepth) {
    // For rapid updates (holding), use very short animation for smooth motion
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
        });
      });
    _controller
      ..reset()
      ..forward();
  }

  void _onAscendSlowly() {
    setState(() {
      _state.consumeOxygen(amount: 0.001); // Consume once per action
    });
    final newDepth = DivingPhysicsService.ascendDepthStep(_state.depthMeters);
    
    // If animation is running (button being held), use rapid smooth animation
    if (_controller.isAnimating) {
      _animateToDepthRapid(newDepth);
    } else {
      _animateToDepth(newDepth);
    }
  }

  void _onDescend() {
    setState(() {
      _state.consumeOxygen(amount: 0.001); // Consume once per action
    });
    final newDepth = DivingPhysicsService.descendDepthStep(_state.depthMeters);
    
    // If animation is running (button being held), use rapid smooth animation
    if (_controller.isAnimating) {
      _animateToDepthRapid(newDepth);
    } else {
      _animateToDepth(newDepth);
    }
  }

  void _onEmergencyAscent() {
    setState(() {
      _state.consumeOxygen(amount: 0.001); // Consume once per action
    });
    final newDepth = DivingPhysicsService.emergencyAscentDepth(_state.depthMeters);
    
    // Show flashing warning
    setState(() {
      _showEmergencyWarning = true;
    });
    // Start flashing animation
    _warningController.repeat(reverse: true);
    
    // Hide warning after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showEmergencyWarning = false;
        });
        _warningFlashController?.stop();
        _warningFlashController?.reset();
      }
    });
    
    // Emergency ascent is always a single dramatic action
    _animateToDepth(newDepth);
  }

  void _onExhale() {
    setState(() {
      _state.exhale(liters: 0.7);
      _state.consumeOxygen(amount: 0.002); // 10x bigger capacity
      _addGraphPoint();
    });
  }

  void _addGraphPoint() {
    _graphPoints.add(Offset(_state.lungVolumeLiters, _state.pressureAtm));
    if (_graphPoints.length > 50) {
      _graphPoints.removeAt(0);
    }
  }

  void _resetActivity() {
    // Stop any ongoing animation first
    _controller.stop();
    _controller.reset();
    
    setState(() {
      // Reset to depth 10.0m (2.0 atm) with lung volume 3.0L
      // At 10m depth, pressure is 2.0 atm
      // At surface (1 ATA): lungs = 6L, so at 10m (2 ATA): lungs = 3L (Boyle's Law)
      _state = DivingState(
        depthMeters: 10.0,
        lungVolumeLiters: 3.0,
      );
      
      // Manually ensure pressure matches depth (2.0 atm at 10m)
      _state.pressureAtm = 1.0 + 10.0 / 10.0; // 2.0 atm
      // Ensure lung volume is 3.0L at 10m
      _state.lungVolumeLiters = 3.0;
      
      _targetDepth = 10.0;
      _graphPoints.clear();
      
      // Recreate animation with correct initial values (both start and end at 10.0m)
      _depthAnimation = Tween<double>(
        begin: 10.0,
        end: 10.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
        ..addListener(() {
          setState(() {
            // Only update if depth actually changes significantly
            if ((_depthAnimation.value - _state.depthMeters).abs() > 0.01) {
              _state.setDepth(_depthAnimation.value);
            }
            _addGraphPoint();
          });
        });
      
      // Add initial graph point
      _addGraphPoint();
    });
  }



  @override
  Widget build(BuildContext context) {
    // Normalize lung volume: range is 2L (at 20m/3 ATA) to 6L (at surface/1 ATA)
    final double normalizedLungVolume =
        ((_state.lungVolumeLiters - 2.0) / (6.0 - 2.0)).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
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
                color: Colors.white.withValues(alpha: 0.2),
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
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF003366),
              Color(0xFF006699),
              Color(0xFF001122),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Underwater background elements (coral, fish, etc.)
              const UnderwaterBackground(),
              
              // Emergency warning - right side, below HUD
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
                                color: Colors.red.withValues(alpha: 0.8),
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
              
              // Main content
              Positioned.fill(
                child: Column(
                  children: [
                    // Top HUD panels
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side - Two separate containers
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Depth and Lung Volume container
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade700.withValues(alpha: 0.8),
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
                                // O2 Tank gauge container - separate (scaled to 85%)
                                Transform.scale(
                                  scale: 0.85,
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade700.withValues(alpha: 0.8),
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
                                          child: _CurvedO2Gauge(percentage: _state.oxygenTankPercent),
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
                          // Right side - Pressure vs Volume graph
                          Expanded(
                            child: SizedBox(
                              height: 150,
                              child: _PressureVolumeGraph(
                                points: _graphPoints,
                                currentVolume: _state.lungVolumeLiters,
                                currentPressure: _state.pressureAtm,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Center - Diver with lungs inside
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Diver widget
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              // Add subtle vertical movement based on depth change
                              final depthOffset = (_state.depthMeters - 10.0) * 2.0; // Scale for visibility
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

                    // Bottom control buttons
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Action buttons
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
                                  allowHold: false, // Single click only
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
            ],
          ),
        ),
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
    const maxPressure = 5.0;

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

    // Draw the path line connecting all points
    if (points.length > 1) {
      final path = Path();
      bool isFirst = true;

      for (final point in points) {
        final x = origin.dx + (point.dx / maxVolume) * graphWidth;
        final y = origin.dy - (point.dy / maxPressure) * graphHeight;

        // Clamp coordinates to graph bounds
        final clampedX = x.clamp(origin.dx, origin.dx + graphWidth);
        final clampedY = y.clamp(origin.dy - graphHeight, origin.dy);

        if (isFirst) {
          path.moveTo(clampedX, clampedY);
          isFirst = false;
        } else {
          path.lineTo(clampedX, clampedY);
        }
      }
      
      // Draw the path with a thicker, more visible line
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

  const _CurvedO2Gauge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CurvedGaugePainter(percentage: percentage),
    );
  }
}

class _CurvedGaugePainter extends CustomPainter {
  final double percentage;

  _CurvedGaugePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height - 5; // Position arc closer to bottom
    final radius = size.width * 0.4; // Smaller radius for compact gauge
    
    // Draw the arc from left to right, curving upward (semicircle)
    final rect = Rect.fromLTWH(
      centerX - radius,
      centerY - radius,
      radius * 2,
      radius * 2,
    );
    
    // Full arc path (180 degrees, from left to right, curving upward)
    const startAngle = math.pi; // Start at left (180°)
    const sweepAngle = math.pi; // Full semicircle to right (0°)
    
    // Draw the background arc (dark gray) - thinner stroke
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, backgroundPaint);
    
    // Calculate the angle for the percentage (from left to right)
    final percentageSweep = (percentage / 100.0) * math.pi;
    
    // Draw yellow portion (safe zone, left side - first 50%)
    final yellowPaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final yellowSweep = math.min(percentageSweep, math.pi * 0.5); // Yellow covers first 50%
    if (yellowSweep > 0) {
      canvas.drawArc(rect, startAngle, yellowSweep, false, yellowPaint);
    }
    
    // Draw red portion (critical zone, right side - last 50%)
    if (percentage > 50) {
      final redPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      const redStartAngle = math.pi * 0.5; // Start at top (90°), where yellow ends
      final redSweep = percentageSweep - math.pi * 0.5;
      if (redSweep > 0) {
        canvas.drawArc(rect, redStartAngle, redSweep, false, redPaint);
      }
    }
    
    // Draw indicator dot at current percentage position - smaller
    final indicatorAngle = startAngle - percentageSweep;
    final indicatorX = centerX + radius * math.cos(indicatorAngle);
    final indicatorY = centerY - radius * math.sin(indicatorAngle);
    
    final indicatorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(indicatorX, indicatorY), 5, indicatorPaint);
    
    // Draw border around indicator
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

