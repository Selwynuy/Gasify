import 'package:flutter/material.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../features/start/screens/start_screen.dart';
import '../../../shared/services/activity_unlock_service.dart';

/// Settings screen for app configuration.
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onResetActivity;
  
  const SettingsScreen({super.key, this.onResetActivity});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SoundService _soundService = SoundService();
  final SettingsService _settingsService = SettingsService();
  
  bool _musicEnabled = true;
  double _musicVolume = 0.7;
  bool _soundEffectsEnabled = true;
  double _soundEffectsVolume = 0.8;
  bool _animationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settingsService.initialize();
    setState(() {
      _musicEnabled = _soundService.isMusicEnabled;
      _musicVolume = _soundService.musicVolume;
      _soundEffectsEnabled = _soundService.isSoundEffectsEnabled;
      _soundEffectsVolume = _soundService.soundEffectsVolume;
      _animationsEnabled = _settingsService.isAnimationsEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Reset section at the start
                _buildSection(
                  title: 'Reset',
                  icon: Icons.refresh,
                  children: [
                    ListTile(
                      title: const Text(
                        'Reset Game',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Return to the main menu and reset all activities',
                        style: TextStyle(color: Colors.white70),
                      ),
                      leading: const Icon(Icons.refresh, color: Colors.white70),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          // Reset all activity unlocks
                          await ActivityUnlockService.resetAllUnlocks();
                          // Navigate to start screen, clearing all routes
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const StartScreen()),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('RESET'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Music section
                _buildSection(
                  title: 'Music',
                  icon: Icons.music_note,
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Enable Music',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _musicEnabled,
                      onChanged: (value) async {
                        setState(() {
                          _musicEnabled = value;
                        });
                        await _soundService.setMusicEnabled(value);
                      },
                      activeThumbColor: colorScheme.primary,
                    ),
                    if (_musicEnabled) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Volume: ${(_musicVolume * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Slider(
                              value: _musicVolume,
                              onChanged: (value) async {
                                setState(() {
                                  _musicVolume = value;
                                });
                                await _soundService.setMusicVolume(value);
                              },
                              activeColor: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                // Sound Effects section
                _buildSection(
                  title: 'Sound Effects',
                  icon: Icons.volume_up,
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Enable Sound Effects',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _soundEffectsEnabled,
                      onChanged: (value) async {
                        setState(() {
                          _soundEffectsEnabled = value;
                        });
                        await _soundService.setSoundEffectsEnabled(value);
                      },
                      activeThumbColor: colorScheme.primary,
                    ),
                    if (_soundEffectsEnabled) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Volume: ${(_soundEffectsVolume * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Slider(
                              value: _soundEffectsVolume,
                              onChanged: (value) async {
                                setState(() {
                                  _soundEffectsVolume = value;
                                });
                                await _soundService.setSoundEffectsVolume(value);
                              },
                              activeColor: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                // Other settings
                _buildSection(
                  title: 'Display',
                  icon: Icons.palette,
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Enable Animations',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _animationsEnabled,
                      onChanged: (value) async {
                        setState(() {
                          _animationsEnabled = value;
                        });
                        await _settingsService.setAnimationsEnabled(value);
                      },
                      activeThumbColor: colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // About section
                _buildSection(
                  title: 'About Us',
                  icon: Icons.info,
                  children: const [
                    ListTile(
                      leading: Icon(Icons.group, color: Colors.white70),
                      title: Text(
                        'Researchers',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '• Shaima L. Manap\n'
                        '• Sharmaine Lyza P. Serentas\n'
                        '• Hussem Jaib C. Surposa',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.code, color: Colors.white70),
                      title: Text(
                        'Developer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Selwyn Uy',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

