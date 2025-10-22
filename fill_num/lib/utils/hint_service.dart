import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class HintService extends ChangeNotifier {
  static const String _hintsBoxName = 'hints_countbox';
  static const String _hintsKey = 'hints';
  
  late Box<int> _hintsBox;
  bool _isInitialized = false;

  int get hints {
    if (!_isInitialized) {
      return 5; // Default value before initialization
    }
    return _hintsBox.get(_hintsKey, defaultValue: 5) ?? 5;
  }
  
  Future<void> init() async {
    try {
      _hintsBox = await Hive.openBox<int>(_hintsBoxName);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing HintService: $e');
      _isInitialized = false;
    }
  }
  
  Future<void> addHints(int amount) async {
    if (!_isInitialized) {
      await init();
    }
    final currentHints = hints;
    await _hintsBox.put(_hintsKey, currentHints + amount);
    notifyListeners();
  }
  
  Future<void> useHint() async {
    if (!_isInitialized) {
      await init();
    }
    if (hints > 0) {
      await _hintsBox.put(_hintsKey, hints - 1);
      notifyListeners();
    }
  }
  
  Future<void> resetHints() async {
    if (!_isInitialized) {
      await init();
    }
    await _hintsBox.put(_hintsKey, 5);
    notifyListeners();
  }
  
  Future<void> close() async {
    if (_isInitialized) {
      await _hintsBox.close();
      _isInitialized = false;
    }
  }
}