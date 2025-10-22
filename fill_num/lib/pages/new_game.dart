import 'package:flutter/material.dart';
import 'dart:math';

class FractionFusionGame extends StatefulWidget {
  @override
  _FractionFusionGameState createState() => _FractionFusionGameState();
}

class _FractionFusionGameState extends State<FractionFusionGame> {
  // Game variables
  int _score = 0;
  int _lives = 3;
  double _currentValue = 0.5;
  double _targetValue = 0.75;
  List<FractionPiece> _fallingPieces = [];
  Random _random = Random();
  bool _isGameOver = false;

  // Available fractions
  final List<Map<String, dynamic>> _fractions = [
    {'numerator': 1, 'denominator': 2, 'value': 0.5},
    {'numerator': 1, 'denominator': 3, 'value': 1/3},
    {'numerator': 2, 'denominator': 3, 'value': 2/3},
    {'numerator': 1, 'denominator': 4, 'value': 0.25},
    {'numerator': 3, 'denominator': 4, 'value': 0.75},
    {'numerator': 1, 'denominator': 5, 'value': 0.2},
    {'numerator': 2, 'denominator': 5, 'value': 0.4},
    {'numerator': 3, 'denominator': 5, 'value': 0.6},
    {'numerator': 4, 'denominator': 5, 'value': 0.8},
  ];

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _isGameOver = false;
    _score = 0;
    _lives = 3;
    _generateNewTarget();
    _currentValue = 0.5;
    
    // Start generating falling pieces
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateFallingPiece();
      _gameLoop();
    });
  }

  void _gameLoop() {
    if (_isGameOver) return;

    // Update falling pieces
    setState(() {
      _fallingPieces.removeWhere((piece) {
        if (piece.position.dy > MediaQuery.of(context).size.height) {
          _lives--;
          if (_lives <= 0) {
            _gameOver();
          }
          return true;
        }
        return false;
      });

      // Move pieces down
      for (var piece in _fallingPieces) {
        piece.position = Offset(
          piece.position.dx,
          piece.position.dy + piece.speed,
        );
      }
    });

    // Continue game loop
    Future.delayed(Duration(milliseconds: 16), _gameLoop);
  }

  void _generateFallingPiece() {
    if (_isGameOver) return;

    setState(() {
      final fraction = _fractions[_random.nextInt(_fractions.length)];
      _fallingPieces.add(FractionPiece(
        numerator: fraction['numerator'],
        denominator: fraction['denominator'],
        value: fraction['value'],
        position: Offset(
          _random.nextDouble() * (MediaQuery.of(context).size.width - 80),
          -50,
        ),
        speed: 2.0 + _random.nextDouble() * 2.0,
        operation: _random.nextBool() ? '+' : '-',
      ));
    });

    // Generate next piece after random delay
    Future.delayed(
      Duration(milliseconds: 800 + _random.nextInt(1200)),
      _generateFallingPiece,
    );
  }

  void _onPieceTap(FractionPiece piece) {
    if (_isGameOver) return;

    setState(() {
      double newValue;
      if (piece.operation == '+') {
        newValue = _currentValue + piece.value;
      } else {
        newValue = _currentValue - piece.value;
      }

      // Keep value between 0 and 1
      newValue = newValue.clamp(0.0, 1.0);

      // Check if we hit the target
      if ((newValue - _targetValue).abs() < 0.001) {
        _score += 10;
        _generateNewTarget();
        _currentValue = 0.5; // Reset current value
      } else {
        _currentValue = newValue;
        _score += 1;
      }

      _fallingPieces.remove(piece);
    });
  }

  void _generateNewTarget() {
    setState(() {
      // Generate target that's achievable with available fractions
      final achievableTarget = _fractions[_random.nextInt(_fractions.length)];
      _targetValue = achievableTarget['value'];
    });
  }

  void _gameOver() {
    setState(() {
      _isGameOver = true;
    });
  }

  String _formatValue(double value) {
    // Convert decimal to fraction for display
    for (var frac in _fractions) {
      if ((frac['value'] - value).abs() < 0.001) {
        return '${frac['numerator']}/${frac['denominator']}';
      }
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Game info panel
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'Fraction Fusion',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Score: $_score'),
                      Text('Lives: $_lives'),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Target: ${_formatValue(_targetValue)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Current: ${_formatValue(_currentValue)}',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),

            // Falling pieces
            ..._fallingPieces.map((piece) {
              return Positioned(
                left: piece.position.dx,
                top: piece.position.dy,
                child: GestureDetector(
                  onTap: () => _onPieceTap(piece),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: piece.operation == '+' 
                          ? Colors.green[300] 
                          : Colors.red[300],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          piece.operation,
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${piece.numerator}/${piece.denominator}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),

            // Game over overlay
            if (_isGameOver)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Game Over!',
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Final Score: $_score',
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _startGame,
                        child: Text('Play Again'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FractionPiece {
  final int numerator;
  final int denominator;
  final double value;
  Offset position;
  final double speed;
  final String operation; // '+' or '-'

  FractionPiece({
    required this.numerator,
    required this.denominator,
    required this.value,
    required this.position,
    required this.speed,
    required this.operation,
  });
}

// Add this to your game mode selector
class FractionFusionMode extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FractionFusionGame();
  }
}