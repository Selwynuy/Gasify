// Data interpretation for rubber boat (volume vs temperature).
// Used for live feedback under the graph and the reference table dialog.

enum RubberBoatSeverity { normal, caution, danger, critical }

class RubberBoatInterpretation {
  const RubberBoatInterpretation({
    required this.message,
    required this.severity,
  });
  final String message;
  final RubberBoatSeverity severity;
}

/// Volume bands (L): 24–36, 37–43, above 43
const List<(double, double)> _volumeBands = [
  (24.0, 36.0),
  (37.0, 43.0),
  (43.0, 200.0), // above 43 L
];

/// Temperature bands (K): 283–300, 300–350, 350–378
const List<(double, double)> _tempBands = [
  (283.0, 300.0),
  (300.0, 350.0),
  (350.0, 378.0),
];

/// Grid: [volumeBandIndex][tempBandIndex] -> interpretation
const List<List<RubberBoatInterpretation>> _grid = [
  [
    const RubberBoatInterpretation(
      message: 'Safe/Under-inflated: Boat is stable; air is cool and compressed.',
      severity: RubberBoatSeverity.normal,
    ),
    const RubberBoatInterpretation(
      message: 'Normal Operation: Typical volume for moderate heat.',
      severity: RubberBoatSeverity.normal,
    ),
    const RubberBoatInterpretation(
      message: 'Warning: Air is very hot but volume is low; check for leaks.',
      severity: RubberBoatSeverity.caution,
    ),
  ],
  [
    const RubberBoatInterpretation(
      message: 'Over-inflated for Cold: High volume despite low temp; risk if it warms up.',
      severity: RubberBoatSeverity.caution,
    ),
    const RubberBoatInterpretation(
      message: 'Maximum Capacity: The boat is fully expanded.',
      severity: RubberBoatSeverity.normal,
    ),
    const RubberBoatInterpretation(
      message: 'DANGER: Expansion Limit: Air is pushing against boat walls.',
      severity: RubberBoatSeverity.danger,
    ),
  ],
  [
    const RubberBoatInterpretation(
      message: 'DANGER: Structural Strain: Volume exceeds safe design.',
      severity: RubberBoatSeverity.danger,
    ),
    const RubberBoatInterpretation(
      message: 'CRITICAL: Rupture Risk: Material is stretching beyond limits.',
      severity: RubberBoatSeverity.critical,
    ),
    const RubberBoatInterpretation(
      message: 'CRITICAL: Rupture Risk: Extreme temperature and volume.',
      severity: RubberBoatSeverity.critical,
    ),
  ],
];

int _volumeBandIndex(double volumeL) {
  if (volumeL > 43.0) return 2; // 43 L above
  if (volumeL >= 37.0) return 1; // 37 to 43
  if (volumeL >= 24.0) return 0; // 24 to 36
  return 0; // below 24, clamp to first band
}

int _tempBandIndex(double tempK) {
  for (var i = 0; i < _tempBands.length; i++) {
    final (lo, hi) = _tempBands[i];
    if (tempK >= lo && tempK < hi) return i;
  }
  if (tempK < _tempBands[0].$1) return 0;
  return _tempBands.length - 1;
}

/// Returns the interpretation for the current volume (L) and temperature (K).
/// Values outside the table bands are clamped to the nearest band.
RubberBoatInterpretation getInterpretation(double volumeL, double tempK) {
  final vi = _volumeBandIndex(volumeL.clamp(0.0, 200.0));
  final ti = _tempBandIndex(tempK.clamp(250.0, 400.0));
  return _grid[vi][ti];
}

/// Volume band labels for the reference table.
List<(String, double, double)> getVolumeBandLabels() {
  const labels = ['24 L TO 36 L', '37 L TO 43 L', '43 L ABOVE'];
  return List.generate(3, (i) => (labels[i], _volumeBands[i].$1, _volumeBands[i].$2));
}

/// Temperature band labels for the reference table.
List<(String, double, double)> getTempBandLabels() {
  const labels = ['283 K TO 300 K', '300 K TO 350 K', '350 K TO 378 K'];
  return List.generate(3, (i) => (labels[i], _tempBands[i].$1, _tempBands[i].$2));
}

/// Full 3×3 grid for the reference dialog. [volumeIndex][tempIndex].
List<List<RubberBoatInterpretation>> getRubberBoatInterpretationGrid() =>
    _grid;
