import 'package:fill_num/components/getmorecoin_dialog.dart';
import 'package:fill_num/constants/hard_levels.dart';
import 'package:fill_num/utils/audio_manager.dart';
import 'package:fill_num/utils/coin_service.dart';
import 'package:flutter/material.dart';
import 'package:fraction/fraction.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class HardMode extends StatefulWidget {
  const HardMode({super.key});

  @override
  _HardModeState createState() => _HardModeState();
}

class _HardModeState extends State<HardMode> {
  static const String _unlockedLevelsKey = 'unlocked_hardcore_levels';
  static const int _hintCost = 20;

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
  String _gameOverReason = ''; // Track the reason for game over

  List<int> _usedTileIndices = [];

  // Use the imported levels
  List<HardcoreLevel> get _levels => hardcoreLevels;

  // Color mapping for different operation types
  Color _getOperationColor(Operation op) {
    switch (op.type) {
      case '+':
      case '-':
        return const Color(0xFF1E88E5); // Blue for basic arithmetic
      case '*':
      case '/':
        return const Color(0xFF43A047); // Green for multiplication/division
      case '^2':
      case '^3':
        return const Color(0xFFFFB300); // Amber for exponents
      case '+%':
      case '-%':
        return const Color(0xFFF4511E); // Deep orange for percentages
      case '√':
      case '∛':
        return const Color(0xFF8E24AA); // Purple for roots
      default:
        return const Color.fromARGB(255, 104, 58, 183); // Default purple
    }
  }

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    // AudioManager.load();
  }

  void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _unlockedLevelsCount = _prefs.getInt(_unlockedLevelsKey) ?? 1;
      // Ensure the unlocked level count doesn't exceed the number of available levels.
      if (_unlockedLevelsCount > _levels.length) {
        _unlockedLevelsCount = _levels.length;
      }
    });
    // Ensure we don't try to start a level that doesn't exist.
    if (_unlockedLevelsCount - 1 < _levels.length) {
      _startGame(levelIndex: _unlockedLevelsCount - 1);
    } else {
      _startGame(levelIndex: 0); // Fallback to level 1 if something is wrong.
    }
  }

  void _saveProgress() {
    _prefs.setInt(_unlockedLevelsKey, _unlockedLevelsCount);
  }

  void _startGame({int levelIndex = 0}) {
    if (levelIndex >= _levels.length) {
      levelIndex =
          0; // Fallback to the first level if the target level doesn't exist
    }

    setState(() {
      _currentLevelIndex = levelIndex;
      _isGameOver = false;
      _isGameWon = false;
      _showLevelSelect = false;
      _hintTileIndex = -1;
      _gameOverReason = '';

      final level = _levels[_currentLevelIndex];
      _currentValue = level.current.reduce();
      _targetValue = level.target.reduce();
      _movesLeft = level.moves;

      // Get the original operations and solution
      _operations = List<Operation>.from(level.operations);
      _operations.shuffle(); // Shuffle the operations
      _solution = List<Operation>.from(level.solution);

      _isUsed = List.filled(_operations.length, false);
      _usedTileIndices = []; // Reset moves
    });
  }

  void _applyOperation(int index) {
    if (_isGameOver || _isGameWon || _isUsed[index]) return;
    final operation = _operations[index];

    setState(() {
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
        case '+%':
          final percentage = _currentValue * operation.value;
          _currentValue += percentage;
          break;
        case '-%':
          final percentage = _currentValue * operation.value;
          _currentValue -= percentage;
          break;
        // Add square root operation
        case '√':
          _currentValue = _calculateSquareRoot(_currentValue);
          break;
        // Add cube root operation
        case '∛':
          _currentValue = _calculateCubeRoot(_currentValue);
          break;
      }
      _movesLeft--;
      _currentValue = _currentValue.reduce();
      _isUsed[index] = true;
      _hintTileIndex = -1;
      _usedTileIndices.add(index); // Track the move
      _checkGameState();
    });
  }

  // Square root calculation method
  Fraction _calculateSquareRoot(Fraction value) {
    // Check if the square root results in a rational number
    // A fraction a/b has a rational square root if both a and b are perfect squares
    final numerator = value.numerator.toDouble();
    final denominator = value.denominator.toDouble();

    final numeratorRoot = math.sqrt(numerator);
    final denominatorRoot = math.sqrt(denominator);

    // Check if both numerator and denominator roots are integers (or very close to integers)
    final isNumeratorPerfectSquare =
        (numeratorRoot - numeratorRoot.roundToDouble()).abs() < 0.0001;
    final isDenominatorPerfectSquare =
        (denominatorRoot - denominatorRoot.roundToDouble()).abs() < 0.0001;

    if (isNumeratorPerfectSquare && isDenominatorPerfectSquare) {
      // Return the rational square root
      return Fraction.fromDouble(numeratorRoot / denominatorRoot).reduce();
    } else {
      // Square root results in irrational number - game over
      _triggerGameOverDueToIrrational(
        'Square root resulted in irrational number',
      );
      return value; // Return original value (won't matter since game will be over)
    }
  }

  // Cube root calculation method
  Fraction _calculateCubeRoot(Fraction value) {
    // Check if the cube root results in a rational number
    // A fraction a/b has a rational cube root if both a and b are perfect cubes
    final numerator = value.numerator.toDouble();
    final denominator = value.denominator.toDouble();

    final numeratorRoot = _cubeRoot(numerator);
    final denominatorRoot = _cubeRoot(denominator);

    // Check if both numerator and denominator roots are integers (or very close to integers)
    final isNumeratorPerfectCube =
        (numeratorRoot - numeratorRoot.roundToDouble()).abs() < 0.0001;
    final isDenominatorPerfectCube =
        (denominatorRoot - denominatorRoot.roundToDouble()).abs() < 0.0001;

    if (isNumeratorPerfectCube && isDenominatorPerfectCube) {
      // Return the rational cube root
      return Fraction.fromDouble(numeratorRoot / denominatorRoot).reduce();
    } else {
      // Cube root results in irrational number - game over
      _triggerGameOverDueToIrrational(
        'Cube root resulted in irrational number',
      );
      return value; // Return original value (won't matter since game will be over)
    }
  }

  // Helper method to calculate cube root
  double _cubeRoot(double value) {
    if (value < 0) {
      return -math.pow(-value, 1 / 3) as double;
    }
    return math.pow(value, 1 / 3) as double;
  }

  // Method to handle game over due to irrational number
  void _triggerGameOverDueToIrrational(String reason) {
    setState(() {
      _isGameOver = true;
      _gameOverReason = reason;
      _saveProgress();
      AudioManager.playGameOver();
    });
  }

  void _checkGameState() {
    if (_currentValue.reduce() == _targetValue.reduce()) {
      _isGameWon = true;
      AudioManager.playDing();
      if (_currentLevelIndex + 1 < _levels.length) {
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
        _gameOverReason = 'You completed all levels!';
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

    // Check if user's moves match the solution so far
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
      // Reset the game and show the first hint
      _startGame(levelIndex: _currentLevelIndex);
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _hintTileIndex = _findNextHintIndex(0);
      });
      return;
    }

    // Otherwise, show the next correct move as hint
    int nextHintStep = movesMade;
    int nextHintIndex = _findNextHintIndex(nextHintStep);

    setState(() {
      if (nextHintIndex != -1) {
        _hintTileIndex = nextHintIndex;
      } else {}
    });
  }

  // Helper to find the next hint index
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
      case '*':
        return '×${op.value.toString()}';
      case '/':
        return '÷${op.value.toString()}';
      case '^2':
        return 'x²';
      case '^3':
        return 'x³';
      case '+%':
        return '+${(op.value.toDouble() * 100).toInt()}%';
      case '-%':
        return '-${(op.value.toDouble() * 100).toInt()}%';
      case '√':
        return '√'; // Square root symbol
      case '∛':
        return '∛'; // Cube root symbol
      default:
        return '${op.type}${op.value.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: Text(
          _showLevelSelect
              ? 'Select a Level'
              : 'Level ${_currentLevelIndex + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            _showLevelSelect ? Icons.arrow_back : Icons.list,
            color: Colors.white,
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
            colors: [Color(0xFF1a1a1a), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
      children: [
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _levels.length,
            itemBuilder: (context, index) {
              final isUnlocked = index < _unlockedLevelsCount;
              return ElevatedButton(
                onPressed: isUnlocked
                    ? () => _startGame(levelIndex: index)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUnlocked
                      ? const Color.fromARGB(213, 104, 58, 183)
                      : const Color.fromARGB(144, 158, 158, 158),
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
    final level = _levels[_currentLevelIndex];
    return Column(
      children: [
        // Game info section - Improved UI
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 30, 30, 30),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Moves left indicator (unchanged as requested)
              _buildInfoContainer(
                title: 'Moves Left',
                value: _movesLeft.toString(),
                color: _movesLeft < 3 ? Colors.red : Colors.green,
              ),
              const SizedBox(height: 16),

              // Improved Current and Target display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Current Value
                  _buildValueCard(
                    title: 'CURRENT',
                    value: _currentValue.toString(),
                    color: Colors.blue,
                    icon: Icons.play_arrow_rounded,
                  ),

                  // Target Value
                  _buildValueCard(
                    title: 'TARGET',
                    value: _targetValue.toString(),
                    color: Colors.green,
                    icon: Icons.flag_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const SizedBox(height: 16),

        // Conditional rendering for game over and operation grid
        if (_isGameOver && !_isGameWon) ...[
          // Game Over Screen
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
                      onPressed: () =>
                          _startGame(levelIndex: _currentLevelIndex),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
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
          // Level Complete Message
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
          // Normal Game Grid (only shown when game is active)
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: level.cols,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
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
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isHint
                          ? Colors.blue.withOpacity(0.8)
                          : isUsed
                          ? const Color.fromARGB(255, 60, 60, 60)
                          : operationColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        if (!isUsed && !isHint)
                          BoxShadow(
                            color: operationColor.withOpacity(0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getOperationString(operation),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: isUsed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Action buttons (only shown when game is active)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _getHint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Hint(20)',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _startGame(levelIndex: _currentLevelIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Restart',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // New method for improved value cards
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
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
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
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                coinService.coins.toString(),
                style: const TextStyle(
                  color: Colors.amber,
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
