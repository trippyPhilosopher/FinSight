import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../services/expense_provider.dart';

class PieChartScreen extends StatefulWidget {
  const PieChartScreen({super.key});

  @override
  State<StatefulWidget> createState() => _PieChartScreenState();
}

class _PieChartScreenState extends State<PieChartScreen> {
  int touchedIndex = -1;
  late DateTime _selectedMonth;

  // predefined colors for the pie chart sections
  final List<Color> predefinedColors = [
    const Color.fromRGBO(66, 66, 66, 1),
    const Color.fromRGBO(96, 96, 96, 1),
    const Color.fromRGBO(128, 128, 128, 1),
    const Color.fromRGBO(160, 160, 160, 1),
    const Color.fromRGBO(192, 192, 192, 1),
    const Color.fromRGBO(208, 208, 208, 1),
    const Color.fromRGBO(224, 224, 224, 1),
    const Color.fromRGBO(240, 240, 240, 1),
  ];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildMonthSelector(),
        Expanded(
          child: Consumer<ExpenseProvider>(
            builder: (context, expenseProvider, child) {
              final monthlyExpenses = _getMonthlyExpenses(expenseProvider.expenses);
              final totalAmount = _calculateTotalAmount(monthlyExpenses);
              final categoryTotals = _calculateCategoryTotals(monthlyExpenses);

              return Column(
                children: <Widget>[
                  const SizedBox(height: 28),
                  _buildTotalMonthlyCost(totalAmount),
                  const SizedBox(height: 18),
                  _buildPieChart(categoryTotals),
                  const SizedBox(height: 18),
                  _buildCategoryDetails(categoryTotals),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // build the month selector widget
  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _decrementMonth,
        ),
        Text(DateFormat('MMMM yyyy').format(_selectedMonth)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _incrementMonth,
        ),
      ],
    );
  }

  // increment the selected month
  void _incrementMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  // decrement the selected month
  void _decrementMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  // build the total monthly cost widget
  Widget _buildTotalMonthlyCost(double totalAmount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        'Total Monthly Cost: LKR ${totalAmount.toStringAsFixed(2)}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  // build the pie chart widget
  Widget _buildPieChart(Map<String, double> categoryTotals) {
    return AspectRatio(
      aspectRatio: 2,
      child: PieChart(
        PieChartData(
          sections: _generatePieChartSections(categoryTotals),
          pieTouchData: PieTouchData(
            touchCallback: _handlePieChartTouch,
          ),
        ),
      ),
    );
  }

  // generate pie chart sections
  List<PieChartSectionData> _generatePieChartSections(Map<String, double> categoryTotals) {
    final sortedCategories = categoryTotals.keys.toList()..sort();
    return sortedCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final value = categoryTotals[category]!;
      final color = predefinedColors[index % predefinedColors.length];
      return PieChartSectionData(
        color: color,
        value: value,
        radius: 50,
        title: '',
      );
    }).toList();
  }

  // handle pie chart touch events
  void _handlePieChartTouch(FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
    setState(() {
      if (event is! PointerExitEvent &&
          event is! PointerUpEvent &&
          pieTouchResponse != null &&
          pieTouchResponse.touchedSection != null) {
        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
      } else {
        touchedIndex = -1;
      }
    });
  }

  // build category details widget
  Widget _buildCategoryDetails(Map<String, double> categoryTotals) {
    final sortedCategories = categoryTotals.keys.toList()..sort();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedCategories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final amount = categoryTotals[category]!;
        final color = predefinedColors[index % predefinedColors.length];

        return _buildCategoryDetailItem(category, amount, color);
      }).toList(),
    );
  }

  // build a single category detail item
  Widget _buildCategoryDetailItem(String category, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            category,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            'LKR ${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // get expenses for the selected month
  List<Expense> _getMonthlyExpenses(List<Expense> expenses) {
    return expenses.where((expense) =>
        expense.date.month == _selectedMonth.month &&
        expense.date.year == _selectedMonth.year).toList();
  }

  // calculate total amount for the given expenses
  double _calculateTotalAmount(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  // calculate category totals for the given expenses
  Map<String, double> _calculateCategoryTotals(List<Expense> expenses) {
    Map<String, double> categoryTotals = {};

    for (var expense in expenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return categoryTotals;
  }
}