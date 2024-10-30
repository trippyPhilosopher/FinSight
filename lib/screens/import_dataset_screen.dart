import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/expense_provider.dart';
import '../models/expense.dart';

class ImportDatasetScreen extends StatefulWidget {
  const ImportDatasetScreen({super.key});

  @override
  _ImportDatasetScreenState createState() => _ImportDatasetScreenState();
}

class _ImportDatasetScreenState extends State<ImportDatasetScreen> {
  // stores the list of processed expenses ready for saving
  List<Expense> _processedExpenses = [];
  // for whether the app currently processing the CSV
  bool _isLoading = false;


  Future<void> _importCSV() async {
    // opens a file picker for CSV
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    
    // read and parse the selected CSV into a list of lists
    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        File file = File(result.files.single.path!);
        final input = file.openRead();
        final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList();
        
        // checks for empty or invalid CSV content
        if (fields.isEmpty || fields.length == 1) {
          throw const FormatException('CSV file is empty or contains only the header.');
        }
        
        // preprocess the data and update the state
        setState(() {
          _processedExpenses = _preprocessData(fields);
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing CSV file: $e')),
        );
      }
    }
  }
  // iterate over CSV rows to create Expense objcts
  List<Expense> _preprocessData(List<List<dynamic>> rawData) {
    List<Expense> processedData = [];

    for (var i = 1; i < rawData.length; i++) {
      try {
        // handle malformed rows and errors during processing
        if (rawData[i].length < 3) {
          throw FormatException('Row $i is malformed.');
        }
        processedData.add(_createExpenseFromRow(rawData[i]));
      } catch (e) {
        print('Error processing row $i: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing row $i: $e')),
        );
      }
    }

    return processedData;
  }
  // convert a row from the CSV into an Expense object
  Expense _createExpenseFromRow(List<dynamic> row) {
    // parses the date, trim the category, and convert the amount.
    DateTime date = _parseDate(row[0]);
    String category = row[1].toString().trim();
    double amount = double.parse(row[2].toString());

    return Expense(
      date: date,
      category: category,
      amount: amount,
    );
  }

  DateTime _parseDate(dynamic dateString) {
    // trying parse a date string using multiple formats
    List<String> formats = ['yyyy-MM-dd', 'MM/dd/yyyy', 'dd/MM/yyyy'];
    for (String format in formats) {
      try {
        return DateFormat(format).parse(dateString.toString());
      } catch (_) {
        // If this format doesn't work, try the next one
      }
    }
    // throw an exception if no valid format
    throw FormatException('Unable to parse date: $dateString');
  }

  Future<void> _saveProcessedData() async {
    setState(() {
      _isLoading = true;
    });

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    // Sort expenses by date in descending order
    _processedExpenses.sort((a, b) => b.date.compareTo(a.date));

    // Add expenses to the ExpenseProvider
    for (var expense in _processedExpenses) {
      await expenseProvider.addExpense(expense);
    }
    // updates the state and navigates back after saving
    setState(() {
      _isLoading = false;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        title: const Text('Import Dataset'),
        backgroundColor: Colors.grey.shade300,
      ),
      // loading indicator
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildImportButton(),
                  const SizedBox(height: 20),
                  Text('Processed Expenses: ${_processedExpenses.length}'),
                  const SizedBox(height: 20),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }
  // import button
  Widget _buildImportButton() {
    return ElevatedButton(
      onPressed: _importCSV,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromRGBO(66, 66, 66, 1),
      ),
      child: const Text('Select CSV File'),
    );
  }
  // save button
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _processedExpenses.isNotEmpty ? _saveProcessedData : null,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromRGBO(66, 66, 66, 1),
      ),
      child: const Text('Save Processed Data'),
    );
  }
}