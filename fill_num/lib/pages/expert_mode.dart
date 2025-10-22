import 'package:fill_num/components/getmorecoin_dialog.dart';
import 'package:fill_num/components/concept_explanation_dialog.dart';
import 'package:fill_num/constants/expert_levels.dart';
import 'package:fill_num/constants/hard_levels.dart';
import 'package:fill_num/utils/audio_manager.dart';
import 'package:fill_num/utils/coin_service.dart';
import 'package:flutter/material.dart';
import 'package:fraction/fraction.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class ExtremeGrid extends StatefulWidget {
  const ExtremeGrid({super.key});

  @override
  _ExtremeGridState createState() => _ExtremeGridState();
}

class _ExtremeGridState extends State<ExtremeGrid> {
  static const String _unlockedLevelsKey = 'unlocked_extreme_levels';
  static const int _hintCost = 30;
  // static const String _autoShowConceptKey = 'auto_show_concept';

  // When true, show concept dialog automatically on level start/restart.
  // bool _autoShowConcept = true;

  late Fraction _currentValue;
  late Fraction _targetValue;
  late int _movesLeft;
  late List<Operation> _operations;
  late List<bool> _isUsed;
  late SharedPreferences _prefs;
  bool _isGameWon = false;
  bool _isGameOver = false;
  int _currentLevelIndex = 0;
  int _unlockedLevelsCount = 1;
  bool _showLevelSelect = false;
  int _hintTileIndex = -1;
  late List<Operation> _solution;
  String _gameOverReason = '';

