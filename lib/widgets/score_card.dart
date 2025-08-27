import 'package:flutter/material.dart';

class ScoreCard extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final double accuracy;

  const ScoreCard({
    Key? key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.accuracy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '$currentQuestion',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Question',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                '$totalQuestions',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Total',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                '${accuracy.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Accuracy',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
