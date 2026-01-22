import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';

/// Service for managing background music and sound effects
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  AudioPlayer? _backgroundPlayer;
  AudioPlayer? _soundEffectsPlayer;
  final SettingsService _settingsService = SettingsService();

  bool _isInitialized = false;
  bool _isBackgroundMusicPlaying = false;

  /// Initialize the sound service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _settingsService.initialize();
      
      // Create audio players for background music and sound effects
      _backgroundPlayer = AudioPlayer();
      _soundEffectsPlayer = AudioPlayer();
      
      // Set background music to loop
      await _backgroundPlayer!.setLoopMode(LoopMode.one);
      
      // Add listener to detect if background music stops unexpectedly
      _backgroundPlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed || 
            state.processingState == ProcessingState.idle) {
          // Music stopped unexpectedly, restart if enabled
          if (_settingsService.isMusicEnabled && _isBackgroundMusicPlaying) {
            debugPrint('Background music stopped unexpectedly, restarting...');
            Future.delayed(const Duration(milliseconds: 100), () {
              playBackgroundMusic();
            });
          } else {
            _isBackgroundMusicPlaying = false;
          }
        } else if (state.playing) {
          _isBackgroundMusicPlaying = true;
        }
      });
      
      // Set volume from settings
      await _updateVolumes();
      
      // Start background music if enabled
      if (_settingsService.isMusicEnabled) {
        await playBackgroundMusic();
      }
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing sound service: $e');
      // Don't mark as initialized if there's an error
    }
  }

  /// Play background music from asset file
  Future<void> playBackgroundMusic() async {
    if (!_isInitialized || _backgroundPlayer == null) {
      debugPrint('Sound service not initialized or player is null');
      return;
    }
    
    if (!_settingsService.isMusicEnabled) {
      debugPrint('Music is disabled in settings');
      return;
    }

    // If already playing, don't restart
    if (_isBackgroundMusicPlaying) {
      debugPrint('Background music already playing');
      return;
    }

    try {
      // Load background music from assets
      final audioSource = AudioSource.asset('assets/Sounds/background_music.wav');
      
      await _backgroundPlayer!.setLoopMode(LoopMode.one);
      await _backgroundPlayer!.setAudioSource(audioSource);
      await _backgroundPlayer!.play();
      _isBackgroundMusicPlaying = true;
      debugPrint('Background music started');
    } catch (e) {
      debugPrint('Error playing background music: $e');
      _isBackgroundMusicPlaying = false;
    }
  }

  /// Stop background music
  Future<void> stopBackgroundMusic() async {
    if (_backgroundPlayer == null) return;
    try {
      await _backgroundPlayer!.stop();
      _isBackgroundMusicPlaying = false;
    } catch (e) {
      debugPrint('Error stopping background music: $e');
    }
  }

  /// Pause background music
  Future<void> pauseBackgroundMusic() async {
    if (_backgroundPlayer == null) return;
    try {
      await _backgroundPlayer!.pause();
      _isBackgroundMusicPlaying = false;
    } catch (e) {
      debugPrint('Error pausing background music: $e');
    }
  }

  /// Resume background music
  Future<void> resumeBackgroundMusic() async {
    if (!_isInitialized || _backgroundPlayer == null) return;
    if (!_settingsService.isMusicEnabled) return;
    try {
      // Check current state - if not playing, start fresh instead of resume
      final state = _backgroundPlayer!.playerState;
      if (state.playing) {
        // Already playing, nothing to do
        _isBackgroundMusicPlaying = true;
        return;
      }
      
      // If paused, resume; otherwise start fresh
      if (state.processingState == ProcessingState.ready) {
        await _backgroundPlayer!.play();
        _isBackgroundMusicPlaying = true;
      } else {
        // Not ready, start fresh
        await playBackgroundMusic();
      }
    } catch (e) {
      debugPrint('Error resuming background music: $e');
      // Try to start fresh if resume fails
      await playBackgroundMusic();
    }
  }

  /// Play touch sound effect from asset file
  Future<void> playTouchSound() async {
    if (!_isInitialized || _soundEffectsPlayer == null) {
      return;
    }
    
    if (!_settingsService.isSoundEffectsEnabled) {
      return;
    }

    try {
      // Load UI click sound from assets
      final audioSource = AudioSource.asset('assets/Sounds/ui_click.wav');
      
      // Set volume from settings
      try {
        await _soundEffectsPlayer!.setVolume(_settingsService.soundEffectsVolume);
      } catch (e) {
        debugPrint('Could not set sound effects volume: $e');
      }
      
      // Play the click sound (don't loop)
      await _soundEffectsPlayer!.setAudioSource(audioSource);
      await _soundEffectsPlayer!.play();
    } catch (e) {
      debugPrint('Error playing touch sound: $e');
    }
  }

  /// Play success sound effect from asset file
  Future<void> playSuccessSound() async {
    if (!_isInitialized || _soundEffectsPlayer == null) {
      return;
    }
    
    if (!_settingsService.isSoundEffectsEnabled) {
      return;
    }

    try {
      // Load success sound from assets
      final audioSource = AudioSource.asset('assets/Sounds/success.wav');
      
      // Set volume from settings
      try {
        await _soundEffectsPlayer!.setVolume(_settingsService.soundEffectsVolume);
      } catch (e) {
        debugPrint('Could not set sound effects volume: $e');
      }
      
      // Play the success sound (don't loop)
      await _soundEffectsPlayer!.setAudioSource(audioSource);
      await _soundEffectsPlayer!.play();
    } catch (e) {
      debugPrint('Error playing success sound: $e');
    }
  }

  /// Play fail sound effect from asset file
  Future<void> playFailSound() async {
    if (!_isInitialized || _soundEffectsPlayer == null) {
      return;
    }
    
    if (!_settingsService.isSoundEffectsEnabled) {
      return;
    }

    try {
      // Load fail sound from assets
      final audioSource = AudioSource.asset('assets/Sounds/fail.wav');
      
      // Set volume from settings
      try {
        await _soundEffectsPlayer!.setVolume(_settingsService.soundEffectsVolume);
      } catch (e) {
        debugPrint('Could not set sound effects volume: $e');
      }
      
      // Play the fail sound (don't loop)
      await _soundEffectsPlayer!.setAudioSource(audioSource);
      await _soundEffectsPlayer!.play();
    } catch (e) {
      debugPrint('Error playing fail sound: $e');
    }
  }

  /// Update volumes from settings
  Future<void> _updateVolumes() async {
    if (_backgroundPlayer != null) {
      try {
        await _backgroundPlayer!.setVolume(_settingsService.musicVolume);
      } catch (e) {
        // If setVolume doesn't exist, volume might be read-only
        debugPrint('Could not set volume: $e');
      }
    }
    if (_soundEffectsPlayer != null) {
      try {
        await _soundEffectsPlayer!.setVolume(_settingsService.soundEffectsVolume);
      } catch (e) {
        debugPrint('Could not set sound effects volume: $e');
      }
    }
  }

  /// Update music enabled state
  Future<void> setMusicEnabled(bool enabled) async {
    await _settingsService.setMusicEnabled(enabled);
    if (enabled) {
      await playBackgroundMusic();
    } else {
      await stopBackgroundMusic();
    }
  }

  /// Update music volume
  Future<void> setMusicVolume(double volume) async {
    await _settingsService.setMusicVolume(volume);
    if (_backgroundPlayer != null) {
      try {
        await _backgroundPlayer!.setVolume(volume);
      } catch (e) {
        // If setVolume doesn't exist, volume might be read-only
        debugPrint('Could not set volume: $e');
      }
    }
  }

  /// Update sound effects enabled state
  Future<void> setSoundEffectsEnabled(bool enabled) async {
    await _settingsService.setSoundEffectsEnabled(enabled);
  }

  /// Update sound effects volume
  Future<void> setSoundEffectsVolume(double volume) async {
    await _settingsService.setSoundEffectsVolume(volume);
    if (_soundEffectsPlayer != null) {
      try {
        await _soundEffectsPlayer!.setVolume(volume);
      } catch (e) {
        debugPrint('Could not set sound effects volume: $e');
      }
    }
  }

  /// Get current music enabled state
  bool get isMusicEnabled => _settingsService.isMusicEnabled;

  /// Get current music volume
  double get musicVolume => _settingsService.musicVolume;

  /// Get current sound effects enabled state
  bool get isSoundEffectsEnabled => _settingsService.isSoundEffectsEnabled;

  /// Get current sound effects volume
  double get soundEffectsVolume => _settingsService.soundEffectsVolume;

  /// Check if background music is currently playing
  bool get isBackgroundMusicPlaying => _isBackgroundMusicPlaying;

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _backgroundPlayer?.dispose();
      await _soundEffectsPlayer?.dispose();
    } catch (e) {
      debugPrint('Error disposing sound service: $e');
    }
    _backgroundPlayer = null;
    _soundEffectsPlayer = null;
    _isInitialized = false;
  }
}

