import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/services/sound_service.dart';

/// Rubber Boat Experiment for Charles Law.
/// Demonstrates: V₁/T₁ = V₂/T₂ (at constant pressure)
/// Interactive simulation with temperature slider and visual feedback.
class RubberBoatActivity extends StatefulWidget {
  const RubberBoatActivity({super.key});

  @override
  State<RubberBoatActivity> createState() => _RubberBoatActivityState();
}

class _RubberBoatActivityState extends State<RubberBoatActivity> {
  // Temperature values (in Celsius)
  double _initialTempC = 22.0;
  double _finalTempC = 45.0; // Start at 45°C to match example

  // Volume values (in Liters)
  // Calculate V₁ to match example: V₂ = 32.3 L at T₂ = 45°C, T₁ = 22°C
  // V₁ = V₂ × T₁ / T₂ = 32.3 × 295.15 / 318.15 ≈ 29.95 L
  static const double _initialVolumeL = 30.0; // V₁ (approximately matches example)
  double _finalVolumeL = 30.0; // V₂ (calculated)
  bool _showAnswer = false; // Whether to show the calculated answer

  // Constants
  // Initial temp range (early morning): 15-30°C, with 22°C in the middle
  static const double _minInitialTempC = 15.0;
  static const double _maxInitialTempC = 30.0;
  // Final temp range: up to 100°C (min is dynamic, based on initial temp)
  static const double _maxFinalTempC = 100.0;
  static const double _kelvinOffset = 273.15;
  static const double _maxSafeVolumeL = 50.0; // Physical limit for tire (burst threshold)

  @override
  void initState() {
    super.initState();
    // Ensure final temp is within valid range
    _finalTempC = _finalTempC.clamp(_initialTempC, _maxFinalTempC);
    // Calculate volume for visual effects, but don't show answer yet
    _calculateVolume();
    
    // Start beach background music
    SoundService().playBeachMusic();
  }

  @override
  void dispose() {
    // Stop beach background music
    SoundService().stopBeachMusic();
    super.dispose();
  }

  /// Convert Celsius to Kelvin
  double _celsiusToKelvin(double celsius) => celsius + _kelvinOffset;

  /// Calculate V₂ using Charles's Law: V₂ = V₁ × (T₂/T₁)
  void _calculateVolume() {
    final t1K = _celsiusToKelvin(_initialTempC);
    final t2K = _celsiusToKelvin(_finalTempC);
    
    // Charles's Law: V₂ = V₁ × (T₂/T₁)
    final calculatedV2 = _initialVolumeL * (t2K / t1K);
    
    // Constraint: V₂ should never go below 0
    _finalVolumeL = calculatedV2.clamp(0.0, double.infinity);
    
    setState(() {});
  }

  /// Check if volume exceeds safe limit (burst warning)
  bool _isBurstWarning() {
    return _finalVolumeL > _maxSafeVolumeL;
  }

  /// Get the scale factor for tire (more exaggerated, 1.0 to ~1.15)
  double _getTireScale() {
    // More exaggerated growth for tire
    final tempRange = _maxFinalTempC - _initialTempC;
    final tempProgress = (_finalTempC - _initialTempC) / tempRange.clamp(1.0, double.infinity);
    return 1.0 + (tempProgress * 0.15).clamp(0.0, 0.15); // 1.0 to 1.15
  }

  /// Get background color filter based on temperature
  ColorFilter _getBackgroundColorFilter() {
    // Interpolate between cool (blue tint) and hot (orange/red tint)
    const tempRange = _maxFinalTempC - _minInitialTempC;
    final tempProgress = tempRange > 0 
        ? ((_finalTempC - _minInitialTempC) / tempRange).clamp(0.0, 1.0)
        : 0.0;
    
    // At 22°C: cool blue tint
    // At 45°C+: warm orange/red tint
    final r = (1.0 + (tempProgress * 0.2)).clamp(0.0, 2.0); // Slight red increase
    final g = (1.0 - (tempProgress * 0.1)).clamp(0.0, 2.0); // Slight green decrease
    final b = (1.0 - (tempProgress * 0.3)).clamp(0.0, 2.0); // More blue decrease
    
    return ColorFilter.matrix([
      r, 0, 0, 0, 0,
      0, g, 0, 0, 0,
      0, 0, b, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }

  /// Get graph data points for the line chart
  List<FlSpot> _getGraphSpots() {
    // Use initial temp as reference for the line
    final t1K = _celsiusToKelvin(_initialTempC);
    final tMinK = _celsiusToKelvin(_minInitialTempC);
    final tMaxK = _celsiusToKelvin(_maxFinalTempC);
    
    // Calculate volumes at min and max temperatures using initial temp as reference
    final vAtMin = _initialVolumeL * (tMinK / t1K);
    final vAtMax = _initialVolumeL * (tMaxK / t1K);
    
    // Return points for a straight line (direct proportion)
    // Extend line to show the relationship clearly
    return [
      FlSpot(tMinK, vAtMin),
      FlSpot(tMaxK, vAtMax),
    ];
  }

  /// Get current indicator spot on the graph
  FlSpot _getCurrentSpot() {
    final t2K = _celsiusToKelvin(_finalTempC);
    return FlSpot(t2K, _finalVolumeL);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Charles's Law: Rubber Boat"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Section: Visual Stack with Graph overlay (55% of height)
              Expanded(
                flex: 11,
                child: _buildVisualStack(),
              ),
              
              // Bottom Section: Simulation Panel (45% of height, full width)
              Expanded(
                flex: 7,
                child: _buildSimulationPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the visual stack with background, boat, tire, and labels
  Widget _buildVisualStack() {
    return Stack(
      children: [
        // Base Layer: Background Image with Color Filter - Full space
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: ColorFiltered(
              key: ValueKey(_finalTempC.round()),
              colorFilter: _getBackgroundColorFilter(),
              child: Image.asset(
                'assets/charles_law_act2/background.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.blue.shade100,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              ),
            ),
          ),
        ),
        
        // Graph at top right - scaled down, non-interactive
        Positioned(
          top: 10,
          right: 10,
          child: IgnorePointer(
            child: SizedBox(
              width: 180,
              height: 140,
              child: _buildGraph(),
            ),
          ),
        ),
        
        // Tire Image (behind boat) - comes before boat in Stack to be behind it
        Positioned(
          left: 120, // Position tire at the back (left side) of boat
          bottom: 105, // Align with boat vertically
          child: AnimatedScale(
            scale: _getTireScale(),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Image.asset(
              'assets/charles_law_act2/tire.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.circle, color: Colors.white, size: 40),
                );
              },
            ),
          ),
        ),
        
        // Boat Image (in front of tire) - comes after tire in Stack to be in front
        // Boat does not expand - only the tire expands
        Positioned(
          left: 50, // Move to the left
          bottom: 40, // Move down (from bottom)
          child: Image.asset(
            'assets/charles_law_act2/boat.png',
            width: 200,
            height: 200,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                color: Colors.brown.shade300,
                child: const Icon(Icons.directions_boat, size: 100),
              );
            },
          ),
        ),
        
        // Overlay Labels: V₁, T₁, T₂, V₂
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'V₁: ${_initialVolumeL.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'T₁: ${_initialTempC.toStringAsFixed(1)} °C (${_celsiusToKelvin(_initialTempC).toStringAsFixed(2)} K)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'T₂: ${_finalTempC.toStringAsFixed(1)} °C (${_celsiusToKelvin(_finalTempC).toStringAsFixed(2)} K)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build the simulation panel with sliders and result box
  Widget _buildSimulationPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade300, width: 1.5),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SIMULATION PANEL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 6),
          
