import 'package:flutter/material.dart';

class EmptyExpensesView extends StatelessWidget {
  const EmptyExpensesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum gasto adicionado ainda.',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Text(
            'Clique no botão + para adicionar seu primeiro gasto ou no ícone de arquivo para importar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
