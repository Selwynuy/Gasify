import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/services/sound_service.dart';

class SyringeTestActivity extends StatefulWidget {
  const SyringeTestActivity({super.key});

  @override
  State<SyringeTestActivity> createState() => _SyringeTestActivityState();
}

class _SyringeTestActivityState extends State<SyringeTestActivity> with SingleTickerProviderStateMixin {
  final double _maxVolume = 60.0;
  double _currentVolume = 30.0;
  double _plungerPosition = 0.5;
  
  bool _balloonInSyringe = false;
  Offset _balloonPosition = const Offset(250, 350);
  double _balloonSize = 1.0;
  bool _isAtMaxPressure = false;
  bool _isAnimatingBalloon = false;
  
  bool _isSealed = false;
  double _pressure = 1.0;
  double _initialVolume = 30.0;
  double _minVolume = 1.0;

  static const double _maxBalloonPressure = 3.0;
  static const double _balloonBaseHeight = 60.0;
  
  final List<Offset> _graphPoints = [];

  AnimationController? _balloonReleaseController;
  Animation<double>? _balloonReleaseAnimation;
  
  // Performance optimization: throttle setState during dragging
  DateTime? _lastUpdateTime;
  static const _minUpdateInterval = Duration(milliseconds: 16); // ~60fps max
  bool _isDraggingSoundPlaying = false; // Track if drag sound is currently playing