            // Initial Temp Slider (Early Morning Range)
            Text(
              'Initial Temp (°C) [Early Morning]: ${_initialTempC.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Slider(
              value: _initialTempC.clamp(_minInitialTempC, _maxInitialTempC),
              min: _minInitialTempC,
              max: _maxInitialTempC,
              divisions: ((_maxInitialTempC - _minInitialTempC) * 10).round(),
              label: _initialTempC.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _initialTempC = value.clamp(_minInitialTempC, _maxInitialTempC);
                  // Ensure final temp is always >= initial temp and within max range
                  _finalTempC = _finalTempC.clamp(_initialTempC, _maxFinalTempC);
                  _calculateVolume(); // Update visuals
                  _showAnswer = false; // Hide answer when sliders change
                });
                SoundService().playTouchSound();
              },
            ),
            
            const SizedBox(height: 2),
            
            // Final Temp Slider
            Text(
              'Final Temp (°C): ${_finalTempC.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Slider(
              value: _finalTempC.clamp(_initialTempC, _maxFinalTempC),
              min: _initialTempC, // Final temp must be >= initial temp
              max: _maxFinalTempC,
              divisions: ((_maxFinalTempC - _initialTempC) * 10).round().clamp(1, 1000),
              label: _finalTempC.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _finalTempC = value.clamp(_initialTempC, _maxFinalTempC);
                  _calculateVolume(); // Update visuals
                  _showAnswer = false; // Hide answer when sliders change
                });
                SoundService().playTouchSound();
              },
            ),
            
            const SizedBox(height: 6),
          
            // Calculate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _calculateVolume();
                    _showAnswer = true;
                  });
                  SoundService().playTouchSound();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Calculate V₂',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 6),
          
            // Result Box (only show if answer is calculated)
            if (_showAnswer)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _isBurstWarning() 
                    ? Colors.red.shade100 
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isBurstWarning() 
                      ? Colors.red.shade400 
                      : Colors.green.shade400, 
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isBurstWarning() 
                        ? '⚠️ BURST! ⚠️' 
                        : 'ANSWER: V₂ = ${_finalVolumeL.toStringAsFixed(1)} L',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isBurstWarning() 
                          ? Colors.red.shade900 
                          : Colors.green.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isBurstWarning())
                    const SizedBox(height: 2),
                  if (_isBurstWarning())
                    Text(
                      'V₂ = ${_finalVolumeL.toStringAsFixed(1)} L\n(Exceeds safe limit!)',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the graph using fl_chart
  Widget _buildGraph() {
    final spots = _getGraphSpots();
    final currentSpot = _getCurrentSpot();
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Volume vs Temperature',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
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
                    axisNameWidget: const Text(
                      'Temperature (K)',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 7,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Volume (L)',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 7,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                minX: _celsiusToKelvin(_minInitialTempC) - 5,
                maxX: _celsiusToKelvin(_maxFinalTempC) + 5,
                minY: (_initialVolumeL * (_celsiusToKelvin(_minInitialTempC) / _celsiusToKelvin(_initialTempC))) - 5,
                maxY: (_initialVolumeL * (_celsiusToKelvin(_maxFinalTempC) / _celsiusToKelvin(_initialTempC))) + 5,
                lineBarsData: [
                  // Direct proportion line
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: Colors.blue.shade400,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Current indicator dot
                  LineChartBarData(
                    spots: [currentSpot],
                    isCurved: false,
                    color: Colors.transparent,
                    barWidth: 0,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.orange.shade700,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                // Add label for P = Constant
                extraLinesData: const ExtraLinesData(
                  verticalLines: [],
                  horizontalLines: [],
                ),
              ),
            ),
          ),
          const SizedBox(height: 1),
          Center(
            child: Text(
              'P = Constant',
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
