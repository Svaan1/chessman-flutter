import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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
  static const String _defaultFileName = 'gastos_automaticos.csv';
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _initLocalPathAndLoadExpenses();
  }

  Future<void> _initLocalPathAndLoadExpenses() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _localPath = directory.path;
      await _loadExpensesFromDefaultFile();
    } catch (e) {
      print("Failed to initialize local path or load expenses: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao inicializar armazenamento: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<String> get _defaultFilePath async {
    if (_localPath == null) {
      final directory = await getApplicationDocumentsDirectory();
      _localPath = directory.path;
    }
    return '$_localPath/$_defaultFileName';
  }

  Future<void> _loadExpensesFromDefaultFile() async {
    if (_localPath == null) {
      return;
    }
    try {
      final filePath = await _defaultFilePath;
      final file = File(filePath);

      if (await file.exists()) {
        String content = await file.readAsString();
        List<String> lines = content.split('\n');
        List<Expense> loadedExpenses = [];

        for (String line in lines) {
          if (line.trim().isEmpty) continue;

          List<String> parts = line.split(',');
          if (parts.length == 2) {
            String title = parts[0].trim().replaceAll(';', ',');
            double? amount = double.tryParse(parts[1].trim().replaceAll(',', '.'));

            if (title.isNotEmpty && amount != null && amount > 0) {
              bool isDuplicate = expenses.any((e) => e.title == title && e.amount == amount);
              if (!isDuplicate) {
                loadedExpenses.add(Expense(title, amount));
              }
            }
          }
        }

        if (loadedExpenses.isNotEmpty) {
          setState(() {
            for (var newExpense in loadedExpenses) {
              if (!expenses.any((e) => e.title == newExpense.title && e.amount == newExpense.amount)) {
                expenses.add(newExpense);
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error loading expenses from default file: $e');
    }
  }

  Future<void> _autoSaveExpensesToDefaultFile() async {
    if (_localPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro crítico: Não foi possível determinar o local para salvar os dados.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    try {
      final filePath = await _defaultFilePath;
      final File file = File(filePath);
      String fileContent = expenses.map((e) => '${e.title.replaceAll(',', ';')},${e.amount.toStringAsFixed(2).replaceAll(',', '.')}').join('\n');
      await file.writeAsString(fileContent);
    } catch (e) {
      print('Error auto-saving expenses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar gastos automaticamente: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

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
      await _autoSaveExpensesToDefaultFile();
    }
  }

  void _navigateToFreePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FreePage(expenses: expenses)),
    );
  }

  void _deleteExpense(int index) {
    String deletedTitle = expenses[index].title;
    setState(() {
      expenses.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$deletedTitle" excluído.'),
        backgroundColor: Colors.redAccent,
      ),
    );
    _autoSaveExpensesToDefaultFile();
  }

  Future<void> _saveExpensesToFile() async {
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nenhum gasto para exportar.'),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Exportar gastos para arquivo:',
        fileName: 'gastos_exportados.csv',
        allowedExtensions: ['csv', 'txt'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        String filePath = outputFile;
        if (!outputFile.toLowerCase().endsWith('.csv') && !outputFile.toLowerCase().endsWith('.txt')) {
          filePath = '$outputFile.csv';
        }

        final File file = File(filePath);
        String fileContent = expenses.map((e) => '${e.title.replaceAll(',', ';')},${e.amount.toStringAsFixed(2).replaceAll(',', '.')}').join('\n');
        await file.writeAsString(fileContent);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gastos exportados para "$filePath" com sucesso!'),
            backgroundColor: Colors.teal[700],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Operação de exportar cancelada.'),
            backgroundColor: Colors.grey[700],
          ),
        );
      }
    } catch (e) {
      print('Error exporting expenses: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao exportar gastos: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _importExpensesFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        List<String> lines = content.split('\n');
        List<Expense> newExpensesToImport = [];
        int successfullyImportedCount = 0;
        bool hadContent = lines.any((l) => l.trim().isNotEmpty);

        for (String line in lines) {
          if (line.trim().isEmpty) continue;

          List<String> parts = line.split(',');
          if (parts.length == 2) {
            String title = parts[0].trim().replaceAll(';', ',');
            double? amount = double.tryParse(parts[1].trim().replaceAll(',', '.'));

            if (title.isNotEmpty && amount != null && amount > 0) {
              bool isDuplicateInCurrent = expenses.any((e) => e.title == title && e.amount == amount);
              bool isDuplicateInStaged = newExpensesToImport.any((e) => e.title == title && e.amount == amount);
              if (!isDuplicateInCurrent && !isDuplicateInStaged) {
                newExpensesToImport.add(Expense(title, amount));
                successfullyImportedCount++;
              }
            }
          }
        }

        if (successfullyImportedCount > 0) {
          setState(() {
            expenses.addAll(newExpensesToImport);
          });
          await _autoSaveExpensesToDefaultFile();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successfullyImportedCount gastos importados com sucesso!'),
              backgroundColor: Colors.teal[700],
            ),
          );
        } else if (hadContent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nenhum gasto novo ou válido encontrado no arquivo, ou formato incorreto (esperado: descrição,valor).'),
              backgroundColor: Colors.orange[700],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Arquivo selecionado está vazio ou não contém gastos válidos.'),
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
            onPressed: _importExpensesFromFile,
            icon: const Icon(Icons.file_open_outlined),
            tooltip: 'Importar Gastos de Arquivo',
          ),
          IconButton(
            onPressed: _saveExpensesToFile,
            icon: const Icon(Icons.save_alt_outlined),
            tooltip: 'Exportar Gastos para Arquivo',
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
                  onDelete: (int idx, String title) => _deleteExpense(idx),
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
      Navigator.pop(context, Expense(title, amount));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gasto "${title}" salvo!'),
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
      String normalizedTitle = e.title.replaceAll(';', ',');
      expensesByTitle[normalizedTitle] = (expensesByTitle[normalizedTitle] ?? 0) + e.amount;
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