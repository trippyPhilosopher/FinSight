import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import '../services/expense_provider.dart';
import '../models/expense.dart';

// widget for creating or editing an expense
class NewExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const NewExpenseScreen({super.key, this.expense});

  @override
  _NewExpenseScreenState createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _category;
  final TextEditingController _otherCategoryController = TextEditingController();
  late double _amount;
  late DateTime _date;

  // preset categories for the dropdown
  final List<String> _presetCategories = [
    'Food', 'Transportation', 'Household', 'Apparel', 'Education', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  // initialise form fields with existing expense data or defaults
  void _initializeFields() {
    _category = widget.expense?.category ?? _presetCategories.first;
    _amount = widget.expense?.amount ?? 0;
    _date = widget.expense?.date ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        title: Text(widget.expense == null ? 'New Expense' : 'Edit Expense'),
        backgroundColor: Colors.grey.shade300,
        ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildCategoryDropdown(),
            if (_category == 'Other') _buildOtherCategoryField(),
            _buildAmountField(),
            _buildDatePicker(),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // build the category dropdown
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _category,
      items: _presetCategories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _category = newValue!;
        });
      },
      validator: _validateCategory,
    );
  }

  // build the 'Other' category input field
  Widget _buildOtherCategoryField() {
    return TextFormField(
      controller: _otherCategoryController,
      decoration: const InputDecoration(labelText: 'Other Category'),
      validator: _validateOtherCategory,
    );
  }

  // build the amount input field
  Widget _buildAmountField() {
    return TextFormField(
      initialValue: _amount == 0 ? '' : _amount.toString(),
      decoration: const InputDecoration(labelText: 'Amount'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: _validateAmount,
      onSaved: (value) => _amount = double.parse(value!),
    );
  }

  // build the date picker
  Widget _buildDatePicker() {
    return ListTile(
      title: const Text('Date'),
      subtitle: Text(DateFormat('yyyy-MM-dd').format(_date)),
      onTap: _selectDate,
    );
  }

  // build the save button
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, 
        backgroundColor: const Color.fromRGBO(66, 66, 66, 1),
      ),
      child: const Text('Save Expense'),
    );
  }

  // validate the category selection
  String? _validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a category';
    }
    return null;
  }

  // validate the 'Other' category input
  String? _validateOtherCategory(String? value) {
    if (_category == 'Other' && (value == null || value.isEmpty)) {
      return 'Please enter a category';
    }
    return null;
  }

  // validate the amount input
  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    double? parsedValue = double.tryParse(value);
    if (parsedValue == null) {
      return 'Please enter a valid number';
    }
    if (parsedValue <= 0) {
      return 'Please enter a non-negative number';
    }
    return null;
  }

  // show date picker dialog
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _date = pickedDate;
      });
    }
  }

  // submit the form
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newExpense = Expense(
        id: widget.expense?.id ?? Isar.autoIncrement,
        category: _category == 'Other' ? _otherCategoryController.text : _category,
        amount: _amount,
        date: _date,
      );
      
      final expenseProvider = context.read<ExpenseProvider>();
      if (widget.expense == null) {
        expenseProvider.addExpense(newExpense);
      } else {
        expenseProvider.updateExpense(newExpense);
      }
      
      Navigator.pop(context);
    }
  }
}