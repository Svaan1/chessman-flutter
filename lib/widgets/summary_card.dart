import 'package:flutter/material.dart';
import '../main.dart';

class SummaryCard extends StatelessWidget {
  final double totalExpenses;
  final int count;
  final Expense? highestExpense;

  const SummaryCard({
    super.key,
    required this.totalExpenses,
    required this.count,
    this.highestExpense,
  });

  @override
  Widget build(BuildContext context) {
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
              'Resumo Geral',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            const Divider(height: 24),
            _buildSummaryRow('Total Gasto:', 'R\$ ${totalExpenses.toStringAsFixed(2)}'),
            _buildSummaryRow('Número de Lançamentos:', '$count'),
            if (highestExpense != null)
              _buildSummaryRow(
                'Maior Gasto:',
                '${highestExpense!.title} (R\$ ${highestExpense!.amount.toStringAsFixed(2)})',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
