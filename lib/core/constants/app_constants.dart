/// Application-wide constants
class AppConstants {
  // Depth limits (no cap on max; 200m allows descending past 60m)
  static const double minDepthMeters = 0.0;
  static const double maxDepthMeters = 200.0;
  
  // Lung volume limits
  static const double minLungVolumeLiters = 2.0;
  static const double maxLungVolumeLiters = 6.0;
  static const double safeLungVolumeMax = 5.5;
  static const double surfaceLungVolumeLiters = 6.0;
  
  // Oxygen tank
  static const double initialOxygenTankPercent = 100.0;
  static const double minOxygenTankPercent = 0.0;
  static const double maxOxygenTankPercent = 100.0;
  static const double criticalOxygenPercent = 20.0;
  static const double deathDepthMeters = 5.0;
  
  // Depth step sizes
  static const double ascendStepMeters = 1.0;
  static const double descendStepMeters = 1.5;
  static const double emergencyAscentStepMeters = 5.0;
  
  // Pressure calculation
  static const double pressurePerMeter = 0.1; // 1 atm per 10m = 0.1 atm/m
  static const double surfacePressureAtm = 1.0;
  
  // Animation durations
  static const Duration depthAnimationDuration = Duration(milliseconds: 600);
  static const Duration warningFlashDuration = Duration(milliseconds: 500);
  static const Duration emergencyWarningDisplayDuration = Duration(seconds: 4);
  
  // Graph limits
  static const int maxGraphPoints = 50;
  static const double maxGraphVolume = 10.0;
  static const double maxGraphPressure = 5.0;
  
  // Syringe experiment
  static const double maxSyringeVolume = 60.0;
  static const double minSyringeVolume = 1.0;
  static const double maxBalloonPressure = 3.0;
}

