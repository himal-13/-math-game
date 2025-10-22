// pages/home_page.dart

import 'package:fill_num/pages/easy_mode.dart';
import 'package:fill_num/pages/expert_mode.dart';
import 'package:fill_num/pages/medium_mode.dart';
import 'package:fill_num/pages/hard_mode.dart';
import 'package:fill_num/utils/hint_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _navigateToEasyMode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EasyMode()),
    );
  }

  void _navigateToMediumMode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MediumMode()),
    );
  }

  void _navigateToHardMode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HardMode()),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => _buildSettingsDialog(),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirecting to app store...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSettingsDialog() {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingOption(
              icon: Icons.volume_up,
              title: 'Sound Effects',
            ),
            _buildSettingOption(
              icon: Icons.music_note,
              title: 'Background Music',
            ),
            _buildSettingOption(
              icon: Icons.vibration,
              title: 'Haptic Feedback',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingOption({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange.shade400, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          Switch(
            value: true,
            onChanged: (value) {},
            activeColor: Colors.orange.shade400,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _showSettings,
                    icon: Icon(
                      Icons.settings,
                      color: Colors.grey.shade400,
                      size: 28,
                    ),
                  ),
                  _buildCoinDisplay(),
                ],
              ),

              const SizedBox(height: 40),

              // Title Section
              Center(
                child: Column(
                  children: [
                   
                    const SizedBox(height: 8),
                    Text(
                      'Math Puzzle Game',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Game Modes
              Expanded(
                child: Column(
                  children: [
                    _buildModeCard(
                      title: 'Easy Mode',
                      subtitle: 'Perfect for beginners',
                      color: Colors.green.shade400,
                      onTap: _navigateToEasyMode,
                      icon: Icons.play_arrow,
                    ),
                    const SizedBox(height: 16),
                    _buildModeCard(
                      title: 'Medium Mode',
                      subtitle: 'Balance of challenge & fun',
                      color: Colors.blue.shade400,
                      onTap: _navigateToMediumMode,
                      icon: Icons.gamepad,
                    ),
                    const SizedBox(height: 16),
                    _buildModeCard(
                      title: 'Hard Mode',
                      subtitle: 'Ultimate brain challenge',
                      color: Colors.red.shade400,
                      onTap: _navigateToHardMode,
                      icon: Icons.psychology,
                    ),
                    _buildModeCard(
                      title: 'Expert Mode',
                      subtitle: 'Ultimate brain challenge',
                      color: Colors.red.shade400,
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ExtremeGrid()),
                        );
                      },
                      icon: Icons.psychology,
                    ),
                  ],
                ),
              ),

              // Bottom Buttons
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomButton(
                      icon: Icons.help_outline,
                      label: 'Help',
                      onTap: () {
                        // TODO: Add help dialog
                        _rateApp();
                      },
                    ),
                    _buildBottomButton(
                      icon: Icons.star_border,
                      label: 'Rate',
                      onTap: _rateApp,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoinDisplay() {
    return Consumer<HintService>(
      builder: (context, coinService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                Icons.monetization_on,
                color: Colors.yellow.shade600,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '${coinService.hints}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Card(
      color: Colors.grey.shade900,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(
            icon,
            color: Colors.grey.shade400,
            size: 28,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}