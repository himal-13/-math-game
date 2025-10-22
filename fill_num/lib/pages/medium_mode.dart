import 'package:fill_num/components/getmore_hint_dialog.dart';
import 'package:fill_num/constants/medium_levels.dart';
import 'package:fill_num/pages/coin_page.dart';
import 'package:fill_num/utils/hint_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class MediumMode extends StatefulWidget {
  const MediumMode({super.key});

  @override
  _MediumModeState createState() => _MediumModeState();
}

class _MediumModeState extends State<MediumMode> {
  static const String _unlockedLevelsKey = 'unlocked_levels_medium';
  static const int _hintCost = 1; // Reduced cost for hints

  final List<Map<String, dynamic>> _levels = mediumLevels;
  int _currentNumber = 0;
  int _targetNumber = 0;
  int _movesRemaining = 0;
  int _currentLevelIndex = 0;
  int _unlockedLevelsCount = 1;
  List<String> _gridTiles = [];
  final List<int> _usedTileIndices = [];
  String? _message;
  bool _isGameOver = false;
  bool _hasWon = false;
  bool _showLevelSelect = false;
  int _hintTileIndex = -1;

  late Box _gameBox;

  @override
  void initState() {
    super.initState();
    _initHiveAndLoad();
  }

  Future<void> _initHiveAndLoad() async {
    try {
      if (!Hive.isBoxOpen('medium_mode_level')) {
        await Hive.openBox('medium_mode_level');
      }
      _gameBox = Hive.box('medium_mode_level');
      await _loadGameData();
    } catch (e, st) {
      debugPrint('Error opening medium_mode_level box: $e\n$st');
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
      });
      _startGame(levelIndex: _unlockedLevelsCount - 1);
    } catch (e, st) {
      debugPrint('Failed to load game data: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load game data')),
        );
      }
    }
  }

  void _saveUnlockedLevels() {
    try {
      _gameBox.put(_unlockedLevelsKey, _unlockedLevelsCount);
    } catch (e, st) {
      debugPrint('Failed to save unlocked levels: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save progress')),
        );
      }
    }
  }

  void _startGame({int levelIndex = 0}) {
    setState(() {
      _currentLevelIndex = levelIndex;
      _isGameOver = false;
      _hasWon = false;
      _showLevelSelect = false;
      _usedTileIndices.clear();
      _hintTileIndex = -1;
      _generatePuzzle();
    });
  }

  void _generatePuzzle() {
    final levelData = _levels[_currentLevelIndex];

    _currentNumber = levelData['start']!;
    _targetNumber = levelData['target']!;
    _movesRemaining = levelData['moves']!;
    _gridTiles = List.from(levelData['grid_tiles']!);
    _gridTiles.shuffle();
  }

  bool _checkIfOnSolutionPath() {
    final solution = _levels[_currentLevelIndex]['sol']!;
    if (_usedTileIndices.length > solution.length) {
      return false;
    }
    for (int i = 0; i < _usedTileIndices.length; i++) {
      if (_gridTiles[_usedTileIndices[i]] != solution[i]) {
        return false;
      }
    }
    return true;
  }

  void _purchaseHint() async {
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
      
      if (!_checkIfOnSolutionPath()) {
        setState(() {
          final levelData = _levels[_currentLevelIndex];
          _currentNumber = levelData['start']!;
          _movesRemaining = levelData['moves']!;
          _usedTileIndices.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wrong path! The board has been reset.'),
          ),
        );
      }
      _getHint();
    } else {
       showNotEnoughHintsDialog(context);
    }
  }

  void _getHint() {
    if (_usedTileIndices.length >= _levels[_currentLevelIndex]['sol']!.length) {
      return;
    }
    final hintSolution =
        _levels[_currentLevelIndex]['sol']![_usedTileIndices.length] as String;
    final int hintIndex = _gridTiles.indexOf(hintSolution);

    setState(() {
      _hintTileIndex = hintIndex;
    });
  }

  void _resetGame() {
    setState(() {
      _startGame(levelIndex: _currentLevelIndex);
    });
  }

  void _handleTileTap(int tileIndex) {
    if (_isGameOver || _hasWon || _usedTileIndices.contains(tileIndex)) return;

    final tile = _gridTiles[tileIndex];
    final operator = tile[0];
    final value = int.parse(tile.substring(1));
    int nextNumber = _currentNumber;

    switch (operator) {
      case '+':
        nextNumber += value;
        break;
      case '-':
        nextNumber -= value;
        break;
      case 'x':
        nextNumber *= value;
      case '÷':
        if (value != 0 && nextNumber % value == 0) {
          nextNumber ~/= value;
        } else {
          setState(() {
            _message =
                'Invalid move! Cannot divide by zero or get a non-integer result.';
            _isGameOver = true;
          });
          return;
        }
        break;
    }

    setState(() {
      _currentNumber = nextNumber;
      _movesRemaining--;
      _usedTileIndices.add(tileIndex);
      _message = null;
      _hintTileIndex = -1;

      _hasWon = (_currentNumber == _targetNumber);

      if (_hasWon) {
        _message = 'Level ${_currentLevelIndex + 1} Complete!';
        _isGameOver = true;
      } else if (_movesRemaining == 0) {
        _message = 'Out of moves! Game Over.';
        _isGameOver = true;
      }
    });
  }

  Widget _buildOperatorButton(String tile, int index) {
    final bool isUsed = _usedTileIndices.contains(index);
    final bool isHint = index == _hintTileIndex;

    final tileColor = isUsed
        ? Colors.white24
        : isHint
        ? Colors.teal.withOpacity(0.4)
        : Colors.white12;
    final borderColor = isUsed
        ? Colors.white30
        : isHint
        ? Colors.teal
        : Colors.white54;
    final textColor = isUsed ? Colors.grey : Colors.white;

    return InkWell(
      onTap: isUsed ? null : () => _handleTileTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            tile,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelectionPage() {
    return Column(
      children: [
        //unlock all levels for debugging
        // ElevatedButton(
        //   onPressed: () {
        //     setState(() {
        //       _unlockedLevelsCount = _levels.length;
        //     });
        //     _saveUnlockedLevels();
        //   },
        //   child: const Text('Unlock All Levels'),
        // ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
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
                      ? Colors.teal[700]
                      : Colors.grey[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _showLevelSelect ? 'Medium Mode' : 'Level ${_currentLevelIndex + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: _showLevelSelect
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            : IconButton(
                icon: const Icon(Icons.list, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showLevelSelect = true;
                  });
                },
              ),
        actions: [
          _showLevelSelect ? const SizedBox.shrink() : _buildHintDisplay(),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a2a2a), Colors.black],
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

  Widget _buildHintDisplay() {
    return Consumer<HintService>(
      builder: (context, hintService, child) {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CoinPage()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.teal.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.yellow,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${hintService.hints}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGamePage() {
    return Column(
      children: [
        _buildInfoContainer(
          title: 'MOVES LEFT',
          value: _movesRemaining.toString(),
          color: _movesRemaining < 3 ? Colors.red : Colors.teal,
        ),
        const SizedBox(height: 20),
        _buildTargetAndCurrentDisplay(),

        const SizedBox(height: 20),

        if (_isGameOver)
          _buildMessageAndResetButton()
        else
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _currentLevelIndex < 5
                    ? 3
                    : _currentLevelIndex < 15
                    ? 4
                    : 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _levels[_currentLevelIndex]['grid_tiles']!.length,
              itemBuilder: (context, index) {
                return _buildOperatorButton(_gridTiles[index], index);
              },
            ),
          ),
        const SizedBox(height: 16),
        if (!_isGameOver) _buildHintAndShuffleButtons(),
      ],
    );
  }

  Widget _buildInfoContainer({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 6,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHintAndShuffleButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 55,
                height: 55,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      onPressed: _purchaseHint,
                      icon: Icon(
                        Icons.lightbulb_outline,
                        color: Colors.teal[300],
                        size: 36,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          size: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hint ($_hintCost)',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 55,
                height: 55,
                child: IconButton(
                  onPressed: _resetGame,
                  icon: Icon(Icons.refresh, color: Colors.amber[700], size: 36),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Reset',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetAndCurrentDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Current Number Display
          Expanded(
            child: Column(
              children: [
                const Text(
                  'CURRENT',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                  child: Text(
                    '$_currentNumber',
                    key: ValueKey<int>(_currentNumber),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Target Number Display
          Expanded(
            child: Column(
              children: [
                const Text(
                  'TARGET',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_targetNumber',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageAndResetButton() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hasWon
                ? Colors.teal.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _hasWon ? Colors.teal : Colors.red,
              width: 2,
            ),
          ),
          child: Text(
            _message!,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _hasWon ? Colors.tealAccent : Colors.redAccent,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        if (_hasWon && _currentLevelIndex < _levels.length - 1)
          _buildActionButton(
            text: 'Next Level',
            onPressed: () {
              if (_currentLevelIndex + 1 >= _unlockedLevelsCount) {
                setState(() {
                  _unlockedLevelsCount = _currentLevelIndex + 2;
                });
                _saveUnlockedLevels();
              }
              _startGame(levelIndex: _currentLevelIndex + 1);
            },
            color: Colors.teal,
          )
        else
          _buildActionButton(
            text: 'Try Again',
            onPressed: () {
              _startGame(levelIndex: _currentLevelIndex);
            },
            color: Colors.red,
          ),
      ],
    );
  }
}