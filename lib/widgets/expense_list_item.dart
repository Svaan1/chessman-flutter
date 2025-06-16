import 'package:flutter/material.dart';
import '../main.dart';

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final int index;
  final void Function(Expense expense, int? index) onEdit;
  final void Function(int index, String title) onDelete;
  final void Function(Expense expense) onDeleteCallback;

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onDeleteCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColorLight,
          child: Text(
            'R\$',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColorDark,
            ),
          ),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'R\$ ${expense.amount.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueGrey),
              tooltip: 'Editar',
              onPressed: () => onEdit(expense, index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Excluir',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirmar Exclusão'),
                      content: Text(
                        'Tem certeza que deseja excluir "${expense.title}"?',
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancelar'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text(
                            'Excluir',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            onDeleteCallback(expense);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        onTap: () => onEdit(expense, index),
      ),
    );
  }
}
