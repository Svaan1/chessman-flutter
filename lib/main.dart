import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/expense_list_item.dart';
import 'widgets/empty_expenses_view.dart';
import 'widgets/summary_card.dart';
import 'widgets/breakdown_card.dart';

import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MaterialApp(
    theme: ThemeData(
      primarySwatch: Colors.teal,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: ExpenseListPage(),
  ));
}

class Expense {
  String? id;
  String title;
  double amount;

  Expense({this.id, required this.title, required this.amount});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
    };
  }

  factory Expense.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Expense(
      id: snapshot.id,
      title: data?['title'] ?? '',
      amount: (data?['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ExpenseListPage extends StatefulWidget {
  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  final CollectionReference<Expense> _expensesCollection =
      FirebaseFirestore.instance.collection('expenses').withConverter<Expense>(
            fromFirestore: Expense.fromFirestore,
            toFirestore: (Expense expense, _) => expense.toMap(),
          );

  void _navigateToForm({Expense? expense}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseFormPage(expense: expense),
      ),
    );
    if (result != null && result is Expense) {
      if (expense != null && expense.id != null) {
        await _expensesCollection.doc(expense.id).update(result.toMap());
      } else {
        await _expensesCollection.add(result);
      }
    }
  }

  void _navigateToFreePage(List<Expense> currentExpenses) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FreePage(expenses: currentExpenses)),
    );
  }

  void _deleteExpense(Expense expenseToDelete) async {
    if (expenseToDelete.id != null) {
      await _expensesCollection.doc(expenseToDelete.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${expenseToDelete.title}" excluído.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir "${expenseToDelete.title}": ID não encontrado.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Expense>>(
      stream: _expensesCollection.orderBy('title').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Controle de Gastos (Firebase)')),
            body: Center(child: Text('Erro ao carregar dados: ${snapshot.error}')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Controle de Gastos (Firebase)')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final expenses = snapshot.data?.docs.map((doc) => doc.data()).toList() ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Controle de Gastos (Firebase)'),
            actions: [
              IconButton(
                onPressed: () => _navigateToFreePage(expenses),
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
                      onEdit: (expFromItem, idxFromItem) => _navigateToForm(expense: expFromItem),
                      onDeleteCallback: _deleteExpense,
                      onDelete: (idx, title) => _deleteExpense(expense),
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
      },
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
      Navigator.pop(context, Expense(id: widget.expense?.id, title: title, amount: amount));
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
        title: Text(widget.expense == null ? 'Adicionar Gasto' : 'Editar Gasto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um título.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um valor.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Por favor, insira um número válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Salvar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FreePage extends StatelessWidget {
  final List<Expense> expenses;

  const FreePage({Key? key, required this.expenses}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double totalExpenses = expenses.fold(0, (sum, item) => sum + item.amount);
    int expenseCount = expenses.length;
    Expense? highestExpense = expenses.isNotEmpty
        ? expenses.reduce((curr, next) => curr.amount > next.amount ? curr : next)
        : null;

    Map<String, double> breakdown = {};
    for (var expense in expenses) {
      breakdown.update(expense.title, (value) => value + expense.amount, ifAbsent: () => expense.amount);
    }

    var sortedBreakdown = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumo dos Gastos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SummaryCard(
              totalExpenses: totalExpenses,
              count: expenseCount,
              highestExpense: highestExpense,
            ),
            const SizedBox(height: 20),
            const Text('Detalhamento:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: sortedBreakdown.length,
                itemBuilder: (context, index) {
                  final entry = sortedBreakdown[index];
                  return BreakdownCard(
                    category: entry.key,
                    amount: entry.value,
                    total: totalExpenses,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}