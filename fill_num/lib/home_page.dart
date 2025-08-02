import 'package:flutter/material.dart';

class MathGameHomepage extends StatelessWidget {
  const MathGameHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF222222),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The main title "MATH GAME"
              const Text(
                'MATH GAME',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48.0),

              // The four main action buttons/cards
              _buildButtonCard(
                context,
                text: 'FILL OPERATOR',
                rightContent: Row(
                  children: [
                    const Text(
                      '3',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8.0),
                    // The square box operator placeholder
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    const Text(
                      '58',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              _buildButtonCard(
                context,
                text: 'FILL NUMBER',
                rightContent: Row(
                  children: const [
                    Text(
                      '+',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 16.0),
                    Text(
                      '÷',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 16.0),
                    Text(
                      '9',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              _buildButtonCard(
                context,
                text: 'QUICK PLAY',
                rightContent: const Icon(
                  Icons.play_circle_fill,
                  size: 40.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16.0),

              _buildButtonCard(
                context,
                text: 'BASIC MATH',
                rightContent: Row(
                  children: const [
                    Icon(Icons.add, size: 28),
                    SizedBox(width: 16),
                    Icon(Icons.remove, size: 28),
                    SizedBox(width: 16),
                    Icon(Icons.close, size: 28),
                    SizedBox(width: 16),
                    Icon(Icons.looks_3, size: 28), // The divide icon is often represented differently, using `looks_3` as a placeholder for a divide-like icon, but a custom `Text` widget could also be used.
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // A helper function to build the common card widget for reusability
  Widget _buildButtonCard(BuildContext context, {required String text, required Widget rightContent}) {
    return GestureDetector(
      onTap: () {
        // Handle tap
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$text tapped!')),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            rightContent,
          ],
        ),
      ),
    );
  }
}
