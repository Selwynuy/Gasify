import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/services/sound_service.dart';
import '../../../settings/screens/settings_screen.dart';

/// Cryo-sim Activity for Combined Gas Law.
/// Demonstrates: P₁V₁/T₁ = P₂V₂/T₂
/// Refrigeration cycle simulation showing how pressure and volume changes affect temperature.
class CryoSimActivity extends StatefulWidget {
  const CryoSimActivity({super.key});

  @override
  State<CryoSimActivity> createState() => _CryoSimActivityState();
}

class _CryoSimActivityState extends State<CryoSimActivity> with TickerProviderStateMixin {
  // Initial state (before expansion valve)
  double _p1 = 450.0; // kPa
  double _v1 = 0.050; // L
  double _t1Celsius = 30.0; // °C
  double get _t1Kelvin => _t1Celsius + 273.15;

  // Final state (after expansion into evaporator)
  double _p2 = 120.0; // kPa
  double _v2 = 0.150; // L
  double? _t2Kelvin; // Calculated
  double? get _t2Celsius => _t2Kelvin != null ? _t2Kelvin! - 273.15 : null;

  bool _showAnswer = false;
  bool _sidebarOpen = false; // Toggle for sidebar
  int _currentStep = 0; // Current instruction step (0-5)

  // Boom effect state
  bool _isBooming = false;
  late AnimationController _boomController;
  late AnimationController _shakeController;
  late Animation<double> _boomAnimation;
  late Animation<double> _shakeAnimation;
  static const double _boomThreshold = 500.0; // Kelvin - if T2 exceeds this, BOOM!

  // Slider ranges
  static const double _minPressure = 50.0;
  static const double _maxPressure = 500.0;
  static const double _minVolume = 0.010;
  static const double _maxVolume = 0.300;
  static const double _minTempC = -50.0;
  static const double _maxTempC = 100.0;