  List<int> _usedTileIndices = [];

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _unlockedLevelsCount = _prefs.getInt(_unlockedLevelsKey) ?? 1;
      // _autoShowConcept = _prefs.getBool(_autoShowConceptKey) ?? true;
      if (_unlockedLevelsCount > extremeLevels.length) {
        _unlockedLevelsCount = extremeLevels.length;
      }
    });
    if (_unlockedLevelsCount - 1 < extremeLevels.length) {
      _startGame(levelIndex: _unlockedLevelsCount - 1);
    } else {
      _startGame(levelIndex: 0);
    }
  }

  void _saveProgress() {
    _prefs.setInt(_unlockedLevelsKey, _unlockedLevelsCount);
  }

  // void _saveAutoShowPreference() {
  //   _prefs.setBool(_autoShowConceptKey, _autoShowConcept);
  // }

  // void _showConceptExplanation() {
  //   if (!_autoShowConcept) return;
  //   final level = extremeLevels[_currentLevelIndex];
  //   if (level.description.isNotEmpty) {
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       showConceptExplanationDialog(context, level.description);
  //     });
  //   }
  // }

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
    // do not auto-show concept on start
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
          case 'prevPrime':
            _currentValue = _previousPrime(_currentValue);
            break;
          case 'isPrime':
            _currentValue = _isPrime(_currentValue) ? Fraction(1, 1) : Fraction(0, 1);
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
        _triggerGameOverDueToIrrational('Invalid operation: ${e.toString()}');
      }
    });
  }

  // Mathematical function implementations
  Fraction _power(Fraction base, Fraction exponent) {
    final baseDouble = base.toDouble();
    final exponentDouble = exponent.toDouble();
    final result = math.pow(baseDouble, exponentDouble);
    return Fraction.fromDouble(result.toDouble());
  }

  Fraction _factorial(Fraction value) {
    if (value < Fraction(0, 1)) {
      throw Exception('Factorial of negative number');
    }
    
    final intValue = value.toDouble().round();
    if ((value.toDouble() - intValue).abs() > 0.0001) {
      // Use gamma function approximation for non-integers
      return Fraction.fromDouble(_gamma(value.toDouble() + 1));
    }
    
    int result = 1;
    for (int i = 2; i <= intValue; i++) {
      result *= i;
    }
    return Fraction(result, 1);
  }

  double _gamma(double x) {
    // Simple gamma function approximation
    if (x <= 0) return double.infinity;
    if (x == 1) return 1;
    if (x < 1) return _gamma(x + 1) / x;
    return math.sqrt(2 * math.pi / x) * math.pow(x / math.e, x);
  }

  Fraction _modulus(Fraction value, Fraction modulus) {
    if (modulus == Fraction(0, 1)) {
      throw Exception('Division by zero in modulus');
    }
    final valueDouble = value.toDouble();
    final modulusDouble = modulus.toDouble();
    final result = valueDouble % modulusDouble;
    return Fraction.fromDouble(result);
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

  Fraction _previousPrime(Fraction value) {
    int n = value.toDouble().floor();
    if (n < 2) return Fraction(2, 1);
    while (!_isPrime(Fraction(n, 1))) {
      n--;
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
    final n = value.toDouble().round();
    if (n < 1) return Fraction(0, 1);
    int result = n;
    int temp = n;
    for (int i = 2; i * i <= temp; i++) {
      if (temp % i == 0) {
        while (temp % i == 0) temp ~/= i;
        result -= result ~/ i;
      }
    }
    if (temp > 1) result -= result ~/ temp;
    return Fraction(result, 1);
  }

  Fraction _sumOfDivisors(Fraction value) {
    final n = value.toDouble().round();
    int sum = 0;
    for (int i = 1; i <= n; i++) {
      if (n % i == 0) sum += i;
    }
    return Fraction(sum, 1);
  }

  // New Number Theory Functions
  Fraction _tauFunction(Fraction value) {
    final n = value.toDouble().round();
    if (n < 1) return Fraction(0, 1);
    int count = 0;
    for (int i = 1; i <= n; i++) {
      if (n % i == 0) count++;
    }
    return Fraction(count, 1);
  }

  Fraction _mobiusFunction(Fraction value) {
    final n = value.toDouble().round();
    if (n < 1) return Fraction(0, 1);
    if (n == 1) return Fraction(1, 1);
    
    int primeFactors = 0;
    int temp = n;
    for (int i = 2; i <= temp; i++) {
      if (temp % i == 0) {
        primeFactors++;
        if (temp % (i * i) == 0) return Fraction(0, 1); // has square factor
        while (temp % i == 0) temp ~/= i;
      }
    }
    return Fraction(primeFactors % 2 == 0 ? 1 : -1, 1);
  }

  Fraction _sumProperDivisors(Fraction value) {
    final n = value.toDouble().round();
    if (n < 1) return Fraction(0, 1);
    int sum = 0;
    for (int i = 1; i < n; i++) {
      if (n % i == 0) sum += i;
    }
    return Fraction(sum, 1);
  }

  Fraction _radical(Fraction value) {
    final n = value.toDouble().round();
    if (n < 1) return Fraction(1, 1);
    int product = 1;
    int temp = n;
    for (int i = 2; i <= temp; i++) {
      if (temp % i == 0) {
        product *= i;
        while (temp % i == 0) temp ~/= i;
      }
    }
    return Fraction(product, 1);
  }

  // New Digit-based Functions
  Fraction _sumDigits(Fraction value) {
    final n = value.toDouble().abs().round();
    int sum = 0;
    String digits = n.toString();
    for (int i = 0; i < digits.length; i++) {
      sum += int.parse(digits[i]);
    }
    return Fraction(sum, 1);
  }

  Fraction _productDigits(Fraction value) {
    final n = value.toDouble().abs().round();
    int product = 1;
    String digits = n.toString();
    for (int i = 0; i < digits.length; i++) {
      product *= int.parse(digits[i]);
    }
    return Fraction(product, 1);
  }

  Fraction _reverseDigits(Fraction value) {
    final n = value.toDouble().abs().round();
    String reversed = n.toString().split('').reversed.join();
    return Fraction(int.parse(reversed), 1);
  }

  Fraction _digitalRoot(Fraction value) {
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
    final n = value.toDouble().abs().round();
    return Fraction(n.toString().length, 1);
  }

  // New Combinatorics
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

  // New Figurate Numbers
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

  // Existing methods from hardcore mode
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

    final coinService = Provider.of<CoinService>(context, listen: false);
    final hasEnoughCoins = await coinService.spendCoins(_hintCost);
    if (!hasEnoughCoins) {
      showNotEnoughCoinsDialog(context);
      return;
    }

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
    case '∑': return 'Σ(n)';
    case '∏': return 'Π(n)';
    
    // Figurate Numbers
    case 'tri': return 'tri(n)';
    case 'pent': return 'pent(n)';
    case 'hex': return 'hex(n)';
    case 'centSq': return 'centSq(n)';
    
    default: return '${op.type}${_formatValue(op.value)}';
  }
}
 Color _getOperationColor(String type) {
    switch (type) {
      case '%': // modulus
      case 'mod':
        return const Color(0xFFFFB300); // saturated amber
      case '√':
      case '∛': // roots
        return const Color(0xFF00BFA5); // saturated teal
      case '/':
      case '1/x':
        return const Color(0xFF2962FF); // saturated indigo
      case '*':
      case '^':
      case '^2':
      case '^3':
        return const Color(0xFF2E7D32); // saturated green
      case '+':
      case '-':
      case '+%':
      case '-%':
        return const Color(0xFF00ACC1); // saturated cyan
      case '!': // factorial
        return const Color(0xFF7C4DFF); // saturated purple
      case 'log':
        return const Color(0xFF1976D2); // saturated blue
      case 'nextPrime':
      case 'prevPrime':
      case 'isPrime':
      case 'φ':
      case 'σ':
        return const Color(0xFFEF6C00); // saturated deep orange
      
      // Number Theory Functions
      case 'τ': case 'd': case 'μ': case 's': case 'rad':
        return const Color(0xFF8E24AA); // Deep purple
      
      // Digit-based Functions
      case 'sumD': case 'prodD': case 'rev': case 'dRoot': case 'len':
        return const Color(0xFFAD1457); // Pink
      
      // Combinatorics
      case 'C': case 'P': case 'sum1toN': case 'prod1toN':
        return const Color(0xFF283593); // Indigo
      
      // Figurate Numbers
      case 'tri': case 'pent': case 'hex': case 'centSq':
        return const Color(0xFF00695C); // Teal
      
      default:
        return const Color(0xFF00695C); // fallback teal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // darker navy background
      appBar: AppBar(
        title: Text(
          _showLevelSelect ? 'Select Extreme Level' : 'Extreme Level ${_currentLevelIndex + 1}',
          style: const TextStyle(
            color: Color(0xFF00BFA5), // teal accent for title
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            _showLevelSelect ? Icons.arrow_back : Icons.list,
            color: const Color(0xFF00BFA5),
          ),
          onPressed: () {
            setState(() {
              _showLevelSelect = !_showLevelSelect;
            });
          },
        ),
        actions: [_buildCoinDisplay()],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF071023), Color(0xFF091827)], // subtle navy gradient
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _showLevelSelect ? _buildLevelSelectionPage() : _buildGamePage(),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelectionPage() {
    return Column(
      children: [
        const Text(
          'Extreme Mode',
          style: TextStyle(
            color: Color(0xFF2962FF), // saturated indigo
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Advanced mathematical operations',
          style: TextStyle(
            color: Color(0xFF00BFA5), // teal accent
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: extremeLevels.length,
            itemBuilder: (context, index) {
              final isUnlocked = index < _unlockedLevelsCount;
              return ElevatedButton(
                onPressed: isUnlocked ? () => _startGame(levelIndex: index) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUnlocked
                      ? const Color(0xFF2962FF) // saturated indigo for unlocked
                      : const Color(0xFF37474F), // dark slate for locked
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF09101A), // deep desaturated card background
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              
              _buildInfoContainer(
                title: 'Moves Left',
                value: _movesLeft.toString(),
                color: _movesLeft < 3 ? const Color(0xFFFFB300) : const Color(0xFF00BFA5),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildValueCard(
                    title: 'CURRENT',
                    value: _formatValue(_currentValue),
                    color: const Color(0xFF00BFA5), // teal
                    icon: Icons.play_arrow_rounded,
                  ),
                  _buildValueCard(
                    title: 'TARGET',
                    value: _formatValue(_targetValue),
                    color: const Color(0xFF7C4DFF), // purple
                    icon: Icons.flag_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_isGameOver && !_isGameWon) ...[
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cancel_rounded,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Game Over!',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _gameOverReason,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _startGame(levelIndex: _currentLevelIndex),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else if (_isGameWon) ...[
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Level Complete! Moving to next level...',
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
        ] else ...[
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: level.cols,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: _operations.length,
              itemBuilder: (context, index) {
                final operation = _operations[index];
                final isUsed = _isUsed[index];
                final isHint = index == _hintTileIndex;

                // select a saturated color for this operation type, then adjust for states
                final opBase = _getOperationColor(operation.type);
                final Color tileColor = isHint
                    ? const Color(0xFFB2EBF2) // bright hint teal-cyan
                    : isUsed
                        ? const Color(0xFF263238) // muted dark used-tile
                        : opBase.withOpacity(1.0);

                return GestureDetector(
                  onTap: () => _applyOperation(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        if (!isUsed && !isHint)
                          BoxShadow(
                            color: opBase.withOpacity(0.22),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getOperationString(operation),
                        style: TextStyle(
                          color: Colors.white.withOpacity(isUsed ? 0.6 : 0.98),
                          fontSize: _getOperationFontSize(operation.type),
                          fontWeight: FontWeight.w700,
                          decoration: isUsed ? TextDecoration.lineThrough : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Action buttons
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _getHint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00ACC1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.lightbulb_outline, color: Colors.white),
                      label: const Text('Hint(30)', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startGame(levelIndex: _currentLevelIndex),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Restart', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Concept button: opens the concept dialog on demand
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book, color: Colors.white),
                      label: const Text('Concept', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // (Auto-show removed) Concept available via the Concept button only.
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

  Widget _buildCoinDisplay() {
    return Consumer<CoinService>(
      builder: (context, coinService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF102027).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFB300)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFB300), size: 16),
              const SizedBox(width: 6),
              Text(
                coinService.coins.toString(),
                style: const TextStyle(
                  color: Color(0xFFFFB300),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}