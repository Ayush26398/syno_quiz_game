import 'package:flutter/material.dart';

class OptionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSelected;
  final bool isCorrect;
  final bool isIncorrect;
  final bool isDisabled;

  const OptionButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isSelected = false,
    this.isCorrect = false,
    this.isIncorrect = false,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.white;
    Color textColor = Colors.black87;
    Color borderColor = Colors.grey.shade300;

    if (isCorrect) {
      backgroundColor = Colors.green;
      textColor = Colors.white;
      borderColor = Colors.green;
    } else if (isIncorrect) {
      backgroundColor = Colors.red;
      textColor = Colors.white;
      borderColor = Colors.red;
    } else if (isSelected) {
      borderColor = Theme.of(context).primaryColor;
    }

    return Container(
      width: double.infinity,
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isSelected ? 4 : 2,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}