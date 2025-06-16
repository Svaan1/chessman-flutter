import 'package:flutter/material.dart';
import 'dart:math';

class BreakdownCard extends StatelessWidget {
  final String category;
  final double amount;
  final double total;

  const BreakdownCard({
    super.key,
    required this.category,
    required this.amount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final Color barColor = Colors.blueAccent;

    double percentage = (total > 0) ? (amount / total) * 100 : 0;
    double barMaxWidth = 100;
    double barWidth = max(0, (percentage / 100) * barMaxWidth);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'R\$ ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (barMaxWidth > 0)
              Container(
                height: 10,
                width: barWidth,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