  @override
  void initState() {
    super.initState();
    
    // Initialize boom animation controllers
    _boomController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _boomAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _boomController, curve: Curves.easeOut),
    );
    
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
    
    _boomController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _resetSimulation();
      }
    });
    
    _calculateT2();
  }

  @override
  void dispose() {
    _boomController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// Calculate cooling intensity (0.0 = no cooling, 1.0 = maximum cooling)
  /// Returns 0.0 if T2 >= T1 (no cooling), otherwise returns normalized cooling amount
  double _getCoolingIntensity() {
    if (_t2Kelvin == null) return 0.0;
    if (_t2Kelvin! >= _t1Kelvin) return 0.0; // No cooling if T2 >= T1
    
    // Calculate temperature drop
    final tempDrop = _t1Kelvin - _t2Kelvin!;
    // Normalize: assume max cooling is when T2 drops to 200K (very cold)
    final maxPossibleDrop = _t1Kelvin - 200.0;
    return (tempDrop / maxPossibleDrop).clamp(0.0, 1.0);
  }

  /// Check if we're in cooling state
  bool _isCooling() {
    return _t2Kelvin != null && _t2Kelvin! < _t1Kelvin;
  }

  /// Calculate T2 using Combined Gas Law: P₁V₁/T₁ = P₂V₂/T₂
  /// Therefore: T₂ = (P₂ × V₂ × T₁) / (P₁ × V₁)
  /// Note: This calculates T2 internally but doesn't show the answer until CALCULATE is clicked
  void _calculateT2() {
    if (_p1 > 0 && _v1 > 0 && _t1Kelvin > 0 && _p2 > 0 && _v2 > 0) {
      setState(() {
        _t2Kelvin = (_p2 * _v2 * _t1Kelvin) / (_p1 * _v1);
        // Don't set _showAnswer here - only show when button is clicked
      });
    }
  }

  /// Check for boom condition after showing answer
  void _checkForBoom() {
    if (_showAnswer && _t2Kelvin != null && _t2Kelvin! > _boomThreshold && !_isBooming) {
      _triggerBoom();
    }
  }

  /// Trigger the boom effect
  void _triggerBoom() {
    setState(() {
      _isBooming = true;
    });
    SoundService().playTouchSound(); // Could add explosion sound here
    _shakeController.forward();
    _boomController.forward();
  }

  /// Reset simulation to initial state
  void _resetSimulation() {
    setState(() {
      _p1 = 450.0;
      _v1 = 0.050;
      _t1Celsius = 30.0;
      _p2 = 120.0;
      _v2 = 0.150;
      _t2Kelvin = null;
      _showAnswer = false;
      _currentStep = 0;
      _isBooming = false;
    });
    _boomController.reset();
    _shakeController.reset();
    _calculateT2();
  }

  /// Get P-V diagram data points
  List<FlSpot> _getPVSpots() {
    final spots = <FlSpot>[];
    
    // Generate points for P-V relationship at constant T1 (isotherm)
    for (double v = _minVolume; v <= _maxVolume; v += 0.01) {
      // Using ideal gas law: P = nRT/V, but normalized for visualization
      // For isotherm: P ∝ 1/V
      final p = (_p1 * _v1) / v;
      if (p >= _minPressure && p <= _maxPressure) {
        spots.add(FlSpot(v * 100, p / 10)); // Scale for display
      }
    }
    
    return spots;
  }

  /// Get points for the transition curve
  List<FlSpot> _getTransitionSpots() {
    if (_t2Kelvin == null) return [];
    
    final spots = <FlSpot>[];
    // Generate points showing the transition from state 1 to state 2
    final steps = 20;
    for (int i = 0; i <= steps; i++) {
      final t = _t1Kelvin + (i / steps) * (_t2Kelvin! - _t1Kelvin);
      // Using combined gas law to find intermediate P-V points
      final v = (_p1 * _v1 * t) / (_t1Kelvin * _p2);
      final p = (_p1 * _v1 * _t1Kelvin) / (v * t);
      if (v >= _minVolume && v <= _maxVolume && p >= _minPressure && p <= _maxPressure) {
        spots.add(FlSpot(v * 100, p / 10));
      }
    }
    
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final titleFontSize = isSmallScreen ? 14.0 : 18.0;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: Text(
          "CRYO-SIM: Refrigeration Physics",
          style: TextStyle(
            color: Colors.cyan,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
            shadows: const [
              Shadow(
                color: Colors.cyan,
                blurRadius: 8,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.grey.shade900,
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
          // Toggle sidebar button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _sidebarOpen ? Icons.close : Icons.tune,
                color: Colors.white,
                size: 24,
              ),
            ),
            onPressed: () {
              setState(() {
                _sidebarOpen = !_sidebarOpen;
              });
              SoundService().playTouchSound();
            },
          ),
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
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content area (full width) - Refrigerator only (with shake effect)
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final shakeOffset = _isBooming
                    ? Offset(
                        (0.5 - _shakeAnimation.value) * 20,
                        (0.5 - _shakeAnimation.value) * 20,
                      )
                    : Offset.zero;
                return Transform.translate(
                  offset: shakeOffset,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.cyan.shade700, width: 2),
                      ),
                      child: _buildRefrigeratorDiagram(),
                    ),
                  ),
                );
              },
            ),
            // Initial State overlay (top left)
            Positioned(
              left: 20,
              top: 20,
              child: _buildStateSection(
                title: "INITIAL STATE",
                p: _p1,
                v: _v1,
                t: _t1Kelvin,
                tempCelsius: _t1Celsius,
                color: Colors.red.shade400,
                isSmallScreen: false,
              ),
            ),
            // Final State overlay (below Initial State)
            Positioned(
              left: 20,
              top: 120,
              child: _buildStateSection(
                title: "FINAL STATE",
                p: _p2,
                v: _v2,
                t: _showAnswer ? _t2Kelvin : null,
                tempCelsius: _showAnswer ? _t2Celsius : null,
                color: Colors.lightBlue.shade400,
                showUnknown: !_showAnswer,
                isSmallScreen: false,
              ),
            ),
            // P-V Diagram overlay (top right, 50% size)
            Positioned(
              right: 20,
              top: 20,
              child: Container(
                width: 175, // 50% of 350
                height: 125, // 50% of 250
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyan.shade700, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _buildPVDiagram(isSmallScreen: true), // Use small screen settings for smaller size
              ),
            ),
            // Overlay Sidebar (slides in from right)
            if (_sidebarOpen)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width * 0.6,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan.shade700, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Sidebar header
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Parameters',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _sidebarOpen = false;
                                });
                                SoundService().playTouchSound();
                              },
                            ),
                          ],
                        ),
                      ),
                      // Sliders
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              _buildSliders(isSmallScreen: false),
                              const SizedBox(height: 12),
                              _buildCalculateSection(isSmallScreen: false),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Instructions overlay (bottom)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: _buildInstructions(),
            ),
            // Boom effect overlay
            if (_isBooming)
              Positioned.fill(
                child: _buildBoomEffect(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateSection({
    required String title,
    required double p,
    required double v,
    double? t,
    double? tempCelsius,
    required Color color,
    bool showUnknown = false,
    required bool isSmallScreen,
  }) {
    final fontSize = isSmallScreen ? 9.0 : 11.0;
    final titleFontSize = isSmallScreen ? 10.0 : 12.0;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: titleFontSize,
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            'P: ${p.toStringAsFixed(0)} kPa',
            style: TextStyle(color: Colors.white70, fontSize: fontSize),
          ),
          Text(
            'V: ${v.toStringAsFixed(3)} L',
            style: TextStyle(color: Colors.white70, fontSize: fontSize),
          ),
          if (showUnknown)
            Text(
              'T: ???? K',
              style: TextStyle(color: Colors.yellow, fontSize: fontSize, fontWeight: FontWeight.bold),
            )
          else if (t != null)
            Text(
              'T: ${t.toStringAsFixed(2)} K (${tempCelsius!.toStringAsFixed(1)}°C)',
              style: TextStyle(color: Colors.white70, fontSize: fontSize),
            ),
        ],
      ),
    );
  }

  Widget _buildRefrigeratorDiagram() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Refrigerator image
              Center(
                child: Image.asset(
                  'assets/combined_gas_law/Refrigerator.png',
                  width: constraints.maxWidth * 0.9,
                  height: constraints.maxHeight * 0.9,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Failed to load Refrigerator.png: $error');
                    debugPrint('Stack trace: $stackTrace');
                    // Fallback to CustomPainter if image doesn't exist
                    return CustomPaint(
                      painter: _RefrigeratorPainter(),
                      child: Container(),
                    );
                  },
                ),
              ),
              // Cooling smoke effect (only when answer is shown AND cooling occurs)
              if (_showAnswer && _isCooling())
                Positioned(
                  // Adjust these values to position the bubble area
                  left: constraints.maxWidth * 0.3,   // 20% from left
                  top: constraints.maxHeight * 0.4,   // 30% from top
                  width: constraints.maxWidth * 0.18,  // 30% of previous 60% width (0.6 * 0.3)
                  height: constraints.maxHeight * 0.15, // 30% of previous 50% height (0.5 * 0.3)
                  child: _CoolingSmokeWidget(
                    coolingIntensity: _getCoolingIntensity(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPVDiagram({required bool isSmallScreen}) {
    final pvSpots = _getPVSpots();
    final transitionSpots = _getTransitionSpots();
    final titleFontSize = isSmallScreen ? 9.0 : 11.0;
    final axisFontSize = isSmallScreen ? 7.0 : 9.0;
    final labelFontSize = isSmallScreen ? 7.0 : 8.0;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan.shade600, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'P-V DIAGRAM (Combined Gas Law)',
            style: TextStyle(
              color: Colors.cyan,
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade600,
                      strokeWidth: 0.5,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade600,
                      strokeWidth: 0.5,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text(
                      'Volume (×0.01 L)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: axisFontSize,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isSmallScreen ? 20 : 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: labelFontSize,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      'Pressure (×10 kPa)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: axisFontSize,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isSmallScreen ? 28 : 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: labelFontSize,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade600),
                ),
                minX: (_minVolume * 100) - 1,
                maxX: (_maxVolume * 100) + 1,
                minY: (_minPressure / 10) - 1,
                maxY: (_maxPressure / 10) + 1,
                lineBarsData: [
                  // Isotherm curve (blue)
                  if (pvSpots.isNotEmpty)
                    LineChartBarData(
                      spots: pvSpots,
                      isCurved: true,
                      color: Colors.blue.shade400,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  // Transition curve (green)
                  if (transitionSpots.isNotEmpty)
                    LineChartBarData(
                      spots: transitionSpots,
                      isCurved: true,
                      color: Colors.green.shade400,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  // Initial state point (red)
                  LineChartBarData(
                    spots: [FlSpot(_v1 * 100, _p1 / 10)],
                    isCurved: false,
                    color: Colors.transparent,
                    barWidth: 0,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: Colors.red.shade400,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                  // Final state point (light blue)
                  if (_t2Kelvin != null)
                    LineChartBarData(
                      spots: [FlSpot(_v2 * 100, _p2 / 10)],
                      isCurved: false,
                      color: Colors.transparent,
                      barWidth: 0,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: Colors.lightBlue.shade400,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
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

  Widget _buildSliders({required bool isSmallScreen}) {
    final spacing = isSmallScreen ? 4.0 : 8.0;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSlider(
            label: 'PRESSURE P1 (kPa)',
            value: _p1,
            min: _minPressure,
            max: _maxPressure,
            isSmallScreen: isSmallScreen,
            onChanged: (value) {
              setState(() {
                _p1 = value;
                _showAnswer = false;
                _calculateT2(); // Recalculate T2 when P1 changes
              });
              SoundService().playTouchSound();
            },
          ),
          SizedBox(height: spacing),
          _buildSlider(
            label: 'PRESSURE P2 (kPa)',
            value: _p2,
            min: _minPressure,
            max: _maxPressure,
            isSmallScreen: isSmallScreen,
            onChanged: (value) {
              setState(() {
                _p2 = value;
                _showAnswer = false;
                _calculateT2(); // Recalculate T2 when P2 changes
              });
              SoundService().playTouchSound();
            },
          ),
          SizedBox(height: spacing),
          _buildSlider(
            label: 'VOLUME V1 (L)',
            value: _v1,
            min: _minVolume,
            max: _maxVolume,
            isSmallScreen: isSmallScreen,
            onChanged: (value) {
              setState(() {
                _v1 = value;
                _showAnswer = false;
                _calculateT2(); // Recalculate T2 when V1 changes
              });
              SoundService().playTouchSound();
            },
          ),
          SizedBox(height: spacing),
          _buildSlider(
            label: 'VOLUME V2 (L)',
            value: _v2,
            min: _minVolume,
            max: _maxVolume,
            isSmallScreen: isSmallScreen,
            onChanged: (value) {
              setState(() {
                _v2 = value;
                _showAnswer = false;
                _calculateT2(); // Recalculate T2 when V2 changes
              });
              SoundService().playTouchSound();
            },
          ),
          SizedBox(height: spacing),
          _buildSlider(
            label: 'TEMP T1 (°C)',
            value: _t1Celsius,
            min: _minTempC,
            max: _maxTempC,
            isSmallScreen: isSmallScreen,
            onChanged: (value) {
              setState(() {
                _t1Celsius = value;
                _showAnswer = false;
                _calculateT2(); // Recalculate T2 when T1 changes
              });
              SoundService().playTouchSound();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required bool isSmallScreen,
  }) {
    final fontSize = isSmallScreen ? 8.0 : 10.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value.toStringAsFixed(value < 1 ? 3 : 1)}',
          style: TextStyle(
            color: Colors.white70,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) * 10).round().clamp(1, 1000),
          activeColor: Colors.cyan,
          inactiveColor: Colors.grey.shade600,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCalculateSection({required bool isSmallScreen}) {
    final buttonFontSize = isSmallScreen ? 12.0 : 14.0;
    final answerFontSize = isSmallScreen ? 11.0 : 14.0;
    final padding = isSmallScreen ? 8.0 : 12.0;
    final verticalPadding = isSmallScreen ? 8.0 : 12.0;
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _calculateT2();
                _showAnswer = true;
              });
              // Check for boom after showing answer
              _checkForBoom();
              SoundService().playTouchSound();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: verticalPadding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'CALCULATE T2',
              style: TextStyle(
                fontSize: buttonFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (_showAnswer && _t2Kelvin != null) ...[
          SizedBox(height: isSmallScreen ? 4 : 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.green.shade900.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade600, width: 2),
            ),
            child: Text(
              'ANSWER: T2 = ${_t2Kelvin!.toStringAsFixed(1)} K (${_t2Celsius!.toStringAsFixed(1)}°C)',
              style: TextStyle(
                color: Colors.green.shade300,
                fontSize: answerFontSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInstructions() {
    final instructions = [
      'Observe the Initial State: The refrigerant gas is at high pressure (450 kPa), small volume (0.050 L), and warm temperature (30.0°C) before passing through the expansion valve.',
      'Observe the Final State: After expansion, the pressure drops to 120 kPa and volume increases to 0.150 L. The final temperature (T₂) is unknown and needs to be calculated.',
      'Open the Parameters sidebar by tapping the menu icon (☰) in the top-right corner to adjust P₁, V₁, T₁, P₂, or V₂ if needed.',
      'Click the "CALCULATE T2" button to determine the final temperature using the Combined Gas Law: P₁V₁/T₁ = P₂V₂/T₂.',
      'Observe the Result: If T₂ < T₁, cooling occurs and you will see sky blue smoke inside the refrigerator, demonstrating the cooling effect. The greater the temperature drop, the more intense the smoke effect.',
      'Analyze the P-V Diagram: The diagram shows the pressure-volume relationship. The transition from initial to final state demonstrates how pressure and volume changes lead to temperature changes.',
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan.shade700, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.cyan.shade400, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Step-by-Step Instructions',
                  style: TextStyle(
                    color: Colors.cyan.shade400,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Step ${_currentStep + 1} of ${instructions.length}',
                style: TextStyle(
                  color: Colors.cyan.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Current step display
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.cyan.shade700,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${_currentStep + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  instructions[_currentStep],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: _currentStep > 0
                    ? () {
                        setState(() {
                          _currentStep--;
                        });
                        SoundService().playTouchSound();
                      }
                    : null,
                icon: const Icon(Icons.arrow_back, size: 12),
                label: const Text('Previous', style: TextStyle(fontSize: 9)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  minimumSize: const Size(0, 0),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _currentStep < instructions.length - 1
                    ? () {
                        setState(() {
                          _currentStep++;
                        });
                        SoundService().playTouchSound();
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward, size: 12),
                label: const Text('Next', style: TextStyle(fontSize: 9)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  minimumSize: const Size(0, 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoomEffect() {
    return AnimatedBuilder(
      animation: _boomAnimation,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        final centerX = screenSize.width / 2;
        final centerY = screenSize.height / 2;
        
        // Explosion radius grows with animation
        final radius = _boomAnimation.value * screenSize.width * 0.8;
        
        // Opacity fades out
        final opacity = (1.0 - _boomAnimation.value).clamp(0.0, 1.0);
        
        return CustomPaint(
          painter: _BoomPainter(
            center: Offset(centerX, centerY),
            radius: radius,
            opacity: opacity,
            progress: _boomAnimation.value,
          ),
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '💥 BOOM! 💥',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade400.withValues(alpha: opacity),
                      shadows: [
                        Shadow(
                          color: Colors.red.withValues(alpha: opacity),
                          blurRadius: 20,
                        ),
                        Shadow(
                          color: Colors.yellow.withValues(alpha: opacity),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Temperature Too High!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: opacity),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Restarting simulation...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70.withValues(alpha: opacity),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for boom explosion effect
class _BoomPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double opacity;
  final double progress;

  _BoomPainter({
    required this.center,
    required this.radius,
    required this.opacity,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw multiple explosion rings
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Outer ring (orange/red)
    paint.color = Colors.orange.withValues(alpha: opacity * 0.6);
    canvas.drawCircle(center, radius, paint);

    // Middle ring (yellow)
    paint.color = Colors.yellow.withValues(alpha: opacity * 0.8);
    canvas.drawCircle(center, radius * 0.7, paint);

    // Inner ring (white)
    paint.color = Colors.white.withValues(alpha: opacity);
    canvas.drawCircle(center, radius * 0.4, paint);

    // Draw explosion particles
    final particlePaint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final angle = (i / 20) * 2 * math.pi;
      final distance = radius * (0.5 + progress * 0.5);
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);
      
      particlePaint.color = [
        Colors.orange,
        Colors.red,
        Colors.yellow,
        Colors.white,
      ][i % 4].withValues(alpha: opacity);
      
      canvas.drawCircle(
        Offset(x, y),
        5 + progress * 10,
        particlePaint,
      );
    }

    // Draw background flash
    final flashPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: opacity * 0.3 * (1 - progress));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), flashPaint);
  }

  @override
  bool shouldRepaint(_BoomPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.opacity != opacity ||
        oldDelegate.progress != progress;
  }
}

/// Custom painter for refrigerator diagram
class _RefrigeratorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    // Refrigerator body (white)
    fillPaint.color = Colors.white;
    final fridgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.1, size.width * 0.5, size.height * 0.6),
      const Radius.circular(4),
    );
    canvas.drawRRect(fridgeRect, fillPaint);
    paint.color = Colors.grey.shade700;
    canvas.drawRRect(fridgeRect, paint);

    // Refrigerator door
    paint.color = Colors.grey.shade600;
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.1),
      Offset(size.width * 0.35, size.height * 0.7),
      paint,
    );

    // Pipes inside (blue)
    paint.color = Colors.blue.shade400;
    paint.strokeWidth = 3;
    final pipePath = Path();
    pipePath.moveTo(size.width * 0.2, size.height * 0.2);
    pipePath.lineTo(size.width * 0.3, size.height * 0.2);
    pipePath.lineTo(size.width * 0.3, size.height * 0.4);
    pipePath.lineTo(size.width * 0.2, size.height * 0.4);
    canvas.drawPath(pipePath, paint);

    // Red component (compressor/condenser)
    fillPaint.color = Colors.red.shade400;
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.3),
      size.width * 0.05,
      fillPaint,
    );

    // Evaporator coils (light blue cloud)
    fillPaint.color = Colors.lightBlue.shade300.withValues(alpha: 0.6);
    final cloudPath = Path();
    cloudPath.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.3, size.height * 0.5),
      radius: size.width * 0.08,
    ));
    cloudPath.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.35, size.height * 0.55),
      radius: size.width * 0.06,
    ));
    cloudPath.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.25, size.height * 0.55),
      radius: size.width * 0.06,
    ));
    canvas.drawPath(cloudPath, fillPaint);

    // External compressor/condenser unit
    fillPaint.color = Colors.grey.shade600;
    final compressorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.65, size.height * 0.3, size.width * 0.25, size.height * 0.2),
      const Radius.circular(4),
    );
    canvas.drawRRect(compressorRect, fillPaint);
    paint.color = Colors.grey.shade700;
    canvas.drawRRect(compressorRect, paint);

    // Labels - scale font size based on available space
    final baseFontSize = (size.width + size.height) / 50;
    final evaporatorFontSize = baseFontSize.clamp(8.0, 12.0);
    final compressorFontSize = baseFontSize.clamp(7.0, 10.0);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Evaporator\nCoils',
        style: TextStyle(
          color: Colors.lightBlue,
          fontSize: evaporatorFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.15, size.height * 0.6));

    final compressorText = TextPainter(
      text: TextSpan(
        text: 'Compressor/\nCondenser',
        style: TextStyle(
          color: Colors.white70,
          fontSize: compressorFontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    compressorText.layout();
    compressorText.paint(canvas, Offset(size.width * 0.67, size.height * 0.35));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cooling smoke effect widget that shows smoke when cooling occurs
class _CoolingSmokeWidget extends StatefulWidget {
  final double coolingIntensity; // 0.0 to 1.0

  const _CoolingSmokeWidget({
    required this.coolingIntensity,
  });

  @override
  State<_CoolingSmokeWidget> createState() => _CoolingSmokeWidgetState();
}

class _CoolingSmokeWidgetState extends State<_CoolingSmokeWidget> with TickerProviderStateMixin {
  final List<_SmokeParticle> _particles = [];
  Timer? _spawnTimer;
  int _maxParticles = 0;

  @override
  void initState() {
    super.initState();
    _updateMaxParticles();
    _initializeParticles();
    _startSpawning();
  }

  @override
  void didUpdateWidget(_CoolingSmokeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coolingIntensity != widget.coolingIntensity) {
      _updateMaxParticles();
    }
  }

  void _updateMaxParticles() {
    // Scale number of smoke particles based on cooling intensity
    // Minimum 5 particles, maximum 20 particles
    _maxParticles = (5 + (widget.coolingIntensity * 15)).round();
  }

  void _initializeParticles() {
    final random = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < _maxParticles; i++) {
      final seed = (random + i * 1000) % 10000;
      final duration = 2500.0 + (seed % 2000); // Random duration between 2500-4500ms
      final xOffset = (seed % 100 - 50).toDouble(); // Random X offset between -50 to 50
      
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: duration.toInt()),
      );
      
      _particles.add(_SmokeParticle(
        controller: controller,
        xOffset: xOffset,
        size: 4.0 + (seed % 10), // Random size between 4-14
        seed: seed,
      ));
    }
  }

  void _startSpawning() {
    void spawnNext() {
      if (!mounted || widget.coolingIntensity <= 0) return;
      
      // Find particles that are not currently animating
      final availableParticles = _particles.where((p) => !p.controller.isAnimating).toList();
      
      if (availableParticles.isNotEmpty) {
        // Pick a random available particle
        final random = DateTime.now().millisecondsSinceEpoch;
        final particle = availableParticles[random % availableParticles.length];
        
        // Assign a new random position for this particle spawn
        // This ensures smoke appears at truly random locations each time
        final randomX = (random * 7) % 10000;
        final randomY = (random * 13) % 10000;
        particle.randomPosition = Offset(
          randomX / 10000.0, // Will be scaled in painter
          randomY / 10000.0, // Will be scaled in painter
        );
        
        // Start the particle animation
        particle.controller.forward(from: 0.0).then((_) {
          if (mounted) {
            particle.controller.reset();
            particle.randomPosition = null; // Clear position when animation ends
          }
        });
      }
      
      // Spawn rate scales with cooling intensity (faster spawning = more cooling)
      // Base delay 400ms, scales down to 150ms at max intensity
      final baseDelay = 400;
      final intensityDelay = (baseDelay * (1.0 - widget.coolingIntensity)).round();
      final randomDelay = intensityDelay + (DateTime.now().millisecondsSinceEpoch % 250);
      _spawnTimer = Timer(Duration(milliseconds: randomDelay.clamp(150, 600)), spawnNext);
    }
    
    // Start spawning immediately
    spawnNext();
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    for (var particle in _particles) {
      particle.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.coolingIntensity <= 0) {
      return const SizedBox.shrink();
    }

    // Listen to all particle controllers for repaints
    return ListenableBuilder(
      listenable: Listenable.merge(_particles.map((p) => p.controller)),
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _CoolingSmokePainter(
                particles: _particles,
                coolingIntensity: widget.coolingIntensity,
              ),
            );
          },
        );
      },
    );
  }
}

