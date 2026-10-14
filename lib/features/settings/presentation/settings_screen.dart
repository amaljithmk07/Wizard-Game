import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _musicVol = 0.8;
  double _sfxVol = 1.0;
  bool _haptics = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('GAME SETTINGS', style: AppTypography.heading(fontSize: 16)),
        backgroundColor: AppColors.midnightPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text('Background Music',
                  style: AppTypography.heading(fontSize: 14)),
              subtitle: Slider(
                value: _musicVol,
                onChanged: (val) => setState(() => _musicVol = val),
                activeColor: AppColors.gold,
              ),
            ),
            ListTile(
              title: Text('Sound Effects (SFX)',
                  style: AppTypography.heading(fontSize: 14)),
              subtitle: Slider(
                value: _sfxVol,
                onChanged: (val) => setState(() => _sfxVol = val),
                activeColor: AppColors.gold,
              ),
            ),
            SwitchListTile(
              title: Text('Tactile Mobile Haptics',
                  style: AppTypography.heading(fontSize: 14)),
              value: _haptics,
              onChanged: (val) => setState(() => _haptics = val),
              activeTrackColor: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}
