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

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // App Title
                      Text(
                        'Math OP Puzzle',
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

                      // Section: Basic Operations
                      _buildSectionHeader('Basic Operations'),
                      const SizedBox(height: 16),
                      
                      // Basic Operations Grid
                      _buildVerticalModeGrid(
                        children: [
                          _buildModeCard(
                            title: 'Easy',
                            subtitle: 'Basic Operations (+, -, ×, ÷)',
                            color: Colors.green.shade400,
                            icon: Icons.play_arrow,
                            onTap: _navigateToEasyMode,
                          ),
                          _buildModeCard(
                            title: 'Medium',
                            subtitle: 'Complex Equations & Patterns',
                            color: Colors.blue.shade400,
                            icon: Icons.gamepad,
                            onTap: _navigateToMediumMode,
                          ),
                          _buildModeCard(
                            title: 'Hard',
                            subtitle: 'Advanced Math %, √, ²',
                            color: Colors.orange.shade400,
                            icon: Icons.psychology,
                            onTap: _navigateToHardMode,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Section: Advanced Operations
                      _buildSectionHeader('Advanced Operations'),
                      const SizedBox(height: 16),
                      
                      // Advanced Operations Grid
                      _buildVerticalModeGrid(
                        children: [
                          _buildModeCard(
                            title: 'Expert Equations',
                            subtitle: 'Complex Equations & Functions',
                            color: Colors.purple.shade400,
                            icon: Icons.functions,
                            onTap: _navigateToMediumMode,
                          ),
                          _buildModeCard(
                            title: 'Calculus',
                            subtitle: 'Expert Level Calculus & Logic',
                            color: Colors.red.shade400,
                            icon: Icons.calculate,
                            onTap: _navigateToHardMode,
                          ),
                          _buildModeCard(
                            title: 'Fractions',
                            subtitle: 'Fraction Operations & Algebra',
                            color: Colors.teal.shade400,
                            icon: Icons.percent,
                            onTap: () {
                              // Navigate to Fraction mode
                            },
                          ),
                        ],
                      ),

                    
                   
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade300,
          ),
        ),
        const Spacer(),
        Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade500,
          size: 14,
        ),
      ],
    );
  }

  Widget _buildVerticalModeGrid({required List<Widget> children}) {
    return Column(
      children: children
          .asMap()
          .entries
          .map((entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == children.length - 1 ? 0 : 12,
                ),
                child: entry.value,
              ))
          .toList(),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
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
            child: Row(
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
                const SizedBox(width: 16),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Arrow indicator
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  
}