  @override
  void initState() {
    super.initState();
    _balloonReleaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _balloonReleaseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _balloonReleaseController!,
      curve: Curves.easeOut,
    ))
      ..addListener(() {
        if (mounted && _balloonReleaseAnimation != null) {
          setState(() {
            _balloonSize = _balloonReleaseAnimation!.value;
          });
        }
      });
    
    _resetActivity();
  }

  @override
  void dispose() {
    _balloonReleaseController?.dispose();
    super.dispose();
  }

  void _onPlungerDragStart(DragStartDetails details) {
    // Start continuous syringe drag sound as soon as user begins dragging
    if (!_isDraggingSoundPlaying) {
      SoundService().startSyringeDragSound();
      _isDraggingSoundPlaying = true;
    }
  }

  void _onPlungerDragUpdate(DragUpdateDetails details) {
    // Throttle updates to prevent excessive rebuilds
    final now = DateTime.now();
    if (_lastUpdateTime != null && now.difference(_lastUpdateTime!) < _minUpdateInterval) {
      return;
    }
    _lastUpdateTime = now;
    
    setState(() {
      final delta = -details.delta.dy / 300;
      double newPlungerPosition = (_plungerPosition + delta).clamp(0.0, 1.0);

      double newVolume = newPlungerPosition * _maxVolume;
      if (newVolume < 1) newVolume = 1;

      if (_balloonInSyringe) {
        if (_isSealed) {
          if (newVolume < _minVolume) {
            newVolume = _minVolume;
            newPlungerPosition = _minVolume / _maxVolume;
          }
        } else {
          final double balloonPhysicalHeight = _balloonBaseHeight * _balloonSize;
          const double typicalSyringeUsableHeight = 400.0;
          final double minVolumeUnsealed = (balloonPhysicalHeight / typicalSyringeUsableHeight) * _maxVolume;
          final double safeMinVolume = math.max(minVolumeUnsealed, _maxVolume * 0.1);
          if (newVolume < safeMinVolume) {
            newVolume = safeMinVolume;
            newPlungerPosition = safeMinVolume / _maxVolume;
          }
        }
      }

      _plungerPosition = newPlungerPosition;
      _currentVolume = newVolume;

      if (_isSealed && _balloonInSyringe) {
        if (_currentVolume > 0.1 && _initialVolume > 0) {
          double calculatedPressure = (1.0 * _initialVolume) / _currentVolume;
          
          if (calculatedPressure > _maxBalloonPressure) {
            _pressure = _maxBalloonPressure;
            _isAtMaxPressure = true;
            _currentVolume = (1.0 * _initialVolume) / _maxBalloonPressure;
            _plungerPosition = _currentVolume / _maxVolume;
          } else {
            _pressure = calculatedPressure;
            _isAtMaxPressure = false;
          }
          
          _pressure = _pressure.clamp(0.1, _maxBalloonPressure);
          if (!_isAnimatingBalloon) {
            _balloonSize = (1.0 / _pressure).clamp(0.5, 2.5);
          }
          _addGraphPoint();
        }
      }
    });
  }

  void _onPlungerDragEnd(DragEndDetails details) {
    _lastUpdateTime = null;
    
    // Stop syringe drag sound when dragging ends
    if (_isDraggingSoundPlaying) {
      SoundService().stopSyringeDragSound();
      _isDraggingSoundPlaying = false;
    }
    
    if (!_isSealed && _balloonInSyringe && _balloonReleaseController != null) {
      final double currentSize = _balloonSize;
      
      if ((currentSize - 1.0).abs() > 0.01) {
        _balloonReleaseController!.stop();
        _balloonReleaseController!.reset();
        
        if (_balloonReleaseAnimation != null) {
          _balloonReleaseAnimation!.removeListener(() {});
        }
        
        _balloonReleaseAnimation = Tween<double>(
          begin: currentSize,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _balloonReleaseController!,
          curve: Curves.easeOut,
        ));
        
        _isAnimatingBalloon = true;
        _balloonReleaseAnimation!.addListener(() {
          if (mounted) {
            setState(() {
              _balloonSize = _balloonReleaseAnimation!.value;
            });
          }
        });
        
        _balloonReleaseController!.addStatusListener((status) {
          if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
            _isAnimatingBalloon = false;
          }
        });
        
        _balloonReleaseController!.forward();
      }
      
      setState(() {
        _pressure = 1.0;
        _isAtMaxPressure = false;
        if ((currentSize - 1.0).abs() <= 0.01) {
          _balloonSize = 1.0;
        }
      });
    }
  }

  void _addGraphPoint() {
    _graphPoints.add(Offset(_currentVolume, _pressure));
    if (_graphPoints.length > 50) {
      _graphPoints.removeAt(0);
    }
  }

  void _onBalloonDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_balloonInSyringe) return;
    setState(() {
      _balloonPosition = Offset(
        (_balloonPosition.dx + details.delta.dx).clamp(0, constraints.maxWidth - 50),
        (_balloonPosition.dy + details.delta.dy).clamp(0, constraints.maxHeight - 60),
      );
    });
  }

  void _onBalloonDragEnd(DragEndDetails details) {
    const syringeOpeningX = 100.0;
    const syringeOpeningY = 450.0;

    if ((_balloonPosition.dx - syringeOpeningX).abs() < 100 &&
        (_balloonPosition.dy - syringeOpeningY).abs() < 100) {
      setState(() {
        _balloonInSyringe = true;
        _balloonSize = 1.0;
        _isAnimatingBalloon = false;
        _balloonReleaseController?.reset();
      });
    }
  }

  void _toggleSeal() {
    setState(() {
      _isSealed = !_isSealed;
      if (_isSealed && _balloonInSyringe) {
        // Stop any ongoing animations first
        _balloonReleaseController?.stop();
        _balloonReleaseController?.reset();
        _isAnimatingBalloon = false;
        
        // Ensure plunger position matches current volume to avoid mismatch
        _plungerPosition = _currentVolume / _maxVolume;
        _initialVolume = _currentVolume;
        _pressure = 1.0;
        _balloonSize = 1.0;
        _minVolume = (1.0 * _initialVolume) / _maxBalloonPressure;
        _isAtMaxPressure = false;
        _graphPoints.clear();
        _addGraphPoint();
      } else {
        // Unsealing: stop any animations and reset to normal state
        _balloonReleaseController?.stop();
        _balloonReleaseController?.reset();
        _isAnimatingBalloon = false;
        
        if (_balloonInSyringe && _balloonReleaseController != null) {
          final double currentSize = _balloonSize;
          
          if ((currentSize - 1.0).abs() > 0.01) {
            if (_balloonReleaseAnimation != null) {
              _balloonReleaseAnimation!.removeListener(() {});
            }
            
            _balloonReleaseAnimation = Tween<double>(
              begin: currentSize,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _balloonReleaseController!,
              curve: Curves.easeOut,
            ));
            
            _isAnimatingBalloon = true;
            _balloonReleaseAnimation!.addListener(() {
              if (mounted) {
                setState(() {
                  _balloonSize = _balloonReleaseAnimation!.value;
                });
              }
            });
            
            _balloonReleaseController!.addStatusListener((status) {
              if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
                _isAnimatingBalloon = false;
              }
            });
            
            _balloonReleaseController!.forward();
          } else {
            _balloonSize = 1.0;
          }
        } else {
          _balloonSize = 1.0;
        }
        
        _pressure = 1.0;
        _isAtMaxPressure = false;
        _minVolume = 1.0;
      }
    });
  }

  void _resetActivity() {
    setState(() {
      _balloonInSyringe = false;
      _balloonPosition = const Offset(250, 350);
      _balloonSize = 1.0;
      _isSealed = false;
      _pressure = 1.0;
      _plungerPosition = 0.5;
      _currentVolume = _maxVolume / 2;
      _initialVolume = _maxVolume / 2;
      _minVolume = 1.0;
      _isAtMaxPressure = false;
      _graphPoints.clear();
      _balloonReleaseController?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Boyle's Law: Vertical Syringe"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade200, Colors.orange.shade100],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  return Stack(
                  children: [
                      Positioned(
                        left: 20,
                        top: 20,
                        bottom: 20,
                        width: 120,
                        child: RepaintBoundary(
                          child: _VerticalSyringeWidget(
                                plungerPosition: _plungerPosition,
                                isSealed: _isSealed,
                                balloonInSyringe: _balloonInSyringe,
                                balloonSize: _balloonSize,
                            isAtMaxPressure: _isAtMaxPressure,
                                onPlungerDragStart: _onPlungerDragStart,
                                onPlungerDrag: _onPlungerDragUpdate,
                                onPlungerDragEnd: _onPlungerDragEnd,
                              ),
                        ),
                          ),
                            Positioned(
                        top: 20,
                        right: 20,
                        width: constraints.maxWidth - 180,
                        height: 250,
                        child: RepaintBoundary(
                          child: _PressureVolumeGraph(
                            points: _graphPoints,
                            currentVolume: _currentVolume,
                            currentPressure: _pressure,
                          ),
                        ),
                      ),
                      if (!_balloonInSyringe)
                        Positioned(
                          left: _balloonPosition.dx,
                          top: _balloonPosition.dy,
                          child: GestureDetector(
                            onTap: () {
                              // Play boop sound when balloon is tapped
                              SoundService().playBoopSound();
                            },
                            onPanUpdate: (details) => _onBalloonDragUpdate(details, constraints),
                            onPanEnd: _onBalloonDragEnd,
                            child: const _BalloonWidget(size: Size(50, 60)),
                      ),
                    ),
                  ],
                  );
                }),
              ),
              Container(
                padding: const EdgeInsets.all(12.0),
                color: Colors.white.withValues(alpha: 0.9),
                child: Column(
                      children: [
                        Text(
                      !_balloonInSyringe
                          ? 'STEP 1: Drag the balloon into the syringe'
                          : !_isSealed
                              ? 'STEP 2: Adjust volume, then SEAL OPENING'
                              : _isAtMaxPressure
                                  ? 'STEP 3: Balloon at MAX PRESSURE! Cannot compress further.'
                                  : 'STEP 3: Change volume to see Boyle\'s Law',
                      style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                        color: _isAtMaxPressure ? Colors.red.shade700 : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('VOLUME: ${_currentVolume.toStringAsFixed(0)} ml', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('PRESSURE: ${_pressure.toStringAsFixed(2)} atm', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12.0,
                      runSpacing: 8.0,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.lock_open),
                          label: const Text('RELEASE'),
                          onPressed: _isSealed ? _toggleSeal : null,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.lock),
                          label: const Text('SEAL'),
                          onPressed: !_isSealed && _balloonInSyringe ? _toggleSeal : null,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('RESET'),
                          onPressed: _resetActivity,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                        ),
                      ],
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

class _VerticalSyringeWidget extends StatelessWidget {
  final double plungerPosition;
  final bool isSealed;
  final bool balloonInSyringe;
  final double balloonSize;
  final bool isAtMaxPressure;
  final Function(DragStartDetails) onPlungerDragStart;
  final Function(DragUpdateDetails) onPlungerDrag;
  final Function(DragEndDetails) onPlungerDragEnd;

  const _VerticalSyringeWidget({
    required this.plungerPosition,
    required this.isSealed,
    required this.balloonInSyringe,
    required this.balloonSize,
    required this.isAtMaxPressure,
    required this.onPlungerDragStart,
    required this.onPlungerDrag,
    required this.onPlungerDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    const outerBodyWidth = 75.0;
    const innerTubeWidth = 55.0;
    const flangeWidth = 20.0;
    const plungerHeadHeight = 18.0;
    const openingHeight = 18.0;
    const thumbPadHeight = 20.0;

    return LayoutBuilder(builder: (context, constraints) {
      final availableHeight = constraints.maxHeight;
      const topPadding = 25.0;
      final syringeBodyHeight = availableHeight - topPadding;
      final double innerTubeTop = syringeBodyHeight - plungerHeadHeight;
      final double innerTubeHeight = innerTubeTop - openingHeight;
      
      final double stopPosition = syringeBodyHeight - plungerHeadHeight;
      final double maxHeadBottom = stopPosition - plungerHeadHeight - 10;
      final double effectiveMaxHeadBottom = math.min(innerTubeTop, maxHeadBottom);
      
      final double plungerHeadBottom = openingHeight + (plungerPosition * innerTubeHeight);
      final double clampedPlungerHeadBottom = plungerHeadBottom.clamp(openingHeight, effectiveMaxHeadBottom);
      
      final double plungerRodTop = clampedPlungerHeadBottom + plungerHeadHeight;
      final double plungerRodHeight = syringeBodyHeight - 60;

      return Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: (constraints.maxWidth - outerBodyWidth) / 2,
            child: CustomPaint(
              size: Size(outerBodyWidth, syringeBodyHeight),
              painter: _RealisticSyringePainter(
                syringeHeight: syringeBodyHeight,
                outerBodyWidth: outerBodyWidth,
                innerTubeWidth: innerTubeWidth,
                flangeWidth: flangeWidth,
                openingHeight: openingHeight,
                plungerHeadBottom: plungerHeadBottom,
                plungerRodTop: plungerRodTop,
                plungerRodHeight: plungerRodHeight,
                plungerHeadHeight: plungerHeadHeight,
                thumbPadHeight: thumbPadHeight,
              ),
            ),
          ),

          Positioned(
            bottom: openingHeight,
            left: (constraints.maxWidth - innerTubeWidth) / 2,
            child: RepaintBoundary(
              child: Container(
                width: innerTubeWidth,
                height: syringeBodyHeight - openingHeight - plungerHeadHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.7),
                      Colors.blue.shade50.withValues(alpha: 0.5),
                      Colors.white.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade600,
                    width: 2,
                  ),
                ),
                child: CustomPaint(
                  painter: _SyringeBarrelPainter(
                    syringeHeight: syringeBodyHeight - openingHeight - plungerHeadHeight,
                    openingHeight: 0,
                  ),
                ),
              ),
            ),
          ),

          if (balloonInSyringe)
            Positioned(
              bottom: openingHeight,
              height: plungerHeadBottom > openingHeight ? plungerHeadBottom - openingHeight : 0,
              left: (constraints.maxWidth - innerTubeWidth) / 2,
              width: innerTubeWidth,
              child: Align(
                alignment: Alignment.center,
                child: LayoutBuilder(
                  builder: (context, balloonConstraints) {
                    const double padding = 2.0;
                    const double maxBalloonWidth = innerTubeWidth - (padding * 2);
                    final double balloonWidth = maxBalloonWidth * balloonSize.clamp(0.5, 2.5);
                    final double balloonHeight = balloonWidth / 0.833;
                    
                    final double maxHeight = balloonConstraints.maxHeight;
                    final double clampedHeight = balloonHeight.clamp(30.0, maxHeight);
                    final double clampedWidth = clampedHeight * 0.833;
                    
                    return AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: GestureDetector(
                        onTap: () {
                          // Play boop sound when balloon is tapped
                          SoundService().playBoopSound();
                        },
                        child: SizedBox(
                          width: clampedWidth,
                          height: clampedHeight,
                          child: _BalloonWidget(
                            isAtMaxPressure: isAtMaxPressure,
                            size: Size(clampedWidth, clampedHeight),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          Positioned(
            bottom: clampedPlungerHeadBottom,
            left: (constraints.maxWidth - outerBodyWidth) / 2,
            child: GestureDetector(
              onVerticalDragStart: onPlungerDragStart,
              onVerticalDragUpdate: onPlungerDrag,
              onVerticalDragEnd: onPlungerDragEnd,
              child: SizedBox(
                width: outerBodyWidth,
                height: plungerRodHeight + plungerHeadHeight + 20,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      bottom: 0,
                      left: (outerBodyWidth - innerTubeWidth) / 2 + 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: innerTubeWidth - 2,
                            height: 3,
              decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.grey.shade300,
                                  Colors.grey.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Container(
                            width: innerTubeWidth - 2,
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.grey.shade300,
                                  Colors.grey.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Container(
                            width: innerTubeWidth - 2,
                            height: plungerHeadHeight - 6,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                              border: Border.all(color: Colors.black, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

          Positioned(
                      bottom: plungerHeadHeight,
                      left: (outerBodyWidth - 8) / 2,
              child: Container(
                        width: 8,
                        height: plungerRodHeight,
                decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey.shade200,
                              Colors.grey.shade300,
                              Colors.grey.shade400,
                              Colors.grey.shade300,
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                          border: Border.all(color: Colors.grey.shade500, width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.6),
                              blurRadius: 2,
                              offset: const Offset(-1, 0),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(1, 2),
                            ),
                          ],
                        ),
                      ),
                    ),

          Positioned(
                      bottom: plungerRodHeight + plungerHeadHeight,
                      left: (outerBodyWidth - (outerBodyWidth + 30)) / 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                            width: outerBodyWidth + 30,
                            height: 10,
                  decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.grey.shade200,
                                  Colors.grey.shade300,
                                  Colors.grey.shade400,
                                  Colors.grey.shade500,
                                ],
                                stops: const [0.0, 0.3, 0.7, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: Colors.grey.shade600, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  blurRadius: 3,
                                  offset: const Offset(0, -2),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 12,
                            height: 4,
                      decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.grey.shade300,
                                  Colors.grey.shade400,
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
              ),
            ),
          ),

                  Positioned(
            bottom: 0,
            left: (constraints.maxWidth - 35) / 2,
                    child: Container(
              width: 35,
              height: openingHeight,
                      decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade500,
                    Colors.grey.shade600,
                    Colors.grey.shade700,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                border: Border.all(color: Colors.grey.shade800, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: syringeBodyHeight - plungerHeadHeight - 5,
            left: (constraints.maxWidth - (outerBodyWidth + 20)) / 2,
            child: Container(
              width: outerBodyWidth + 20,
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade400,
                    Colors.grey.shade600,
                    Colors.grey.shade700,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                border: Border.all(color: Colors.grey.shade800, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 6,
                    offset: const Offset(0, -3),
          ),
        ],
      ),
              child: Center(
                child: Container(
                  width: 12,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
            ),
          ),

          if (isSealed)
            Positioned(
              bottom: -15,
              child: Icon(Icons.pan_tool, color: Colors.pink.shade300, size: 28),
            ),
        ],
      );
    });
  }
}

class _BalloonWidget extends StatelessWidget {
  final bool isAtMaxPressure;
  final Size size;

  const _BalloonWidget({
    this.isAtMaxPressure = false,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isAtMaxPressure ? Colors.deepOrange : Colors.red;
    
    return CustomPaint(
      size: size,
      painter: _BalloonPainter(
        baseColor: baseColor,
        isAtMaxPressure: isAtMaxPressure,
      ),
    );
  }
}

class _BalloonPainter extends CustomPainter {
  final Color baseColor;
  final bool isAtMaxPressure;

  _BalloonPainter({
    required this.baseColor,
    required this.isAtMaxPressure,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final balloonPath = Path();
    balloonPath.addOval(Rect.fromCenter(
      center: Offset(centerX, centerY - 5),
      width: size.width * 0.9,
      height: size.height * 0.7,
    ));
    balloonPath.lineTo(centerX, size.height - 8);
    balloonPath.close();

    final MaterialColor colorSwatch = isAtMaxPressure ? Colors.deepOrange : Colors.red;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colorSwatch.shade200,
        colorSwatch.shade400,
        colorSwatch.shade600,
      ],
    );
    paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    paint.style = PaintingStyle.fill;
    canvas.drawPath(balloonPath, paint);

    final highlightPath = Path();
    highlightPath.addOval(Rect.fromCenter(
      center: Offset(centerX - 8, centerY - 10),
      width: size.width * 0.4,
      height: size.height * 0.3,
    ));
    paint.shader = null;
    paint.color = Colors.white.withValues(alpha: 0.4);
    canvas.drawPath(highlightPath, paint);

    paint.color = isAtMaxPressure ? Colors.red.shade900 : colorSwatch.shade800;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = isAtMaxPressure ? 2.5 : 1.5;
    canvas.drawPath(balloonPath, paint);

    paint.color = colorSwatch.shade900;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, size.height - 6), 3, paint);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    paint.color = Colors.black.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(centerX, size.height - 6), 3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _BalloonPainter) {
      return oldDelegate.baseColor != baseColor ||
          oldDelegate.isAtMaxPressure != isAtMaxPressure;
    }
    return true;
  }
}

class _RealisticSyringePainter extends CustomPainter {
  final double syringeHeight;
  final double outerBodyWidth;
  final double innerTubeWidth;
  final double flangeWidth;
  final double openingHeight;
  final double plungerHeadBottom;
  final double plungerRodTop;
  final double plungerRodHeight;
  final double plungerHeadHeight;
  final double thumbPadHeight;

  _RealisticSyringePainter({
    required this.syringeHeight,
    required this.outerBodyWidth,
    required this.innerTubeWidth,
    required this.flangeWidth,
    required this.openingHeight,
    required this.plungerHeadBottom,
    required this.plungerRodTop,
    required this.plungerRodHeight,
    required this.plungerHeadHeight,
    required this.thumbPadHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final centerX = size.width / 2;
    const rodWidth = 6.0;

    final bodyPath = Path();
    final topY = size.height - thumbPadHeight;
    bodyPath.moveTo(0, openingHeight);
    bodyPath.lineTo(0, topY);
    bodyPath.lineTo(centerX - rodWidth / 2 - 2, topY);
    bodyPath.lineTo(centerX - rodWidth / 2 - 2, size.height - thumbPadHeight);
    bodyPath.lineTo(centerX + rodWidth / 2 + 2, size.height - thumbPadHeight);
    bodyPath.lineTo(centerX + rodWidth / 2 + 2, topY);
    bodyPath.lineTo(size.width, topY);
    bodyPath.lineTo(size.width, openingHeight);
    bodyPath.close();

    final bodyGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        Colors.grey.shade200,
        Colors.grey.shade300,
      ],
    );
    paint.shader = bodyGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    paint.style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, paint);

    paint.shader = null;
    paint.color = Colors.grey.shade600;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.5;
    canvas.drawPath(bodyPath, paint);

    const flangeHeight = 25.0;
    final flangeY = openingHeight + 5;

    final leftFlangePath = Path();
    leftFlangePath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(-flangeWidth / 2, flangeY, flangeWidth, flangeHeight),
      const Radius.circular(8),
    ));
    paint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.grey.shade400,
        Colors.grey.shade300,
        Colors.grey.shade200,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    paint.style = PaintingStyle.fill;
    canvas.drawPath(leftFlangePath, paint);

    final rightFlangePath = Path();
    rightFlangePath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width - flangeWidth / 2, flangeY, flangeWidth, flangeHeight),
      const Radius.circular(8),
    ));
    canvas.drawPath(rightFlangePath, paint);

    paint.shader = null;
    paint.color = Colors.grey.shade600;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawPath(leftFlangePath, paint);
    canvas.drawPath(rightFlangePath, paint);

    paint.shader = null;
    paint.color = Colors.black.withValues(alpha: 0.1);
    paint.style = PaintingStyle.fill;
    final shadowPath = Path();
    shadowPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(2, openingHeight + 2, size.width - 4, size.height - openingHeight - thumbPadHeight - 2),
      const Radius.circular(10),
    ));
    canvas.drawPath(shadowPath, paint);

    paint.color = Colors.white.withValues(alpha: 0.4);
    final highlightPath = Path();
    highlightPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(5, openingHeight + 5, size.width - 10, 15),
      const Radius.circular(8),
    ));
    canvas.drawPath(highlightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _RealisticSyringePainter) {
      return oldDelegate.plungerHeadBottom != plungerHeadBottom ||
          oldDelegate.plungerRodTop != plungerRodTop;
    }
    return true;
  }
}

