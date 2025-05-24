import 'package:flutter/material.dart';
import 'dart:math';

class BreakdownCard extends StatelessWidget {
  final List<MapEntry<String, double>> sortedExpenses;
  final double total;

  const BreakdownCard({
    super.key,
    required this.sortedExpenses,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      Colors.blueAccent,
      Colors.greenAccent[700]!,
      Colors.orangeAccent[700]!,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.tealAccent[700]!,
      Colors.pinkAccent,
      Colors.amberAccent[700]!,
      Colors.cyanAccent[700]!,
      Colors.indigoAccent,
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gastos por Item',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            const Divider(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                double maxValue =
                    sortedExpenses.isNotEmpty ? sortedExpenses.first.value : 1;
                double barMaxWidth = constraints.maxWidth * 0.45;

                return Column(
                  children: sortedExpenses.asMap().entries.map((entry) {
                    int index = entry.key;
                    MapEntry<String, double> item = entry.value;
                    double barWidth = maxValue > 0
                        ? (item.value / maxValue) * barMaxWidth
                        : 0;
                    Color barColor = colors[index % colors.length];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.key,
                                  style: const TextStyle(fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  '${(total > 0 ? (item.value / total) * 100 : 0).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 6,
                            child: Row(
                              children: [
                                Container(
                                  height: 18,
                                  width: max(0, barWidth),
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'R\$ ${item.value.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
