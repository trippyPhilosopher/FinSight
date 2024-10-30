import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ForecastBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> forecastData;

  // predefined color palette for the bars
  final List<Color> colors = const [
    Color.fromRGBO(66, 66, 66, 1),
    Color.fromRGBO(96, 96, 96, 1),
    Color.fromRGBO(128, 128, 128, 1),
    Color.fromRGBO(160, 160, 160, 1),
    Color.fromRGBO(192, 192, 192, 1),
    Color.fromRGBO(208, 208, 208, 1),
    Color.fromRGBO(224, 224, 224, 1),
    Color.fromRGBO(240, 240, 240, 1),
  ];

  ForecastBarChart({super.key, required this.forecastData});

  // scroll controller to make sure it scrolls to the end/latest month
  final ScrollController _scrollController = ScrollController();

  void scrollToEnd() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    // calculate the maximum Y value and add 10% padding
    final double maxY = _getMaxAmount();
    final double chartMaxY = maxY * 1.5;

    // get unique categories and dates for the chart
    final uniqueCategories = _getUniqueCategories();
    final uniqueDates = _getUniqueDates();

    return SizedBox(
      height: 300,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            // set width based on the number of unique dates
            width: uniqueDates.length * 100,
            child: BarChart(
              BarChartData(
                gridData: _buildGridData(chartMaxY),
                borderData: FlBorderData(show: false),
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMaxY,
                barTouchData: _buildBarTouchData(),
                titlesData: _buildTitlesData(chartMaxY),
                barGroups: _createBarGroups(uniqueCategories, uniqueDates, chartMaxY),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // calculate the maximum amount from the forecast data
  double _getMaxAmount() {
    return forecastData.isEmpty
        ? 100.0
        : forecastData
            .map((e) => (e['amount'] as double?) ?? 0.0)
            .reduce((a, b) => a > b ? a : b);
  }

  // get a list of unique categories from the forecast data
  List<String> _getUniqueCategories() {
    return forecastData
        .map((e) => (e['category'] as String?) ?? '')
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
  }

  // get a list of unique dates from the forecast data
  List<String> _getUniqueDates() {
    return forecastData
        .map((e) => (e['date'] as String?) ?? '')
        .where((date) => date.isNotEmpty)
        .toSet()
        .toList();
  }

  // build the grid data for the chart
  FlGridData _buildGridData(double chartMaxY) {
    final interval = chartMaxY / 5;
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval != 0 ? interval : 1.0,
      getDrawingHorizontalLine: (value) => FlLine(
        color: Colors.grey[300],
        strokeWidth: 1,
      ),
    );
  }

  // build the touch data for interactive tooltips
  BarTouchData _buildBarTouchData() {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        tooltipRoundedRadius: 8,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final data = forecastData[groupIndex * _getUniqueCategories().length + rodIndex];
          return BarTooltipItem(
            '${data['category']}\n${NumberFormat.currency(symbol: '').format(data['amount'])}',
            const TextStyle(color: Colors.white),
          );
        },
        fitInsideHorizontally: true,
        fitInsideVertically: true,
      ),
      handleBuiltInTouches: true,
    );
  }

  // build the titles data for X and Y axes
  FlTitlesData _buildTitlesData(double chartMaxY) {
    return FlTitlesData(
      show: true,
      // Bottom titles (dates)
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (double value, TitleMeta meta) {
            final index = value.toInt();
            final uniqueDates = _getUniqueDates();
            if (index >= 0 && index < uniqueDates.length) {
              final date = DateTime.parse(uniqueDates[index]);
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('MM/dd').format(date),
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

  // create the bar groups for the chart
  List<BarChartGroupData> _createBarGroups(List<String> uniqueCategories, List<String> uniqueDates, double chartMaxY) {
    return uniqueDates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;

      final bars = uniqueCategories.asMap().entries.map((catEntry) {
        final catIndex = catEntry.key;
        final category = catEntry.value;

        // find the amount for this category and date, or use 0.0 if not found
        final amount = forecastData.firstWhere(
              (e) => e['category'] == category && e['date'] == date,
              orElse: () => {'amount': 0.0},
            )['amount'] as double? ??
            0.0;

        return BarChartRodData(
          toY: amount,
          color: colors[catIndex % colors.length],
          width: 15,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: chartMaxY,
            color: Colors.grey[200],
          ),
        );
      }).toList();

      return BarChartGroupData(
        x: index,
        barsSpace: 2,
        barRods: bars,
      );
    }).toList();
  }
}