class _SyringeBarrelPainter extends CustomPainter {
  final double syringeHeight;
  final double openingHeight;

  _SyringeBarrelPainter({
    required this.syringeHeight,
    required this.openingHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final usableHeight = size.height - openingHeight;
    const numMarkings = 6;
    
    for (int i = 0; i <= numMarkings; i++) {
      final y = openingHeight + (i * usableHeight / numMarkings);
      final isMajorMark = i % 2 == 0;
      final markWidth = isMajorMark ? 8.0 : 5.0;
      
      canvas.drawLine(
        Offset(2, y),
        Offset(2 + markWidth, y),
        paint,
      );
      
      canvas.drawLine(
        Offset(size.width - 2, y),
        Offset(size.width - 2 - markWidth, y),
        paint,
      );

      if (isMajorMark && i < numMarkings) {
        final volume = ((numMarkings - i) / numMarkings * 60).toInt();
        final textSpan = TextSpan(
          text: '$volume',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(size.width / 2 - textPainter.width / 2, y - textPainter.height / 2),
        );
      }
    }

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    final highlightPath = Path()
      ..moveTo(5, openingHeight)
      ..lineTo(15, openingHeight + 10)
      ..lineTo(15, size.height - 10)
      ..lineTo(5, size.height)
      ..close();
    
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _SyringeBarrelPainter) {
      return oldDelegate.syringeHeight != syringeHeight ||
          oldDelegate.openingHeight != openingHeight;
    }
    return true;
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
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Pressure-Volume Graph',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                RotatedBox(
                  quarterTurns: -1,
                  child: Text(
                    'Pressure (atm)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
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
              Text(
            'Volume (ml)',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
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
    const double leftPadding = 30;
    const double bottomPadding = 20;
    const double rightPadding = 10;
    const double topPadding = 10;

    final double graphWidth = size.width - leftPadding - rightPadding;
    final double graphHeight = size.height - topPadding - bottomPadding;

    final Offset origin = Offset(leftPadding, size.height - bottomPadding);

    final paint = Paint()
      ..color = Colors.orange.shade600
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.deepOrange
      ..style = PaintingStyle.fill;

    final axisPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.5;

    canvas.drawLine(origin, Offset(origin.dx + graphWidth, origin.dy), axisPaint);
    canvas.drawLine(origin, Offset(origin.dx, origin.dy - graphHeight), axisPaint);

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;
    
    final textStyle = TextStyle(
      color: Colors.grey.shade800,
      fontSize: 9,
    );

    const int numGridLines = 5;
    const maxVolume = 60.0;
    const maxPressure = 6.0;

    for (int i = 0; i <= numGridLines; i++) {
      final y = origin.dy - (i * graphHeight / numGridLines);
      if (i > 0) {
        canvas.drawLine(Offset(origin.dx, y), Offset(origin.dx + graphWidth, y), gridPaint);
      }

      final pressure = (i * maxPressure / numGridLines);
      final textSpan = TextSpan(text: pressure.toStringAsFixed(1), style: textStyle);
      final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(origin.dx - textPainter.width - 6, y - textPainter.height / 2));
    }

    for (int i = 0; i <= numGridLines; i++) {
      final x = origin.dx + (i * graphWidth / numGridLines);
      if (i > 0) {
        canvas.drawLine(Offset(x, origin.dy), Offset(x, origin.dy - graphHeight), gridPaint);
      }

      final volume = (i * maxVolume / numGridLines);
      final textSpan = TextSpan(text: volume.toStringAsFixed(0), style: textStyle);
      final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, origin.dy + 6));
    }

    if (points.length > 1) {
      final path = Path();

      for (int i = 0; i < points.length; i++) {
        final point = points[i];
        final x = origin.dx + (point.dx / maxVolume) * graphWidth;
        final y = origin.dy - (point.dy / maxPressure) * graphHeight;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    if (currentVolume > 0 && currentPressure > 0) {
      final x = origin.dx + (currentVolume / maxVolume) * graphWidth;
      final y = origin.dy - (currentPressure / maxPressure) * graphHeight;

      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      canvas.drawCircle(Offset(x, y), 5, paint..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _GraphPainter) {
      return oldDelegate.points.length != points.length ||
          oldDelegate.currentVolume != currentVolume ||
          oldDelegate.currentPressure != currentPressure ||
          (points.isNotEmpty && oldDelegate.points.isNotEmpty &&
           (oldDelegate.points.last.dx != points.last.dx ||
            oldDelegate.points.last.dy != points.last.dy));
    }
    return true;
  }
}
