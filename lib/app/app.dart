import 'package:flutter/material.dart';
import '../features/start/screens/start_screen.dart';
import '../core/services/sound_service.dart';

/// Root widget that sets up Material theming and routes.
class ScubaGasLawsApp extends StatefulWidget {
  const ScubaGasLawsApp({super.key});

  @override
  State<ScubaGasLawsApp> createState() => _ScubaGasLawsAppState();
}

class _ScubaGasLawsAppState extends State<ScubaGasLawsApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSound();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final soundService = SoundService();
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - resume music if it should be playing
        if (soundService.isMusicEnabled && !soundService.isBackgroundMusicPlaying) {
          soundService.resumeBackgroundMusic();
        }
        break;
      case AppLifecycleState.paused:
        // App went to background - pause music (optional, can remove if you want it to keep playing)
        // soundService.pauseBackgroundMusic();
        break;
      default:
        break;
    }
  }

  Future<void> _initializeSound() async {
    // Wait for the app to be fully ready before initializing sound
    await WidgetsBinding.instance.endOfFrame;
    // Small delay to ensure plugins are registered
    await Future.delayed(const Duration(milliseconds: 500));
    await SoundService().initialize();
    
    // Double-check music is playing after a short delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      final soundService = SoundService();
      if (soundService.isMusicEnabled && !soundService.isBackgroundMusicPlaying) {
        soundService.playBackgroundMusic();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GASIFY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF99CAE8)),
        useMaterial3: true,
      ),
      home: const StartScreen(),
      builder: (context, child) {
        return _TouchSoundWrapper(child: child!);
      },
    );
  }
}

/// Wrapper that plays touch sounds on taps (not drags)
class _TouchSoundWrapper extends StatefulWidget {
  final Widget child;

  const _TouchSoundWrapper({required this.child});

  @override
  State<_TouchSoundWrapper> createState() => _TouchSoundWrapperState();
}

class _TouchSoundWrapperState extends State<_TouchSoundWrapper> {
  Offset? _pointerDownPosition;
  static const double _maxDragDistance = 10.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _pointerDownPosition = event.position;
      },
      onPointerUp: (event) {
        // Skip sound if this pointer is registered to skip wrapper sounds
        if (SoundService.shouldSkipWrapperSound(event.pointer)) {
          SoundService.unregisterSkipWrapperSound(event.pointer);
          _pointerDownPosition = null;
          return;
        }
        
        if (_pointerDownPosition != null) {
          final distance = (_pointerDownPosition! - event.position).distance;
          // Only play sound if it was a tap (not a drag)
          if (distance < _maxDragDistance) {
            SoundService().playTouchSound();
          }
        }
        _pointerDownPosition = null;
      },
      onPointerCancel: (event) {
        SoundService.unregisterSkipWrapperSound(event.pointer);
        _pointerDownPosition = null;
      },
      child: widget.child,
    );
  }
}

