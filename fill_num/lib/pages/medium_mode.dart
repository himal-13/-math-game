import 'package:fill_num/components/getmorecoin_dialog.dart';
import 'package:fill_num/constants/medium_levels.dart';
import 'package:fill_num/pages/coin_page.dart';
import 'package:fill_num/utils/coin_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MediumMode extends StatefulWidget {
  const MediumMode({super.key});

  @override
  _MediumModeState createState() => _MediumModeState();
}

class _MediumModeState extends State<MediumMode> {
  static const String _unlockedLevelsKey = 'hard_unlocked_levels'; // Different key
  static const int _hintCost = 25; // Higher cost for hard mode

  final List<Map<String, dynamic>> _levels = mediumLevels;
  int _currentNumber = 0;
  int _targetNumber = 0;
  int _movesRemaining = 0;
  int _currentLevelIndex = 0;
  int _unlockedLevelsCount = 1;
  List<String> _gridTiles = [];
  List<int> _usedTileIndices = [];
  String? _message;
  bool _isGameOver = false;
  bool _hasWon = false;
  bool _showLevelSelect = false;
  int _hintTileIndex = -1;

  // Hard mode color scheme - Dark red/orange theme
  final Color _primaryColor = const Color(0xFFB71C1C);
  final Color _accentColor = const Color(0xFFFF6D00);
  final Color _backgroundColor = const Color(0xFF1A0000);
  final Color _cardColor = const Color(0xFF2D1B1B);
  final Color _textColor = Colors.orangeAccent;

  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _unlockedLevelsCount = _prefs!.getInt(_unlockedLevelsKey) ?? 1;
    });
    _startGame(levelIndex: _unlockedLevelsCount - 1);
  }

  void _saveUnlockedLevels() {
    _prefs?.setInt(_unlockedLevelsKey, _unlockedLevelsCount);
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
    if (_usedTileIndices.length > solution.length) return false;
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

    final coinService = Provider.of<CoinService>(context, listen: false);
    final hasEnoughCoins = await coinService.spendCoins(_hintCost);

    if (hasEnoughCoins) {
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
      showNotEnoughCoinsDialog(context);
    }
  }

  void _getHint() {
    if (_usedTileIndices.length >= _levels[_currentLevelIndex]['sol']!.length) return;
    final hintSolution = _levels[_currentLevelIndex]['sol']![_usedTileIndices.length] as String;
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
        break;
      case '÷':
        if (value != 0 && nextNumber % value == 0) {
          nextNumber ~/= value;
        } else {
          setState(() {
            _message = 'Invalid move! Cannot divide by zero or get a non-integer result.';
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
        if (_currentLevelIndex + 1 >= _unlockedLevelsCount) {
          _unlockedLevelsCount = _currentLevelIndex + 2;
          _saveUnlockedLevels();
        }
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
        ? _cardColor.withOpacity(0.5)
        : isHint
            ? _accentColor.withOpacity(0.4)
            : _cardColor;
    final borderColor = isUsed
        ? Colors.grey
        : isHint
            ? _accentColor
            : _primaryColor;
    final textColor = isUsed ? Colors.grey : _textColor;

    return InkWell(
      onTap: isUsed ? null : () => _handleTileTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(8), // Smaller radius for harder feel
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
              fontSize: _levels[_currentLevelIndex]['grid_tiles']![0].length >= 20 ? 14 : 18,
              fontWeight: FontWeight.bold,
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
        const Padding(
          padding: EdgeInsets.only(top: 24.0, bottom: 16.0),
          child: Text(
            'Hard Levels',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, // More columns for hard mode
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _levels.length,
            itemBuilder: (context, index) {
              final isUnlocked = index < _unlockedLevelsCount;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 6,
                      offset: const Offset(3, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: isUnlocked ? () => _startGame(levelIndex: index) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUnlocked ? _primaryColor : Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isUnlocked ? _accentColor : Colors.grey,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? Colors.white : Colors.grey,
                        ),
                      ),
                      if (!isUnlocked)
                        const Icon(Icons.lock, color: Colors.white, size: 16),
                    ],
                  ),
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
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _showLevelSelect ? 'HARD MODE' : 'Level ${_currentLevelIndex + 1}',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: _showLevelSelect ? 24 : 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: _showLevelSelect
            ? const SizedBox.shrink()
            : IconButton(
                icon: Icon(Icons.list, color: _textColor),
                onPressed: () {
                  setState(() {
                    _showLevelSelect = true;
                  });
                },
              ),
        actions: [
          _showLevelSelect ? const SizedBox.shrink() : _buildCoinDisplay(),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_backgroundColor, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _showLevelSelect ? _buildLevelSelectionPage() : _buildGamePage(),
          ),
        ),
      ),
    );
  }

  Widget _buildCoinDisplay() {
    return Consumer<CoinService>(
      builder: (context, coinService, child) {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CoinPage()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _accentColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: Colors.yellow[700],
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${coinService.coins}',
                  style: TextStyle(
                    color: _textColor,
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
          color: _movesRemaining < 3 ? Colors.red : _accentColor,
        ),
        const SizedBox(height: 16),
        _buildTargetAndCurrentDisplay(),
        const SizedBox(height: 20),
        
        if (_isGameOver)
          _buildMessageAndResetButton()
        else
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _currentLevelIndex < 3
                    ? 3
                    : _currentLevelIndex < 15
                    ? 4
                    : 5,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.0,
              ),
              itemCount: _levels[_currentLevelIndex]['grid_tiles']!.length,
              itemBuilder: (context, index) {
                return _buildOperatorButton(_gridTiles[index], index);
              },
            ),
          ),
        
        if (!_isGameOver) ...[
          const SizedBox(height: 16),
          _buildHintAndShuffleButtons(),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        border: Border.all(color: Colors.white.withOpacity(0.2)),
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
              letterSpacing: 1,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHintAndShuffleButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildIconButton(
          icon: Icons.lightbulb_outline,
          label: 'Hint ($_hintCost)',
          onPressed: _purchaseHint,
          color: _accentColor,
        ),
        _buildIconButton(
          icon: Icons.refresh,
          label: 'Reset',
          onPressed: _resetGame,
          color: _primaryColor,
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: _textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetAndCurrentDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _primaryColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Current Number
          Expanded(
            child: Column(
              children: [
                Text(
                  'CURRENT',
                  style: TextStyle(
                    fontSize: 14,
                    color: _textColor.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Text(
                    '$_currentNumber',
                    key: ValueKey<int>(_currentNumber),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // VS Separator
          Container(
            width: 1,
            height: 40,
            color: _primaryColor.withOpacity(0.5),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          // Target Number
          Expanded(
            child: Column(
              children: [
                Text(
                  'TARGET',
                  style: TextStyle(
                    fontSize: 14,
                    color: _textColor.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_targetNumber',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _accentColor,
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _hasWon ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                _hasWon ? Icons.celebration : Icons.warning,
                color: _hasWon ? Colors.green : Colors.red,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                _message!,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _hasWon ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_hasWon && _currentLevelIndex < _levels.length - 1)
          _buildActionButton(
            text: 'NEXT LEVEL',
            onPressed: () {
              _startGame(levelIndex: _currentLevelIndex + 1);
            },
            color: Colors.green,
          )
        else
          _buildActionButton(
            text: 'TRY AGAIN',
            onPressed: () {
              _startGame(levelIndex: _currentLevelIndex);
            },
            color: Colors.red,
          ),
      ],
    );
  }
}