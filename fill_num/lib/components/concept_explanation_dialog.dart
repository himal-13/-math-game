// concept_explanation_dialog.dart
import 'package:flutter/material.dart';

void showConceptExplanationDialog(BuildContext context, String concept) {
 final explanations = {
  'Basic fraction operations': 
      'Use division (÷), reciprocal (1/x), and fractions to transform numbers. Example: 8 ÷ 2 ÷ 2 = 2',
  
  'Fraction and percentage operations': 
      'Combine fractions with percentages. +50% means add half the current value, -25% means subtract a quarter.',
  
  'Square roots and exponents': 
      '√x finds the square root, x² squares the number. Use these to transform numbers through powers and roots.',
  
  'Cube roots and powers': 
      '∛x finds the cube root, x³ cubes the number. These are the 3D equivalents of square operations.',
  
  'Factorial and modulus operations': 
      'x! multiplies all numbers from 1 to x (5! = 120). mod finds remainder after division (7 mod 3 = 1).',
  
  'Modulus and factorial combinations': 
      'Combine factorial and modulus operations. Factorials grow quickly, modulus keeps numbers manageable.',
  
  'Prime number operations': 
      'isPrime: returns 1 if prime, 0 if not\nnextPrime: finds next prime number\nprevPrime: finds previous prime',
  
  'Prime number detection': 
      'Use prime detection to create binary results (1 for prime, 0 for composite), then transform further.',
  
  'Euler\'s totient function φ(n)': 
      'φ(n) counts numbers ≤ n that are coprime with n (share no common factors). φ(12) = 4 (1,5,7,11)',
  
  'Sum of divisors function σ(n)': 
      'σ(n) sums all positive divisors of n. σ(10) = 18 (1+2+5+10). Different from proper divisors sum s(n).',
  
  'Digit sum operation': 
      'sumD adds all digits of a number. sumD(123) = 1+2+3 = 6. Works only on positive integers.',
  
  'Digit product operation': 
      'prodD multiplies all digits. prodD(234) = 2×3×4 = 24. Be careful with zeros!',
  
  'Digit reverse operation': 
      'reverse flips the digits. reverse(456) = 654. Only works on integers.',
  
  'Digital root operation': 
      'digital root repeatedly sums digits until single digit. dRoot(987) = 9+8+7=24 → 2+4=6',
  
  'Tau function τ(n) - number of divisors': 
      'τ(n) counts how many positive divisors n has. τ(12) = 6 (1,2,3,4,6,12). Also called d(n).',
  
  'Divisor count operations': 
      'τ(n) and d(n) are the same function - counting divisors. Useful for number theory puzzles.',
  
  'Combination operation nCk': 
      'C(k) calculates combinations: ways to choose k items from n. C(2) from 5 = 5!/(2!×3!) = 10',
  
  'Permutation operation nPk': 
      'P(k) calculates permutations: ordered arrangements of k items from n. P(2) from 4 = 4×3 = 12',
  
  'Summation operation Σ': 
      'Σ(n) calculates sum from 1 to n. Σ(4) = 1+2+3+4 = 10. Same as triangular numbers.',
  
  'Product series operation ∏': 
      'Π(n) calculates product from 1 to n. Π(3) = 1×2×3 = 6. Same as factorial for integers.',
  
  'Triangular numbers': 
      'tri(n) = n(n+1)/2. tri(4) = 10. These numbers form triangular patterns: 1, 3, 6, 10, 15...',
  
  'Triangular number patterns': 
      'Triangular numbers grow quadratically. Each is the sum of previous plus the next integer.',
  
  'Pentagonal numbers': 
      'pent(n) = n(3n-1)/2. pent(4) = 22. Forms pentagon patterns: 1, 5, 12, 22, 35...',
  
  'Pentagonal number sequences': 
      'Pentagonal numbers have applications in partitions and number theory.',
  
  'Hexagonal numbers': 
      'hex(n) = n(2n-1). hex(4) = 28. Forms hexagon patterns: 1, 6, 15, 28, 45...',
  
  'Hexagonal number patterns': 
      'Hexagonal numbers are also triangular numbers at every other position.',
  
  'Centered square numbers': 
      'centSq(n) = n² + (n-1)². centSq(3) = 13. Represents points in centered square arrangement.',
  
  'Centered square patterns': 
      'Centered square numbers: 1, 5, 13, 25, 41... Each layer adds points around the center.',
  
  'Mixed advanced operations challenge': 
      'Combine multiple mathematical concepts. Think about the order of operations carefully!',
  
  'Final challenge - all concepts': 
      'The ultimate test! Use everything you\'ve learned about number theory and special functions.',
};
 showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(
        'Mathematical Concept',
        style: TextStyle(
          color: Color(0xFF00BFA5),
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color(0xFF0B1220),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: SingleChildScrollView(
        child: Text(
          explanations[concept] ?? 'Advanced mathematical operation',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF00BFA5),
          ),
          child: const Text('GOT IT'),
        ),
      ],
    ),
  );
}