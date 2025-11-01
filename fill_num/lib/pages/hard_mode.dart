import 'package:fill_num/components/getmore_hint_dialog.dart';
import 'package:fill_num/constants/hard_levels.dart';
import 'package:fill_num/utils/audio_manager.dart';
import 'package:fill_num/utils/hint_service.dart';
import 'package:flutter/material.dart';
import 'package:fraction/fraction.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class HardMode extends StatefulWidget {
  const HardMode({super.key});

  @override
  _HardModeState createState() => _HardModeState();
}

class _HardModeState extends State<HardMode> {
  static const String _unlockedLevelsKey = 'unlocked_hardcore_levels';
  static const int _hintCost = 2; // Reduced cost for hints

  late Fraction _currentValue;
  late Fraction _targetValue;
  late int _movesLeft;
  late List<Operation> _operations;
  late List<bool> _isUsed;
  late Box _gameBox;
  bool _isGameWon = false;
  bool _isGameOver = false;
  int _currentLevelIndex = 0;
  int _unlockedLevelsCount = 1;
  bool _showLevelSelect = false;
  int _hintTileIndex = -1;
  late List<Operation> _solution;
  String _gameOverReason = '';

  List<int> _usedTileIndices = [];

  List<HardcoreLevel> get _levels => hardcoreLevels;

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
      default:
        return const Color.fromARGB(255, 104, 58, 183);
    }
  }

  @override
  void initState() {
    super.initState();
    _initHiveAndLoad();
  }

  Future<void> _initHiveAndLoad() async {
    try {
      if (!Hive.isBoxOpen('hard_mode_level')) {
        await Hive.openBox('hard_mode_level');
      }
      _gameBox = Hive.box('hard_mode_level');
      await _loadGameData();
    } catch (e, st) {
      debugPrint('Error opening hard_mode_level box: $e\n$st');
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
        if (_unlockedLevelsCount > _levels.length) {
          _unlockedLevelsCount = _levels.length;
        }
      });
      if (_unlockedLevelsCount - 1 < _levels.length) {
        _startGame(levelIndex: _unlockedLevelsCount - 1);
      } else {
        _startGame(levelIndex: 0);
      }
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
    if (levelIndex >= _levels.length) {
      levelIndex = 0;
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

      _operations = List<Operation>.from(level.operations);
      _operations.shuffle();
      _solution = List<Operation>.from(level.solution);

      _isUsed = List.filled(_operations.length, false);
      _usedTileIndices = [];
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
        case '√':
          _currentValue = _calculateSquareRoot(_currentValue);
          break;
        case '∛':
          _currentValue = _calculateCubeRoot(_currentValue);
          break;
      }
      _movesLeft--;
      _currentValue = _currentValue.reduce();
      _isUsed[index] = true;
      _hintTileIndex = -1;
      _usedTileIndices.add(index);
      _checkGameState();
    });
  }

  Fraction _calculateSquareRoot(Fraction value) {
    final numerator = value.numerator.toDouble();
    final denominator = value.denominator.toDouble();

    final numeratorRoot = math.sqrt(numerator);
    final denominatorRoot = math.sqrt(denominator);

    final isNumeratorPerfectSquare =
        (numeratorRoot - numeratorRoot.roundToDouble()).abs() < 0.0001;
    final isDenominatorPerfectSquare =
        (denominatorRoot - denominatorRoot.roundToDouble()).abs() < 0.0001;

    if (isNumeratorPerfectSquare && isDenominatorPerfectSquare) {
      return Fraction.fromDouble(numeratorRoot / denominatorRoot).reduce();
    } else {
      _triggerGameOverDueToIrrational(
        'Square root resulted in irrational number',
      );
      return value;
    }
  }

  Fraction _calculateCubeRoot(Fraction value) {
    final numerator = value.numerator.toDouble();
    final denominator = value.denominator.toDouble();

    final numeratorRoot = _cubeRoot(numerator);
    final denominatorRoot = _cubeRoot(denominator);

    final isNumeratorPerfectCube =
        (numeratorRoot - numeratorRoot.roundToDouble()).abs() < 0.0001;
    final isDenominatorPerfectCube =
        (denominatorRoot - denominatorRoot.roundToDouble()).abs() < 0.0001;

    if (isNumeratorPerfectCube && isDenominatorPerfectCube) {
      return Fraction.fromDouble(numeratorRoot / denominatorRoot).reduce();
    } else {
      _triggerGameOverDueToIrrational(
        'Cube root resulted in irrational number',
      );
      return value;
    }
  }

  double _cubeRoot(double value) {
    if (value < 0) {
      return -math.pow(-value, 1 / 3) as double;
    }
    return math.pow(value, 1 / 3) as double;
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
        return '√';
      case '∛':
        return '∛';
      default:
        return '${op.type}${op.value.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          _showLevelSelect ? 'Select Level' : 'Level ${_currentLevelIndex + 1}',
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
            'Hardcore Levels',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        //unlock all levels for debugging
        // ElevatedButton( 
        //   onPressed: () {
        //     setState(() {
        //       _unlockedLevelsCount = _levels.length;
        //       _saveProgress();
        //     });
        //   },
        //   child: const Text('Unlock All Levels'),
        // ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _levels.length,
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
    final level = _levels[_currentLevelIndex];
    return Column(
      children: [
        // Game info section - KEEPING MOVES LEFT AS ORIGINAL
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              // Moves left indicator - KEEPING EXACTLY AS ORIGINAL
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
                          fontSize: 18,
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
                    Icons.lightbulb_outline_rounded,
                    size: 20,
                  ),
                  label: Text(
                    'Hint ($_hintCost)',
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
                    'Restart',
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

  // KEEPING THE ORIGINAL MOVES LEFT CONTAINER AS REQUESTED
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