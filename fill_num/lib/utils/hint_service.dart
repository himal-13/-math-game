import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HintService extends ChangeNotifier {
  static const String _hintKey = 'user_hints';
  int _hints = 0;
  SharedPreferences? _prefs;

  int get hints => _hints;

  HintService() {
    _loadHints();
  }

  Future<void> _loadHints() async {
    _prefs = await SharedPreferences.getInstance();
    _hints = _prefs?.getInt(_hintKey) ?? 1; // Start with 5 hints by default
    notifyListeners();
  }

  Future<bool> addHints(int amount) async {
    if (amount <= 0) return false;
    
    _hints += amount;
    await _saveHints();
    notifyListeners();
    return true;
  }

  Future<bool> useHint() async {
    if (_hints <= 0) return false;
    
    _hints -= 1;
    await _saveHints();
    notifyListeners();
    return true;
  }

  Future<void> resetHints([int defaultAmount = 5]) async {
    _hints = defaultAmount;
    await _saveHints();
    notifyListeners();
  }

  Future<void> _saveHints() async {
    await _prefs?.setInt(_hintKey, _hints);
  }

  // Check if user has enough hints
  bool hasEnoughHints(int amount) {
    return _hints >= amount;
  }
}