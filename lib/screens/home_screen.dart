import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../services/expense_provider.dart';
import '../services/my_list_tile.dart';
import '../widgets/monthly_expense_bar_chart.dart';
import 'pie_chart_screen.dart';
import 'expense_forecast_screen.dart';
import 'import_dataset_screen.dart';
import 'new_expense_screen.dart';

// main HomeScreen widget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // index of the currently selected screen
  int _selectedIndex = 0;

  // list of screens for the bottom navigation
  final List<Widget> _screens = [
    const _ExpenseListScreen(),
    const PieChartScreen(),
    const ExpenseForecastScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // load expenses when the screen initializes
    Future.microtask(() => context.read<ExpenseProvider>().loadExpenses());
  }

  // handle bottom navigation item tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: _buildAppBar(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // build the app bar
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Expense Tracker'),
      backgroundColor: Colors.grey.shade300,
      actions: [
        IconButton(
          icon: const Icon(Icons.upload),
          onPressed: _navigateToImportScreen,
        ),
      ],
    );
  }

  // build the bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Pie Chart'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Forecast'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromRGBO(66, 66, 66, 1),
        backgroundColor: Colors.grey.shade200,
        onTap: _onItemTapped,
      ),
    );
  }

  // build the floating action button
  Widget? _buildFloatingActionButton() {
    return _selectedIndex == 0
        ? FloatingActionButton(
            onPressed: _navigateToNewExpenseScreen,
            backgroundColor: const Color.fromRGBO(66, 66, 66, 1),
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          )
        : null;
  }

  // navigate to the import dataset screen
  void _navigateToImportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImportDatasetScreen()),
    );
  }

  // navigate to the new expense screen
  void _navigateToNewExpenseScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewExpenseScreen()),
    );
  }
}

// separate stateful widget for the expense list screen
class _ExpenseListScreen extends StatefulWidget {
  const _ExpenseListScreen();

  @override
  __ExpenseListScreenState createState() => __ExpenseListScreenState();
}

class __ExpenseListScreenState extends State<_ExpenseListScreen> {
  // currently selected year for filtering expenses
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMonthlyExpenseChart(),
        Expanded(child: _buildExpenseList()),
      ],
    );
  }

  // build the monthly expense chart
  Widget _buildMonthlyExpenseChart() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final expenses = provider.expenses;
        final yearlyExpenses = _calculateYearlyExpenses(expenses);

        return MonthlyExpenseBarChart(
          yearlyExpenses: yearlyExpenses,
          selectedYear: _selectedYear,
          onYearSelected: (year) => setState(() => _selectedYear = year),
        );
      },
    );
  }

  // build the expense list
  Widget _buildExpenseList() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final expenses = provider.expenses
            .where((expense) => expense.date.year == _selectedYear)
            .toList();

        if (expenses.isEmpty) {
          return const Center(child: Text('No expenses Added'));
        }

        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) => _buildExpenseListItem(expenses[index], provider),
        );
      },
    );
  }

  // build a single expense list item
  Widget _buildExpenseListItem(Expense expense, ExpenseProvider provider) {
    return MyListTile(
      expense: expense,
      editAction: (editedExpense) => _editExpense(context, provider, editedExpense),
      deleteAction: (deletedExpense) => _deleteExpense(context, provider, deletedExpense),
    );
  }

  // handle expense editing
  void _editExpense(BuildContext context, ExpenseProvider provider, Expense editedExpense) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewExpenseScreen(expense: editedExpense)),
    );
  }

  // handle expense deletion
  void _deleteExpense(BuildContext context, ExpenseProvider provider, Expense deletedExpense) {
    provider.deleteExpense(deletedExpense.id);
  }

  // calculate yearly expenses for the chart
  Map<int, List<MapEntry<DateTime, double>>> _calculateYearlyExpenses(List<Expense> expenses) {
    Map<int, Map<DateTime, double>> yearlyTotals = {};
    for (var expense in expenses) {
      int year = expense.date.year;
      DateTime month = DateTime(year, expense.date.month);
      yearlyTotals.putIfAbsent(year, () => {});
      yearlyTotals[year]![month] = (yearlyTotals[year]![month] ?? 0) + expense.amount;
    }

    return yearlyTotals.map((year, monthlyTotals) {
      var sortedEntries = monthlyTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      return MapEntry(year, sortedEntries);
    });
  }
}