class _SmokeParticle {
  final AnimationController controller;
  final double xOffset;
  final double size;
  final int seed;
  Offset? randomPosition; // Random position assigned when particle spawns

  _SmokeParticle({
    required this.controller,
    required this.xOffset,
    required this.size,
    required this.seed,
    this.randomPosition,
  });
}

class _CoolingSmokePainter extends CustomPainter {
  final List<_SmokeParticle> particles;
  final double coolingIntensity;

  _CoolingSmokePainter({
    required this.particles,
    required this.coolingIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      if (!particle.controller.isAnimating && particle.controller.value == 0) {
        continue; // Skip particles that haven't started
      }

      final progress = particle.controller.value;
      
      // Use the random position assigned when particle spawned, or generate one if missing
      Offset position;
      if (particle.randomPosition != null) {
        position = particle.randomPosition!;
      } else {
        // Fallback: generate position from seed if randomPosition wasn't set
        final xSeed = (particle.seed * 7) % 10000;
        final ySeed = (particle.seed * 13) % 10000;
        position = Offset(xSeed / 10000.0, ySeed / 10000.0);
      }
      
      // Scale random position (0.0-1.0) to actual container bounds
      // Keep smoke well inside container with margins
      final minX = particle.size + 5; // Margin from left edge
      final maxX = size.width - particle.size - 5; // Margin from right edge
      final startX = minX + position.dx * (maxX - minX);
      
      final minY = particle.size + 5; // Margin from top edge
      final maxY = size.height - particle.size - 5; // Margin from bottom edge
      final startY = minY + position.dy * (maxY - minY);
      
      // Smoke floats and expands at its random position
      // Slight movement during animation
      final driftX = (progress - 0.5) * 10.0; // Horizontal drift
      final driftY = (progress - 0.5) * 5.0; // Vertical drift
      
      // Clamp positions to ensure smoke stays within bounds
      final x = (startX + driftX).clamp(particle.size + 2, size.width - particle.size - 2);
      final y = (startY + driftY).clamp(particle.size + 2, size.height - particle.size - 2);
      
      // Opacity: fade in, stay visible, then fade out
      final opacity = _calculateOpacity(progress) * coolingIntensity;
      
      // Smoke size increases as it rises (expands)
      final currentSize = particle.size * (1.0 + progress * 0.8);
      
      // Draw wispy smoke effect - multiple overlapping circles for wispy look
      final smokePaint = Paint()
        ..style = PaintingStyle.fill;
      
      // Sky blue color (#87CEEB)
      const skyBlue = Color(0xFF87CEEB);
      const lightSkyBlue = Color(0xFFB0E0E6);
      const paleSkyBlue = Color(0xFFE0F6FF);
      
      // Main smoke wisp (sky blue)
      smokePaint.color = paleSkyBlue.withOpacity(opacity * 0.7);
      canvas.drawCircle(Offset(x, y), currentSize, smokePaint);
      
      // Additional wisps for more realistic smoke effect
      smokePaint.color = lightSkyBlue.withOpacity(opacity * 0.5);
      canvas.drawCircle(Offset(x - currentSize * 0.3, y - currentSize * 0.2), currentSize * 0.7, smokePaint);
      canvas.drawCircle(Offset(x + currentSize * 0.3, y - currentSize * 0.2), currentSize * 0.7, smokePaint);
      canvas.drawCircle(Offset(x, y - currentSize * 0.4), currentSize * 0.6, smokePaint);
      
      // Outer glow for cool air effect
      smokePaint.color = skyBlue.withOpacity(opacity * 0.3);
      canvas.drawCircle(Offset(x, y), currentSize * 1.3, smokePaint);
    }
  }

  /// Calculate opacity based on animation progress (fade in, stay visible, fade out)
  double _calculateOpacity(double progress) {
    if (progress < 0.2) {
      // Fade in (0 to 0.2)
      return (progress / 0.2) * 0.9;
    } else if (progress < 0.7) {
      // Stay visible (0.2 to 0.7)
      return 0.9;
    } else {
      // Fade out (0.7 to 1.0)
      return 0.9 * (1.0 - (progress - 0.7) / 0.3);
    }
  }

  @override
  bool shouldRepaint(_CoolingSmokePainter oldDelegate) => true; // Always repaint for smooth animation
}

