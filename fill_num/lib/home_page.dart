// pages/home_page.dart

import 'package:fill_num/pages/easy_mode.dart';
import 'package:fill_num/pages/medium_mode.dart';
import 'package:fill_num/utils/coin_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToEasyMode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EasyMode()),
    );
  }

  void _navigateToHardMode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MediumMode()),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => _buildSettingsDialog(),
    );
  }

  void _rateApp() {
    // TODO: Implement app rating logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirecting to app store...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSettingsDialog() {
    return AlertDialog(
      backgroundColor: const Color(0xFF2D1B1B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Settings',
        style: TextStyle(
          color: Colors.orangeAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSettingOption(
            icon: Icons.volume_up,
            title: 'Sound Effects',
            onChanged: (value) {},
          ),
          _buildSettingOption(
            icon: Icons.music_note,
            title: 'Background Music',
            onChanged: (value) {},
          ),
          _buildSettingOption(
            icon: Icons.vibration,
            title: 'Haptic Feedback',
            onChanged: (value) {},
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'CLOSE',
            style: TextStyle(color: Colors.orangeAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.orangeAccent),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: Switch(
        value: true,
        onChanged: onChanged,
        activeColor: Colors.orangeAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0000),
              Color(0xFF2D1B1B),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header with coins and settings
                _buildCoinDisplay(),
                
                const SizedBox(height: 40),
                
                // Game Title
                ScaleTransition(
                  scale: _animation,
                  child: Column(
                    children: [
                      const Text(
                        'FILL NUM',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Math Puzzle Game',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.orangeAccent.withOpacity(0.8),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Game Mode Buttons
                FadeTransition(
                  opacity: _animation,
                  child: Column(
                    children: [
                      _buildGameModeButton(
                        title: 'EASY MODE',
                        subtitle: 'Perfect for beginners',
                        color: const Color(0xFF7E57C2),
                        onTap: _navigateToEasyMode,
                        icon: Icons.play_arrow_rounded,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildGameModeButton(
                        title: 'HARD MODE',
                        subtitle: 'Challenge yourself',
                        color: const Color(0xFFB71C1C),
                        onTap: _navigateToHardMode,
                        icon: Icons.sports_esports_rounded,
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Bottom Buttons
                FadeTransition(
                  opacity: _animation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomButton(
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: _showSettings,
                      ),
                      _buildBottomButton(
                        icon: Icons.star,
                        label: 'Rate Us',
                        onTap: _rateApp,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildCoinDisplay() {
    return Consumer<CoinService>(
      builder: (context, coinService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on,
                color: Colors.yellow,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '${coinService.coins}',
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

  Widget _buildGameModeButton({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.8),
              color.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: 10,
              top: 10,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  icon,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
            ),
            child: Icon(
              icon,
              color: Colors.orangeAccent,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.orangeAccent.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}