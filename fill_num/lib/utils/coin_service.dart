import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinService extends ChangeNotifier {
  static const String _coinKey = 'user_coins';
  int _coins = 0;
  SharedPreferences? _prefs;

  int get coins => _coins;

  CoinService() {
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    _prefs = await SharedPreferences.getInstance();
    _coins = _prefs?.getInt(_coinKey) ?? 100; // Start with 100 coins by default
    notifyListeners();
  }

  Future<bool> addCoins(int amount) async {
    if (amount <= 0) return false;
    
    _coins += amount;
    await _saveCoins();
    notifyListeners();
    return true;
  }

  Future<bool> spendCoins(int amount) async {
    if (amount <= 0 || _coins < amount) return false;
    
    _coins -= amount;
    await _saveCoins();
    notifyListeners();
    return true;
  }

  Future<void> resetCoins([int defaultAmount = 100]) async {
    _coins = defaultAmount;
    await _saveCoins();
    notifyListeners();
  }

  Future<void> _saveCoins() async {
    await _prefs?.setInt(_coinKey, _coins);
  }

  // Check if user has enough coins
  bool hasEnoughCoins(int amount) {
    return _coins >= amount;
  }
}