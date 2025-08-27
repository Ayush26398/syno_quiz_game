
import 'package:flutter/material.dart';

class EnhancedProgressBar extends StatelessWidget {
  final double progress;
  final int correctAnswers;
  final int totalAnswers;

  const EnhancedProgressBar({
    Key? key,
    required this.progress,
    required this.correctAnswers,
    required this.totalAnswers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              // Overall progress
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              // Correct answers overlay
              if (totalAnswers > 0)
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (correctAnswers / totalAnswers * progress).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress: ${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (totalAnswers > 0)
              Text(
                'Correct: $correctAnswers/$totalAnswers',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ],
    );
  }
}
