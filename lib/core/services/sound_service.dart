import 'dart:async';
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
  AudioPlayer? _continuousSoundPlayer; // For looping sounds like syringe drag
  AudioPlayer? _activityMusicPlayer; // For activity-specific background music (e.g., bubbles)
  final SettingsService _settingsService = SettingsService();

  bool _isInitialized = false;
  bool _isBackgroundMusicPlaying = false;
  bool _isActivityMusicPlaying = false;
  
  // Track pointer IDs that should skip wrapper touch sounds (e.g., ActionButtons)
  static final Set<int> _skipWrapperSoundPointers = {};
  
  /// Register a pointer ID to skip wrapper touch sounds
  static void registerSkipWrapperSound(int pointer) {
    _skipWrapperSoundPointers.add(pointer);
  }
  
  /// Unregister a pointer ID from skipping wrapper touch sounds
  static void unregisterSkipWrapperSound(int pointer) {
    _skipWrapperSoundPointers.remove(pointer);
  }
  
  /// Check if a pointer ID should skip wrapper touch sounds
  static bool shouldSkipWrapperSound(int pointer) {
    return _skipWrapperSoundPointers.contains(pointer);
  }

  /// Initialize the sound service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _settingsService.initialize();
      
      // Create audio players for background music and sound effects
      _backgroundPlayer = AudioPlayer();
      _soundEffectsPlayer = AudioPlayer();
      _continuousSoundPlayer = AudioPlayer();
      _activityMusicPlayer = AudioPlayer();
      
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

  /// Play boop sound effect from asset file
  Future<void> playBoopSound() async {
    if (!_isInitialized || _soundEffectsPlayer == null) {
      return;
    }
    
    if (!_settingsService.isSoundEffectsEnabled) {
      return;
    }

    try {
      // Load boop sound from assets
      final audioSource = AudioSource.asset('assets/Sounds/boop.wav');
      
      // Set volume from settings
      try {
        await _soundEffectsPlayer!.setVolume(_settingsService.soundEffectsVolume);
      } catch (e) {
        debugPrint('Could not set sound effects volume: $e');
      }
      
      // Play the boop sound (don't loop)
      await _soundEffectsPlayer!.setAudioSource(audioSource);
      await _soundEffectsPlayer!.play();
    } catch (e) {
      debugPrint('Error playing boop sound: $e');
    }
  }

  /// Play explosion sound effect from asset file
  Future<void> playExplosionSound() async {
    if (!_isInitialized || _soundEffectsPlayer == null) {
      return;
    }
    
    if (!_settingsService.isSoundEffectsEnabled) {
      return;
    }

    try {
      // Temporarily pause activity music to avoid conflicts
      bool wasActivityMusicPlaying = false;
      if (_isActivityMusicPlaying && _activityMusicPlayer != null) {
        try {
          await _activityMusicPlayer!.pause();
          wasActivityMusicPlaying = true;
        } catch (e) {
          // Ignore errors when pausing
        }
      }
      
      // Stop and reset the player to ensure clean state
      try {
        await _soundEffectsPlayer!.stop();
        // Small delay to ensure player is ready
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        // Try to reset the player if stop failed
        try {
          await _soundEffectsPlayer!.seek(Duration.zero);
        } catch (e2) {
          // Ignore errors
        }
      }
      
      // Load explosion sound from assets
      final audioSource = AudioSource.asset('assets/Sounds/explosion.mp3');
      
      // Set volume from settings first
      try {
        await _soundEffectsPlayer!.setVolume(_settingsService.soundEffectsVolume);
      } catch (e) {
        // Ignore volume errors
      }
      
      // Set audio source and play
      try {
        await _soundEffectsPlayer!.setAudioSource(audioSource);
        // Small delay to ensure source is loaded
        await Future.delayed(const Duration(milliseconds: 100));
        await _soundEffectsPlayer!.play();
        
        // Resume activity music after explosion sound finishes
        if (wasActivityMusicPlaying && _activityMusicPlayer != null) {
          // Listen for when explosion sound completes
          StreamSubscription? subscription;
          subscription = _soundEffectsPlayer!.playerStateStream.listen((state) {
            if (state.processingState == ProcessingState.completed) {
              _activityMusicPlayer!.play();
              subscription?.cancel();
            }
          });
          
          // Fallback: resume after 2 seconds if stream doesn't fire
          Future.delayed(const Duration(seconds: 2), () {
            subscription?.cancel();
            if (_activityMusicPlayer != null) {
              _activityMusicPlayer!.play();
            }
          });
        }
      } catch (e) {
        // Resume activity music if we failed
        if (wasActivityMusicPlaying && _activityMusicPlayer != null) {
          try {
            await _activityMusicPlayer!.play();
          } catch (e2) {
            // Ignore errors
          }
        }
        // Try to recreate the player if there's a persistent issue
        try {
          await _soundEffectsPlayer!.dispose();
          _soundEffectsPlayer = AudioPlayer();
          await _soundEffectsPlayer!.setVolume(_settingsService.soundEffectsVolume);
          await _soundEffectsPlayer!.setAudioSource(audioSource);
          await _soundEffectsPlayer!.play();
        } catch (e2) {
          // Ignore errors
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Play pop sound effect from asset file
  /// Note: If pop.aiff doesn't work, converts to pop.wav for better compatibility
  Future<void> playPopSound() async {
    if (!_isInitialized || _soundEffectsPlayer == null) {
      return;
    }
    
    if (!_settingsService.isSoundEffectsEnabled) {
      return;
    }

    try {
      // Stop any currently playing sound first
      try {
        await _soundEffectsPlayer!.stop();
      } catch (e) {
        // Ignore errors when stopping
      }
      
      // Try pop.wav first (if you convert the file), then fallback to pop.aiff
      String soundPath = 'assets/Sounds/pop.wav';
      try {
        final audioSource = AudioSource.asset(soundPath);
        await _soundEffectsPlayer!.setVolume(_settingsService.soundEffectsVolume);
        await _soundEffectsPlayer!.setAudioSource(audioSource);
        await _soundEffectsPlayer!.play();
        return;
      } catch (e) {
        debugPrint('pop.wav not found, trying pop.aiff: $e');
        soundPath = 'assets/Sounds/pop.aiff';
      }
      
      // Load pop sound from assets (try aiff if wav doesn't exist)
      final audioSource = AudioSource.asset(soundPath);
      
      // Set volume from settings
      try {
        await _soundEffectsPlayer!.setVolume(_settingsService.soundEffectsVolume);
      } catch (e) {
        debugPrint('Could not set sound effects volume: $e');
      }
      
      // Play the pop sound (don't loop)
      await _soundEffectsPlayer!.setAudioSource(audioSource);
      await _soundEffectsPlayer!.play();
    } catch (e) {
      debugPrint('Error playing pop sound: $e');
      // Fallback to ui_click sound if pop files fail
      try {
        final fallbackSource = AudioSource.asset('assets/Sounds/ui_click.wav');
        await _soundEffectsPlayer!.setAudioSource(fallbackSource);
        await _soundEffectsPlayer!.play();
      } catch (fallbackError) {
        debugPrint('Error playing fallback sound: $fallbackError');
      }
    }
  }

  /// Start playing syringe drag sound (looped)
  Future<void> startSyringeDragSound() async {
    if (!_isInitialized || _continuousSoundPlayer == null) {
      return;
    }
    
    if (!_settingsService.isSoundEffectsEnabled) {
      return;
    }

    try {
      // Stop any existing sound first
      await _continuousSoundPlayer!.stop();
      
      // Load syringe drag sound from assets
      final audioSource = AudioSource.asset('assets/Sounds/syringe_drag.wav');
      
      // Set volume from settings
      try {
        await _continuousSoundPlayer!.setVolume(_settingsService.soundEffectsVolume);
      } catch (e) {
        debugPrint('Could not set sound effects volume: $e');
      }
      
      // Set to loop mode
      await _continuousSoundPlayer!.setLoopMode(LoopMode.one);
      
      // Play the syringe drag sound (looped)
      await _continuousSoundPlayer!.setAudioSource(audioSource);
      await _continuousSoundPlayer!.play();
    } catch (e) {
      debugPrint('Error playing syringe drag sound: $e');
    }
  }

  /// Stop playing syringe drag sound
  Future<void> stopSyringeDragSound() async {
    if (_continuousSoundPlayer == null) return;
    try {
      await _continuousSoundPlayer!.stop();
    } catch (e) {
      debugPrint('Error stopping syringe drag sound: $e');
    }
  }

  /// Play bubbles background music (for scuba diving activity)
  Future<void> playBubblesMusic() async {
    if (!_isInitialized || _activityMusicPlayer == null) {
      debugPrint('Sound service not initialized or activity music player is null');
      return;
    }
    
    if (!_settingsService.isMusicEnabled) {
      debugPrint('Music is disabled in settings');
      return;
    }

    // If already playing, don't restart
    if (_isActivityMusicPlaying) {
      debugPrint('Bubbles music already playing');
      return;
    }

    try {
      // Pause regular background music
      await pauseBackgroundMusic();
      
      // Load bubbles music from assets
      final audioSource = AudioSource.asset('assets/Sounds/bubbles.wav');
      
      await _activityMusicPlayer!.setLoopMode(LoopMode.one);
      await _activityMusicPlayer!.setAudioSource(audioSource);
      
      // Set volume from settings
      try {
        await _activityMusicPlayer!.setVolume(_settingsService.musicVolume);
      } catch (e) {
        debugPrint('Could not set activity music volume: $e');
      }
      
      await _activityMusicPlayer!.play();
      _isActivityMusicPlaying = true;
      debugPrint('Bubbles music started');
    } catch (e) {
      debugPrint('Error playing bubbles music: $e');
      _isActivityMusicPlaying = false;
    }
  }

  /// Stop bubbles background music and resume regular background music
  Future<void> stopBubblesMusic() async {
    if (_activityMusicPlayer == null) return;
    try {
      await _activityMusicPlayer!.stop();
      _isActivityMusicPlaying = false;
      debugPrint('Bubbles music stopped');
      
      // Resume regular background music if enabled
      if (_settingsService.isMusicEnabled) {
        await resumeBackgroundMusic();
      }
    } catch (e) {
      debugPrint('Error stopping bubbles music: $e');
    }
  }

  /// Play laboratory background music (for cryo sim activity)
  Future<void> playLaboratoryMusic() async {
    if (!_isInitialized || _activityMusicPlayer == null) {
      debugPrint('Sound service not initialized or activity music player is null');
      return;
    }
    
    if (!_settingsService.isMusicEnabled) {
      debugPrint('Music is disabled in settings');
      return;
    }

    // If already playing, don't restart
    if (_isActivityMusicPlaying) {
      debugPrint('Laboratory music already playing');
      return;
    }

    try {
      // Pause regular background music
      await pauseBackgroundMusic();
      
      // Load laboratory music from assets
      final audioSource = AudioSource.asset('assets/Sounds/laboratory.wav');
      
      await _activityMusicPlayer!.setLoopMode(LoopMode.one);
      await _activityMusicPlayer!.setAudioSource(audioSource);
      
      // Set volume from settings
      try {
        await _activityMusicPlayer!.setVolume(_settingsService.musicVolume);
      } catch (e) {
        debugPrint('Could not set activity music volume: $e');
      }
      
      await _activityMusicPlayer!.play();
      _isActivityMusicPlaying = true;
      debugPrint('Laboratory music started');
    } catch (e) {
      debugPrint('Error playing laboratory music: $e');
      _isActivityMusicPlaying = false;
    }
  }

  /// Stop laboratory background music and resume regular background music
  Future<void> stopLaboratoryMusic() async {
    if (_activityMusicPlayer == null) return;
    try {
      await _activityMusicPlayer!.stop();
      _isActivityMusicPlaying = false;
      debugPrint('Laboratory music stopped');
      
      // Resume regular background music if enabled
      if (_settingsService.isMusicEnabled) {
        await resumeBackgroundMusic();
      }
    } catch (e) {
      debugPrint('Error stopping laboratory music: $e');
    }
  }

  /// Play beach background music (for rubber boat activity)
  Future<void> playBeachMusic() async {
    if (!_isInitialized || _activityMusicPlayer == null) {
      debugPrint('Sound service not initialized or activity music player is null');
      return;
    }
    
    if (!_settingsService.isMusicEnabled) {
      debugPrint('Music is disabled in settings');
      return;
    }

    // If already playing, don't restart
    if (_isActivityMusicPlaying) {
      debugPrint('Beach music already playing');
      return;
    }

    try {
      // Pause regular background music
      await pauseBackgroundMusic();
      
      // Load beach music from assets
      final audioSource = AudioSource.asset('assets/Sounds/beach.wav');
      
      await _activityMusicPlayer!.setLoopMode(LoopMode.one);
      await _activityMusicPlayer!.setAudioSource(audioSource);
      
      // Set volume from settings
      try {
        await _activityMusicPlayer!.setVolume(_settingsService.musicVolume);
      } catch (e) {
        debugPrint('Could not set activity music volume: $e');
      }
      
      await _activityMusicPlayer!.play();
      _isActivityMusicPlaying = true;
      debugPrint('Beach music started');
    } catch (e) {
      debugPrint('Error playing beach music: $e');
      _isActivityMusicPlaying = false;
    }
  }

  /// Stop beach background music and resume regular background music
  Future<void> stopBeachMusic() async {
    if (_activityMusicPlayer == null) return;
    try {
      await _activityMusicPlayer!.stop();
      _isActivityMusicPlaying = false;
      debugPrint('Beach music stopped');
      
      // Resume regular background music if enabled
      if (_settingsService.isMusicEnabled) {
        await resumeBackgroundMusic();
      }
    } catch (e) {
      debugPrint('Error stopping beach music: $e');
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
    if (_activityMusicPlayer != null) {
      try {
        await _activityMusicPlayer!.setVolume(volume);
      } catch (e) {
        debugPrint('Could not set activity music volume: $e');
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
      await _continuousSoundPlayer?.dispose();
      await _activityMusicPlayer?.dispose();
    } catch (e) {
      debugPrint('Error disposing sound service: $e');
    }
    _backgroundPlayer = null;
    _soundEffectsPlayer = null;
    _continuousSoundPlayer = null;
    _activityMusicPlayer = null;
    _isInitialized = false;
  }
}

