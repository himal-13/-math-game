import 'package:fill_num/utils/hint_service.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinPage extends StatefulWidget {
  const CoinPage({super.key});

  @override
  _CoinPageState createState() => _CoinPageState();
}

class _CoinPageState extends State<CoinPage> {
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _isAdLoaded = false;
  int _dailyClaimsLeft = 2;
  DateTime? _lastClaimDate;
  int _claimsToday = 0;

  // Test Ad Unit ID - Replace with your actual Ad Unit ID for production
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
    _checkDailyClaimsStatus();
  }

  void _checkDailyClaimsStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimTimestamp = prefs.getInt('lastDailyClaimDate');
    final savedClaimsToday = prefs.getInt('claimsToday') ?? 0;
    
    if (lastClaimTimestamp != null) {
      final lastClaimDate = DateTime.fromMillisecondsSinceEpoch(lastClaimTimestamp);
      final now = DateTime.now();
      
      // Check if the last claim was today
      final isSameDay = lastClaimDate.year == now.year &&
          lastClaimDate.month == now.month &&
          lastClaimDate.day == now.day;
      
      if (isSameDay) {
        setState(() {
          _lastClaimDate = lastClaimDate;
          _claimsToday = savedClaimsToday;
          _dailyClaimsLeft = (2 - savedClaimsToday).clamp(0, 2);
        });
      } else {
        // New day, reset claims
        setState(() {
          _lastClaimDate = null;
          _claimsToday = 0;
          _dailyClaimsLeft = 2;
        });
        await prefs.remove('claimsToday');
        await prefs.remove('lastDailyClaimDate');
      }
    } else {
      setState(() {
        _claimsToday = 0;
        _dailyClaimsLeft = 2;
      });
    }
  }

  void _loadRewardedAd() {
    setState(() {
      _isAdLoading = true;
      _isAdLoaded = false;
    });

    RewardedAd.load(
      adUnitId: _testRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          setState(() {
            _rewardedAd = ad;
            _isAdLoading = false;
            _isAdLoaded = true;
          });

          // Set up full screen content callbacks
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (RewardedAd ad) =>
                debugPrint('$ad onAdShowedFullScreenContent.'),
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
              _loadRewardedAd(); // Load a new ad after this one is dismissed
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              ad.dispose();
              _loadRewardedAd(); // Load a new ad after failure
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          setState(() {
            _isAdLoading = false;
            _isAdLoaded = false;
          });
          // Optionally retry loading after a delay
          Future.delayed(const Duration(seconds: 5), _loadRewardedAd);
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null && _isAdLoaded) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          // Add hints when user completes the ad
          final hintService = Provider.of<HintService>(context, listen: false);
          hintService.addHints(2);
          
          // Update daily claims
          _updateDailyClaims();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('+2 hints added! Thanks for watching!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    } else {
      // If ad is not ready, show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad is not ready yet. Please try again in a moment.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Try to load the ad again
      _loadRewardedAd();
    }
  }

  void _watchAdForHints() {
    if (_dailyClaimsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Daily limit reached! Come back tomorrow.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isAdLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad is loading. Please wait...'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isAdLoaded) {
      _showRewardedAd();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad not available. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadRewardedAd();
    }
  }

  void _updateDailyClaims() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    setState(() {
      _claimsToday++;
      _dailyClaimsLeft = (2 - _claimsToday).clamp(0, 2);
    });

    await prefs.setInt('claimsToday', _claimsToday);
    await prefs.setInt('lastDailyClaimDate', now.millisecondsSinceEpoch);
  }

  String _getNextAvailableTime() {
    if (_lastClaimDate == null) return 'Now';
    
    final now = DateTime.now();
    final tomorrow = DateTime(_lastClaimDate!.year, _lastClaimDate!.month, _lastClaimDate!.day + 1);
    final difference = tomorrow.difference(now);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes.remainder(60)}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Hint Store',
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
                _buildFreeHintsSection(),
                const SizedBox(height: 20),
                _buildDailyLimitIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBalance() {
    return Consumer<HintService>(
      builder: (context, hintService, child) {
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
                'Your Hints',
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
                    Icons.lightbulb_outline,
                    color: Colors.yellow,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${hintService.hints}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Ad status indicator
              const SizedBox(height: 8),
              _buildAdStatusIndicator(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdStatusIndicator() {
    Widget statusWidget;
    
    if (_isAdLoading) {
      statusWidget = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Loading ad...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      );
    } else if (_isAdLoaded) {
      statusWidget = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 12),
          const SizedBox(width: 8),
          const Text(
            'Ad ready to watch',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      );
    } else {
      statusWidget = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 12),
          const SizedBox(width: 8),
          const Text(
            'Ad not available',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      );
    }
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: statusWidget,
    );
  }

  Widget _buildFreeHintsSection() {
    final canClaimMore = _dailyClaimsLeft > 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: canClaimMore ? Colors.green : Colors.grey),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, color: canClaimMore ? Colors.green : Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(
                'Free Hints',
                style: TextStyle(
                  color: canClaimMore ? Colors.white : Colors.white54,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!canClaimMore)
                Text(
                  'Limit reached',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFreeHintButton(
            title: canClaimMore ? 'Watch Ad for 2 Hints' : 'Daily Limit Reached',
            hints: 2,
            icon: canClaimMore ? Icons.play_arrow : Icons.lock,
            color: canClaimMore && _isAdLoaded ? Colors.blue : Colors.grey,
            onTap: canClaimMore ? _watchAdForHints : null,
            subtitle: canClaimMore ? '$_dailyClaimsLeft left today' : 'Come back tomorrow',
          ),
        ],
      ),
    );
  }

  Widget _buildFreeHintButton({
    required String title,
    required int hints,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    String? subtitle,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold,
              color: onTap != null ? Colors.white : Colors.white54,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lightbulb_outline, size: 16, color: Colors.yellow),
              const SizedBox(width: 4),
              Text(
                '+$hints',
                style: TextStyle(
                  fontSize: 14,
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

  Widget _buildDailyLimitIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Daily claims:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              Text(
                '$_dailyClaimsLeft/2 remaining',
                style: TextStyle(
                  color: _dailyClaimsLeft > 0 ? Colors.green : Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              if (_dailyClaimsLeft <= 0)
                Text(
                  'Resets in ${_getNextAvailableTime()}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}