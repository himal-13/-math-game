import 'package:fill_num/components/getmore_hint_dialog.dart';
import 'package:fill_num/components/concept_explanation_dialog.dart';
import 'package:fill_num/constants/expert_levels.dart';
import 'package:fill_num/constants/hard_levels.dart';
import 'package:fill_num/utils/audio_manager.dart';
import 'package:fill_num/utils/hint_service.dart';
import 'package:flutter/material.dart';
import 'package:fraction/fraction.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class ExtremeGrid extends StatefulWidget {
  const ExtremeGrid({super.key});

  @override
  _ExtremeGridState createState() => _ExtremeGridState();
}

class _ExtremeGridState extends State<ExtremeGrid> {
  static const String _unlockedLevelsKey = 'unlocked_extreme_levels';
  static const int _hintCost = 3; // Reduced cost for hints

  // Initialize variables with default values to avoid LateInitializationError
  Fraction _currentValue = Fraction(0);
  Fraction _targetValue = Fraction(0);
  int _movesLeft = 0;
  List<Operation> _operations = [];
  List<bool> _isUsed = [];
  late Box _gameBox;
  bool _isGameWon = false;
  bool _isGameOver = false;
  int _currentLevelIndex = 0;
  int _unlockedLevelsCount = 1;
  bool _showLevelSelect = false;
  int _hintTileIndex = -1;
  List<Operation> _solution = [];
  String _gameOverReason = '';

