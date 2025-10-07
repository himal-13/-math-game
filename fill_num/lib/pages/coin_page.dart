import 'package:fill_num/utils/coin_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CoinPage extends StatefulWidget {
  const CoinPage({super.key});

  @override
  _CoinPageState createState() => _CoinPageState();
}

class _CoinPageState extends State<CoinPage> {
  final List<Map<String, dynamic>> _coinPackages = [
    {'coins': 100, 'price': '\$0.99', 'bonus': 0, 'color': Colors.blue},
    {'coins': 300, 'price': '\$2.99', 'bonus': 50, 'color': Colors.green},
    {'coins': 500, 'price': '\$4.99', 'bonus': 100, 'color': Colors.orange},
    {'coins': 1000, 'price': '\$8.99', 'bonus': 300, 'color': Colors.purple},
    {'coins': 2500, 'price': '\$19.99', 'bonus': 1000, 'color': Colors.red},
    {'coins': 5000, 'price': '\$34.99', 'bonus': 2500, 'color': Colors.amber},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Coin Store',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCurrentBalance(),
                const SizedBox(height: 20),
                _buildFreeCoinsSection(),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildCoinPackages(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBalance() {
    return Consumer<CoinService>(
      builder: (context, coinService, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Your Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.yellow,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${coinService.coins}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFreeCoinsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Free Coins',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFreeCoinButton(
                  title: 'Watch Ad',
                  coins: 25,
                  icon: Icons.play_arrow,
                  color: Colors.blue,
                  onTap: _watchAdForCoins,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFreeCoinButton(
                  title: 'Daily Bonus',
                  coins: 50,
                  icon: Icons.calendar_today,
                  color: Colors.orange,
                  onTap: _claimDailyBonus,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFreeCoinButton({
    required String title,
    required int coins,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, size: 14, color: Colors.yellow),
              const SizedBox(width: 2),
              Text(
                '+$coins',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoinPackages() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Coin Packages',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: _coinPackages.length,
            itemBuilder: (context, index) {
              final package = _coinPackages[index];
              return _buildCoinPackageCard(package);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCoinPackageCard(Map<String, dynamic> package) {
    final totalCoins = package['coins'] + package['bonus'];
    
    return GestureDetector(
      onTap: () => _purchaseCoins(package),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              package['color'] as Color,
              package['color'].withOpacity(0.7) as Color,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: (package['color'] as Color).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              right: 10,
              child: package['bonus'] > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+${package['bonus']} FREE',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.yellow, size: 24),
                    const SizedBox(width: 4),
                    Text(
                      totalCoins.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  package['price'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (package['bonus'] > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${package['coins']} + ${package['bonus']} bonus',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _watchAdForCoins() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
          ),
        ),
      ),
    );

    // Simulate ad loading and reward
    await Future.delayed(const Duration(seconds: 2));

    Navigator.pop(context); // Remove loading dialog

    final coinService = Provider.of<CoinService>(context, listen: false);
    await coinService.addCoins(25);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('+25 coins added! Thanks for watching!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _claimDailyBonus() async {
    final coinService = Provider.of<CoinService>(context, listen: false);
    await coinService.addCoins(50);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('+50 coins added! Daily bonus claimed!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _purchaseCoins(Map<String, dynamic> package) {
    // In a real app, this would integrate with your payment system
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Coins'),
        content: Text(
          'Purchase ${package['coins']} coins for ${package['price']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Purchase successful! ${package['coins']} coins added.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }
}