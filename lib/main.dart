import 'package:flutter/material.dart';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'widgets/expense_list_item.dart';
import 'widgets/empty_expenses_view.dart';
import 'widgets/summary_card.dart';
import 'widgets/breakdown_card.dart';

void main() {
  runApp(MaterialApp(
    theme: ThemeData(
      primarySwatch: Colors.teal,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: ExpenseListPage(),
  ));
}

class Expense {
  String title;
  double amount;

  Expense(this.title, this.amount);
}

class ExpenseListPage extends StatefulWidget {
  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  List<Expense> expenses = [];

  void _navigateToForm({Expense? expense, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseFormPage(expense: expense),
      ),
    );
    if (result != null && result is Expense) {
      setState(() {
        if (index != null) {
          expenses[index] = result;
        } else {
          expenses.add(result);
        }
      });
    }
  }

  void _navigateToFreePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FreePage(expenses: expenses)),
    );
  }

  void _deleteExpense(int index, String title) {
    setState(() {
      expenses.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$title" excluído.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _saveExpensesToFile() async {
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nenhum gasto para salvar.'),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Salvar gastos em arquivo:',
        fileName: 'gastos.csv',
        allowedExtensions: ['csv', 'txt'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        // Ensure the filename has an extension if the user didn't provide one
        String filePath = outputFile;
        if (!outputFile.toLowerCase().endsWith('.csv') && !outputFile.toLowerCase().endsWith('.txt')) {
          // Default to .csv if no valid extension is part of the name
          filePath = '$outputFile.csv';
        }

        final File file = File(filePath);
        String fileContent = expenses.map((e) => '${e.title},${e.amount.toStringAsFixed(2).replaceAll(',', '.')}').join('\n');
        await file.writeAsString(fileContent);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gastos salvos em "$filePath" com sucesso!'),
            backgroundColor: Colors.teal[700],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Operação de salvar cancelada.'),
            backgroundColor: Colors.grey[700],
          ),
        );
      }
    } catch (e) {
      print('Error saving expenses: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar gastos: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _simulateLoadExpensesFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        List<String> lines = content.split('\n');
        List<Expense> importedExpenses = [];
        int lineNumber = 0;

        for (String line in lines) {
          lineNumber++;
          if (line.trim().isEmpty) continue;

          List<String> parts = line.split(',');
          if (parts.length == 2) {
            String title = parts[0].trim();
            double? amount = double.tryParse(parts[1].trim());

            if (title.isNotEmpty && amount != null && amount > 0) {
              importedExpenses.add(Expense(title, amount));
            } else {
              print('Skipping invalid line $lineNumber: "$line" - Invalid format or amount.');
            }
          } else {
            print('Skipping invalid line $lineNumber: "$line" - Expected 2 parts, got ${parts.length}.');
          }
        }

        if (importedExpenses.isNotEmpty) {
          setState(() {
            expenses.addAll(importedExpenses);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${importedExpenses.length} gastos importados com sucesso!'),
              backgroundColor: Colors.teal[700],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nenhum gasto válido encontrado no arquivo ou formato incorreto (esperado: descrição,valor).'),
              backgroundColor: Colors.orange[700],
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Importação cancelada.'),
            backgroundColor: Colors.grey[700],
          ),
        );
      }
    } catch (e) {
      print('Error importing expenses: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao importar gastos: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Gastos'),
        actions: [
          IconButton(
            onPressed: _simulateLoadExpensesFromFile,
            icon: const Icon(Icons.file_open_outlined),
            tooltip: 'Importar Gastos (Simulado)',
          ),
          IconButton(
            onPressed: _saveExpensesToFile, // Added this button
            icon: const Icon(Icons.save_alt_outlined),
            tooltip: 'Salvar Gastos',
          ),
          IconButton(
            onPressed: _navigateToFreePage,
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Ver Resumo',
          ),
        ],
      ),
      body: expenses.isEmpty
          ? const EmptyExpensesView()
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return ExpenseListItem(
                  expense: expense,
                  index: index,
                  onEdit: _navigateToForm,
                  onDelete: _deleteExpense,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
        tooltip: 'Adicionar Novo Gasto',
      ),
    );
  }
}

class ExpenseFormPage extends StatefulWidget {
  final Expense? expense;

  ExpenseFormPage({this.expense});

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      titleController.text = widget.expense!.title;
      // Ensure the amount is formatted with a period for consistency with parsing
      amountController.text = widget.expense!.amount.toStringAsFixed(2).replaceAll(',', '.');
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final title = titleController.text.trim();
      final amount = double.parse(amountController.text.replaceAll(',', '.'));
      Navigator.pop(context, Expense(title, amount));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gasto "${title}" salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Novo Gasto' : 'Editar Gasto'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex: Almoço, Transporte',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira uma descrição.';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Valor',
                    prefixText: 'R\$ ',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira um valor.';
                    }
                    final number = double.tryParse(value.replaceAll(',', '.'));
                    if (number == null) {
                      return 'Por favor, insira um número válido.';
                    }
                    if (number <= 0) {
                      return 'O valor deve ser maior que zero.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Salvar Gasto'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FreePage extends StatelessWidget {
  final List<Expense> expenses;

  const FreePage({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    double total = expenses.fold(0, (sum, e) => sum + e.amount);
    Expense? highestExpense = expenses.isEmpty
        ? null
        : expenses.reduce((a, b) => a.amount > b.amount ? a : b);
    Map<String, double> expensesByTitle = {};
    for (var e in expenses) {
      expensesByTitle[e.title] = (expensesByTitle[e.title] ?? 0) + e.amount;
    }
    var sortedExpenses = expensesByTitle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Resumo de Gastos')),
      body: expenses.isEmpty
          ? const Center(
              child: Text('Nenhum gasto registrado para exibir o resumo.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SummaryCard(
                  total: total,
                  count: expenses.length,
                  highestExpense: highestExpense,
                ),
                const SizedBox(height: 16),
                BreakdownCard(
                  sortedExpenses: sortedExpenses,
                  total: total,
                ),
              ],
            ),
    );
  }
}