import 'package:fill_num/pages/coin_page.dart';
import 'package:fill_num/utils/coin_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CoinDisplay extends StatelessWidget {
  final bool showAddButton;
  final double iconSize;
  final double fontSize;

  const CoinDisplay({
    super.key,
    this.showAddButton = true,
    this.iconSize = 20,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CoinService>(
      builder: (context, coinService, child) {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CoinPage()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: Colors.yellow,
                  size: iconSize,
                ),
                const SizedBox(width: 6),
                Text(
                  '${coinService.coins}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
                if (showAddButton) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: iconSize * 0.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}