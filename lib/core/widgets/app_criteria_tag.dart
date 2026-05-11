import 'package:flutter/material.dart';

class AppCriteriaTag extends StatelessWidget {
  final String label;
  final Color color;

  const AppCriteriaTag({
    super.key,
    required this.label,
    this.color = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}
