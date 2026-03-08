// Data interpretation and danger signs for scuba diving (pressure vs. lung volume).
// Used for live feedback under the graph and the reference table dialog.

enum DangerSeverity { normal, caution, danger, critical }

class DangerZoneInterpretation {
  const DangerZoneInterpretation({
    required this.message,
    required this.severity,
  });
  final String message;
  final DangerSeverity severity;
}

/// Pressure bands (atm): 0–1.6, 1.6–3.2, 3.2–4.8, 4.8–6.4, 6.4–8.0
const List<(double, double)> _pressureBands = [
  (0.0, 1.6),
  (1.6, 3.2),
  (3.2, 4.8),
  (4.8, 6.4),
  (6.4, 8.0),
];

/// Volume bands (L): 0–1.9, 2.0–3.9, 4.0–5.9, 6.0–7.9, 8.0–10.0
const List<(double, double)> _volumeBands = [
  (0.0, 1.9),
  (2.0, 3.9),
  (4.0, 5.9),
  (6.0, 7.9),
  (8.0, 10.0),
];

/// Grid: [pressureBandIndex][volumeBandIndex] -> interpretation
const List<List<DangerZoneInterpretation>> _grid = [
  [
    DangerZoneInterpretation(
      message: 'DANGER: Lung Squeeze. Volume is too low for this shallow depth (0-6m).',
      severity: DangerSeverity.danger,
    ),
    DangerZoneInterpretation(
      message: 'Caution: Lungs are moderately compressed; typical for a partial exhale.',
      severity: DangerSeverity.caution,
    ),
    DangerZoneInterpretation(
      message: 'Normal Zone: Standard lung volume at or near the surface.',
      severity: DangerSeverity.normal,
    ),
    DangerZoneInterpretation(
      message: 'Full Capacity: Lungs are at maximum safe expansion near the surface.',
      severity: DangerSeverity.normal,
    ),
    DangerZoneInterpretation(
      message: '▲ CRITICAL DANGER: Lung Rupture. Volume exceeds physical capacity.',
      severity: DangerSeverity.critical,
    ),
  ],
  [
    DangerZoneInterpretation(
      message: 'DANGER: Severe Lung Squeeze. Risk of chest wall collapse at 6-22m.',
      severity: DangerSeverity.danger,
    ),
    DangerZoneInterpretation(
      message: 'Stable Diving: Expected volume for recreational depths.',
      severity: DangerSeverity.normal,
    ),
    DangerZoneInterpretation(
      message: 'High Volume: Diver has inhaled deeply; MUST EXHALE before ascending.',
      severity: DangerSeverity.caution,
    ),
    DangerZoneInterpretation(
      message: '▲ DANGER: Over-inflation. Risk of air embolism if depth decreases.',
      severity: DangerSeverity.danger,
    ),
    DangerZoneInterpretation(
      message: '▲ CRITICAL DANGER: Immediate risk of pulmonary barotrauma.',
      severity: DangerSeverity.critical,
    ),
  ],
  [
    DangerZoneInterpretation(
      message: 'DANGER: Lung Squeeze. Depth (22-38m) is crushing the air space.',
      severity: DangerSeverity.danger,
    ),
    DangerZoneInterpretation(
      message: 'Deep Dive Compression: Normal for these high-pressure depths.',
      severity: DangerSeverity.normal,
    ),
    DangerZoneInterpretation(
      message: 'Warning: Artificially high volume; indicates high-pressure tank air.',
      severity: DangerSeverity.caution,
    ),
    DangerZoneInterpretation(
      message: '▲ DANGER: Extreme internal pressure against the chest cavity.',
      severity: DangerSeverity.danger,
    ),
    DangerZoneInterpretation(
      message: '▲ CRITICAL DANGER: High risk of lung tissue tearing.',
      severity: DangerSeverity.critical,
    ),
  ],
  [
    DangerZoneInterpretation(
      message: 'Critical Compression: Approaching the "Residual Volume" limit.',
      severity: DangerSeverity.danger,
    ),
    DangerZoneInterpretation(
      message: 'Technical Zone (38-54m): Deep compression; high gas density.',
      severity: DangerSeverity.normal,
    ),
    DangerZoneInterpretation(
      message: 'Warning: Massive amount of compressed gas held in lungs.',
      severity: DangerSeverity.caution,
    ),
    DangerZoneInterpretation(
      message: '▲ DANGER: Severe risk of "The Bends" and Lung Over-expansion.',
      severity: DangerSeverity.danger,
    ),
    DangerZoneInterpretation(
      message: '▲ CRITICAL DANGER: Fatal risk if any upward movement occurs.',
      severity: DangerSeverity.critical,
    ),
  ],
  [
    DangerZoneInterpretation(
      message: 'DANGER: Maximum Compression. Risk of blood pooling in lungs.',
      severity: DangerSeverity.danger,
    ),
    DangerZoneInterpretation(
      message: 'Extreme Depth (54-70m): Significant nitrogen/oxygen narcosis risk.',
      severity: DangerSeverity.normal,
    ),
    DangerZoneInterpretation(
      message: 'Caution: High density air, breathing is physically exhausting.',
      severity: DangerSeverity.caution,
    ),
    DangerZoneInterpretation(
      message: '▲ DANGER: Lung volume is dangerously high for this pressure.',
      severity: DangerSeverity.danger,
    ),
    DangerZoneInterpretation(
      message: '▲ CRITICAL DANGER: Immediate explosive decompression risk.',
      severity: DangerSeverity.critical,
    ),
  ],
];

int _pressureBandIndex(double pressureAtm) {
  for (var i = 0; i < _pressureBands.length; i++) {
    final (lo, hi) = _pressureBands[i];
    if (pressureAtm >= lo && pressureAtm < hi) return i;
  }
  return _pressureBands.length - 1;
}

int _volumeBandIndex(double volumeL) {
  for (var i = 0; i < _volumeBands.length; i++) {
    final (lo, hi) = _volumeBands[i];
    if (volumeL >= lo && volumeL <= hi) return i;
  }
  if (volumeL < _volumeBands[0].$2) return 0;
  return _volumeBands.length - 1;
}

/// Returns the interpretation for the current pressure (atm) and lung volume (L).
DangerZoneInterpretation getInterpretation(double pressureAtm, double volumeL) {
  final pi = _pressureBandIndex(pressureAtm.clamp(0.0, 8.0));
  final vi = _volumeBandIndex(volumeL.clamp(0.0, 10.0));
  return _grid[pi][vi];
}

/// Pressure bands for the reference table (label and range).
List<(String, double, double)> getPressureBandLabels() {
  const labels = ['0.0 to 1.6 atm', '1.6 to 3.2 atm', '3.2 to 4.8 atm', '4.8 to 6.4 atm', '6.4 to 8.0 atm'];
  return List.generate(5, (i) => (labels[i], _pressureBands[i].$1, _pressureBands[i].$2));
}

/// Volume bands for the reference table (label and range).
List<(String, double, double)> getVolumeBandLabels() {
  const labels = ['0.0 L to 1.9 L', '2.0 L to 3.9 L', '4.0 L to 5.9 L', '6.0 L to 7.9 L', '8.0 L to 10.0 L'];
  return List.generate(5, (i) => (labels[i], _volumeBands[i].$1, _volumeBands[i].$2));
}

/// Full 5×5 grid for the reference dialog. [pressureIndex][volumeIndex].
List<List<DangerZoneInterpretation>> getDangerZonesGrid() => _grid;
