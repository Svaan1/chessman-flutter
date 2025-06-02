import 'package:flutter/material.dart';
import 'dart:math';
import 'widgets/expense_list_item.dart';
import 'widgets/empty_expenses_view.dart';
import 'widgets/summary_card.dart';
import 'widgets/breakdown_card.dart';
import 'database_helper.dart';
import 'dart:io' show Platform; // Added for platform checking
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Added for FFI

Future<void> main() async { // Modified to be async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(MaterialApp(
    theme: ThemeData(
      primarySwatch: Colors.teal,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: ExpenseListPage(),
  ));
}

class Expense {
  int? id;
  String title;
  double amount;

  Expense({this.id, required this.title, required this.amount});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
    );
  }
}

class ExpenseListPage extends StatefulWidget {
  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  List<Expense> expenses = [];
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final loadedExpenses = await dbHelper.getExpenses();
    setState(() {
      expenses = loadedExpenses;
    });
  }

  void _navigateToForm({Expense? expense, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseFormPage(expense: expense),
      ),
    );
    if (result != null && result is Expense) {
      if (expense != null && index != null) {
        result.id = expense.id;
        await dbHelper.updateExpense(result);
      } else {
        await dbHelper.insertExpense(result);
      }
      _loadExpenses();
    }
  }

  void _navigateToFreePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FreePage(expenses: expenses)),
    );
  }

  void _deleteExpense(int index, String title) async {
    int? expenseId = expenses[index].id;
    if (expenseId != null) {
      await dbHelper.deleteExpense(expenseId);
      _loadExpenses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$title" excluído.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir "$title": ID não encontrado.'),
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
      amountController.text = widget.expense!.amount.toStringAsFixed(2).replaceAll(',', '.');
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final title = titleController.text.trim();
      final amount = double.parse(amountController.text.replaceAll(',', '.'));
      Navigator.pop(context, Expense(title: title, amount: amount));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gasto "$title" salvo com sucesso!'),
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