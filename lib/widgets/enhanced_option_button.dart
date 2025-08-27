
import 'package:flutter/material.dart';

class EnhancedOptionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSelected;
  final bool isCorrect;
  final bool isIncorrect;
  final bool isDisabled;
  final int responseTime;

  const EnhancedOptionButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.isSelected,
    required this.isCorrect,
    required this.isIncorrect,
    required this.isDisabled,
    required this.responseTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.grey.shade300;
    Color fillColor = Colors.white;
    Color textColor = Colors.black87;

    if (isDisabled) {
      if (isCorrect) {
        borderColor = Colors.green;
        fillColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
      } else if (isIncorrect) {
        borderColor = Colors.red;
        fillColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
      }
    } else if (isSelected) {
      borderColor = Theme.of(context).primaryColor;
      fillColor = Theme.of(context).primaryColor.withOpacity(0.08);
      textColor = Theme.of(context).primaryColor;
    }

    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: fillColor,
        foregroundColor: textColor,
        elevation: 0,
        side: BorderSide(color: borderColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
