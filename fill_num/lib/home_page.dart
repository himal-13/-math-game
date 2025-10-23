// pages/home_page.dart

import 'package:fill_num/components/hint_display.dart';
import 'package:fill_num/pages/easy_mode.dart';
import 'package:fill_num/pages/expert_mode.dart';
import 'package:fill_num/pages/medium_mode.dart';
import 'package:fill_num/pages/hard_mode.dart';
import 'package:flutter/material.dart';

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
    showDialog(context: context, builder: (context) => _buildSettingsDialog());
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
            _buildSettingOption(icon: Icons.volume_up, title: 'Sound Effects'),
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

  Widget _buildSettingOption({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange.shade400, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _showSettings,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: Colors.grey.shade400,
                        size: 22,
                      ),
                    ),
                  ),
                  const HintDisplay(),
                ],
              ),

              const SizedBox(height: 20),

              // Main Content - Compact Grid
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Title
                    Text(
                      'Math Puzzle',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade400,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your challenge',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Compact Mode Grid - 2x2 layout
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        childAspectRatio: 0.9,
                        children: [
                          _buildCompactModeCard(
                            title: 'Easy',
                            subtitle: 'Basic Operations\n(+, -, ×, ÷)',
                            color: Colors.green.shade400,
                            icon: Icons.play_arrow,
                            onTap: _navigateToEasyMode,
                          ),
                          _buildCompactModeCard(
                            title: 'Medium',
                            subtitle: 'Complex Equations\n& Patterns',
                            color: Colors.blue.shade400,
                            icon: Icons.gamepad,
                            onTap: _navigateToMediumMode,
                          ),
                          _buildCompactModeCard(
                            title: 'Hard',
                            subtitle: 'Advanced Math\n%, √, ²',
                            color: Colors.orange.shade400,
                            icon: Icons.psychology,
                            onTap: _navigateToHardMode,
                          ),
                          _buildCompactModeCard(
                            title: 'Expert',
                            subtitle: 'More Advanced\n%, !, ∑',
                            color: Colors.purple.shade300,
                            icon: Icons.whatshot,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ExtremeGrid()),
                              );
                            },
                            isExpert: true,
                          ),
                        ],
                      ),
                    ),

                    // Bottom Section with Additional Info
                    // Container(
                    //   margin: const EdgeInsets.only(top: 20, bottom: 10),
                    //   padding: const EdgeInsets.all(16),
                    //   decoration: BoxDecoration(
                    //     color: Colors.grey.shade900.withOpacity(0.3),
                    //     borderRadius: BorderRadius.circular(16),
                    //   ),
                    //   child: Column(
                    //     children: [
                    //       Row(
                    //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //         children: [
                    //           _buildInfoItem(
                    //             icon: Icons.grid_view,
                    //             text: '4 Grid Sizes',
                    //           ),
                    //           _buildInfoItem(
                    //             icon: Icons.psychology,
                    //             text: 'Progressive Difficulty',
                    //           ),
                    //           _buildInfoItem(
                    //             icon: Icons.timer,
                    //             text: 'Time Challenges',
                    //           ),
                    //         ],
                    //       ),
                    //       const SizedBox(height: 12),
                    //       Text(
                    //         'Complete puzzles to earn hints and unlock achievements!',
                    //           textAlign: TextAlign.center,
                    //         style: TextStyle(
                    //           fontSize: 12,
                    //           color: Colors.grey.shade500,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactModeCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    bool isExpert = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.15),
                Colors.grey.shade900.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with background
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.4), width: 1.5),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (isExpert) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                
                // Subtitle
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Difficulty indicator
                const SizedBox(height: 8),
                Container(
                  height: 3,
                  width: 30,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildInfoItem({required IconData icon, required String text}) {
  //   return Column(
  //     children: [
  //       Icon(icon, color: Colors.orange.shade400, size: 20),
  //       const SizedBox(height: 4),
  //       Text(
  //         text,
  //         style: TextStyle(
  //           fontSize: 10,
  //           color: Colors.grey.shade400,
  //         ),
  //         textAlign: TextAlign.center,
  //       ),
  //     ],
  //   );
  // }
}