  List<int> _usedTileIndices = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initHiveAndLoad();
  }

  Future<void> _initHiveAndLoad() async {
    try {
      if (!Hive.isBoxOpen('expert_mode_level')) {
        await Hive.openBox('expert_mode_level');
      }
      _gameBox = Hive.box('expert_mode_level');
      await _loadGameData();
    } catch (e, st) {
      debugPrint('Error opening expert_mode_level box: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize game data storage')),
        );
      }
    }
  }

  Future<void> _loadGameData() async {
    try {
      final unlockedLevels = _gameBox.get(_unlockedLevelsKey, defaultValue: 1);
      setState(() {
        _unlockedLevelsCount = unlockedLevels;
        if (_unlockedLevelsCount > extremeLevels.length) {
          _unlockedLevelsCount = extremeLevels.length;
        }
      });
      
      // Start with level 0 by default, then adjust if unlocked levels exist
      int startLevel = 0;
      if (_unlockedLevelsCount - 1 < extremeLevels.length && _unlockedLevelsCount > 0) {
        startLevel = _unlockedLevelsCount - 1;
      }
      
      _startGame(levelIndex: startLevel);
      setState(() {
        _isInitialized = true;
      });
    } catch (e, st) {
      debugPrint('Failed to load game data: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load game data')),
        );
      }
    }
  }

  void _saveProgress() {
    try {
      _gameBox.put(_unlockedLevelsKey, _unlockedLevelsCount);
    } catch (e, st) {
      debugPrint('Failed to save progress: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save progress')),
        );
      }
    }
  }

  void _startGame({int levelIndex = 0}) {
    if (levelIndex >= extremeLevels.length) {
      levelIndex = 0;
    }

    setState(() {
      _currentLevelIndex = levelIndex;
      _isGameOver = false;
      _isGameWon = false;
      _showLevelSelect = false;
      _hintTileIndex = -1;
      _gameOverReason = '';

      final level = extremeLevels[_currentLevelIndex];
      _currentValue = level.current.reduce();
      _targetValue = level.target.reduce();
      _movesLeft = level.moves;

      _operations = List<Operation>.from(level.operations);
      _operations.shuffle();
      _solution = List<Operation>.from(level.solution);

      _isUsed = List.filled(_operations.length, false);
      _usedTileIndices = [];
    });
  }

  // Color scheme matching hard_mode
  Color _getOperationColor(Operation op) {
    switch (op.type) {
      case '+':
      case '-':
        return const Color(0xFF1E88E5);
      case '*':
      case '/':
        return const Color(0xFF43A047);
      case '^2':
      case '^3':
        return const Color(0xFFFFB300);
      case '+%':
      case '-%':
        return const Color(0xFFF4511E);
      case '√':
      case '∛':
        return const Color(0xFF8E24AA);
      case '!': // Factorial
      case 'nextPrime':
      case 'prevPrime':
      case 'isPrime':
        return const Color(0xFF7C4DFF);
      case 'φ': // Euler's totient
      case 'σ': // Sum of divisors
      case 'τ': case 'd': case 'μ': case 's': case 'rad': // Number Theory
        return const Color(0xFF8E24AA);
      case 'sumD': case 'prodD': case 'rev': case 'dRoot': case 'len': // Digit-based
        return const Color(0xFFAD1457);
      case 'C': case 'P': case 'sum1toN': case 'prod1toN': // Combinatorics
        return const Color(0xFF283593);
      case 'tri': case 'pent': case 'hex': case 'centSq': // Figurate Numbers
        return const Color(0xFF00695C);
      default:
        return const Color.fromARGB(255, 104, 58, 183);
    }
  }

  void _applyOperation(int index) {
    if (_isGameOver || _isGameWon || _isUsed[index]) return;
    final operation = _operations[index];

    setState(() {
      try {
        switch (operation.type) {
          case '+':
            _currentValue += operation.value;
            break;
          case '-':
            _currentValue -= operation.value;
            break;
          case '*':
            _currentValue *= operation.value;
            break;
          case '/':
            if (operation.value != Fraction(0, 1)) {
              _currentValue /= operation.value;
            }
            break;
          case '^2':
            _currentValue = _currentValue * _currentValue;
            break;
          case '^3':
            _currentValue = _currentValue * _currentValue * _currentValue;
            break;
          case '^':
            _currentValue = _power(_currentValue, operation.value);
            break;
          case '√':
            _currentValue = _calculateSquareRoot(_currentValue);
            break;
          case '∛':
            _currentValue = _calculateCubeRoot(_currentValue);
            break;
          case '+%':
            final percentage = _currentValue * operation.value;
            _currentValue += percentage;
            break;
          case '-%':
            final percentage = _currentValue * operation.value;
            _currentValue -= percentage;
            break;
          case '!': // Factorial
            _currentValue = _factorial(_currentValue);
            break;
          case '%': // Modulus
            _currentValue = _modulus(_currentValue, operation.value);
            break;
          case 'log': // Log base 10
            _currentValue = _log10(_currentValue);
            break;
          case '1/x': // Reciprocal
            _currentValue = Fraction(1, 1) / _currentValue;
            break;
          case 'nextPrime':
            _currentValue = _nextPrime(_currentValue);
            break;

          case 'φ': // Euler's totient
            _currentValue = _eulerTotient(_currentValue);
            break;
          case 'σ': // Sum of divisors
            _currentValue = _sumOfDivisors(_currentValue);
            break;
          
          // New Number Theory Functions
          case 'τ': // Tau function - number of divisors
          case 'd': // Same as tau
            _currentValue = _tauFunction(_currentValue);
            break;
          case 'μ': // Möbius function
            _currentValue = _mobiusFunction(_currentValue);
            break;
          case 's': // Sum of proper divisors
            _currentValue = _sumProperDivisors(_currentValue);
            break;
          case 'rad': // Radical - product of distinct prime factors
            _currentValue = _radical(_currentValue);
            break;

          // New Digit-based Functions
          case 'sumD': // Sum of digits
            _currentValue = _sumDigits(_currentValue);
            break;
          case 'prodD': // Product of digits
            _currentValue = _productDigits(_currentValue);
            break;
          case 'rev': // Reverse digits
            _currentValue = _reverseDigits(_currentValue);
            break;
          case 'dRoot': // Digital root
            _currentValue = _digitalRoot(_currentValue);
            break;
          case 'len': // Count digits
            _currentValue = _countDigits(_currentValue);
            break;

          // New Combinatorics
          case 'C': // Combination nCk
            _currentValue = _combination(_currentValue, operation.value);
            break;
          case 'P': // Permutation nPk
            _currentValue = _permutation(_currentValue, operation.value);
            break;
          case 'sum1toN': // Sum from 1 to n
            _currentValue = _sum1ToN(_currentValue);
            break;
          case 'prod1toN': // Product from 1 to n (factorial)
            _currentValue = _factorial(_currentValue);
            break;

          // New Figurate Numbers
          case 'tri': // Triangular number
            _currentValue = _triangularNumber(_currentValue);
            break;
          case 'pent': // Pentagonal number
            _currentValue = _pentagonalNumber(_currentValue);
            break;
          case 'hex': // Hexagonal number
            _currentValue = _hexagonalNumber(_currentValue);
            break;
          case 'centSq': // Centered square number
            _currentValue = _centeredSquareNumber(_currentValue);
            break;
        }
        _movesLeft--;
        _currentValue = _currentValue.reduce();
        _isUsed[index] = true;
        _hintTileIndex = -1;
        _usedTileIndices.add(index);
        _checkGameState();
      } catch (e) {
        // Check if it's a fraction error vs other math errors
        final errorMessage = e.toString();
        if (errorMessage.contains('fraction') || errorMessage.contains('only defined for integers')) {
          _triggerGameOverDueToIrrational('Math Error: $errorMessage');
        } else {
          _triggerGameOverDueToIrrational('Invalid operation: $errorMessage');
        }
      }
    });
  }

  // Mathematical function implementations with fraction error handling
  Fraction _power(Fraction base, Fraction exponent) {
    final baseDouble = base.toDouble();
    final exponentDouble = exponent.toDouble();
    final result = math.pow(baseDouble, exponentDouble);
    return Fraction.fromDouble(result.toDouble());
  }

  Fraction _factorial(Fraction value) {
    // Only allow factorial for non-negative integers.
    if (value < Fraction(0, 1)) {
      throw Exception('Factorial of negative number');
    }

   final doubleVal = value.toDouble();
   final int intValue = doubleVal.round();
   // require exact integer (with small tolerance)
   if ((doubleVal - intValue).abs() > 0.000001) {
     throw Exception('Factorial is only defined for non-negative integers');
   }

   int result = 1;
   for (int i = 2; i <= intValue; i++) {
     result *= i;
   }
   return Fraction(result, 1);
   }

  Fraction _modulus(Fraction value, Fraction modulus) {
    if (modulus == Fraction(0, 1)) {
      throw Exception('Division by zero in modulus');
    }

    // Exact rational modulus: r = value - floor(value / modulus) * modulus
    // value = A / B, modulus = M / N => value/modulus = (A * N) / (B * M)
    final int A = value.numerator;
    final int B = value.denominator;
    final int M = modulus.numerator;
    final int N = modulus.denominator;

    final int num = A * N;
    final int den = B * M;

    // floor division for possibly negative numerator/denominator
    int q = _floorDivInt(num, den);

    // remainder = value - modulus * q = A/B - (M/N)*q
    final Fraction rem = Fraction(A * N - M * q * B, B * N);
    return rem.reduce();
  }

  int _floorDivInt(int a, int b) {
    if (b == 0) throw Exception('Division by zero');
    int q = a ~/ b; // truncating division
    // if signs differ and not exact, adjust to floor
    if ((a ^ b) < 0 && a % b != 0) q -= 1;
    return q;
  }

  Fraction _log10(Fraction value) {
    // Only allow powers of 10 for rational results
    final doubleValue = value.toDouble();
    if (doubleValue == 1) return Fraction(0, 1);
    if (doubleValue == 10) return Fraction(1, 1);
    if (doubleValue == 100) return Fraction(2, 1);
    if (doubleValue == 1000) return Fraction(3, 1);
    if (doubleValue == 0.1) return Fraction(-1, 1);
    if (doubleValue == 0.01) return Fraction(-2, 1);
    
    throw Exception('Logarithm would produce irrational number');
  }

  Fraction _nextPrime(Fraction value) {
    int n = value.toDouble().ceil();
    while (!_isPrime(Fraction(n, 1))) {
      n++;
    }
    return Fraction(n, 1);
  }


  bool _isPrime(Fraction value) {
    final n = value.toDouble().round();
    if (n < 2) return false;
    if (n == 2) return true;
    if (n % 2 == 0) return false;
    for (int i = 3; i * i <= n; i += 2) {
      if (n % i == 0) return false;
    }
    return true;
  }

  Fraction _eulerTotient(Fraction value) {
    // Check if the value is a fraction (not a whole number)
    if (value.denominator != 1) {
      throw Exception('Euler\'s totient φ is only defined for integers. ${value.toString()} is a fraction.');
    }
    
    final n = value.toDouble().round();
    if (n < 1) return Fraction(0, 1);
    int result = n;
    int temp = n;
    for (int i = 2; i * i <= temp; i++) {
      if (temp % i == 0) {
        while (temp % i == 0) {
          temp ~/= i;
        }
        result -= result ~/ i;
      }
    }
    if (temp > 1) result -= result ~/ temp;
    return Fraction(result, 1);
  }

  Fraction _sumOfDivisors(Fraction value) {
    if (value.denominator != 1) {
      throw Exception('Sum of divisors σ is only defined for integers. ${value.toString()} is a fraction.');
    }
    final n = value.toDouble().round();
    int sum = 0;
    for (int i = 1; i <= n; i++) {
      if (n % i == 0) sum += i;
    }
    return Fraction(sum, 1);
  }

  Fraction _tauFunction(Fraction value) {
    if (value.denominator != 1) {
      throw Exception('Tau function τ is only defined for integers. ${value.toString()} is a fraction.');
    }
    final n = value.toDouble().round();
    if (n < 1) return Fraction(0, 1);
    int count = 0;
    for (int i = 1; i <= n; i++) {
      if (n % i == 0) count++;
    }
    return Fraction(count, 1);
  }

  Fraction _mobiusFunction(Fraction value) {
    if (value.denominator != 1) {
      throw Exception('Möbius function μ is only defined for integers. ${value.toString()} is a fraction.');
    }
    final n = value.toDouble().round();
    if (n < 1) return Fraction(0, 1);
    if (n == 1) return Fraction(1, 1);
    
    int primeFactors = 0;
    int temp = n;
    for (int i = 2; i <= temp; i++) {
      if (temp % i == 0) {
        primeFactors++;
        if (temp % (i * i) == 0) return Fraction(0, 1); // has square factor
        while (temp % i == 0) {
          temp ~/= i;
        }
      }
    }
    return Fraction(primeFactors % 2 == 0 ? 1 : -1, 1);
  }

  Fraction _sumProperDivisors(Fraction value) {
    if (value.denominator != 1) {
      throw Exception('Sum of proper divisors is only defined for integers. ${value.toString()} is a fraction.');
    }
    final n = value.toDouble().round();
    if (n < 1) return Fraction(0, 1);
    int sum = 0;
    for (int i = 1; i < n; i++) {
      if (n % i == 0) sum += i;
    }
    return Fraction(sum, 1);
  }

  Fraction _radical(Fraction value) {
    if (value.denominator != 1) {
      throw Exception('Radical is only defined for integers. ${value.toString()} is a fraction.');
    }
    final n = value.toDouble().round();
    if (n < 1) return Fraction(1, 1);
    int product = 1;
    int temp = n;
    for (int i = 2; i <= temp; i++) {
      if (temp % i == 0) {
        product *= i;
        while (temp % i == 0) {
          temp ~/= i;
        }
      }
    }
    return Fraction(product, 1);
  }

  Fraction _sumDigits(Fraction value) {
    if (value.denominator != 1) {
      throw Exception('Sum of digits is only defined for integers. ${value.toString()} is a fraction.');
    }
    final n = value.toDouble().abs().round();
    int sum = 0;
    String digits = n.toString();
    for (int i = 0; i < digits.length; i++) {
      sum += int.parse(digits[i]);
    }
    return Fraction(sum, 1);
  }

  Fraction _productDigits(Fraction value) {
    if (value.denominator != 1) {
      throw Exception('Product of digits is only defined for integers. ${value.toString()} is a fraction.');
    }
    final n = value.toDouble().abs().round();
    int product = 1;
    String digits = n.toString();
    for (int i = 0; i < digits.length; i++) {
      product *= int.parse(digits[i]);
    }
    return Fraction(product, 1);
  }

  Fraction _reverseDigits(Fraction value) {
    if (value.denominator != 1) {
      throw Exception('Digit reversal is only defined for integers. ${value.toString()} is a fraction.');
    }
    final n = value.toDouble().abs().round();
    String reversed = n.toString().split('').reversed.join();
    return Fraction(int.parse(reversed), 1);
  }

  Fraction _digitalRoot(Fraction value) {
    if (value.denominator != 1) {
      throw Exception('Digital root is only defined for integers. ${value.toString()} is a fraction.');
    }
    final n = value.toDouble().abs().round();
    int result = n;
    while (result >= 10) {
      int sum = 0;
      String digits = result.toString();
      for (int i = 0; i < digits.length; i++) {
        sum += int.parse(digits[i]);
      }
      result = sum;
    }
    return Fraction(result, 1);
  }

  Fraction _countDigits(Fraction value) {
    if (value.denominator != 1) {
      throw Exception('Digit count is only defined for integers. ${value.toString()} is a fraction.');
    }
    final n = value.toDouble().abs().round();
    return Fraction(n.toString().length, 1);
  }

  Fraction _combination(Fraction n, Fraction k) {
    final nVal = n.toDouble().round();
    final kVal = k.toDouble().round();
    if (nVal < 0 || kVal < 0 || kVal > nVal) return Fraction(0, 1);
    if (kVal == 0 || kVal == nVal) return Fraction(1, 1);
    
    // Use iterative calculation to avoid large numbers
    int result = 1;
    for (int i = 1; i <= kVal; i++) {
      result = result * (nVal - i + 1) ~/ i;
    }
    return Fraction(result, 1);
  }

  Fraction _permutation(Fraction n, Fraction k) {
    final nVal = n.toDouble().round();
    final kVal = k.toDouble().round();
    if (nVal < 0 || kVal < 0 || kVal > nVal) return Fraction(0, 1);
    
    int result = 1;
    for (int i = 0; i < kVal; i++) {
      result *= (nVal - i);
    }
    return Fraction(result, 1);
  }

  Fraction _sum1ToN(Fraction value) {
    final n = value.toDouble().round();
    if (n < 1) return Fraction(0, 1);
    return Fraction(n * (n + 1) ~/ 2, 1);
  }

  Fraction _triangularNumber(Fraction value) {
    final n = value.toDouble().round();
    if (n < 1) return Fraction(0, 1);
    return Fraction(n * (n + 1) ~/ 2, 1);
  }

  Fraction _pentagonalNumber(Fraction value) {
    final n = value.toDouble().round();
    if (n < 1) return Fraction(0, 1);
    return Fraction(n * (3 * n - 1) ~/ 2, 1);
  }

  Fraction _hexagonalNumber(Fraction value) {
    final n = value.toDouble().round();
    if (n < 1) return Fraction(0, 1);
    return Fraction(n * (2 * n - 1), 1);
  }

  Fraction _centeredSquareNumber(Fraction value) {
    final n = value.toDouble().round();
    if (n < 1) return Fraction(1, 1);
    return Fraction(n * n + (n - 1) * (n - 1), 1);
  }

  Fraction _calculateSquareRoot(Fraction value) {
    final numerator = value.numerator.toDouble();
    final denominator = value.denominator.toDouble();
    
    final numeratorRoot = math.sqrt(numerator);
    final denominatorRoot = math.sqrt(denominator);
    
    final isNumeratorPerfectSquare = (numeratorRoot - numeratorRoot.roundToDouble()).abs() < 0.0001;
    final isDenominatorPerfectSquare = (denominatorRoot - denominatorRoot.roundToDouble()).abs() < 0.0001;
    
    if (isNumeratorPerfectSquare && isDenominatorPerfectSquare) {
      return Fraction.fromDouble(numeratorRoot / denominatorRoot).reduce();
    } else {
      _triggerGameOverDueToIrrational('Square root resulted in irrational number');
      return value;
    }
  }

  Fraction _calculateCubeRoot(Fraction value) {
    final numerator = value.numerator.toDouble();
    final denominator = value.denominator.toDouble();
    
    final numeratorRoot = _cubeRoot(numerator);
    final denominatorRoot = _cubeRoot(denominator);
    
    final isNumeratorPerfectCube = (numeratorRoot - numeratorRoot.roundToDouble()).abs() < 0.0001;
    final isDenominatorPerfectCube = (denominatorRoot - denominatorRoot.roundToDouble()).abs() < 0.0001;
    
    if (isNumeratorPerfectCube && isDenominatorPerfectCube) {
      return Fraction.fromDouble(numeratorRoot / denominatorRoot).reduce();
    } else {
      _triggerGameOverDueToIrrational('Cube root resulted in irrational number');
      return value;
    }
  }

  double _cubeRoot(double value) {
    if (value < 0) {
      return -math.pow(-value, 1/3) as double;
    }
    return math.pow(value, 1/3) as double;
  }

  void _triggerGameOverDueToIrrational(String reason) {
    setState(() {
      _isGameOver = true;
      _gameOverReason = reason;
      _saveProgress();
      AudioManager.playGameOver();
    });
  }

  void _checkGameState() {
    // Use tolerance for floating point comparison
    final currentDouble = _currentValue.toDouble();
    final targetDouble = _targetValue.toDouble();
    
    if ((currentDouble - targetDouble).abs() < 0.0001) {
      _isGameWon = true;
      AudioManager.playDing();
      if (_currentLevelIndex + 1 < extremeLevels.length) {
        if (_currentLevelIndex + 2 > _unlockedLevelsCount) {
          _unlockedLevelsCount = _currentLevelIndex + 2;
        }
        _saveProgress();
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _currentLevelIndex++;
            _startGame(levelIndex: _currentLevelIndex);
          });
        });
      } else {
        _isGameOver = true;
        _gameOverReason = 'You completed all extreme levels!';
      }
    } else if (_movesLeft <= 0) {
      _isGameOver = true;
      _gameOverReason = 'You ran out of moves';
      _saveProgress();
      AudioManager.playGameOver();
    }
  }

  void _getHint() async {
    if (_hintTileIndex != -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A hint is already showing.')),
      );
      return;
    }

    final hintService = Provider.of<HintService>(context, listen: false);
    
    // Check if user has enough hints
    if (hintService.hints >= _hintCost) {
      // Use hint
      await hintService.useHint();

      int movesMade = _usedTileIndices.length;
      bool needsReset = false;
      for (int i = 0; i < movesMade; i++) {
        if (i >= _solution.length) {
          needsReset = true;
          break;
        }
        final userOp = _operations[_usedTileIndices[i]];
        final solOp = _solution[i];
        if (userOp.type != solOp.type || userOp.value != solOp.value) {
          needsReset = true;
          break;
        }
      }

      if (needsReset) {
        _startGame(levelIndex: _currentLevelIndex);
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          _hintTileIndex = _findNextHintIndex(0);
        });
        return;
      }

      int nextHintStep = movesMade;
      int nextHintIndex = _findNextHintIndex(nextHintStep);

      setState(() {
        if (nextHintIndex != -1) {
          _hintTileIndex = nextHintIndex;
        }
      });
    } else {
       showNotEnoughHintsDialog(context);
    }
  }

  int _findNextHintIndex(int step) {
    if (step < _solution.length) {
      Operation nextSolutionOperation = _solution[step];
      for (int i = 0; i < _operations.length; i++) {
        if (!_isUsed[i] &&
            _operations[i].type == nextSolutionOperation.type &&
            _operations[i].value == nextSolutionOperation.value) {
          return i;
        }
      }
    }
    return -1;
  }

 String _getOperationString(Operation op) {
  switch (op.type) {
    case '*': return '×${_formatValue(op.value)}';
    case '/': return '÷${_formatValue(op.value)}';
    case '^2': return 'x²';
    case '^3': return 'x³';
    case '^': return 'x^${_formatValue(op.value)}';
    case '+%': return '+${(op.value.toDouble() * 100).toInt()}%';
    case '-%': return '-${(op.value.toDouble() * 100).toInt()}%';
    case '√': return '√';
    case '∛': return '∛';
    case '!': return 'x!';
    case '%': return 'mod ${_formatValue(op.value)}';
    case 'log': return 'log';
    case '1/x': return '1/x';
    case 'nextPrime': return 'next prime';
    case 'prevPrime': return 'prev prime';
    case 'isPrime': return 'is prime?';
    case 'φ': return 'φ(x)';
    case 'σ': return 'σ(x)';
    
    // Number Theory
    case 'τ': return 'τ(x)';
    case 'd': return 'd(x)';
    case 'μ': return 'μ(x)';
    case 's': return 's(x)';
    case 'rad': return 'rad(x)';
    
    // Digit-based
    case 'sumD': return 'sum digits';
    case 'prodD': return 'prod digits';
    case 'rev': return 'reverse';
    case 'dRoot': return 'digital root';
    case 'len': return 'digit count';
    
    // Combinatorics
    case 'C': return 'C(${_formatValue(op.value)})';
    case 'P': return 'P(${_formatValue(op.value)})';
    case 'sum1toN': return 'Σ(n)';
    case 'prod1toN': return 'Π(n)';
    
    // Figurate Numbers
    case 'tri': return 'tri(n)';
    case 'pent': return 'pent(n)';
    case 'hex': return 'hex(n)';
    case 'centSq': return 'centSq(n)';
    
    default: return '${op.type}${_formatValue(op.value)}';
  }
}

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF7C4DFF)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Loading Extreme Mode...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          _showLevelSelect ? 'Select Level' : 'Extreme Level ${_currentLevelIndex + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _showLevelSelect ? Icons.arrow_back_ios_new_rounded : Icons.list_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () {
            setState(() {
              _showLevelSelect = !_showLevelSelect;
            });
          },
        ),
        actions: [_buildHintDisplay()],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _showLevelSelect
                ? _buildLevelSelectionPage()
                : _buildGamePage(),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelectionPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Text(
            'Extreme Levels',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: extremeLevels.length,
            itemBuilder: (context, index) {
              final isUnlocked = index < _unlockedLevelsCount;
              final isCurrent = index == _currentLevelIndex;
              
              return GestureDetector(
                onTap: isUnlocked ? () => _startGame(levelIndex: index) : null,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isUnlocked
                        ? (isCurrent 
                            ? const LinearGradient(
                                colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.05)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ))
                        : LinearGradient(
                            colors: [
                              Colors.grey.withOpacity(0.3),
                              Colors.grey.withOpacity(0.1)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: isCurrent 
                        ? Border.all(color: Colors.white, width: 2)
                        : Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    boxShadow: [
                      if (isUnlocked)
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isUnlocked ? Colors.white : Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!isUnlocked)
                          const Icon(
                            Icons.lock,
                            color: Colors.grey,
                            size: 12,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGamePage() {
    final level = extremeLevels[_currentLevelIndex];
    return Column(
      children: [
        // Game info section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              // Moves left indicator
              _buildInfoContainer(
                title: 'Moves Left',
                value: _movesLeft.toString(),
                color: _movesLeft < 3 ? Colors.red : Colors.green,
              ),
              const SizedBox(height: 16),

              // Current and Target display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Current Value
                  _buildValueCard(
                    title: 'CURRENT',
                    value: _formatValue(_currentValue),
                    color: Colors.blue,
                    icon: Icons.play_arrow_rounded,
                  ),

                  // Target Value
                  _buildValueCard(
                    title: 'TARGET',
                    value: _formatValue(_targetValue),
                    color: Colors.green,
                    icon: Icons.flag_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Game grid or game over screen
        if (_isGameOver && !_isGameWon) ...[
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.15),
                      Colors.orange.withOpacity(0.1)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cancel_rounded,
                        color: Colors.red,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Game Over',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _gameOverReason,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: () => _startGame(levelIndex: _currentLevelIndex),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else if (_isGameWon) ...[
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.15),
                      Colors.teal.withOpacity(0.1)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Level Complete!',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Moving to next level...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          // Operation grid
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: level.cols,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.2,
              ),
              itemCount: _operations.length,
              itemBuilder: (context, index) {
                final operation = _operations[index];
                final isUsed = _isUsed[index];
                final isHint = index == _hintTileIndex;
                final operationColor = _getOperationColor(operation);

                return GestureDetector(
                  onTap: () => _applyOperation(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient: isHint
                          ? const LinearGradient(
                              colors: [Color(0xFF29B6F6), Color(0xFF03A9F4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : isUsed
                              ? LinearGradient(
                                  colors: [
                                    Colors.grey.withOpacity(0.3),
                                    Colors.grey.withOpacity(0.1)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    operationColor.withOpacity(0.9),
                                    operationColor.withOpacity(0.7)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (!isUsed && !isHint)
                          BoxShadow(
                            color: operationColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: isHint 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.1),
                        width: isHint ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getOperationString(operation),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _getOperationFontSize(operation.type),
                          fontWeight: FontWeight.w700,
                          decoration: isUsed ? TextDecoration.lineThrough : null,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _getHint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(
                    Icons.lightbulb_outline, color: Colors.yellow,
                    size: 20,
                  ),
                  label: Text(
                    'Hint($_hintCost)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _startGame(levelIndex: _currentLevelIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final level = extremeLevels[_currentLevelIndex];
                    if (level.description.isNotEmpty) {
                      showConceptExplanationDialog(context, level.description);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No concept available for this level')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.menu_book, size: 20),
                  label: const Text(
                    '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  double _getOperationFontSize(String operationType) {
    switch (operationType) {
      case 'nextPrime':
      case 'prevPrime':
      case 'isPrime':
        return 12;
      case 'φ':
      case 'σ':
      case 'τ':
      case 'μ':
      case 's':
      case 'rad':
        return 16;
      case 'sumD':
      case 'prodD':
      case 'rev':
      case 'dRoot':
      case 'len':
      case 'tri':
      case 'pent':
      case 'hex':
      case 'centSq':
        return 12;
      case 'C':
      case 'P':
      case 'sum1toN':
      case 'prod1toN':
        return 12;
      default:
        return 14;
    }
  }

  String _formatValue(Fraction value) {
    final doubleValue = value.toDouble();
    if (doubleValue == doubleValue.roundToDouble()) {
      return doubleValue.round().toString();
    }
    return value.toString();
  }

  Widget _buildValueCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.25), color.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContainer({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintDisplay() {
    return Consumer<HintService>(
      builder: (context, hintService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFC400)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lightbulb_outline_rounded, 
                color: Colors.white, 
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                hintService.hints.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}