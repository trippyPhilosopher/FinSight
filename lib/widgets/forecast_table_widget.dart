import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ForecastTableWidget extends StatelessWidget {
  final List<Map<String, dynamic>> forecastData;

  const ForecastTableWidget({super.key, required this.forecastData});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1.2),
            },
            border: TableBorder.all(
              color: Colors.grey.shade300,
              width: 1,
              borderRadius: BorderRadius.circular(8),
            ),
            children: [
              _buildTableHeader(),
              ..._buildRows(),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      children: const [
        _HeaderCell(text: 'Date'),
        _HeaderCell(text: 'Category'),
        _HeaderCell(text: 'Amount'),
      ],
    );
  }

  List<TableRow> _buildRows() {
    List<TableRow> rows = [];
    String? lastDate;

    for (var data in forecastData) {
      final currentDate = _formatDate(data['date']);

      if (lastDate != currentDate) {
        rows.add(_buildDateRow(currentDate));
        lastDate = currentDate;
      }

      rows.add(_buildDataRow(data));
    }

    return rows;
  }

  TableRow _buildDateRow(String date) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade300),
      children: [
        _DataCell(text: date, alignment: Alignment.centerLeft, fontWeight: FontWeight.bold),
        const _DataCell(text: ''),
        const _DataCell(text: ''),
      ],
    );
  }

  TableRow _buildDataRow(Map<String, dynamic> data) {
    final String category = data['category'] ?? 'Unknown Category';
    final double amount = data['amount'] ?? 0.0;

    return TableRow(
      children: [
        const _DataCell(text: ''),
        _DataCell(text: category, alignment: Alignment.centerLeft),
        _DataCell(
          text: NumberFormat.currency(symbol: 'LKR ', decimalDigits: 2).format(amount),
          alignment: Alignment.centerRight,
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    final DateTime date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy').format(date);
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final Alignment alignment;
  final FontWeight fontWeight;

  const _DataCell({
    required this.text,
    this.alignment = Alignment.center,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      alignment: alignment,
      child: Text(
        text,
        style: TextStyle(fontWeight: fontWeight),
      ),
    );
  }
}
