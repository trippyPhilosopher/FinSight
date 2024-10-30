import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MonthlyExpenseBarChart extends StatelessWidget {
  final Map<int, List<MapEntry<DateTime, double>>> yearlyExpenses;
  final int selectedYear;
  final Function(int) onYearSelected;

  // constant for chart padding
  static const double _chartPadding = 1.1;

  MonthlyExpenseBarChart({
    super.key,
    required this.yearlyExpenses,
    required this.selectedYear,
    required this.onYearSelected,
  });

  // scroll conntroller to make sure it scrolls to the end/latest month
  final ScrollController _scrollController = ScrollController();
  void scrollToEnd(){
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
     duration: const Duration(seconds: 1), 
     curve: Curves.fastOutSlowIn);
  }

  @override
  Widget build(BuildContext context) {
    final expenses = yearlyExpenses[selectedYear] ?? [];
    final double maxY = expenses.isEmpty ? 100 : expenses.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double chartMaxY = maxY * _chartPadding; // add padding to the top

    return Column(
      children: [
        _buildYearSelector(context),
        SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: expenses.isEmpty
                ? const Center(child: Text('No expenses Added'))
                : SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: max(MediaQuery.of(context).size.width - 32, expenses.length * 40.0),
                    child: BarChart(BarChartData(
                        gridData: _buildGridData(chartMaxY),
                        borderData: FlBorderData(show: false),
                        alignment: BarChartAlignment.spaceAround,
                        maxY: chartMaxY,
                        barTouchData: _buildBarTouchData(),
                        titlesData: _buildTitlesData(expenses, chartMaxY),
                        barGroups: _buildBarGroups(expenses, chartMaxY),
                      )),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  // build grid data for the chart
  FlGridData _buildGridData(double chartMaxY) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: chartMaxY / 5,
      getDrawingHorizontalLine: (value) => FlLine(
        color: Colors.grey[300],
        strokeWidth: 1,
      ),
    );
  }

  // build touch data for interactive tooltips
  BarTouchData _buildBarTouchData() {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          return BarTooltipItem(
            NumberFormat.compactCurrency(symbol: 'LKR').format(rod.toY),
            const TextStyle(color: Colors.white),
          );
        },
        fitInsideHorizontally: true,
      fitInsideVertically: true,
      ),
      handleBuiltInTouches: true,
    );
  }

  // build titles data for X and Y axes
  FlTitlesData _buildTitlesData(List<MapEntry<DateTime, double>> expenses, double chartMaxY) {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (double value, TitleMeta meta) {
            if (value.toInt() >= 0 && value.toInt() < expenses.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('MMM').format(expenses[value.toInt()].key),
                  style: const TextStyle(color: Colors.black, fontSize: 10),
                ),
              );
            }
            return const SizedBox();
          },
          reservedSize: 40,
        ),
      ),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  // build bar groups for the chart
  List<BarChartGroupData> _buildBarGroups(List<MapEntry<DateTime, double>> expenses, double chartMaxY) {
    return List.generate(expenses.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: expenses[index].value,
            color: const Color.fromRGBO(66, 66, 66, 1),
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: chartMaxY,
              color: Colors.grey[200],
            ),
          ),
        ],
      );
    });
  }

  // build year selector dropdown
  Widget _buildYearSelector(BuildContext context) {
    List<int> years = yearlyExpenses.keys.toList()..sort(); // Sort in descending order

    // return an empty container, If there are no years in the dataset
    if (years.isEmpty) {
      return Container();
    }

    // use the most recent year as the default if the selectedYear is not in the list
    int currentSelectedYear = years.contains(selectedYear) ? selectedYear : years.first;


    return DropdownButton<int>(
    value: currentSelectedYear,
    items: years.map((int year) {
      return DropdownMenuItem<int>(
        value: year,
        child: Text(year.toString()),
      );
    }).toList(),
    onChanged: (int? newValue) {
      if (newValue != null) {
        onYearSelected(newValue);
        }
      },
    );
  }
}