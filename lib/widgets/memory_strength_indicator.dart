
import 'package:flutter/material.dart';
import 'dart:math' as math;

class MemoryStrengthIndicator extends StatelessWidget {
  final double retrievability;
  final double stability;

  const MemoryStrengthIndicator({
    Key? key,
    required this.retrievability,
    required this.stability,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Memory Strength:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [Colors.red, Colors.orange, Colors.green],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: retrievability.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _getStrengthColor(retrievability), width: 2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(retrievability * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _getStrengthColor(retrievability),
          ),
        ),
      ],
    );
  }

  Color _getStrengthColor(double strength) {
    if (strength >= 0.8) return Colors.green;
    if (strength >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
