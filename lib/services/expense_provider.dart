import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../models/expense.dart';

// extends ChangeNotifier, allowing it to notify listeners of changes
class ExpenseProvider with ChangeNotifier {
  // isar db reference
  final Isar isar;
  //for maintain the state of expenses and categories
  List<Expense> _expenses = [];
  List<String> _categories = [];

  // initialise isar instance
  ExpenseProvider(this.isar);

  List<Expense> get expenses => _expenses;
  List<String> get categories => _categories;

  // load all expenses from the database
  Future<void> loadExpenses() async {
    _expenses = await isar.expenses.where().sortByDateDesc().findAll();
    notifyListeners();
  }

  // add a new expense to the database
  Future<void> addExpense(Expense expense) async {
    await _writeExpense(expense);
    await loadExpenses();
  }

  // update an existing expense in the database
  Future<void> updateExpense(Expense expense) async {
    await _writeExpense(expense);
    await loadExpenses();
  }

  // delete an expense from the database
  Future<void> deleteExpense(Id id) async {
    await isar.writeTxn(() async {
      await isar.expenses.delete(id);
    });
    await loadExpenses();
  }

  // helper method to write an expense to the database
  Future<void> _writeExpense(Expense expense) async {
    await isar.writeTxn(() async {
      await isar.expenses.put(expense);
    });
  }

  // load unique categories from the database
  Future<List<String>> loadCategories() async {
    final expenses = await isar.expenses.where().findAll();
    _categories = expenses.map((e) => e.category).toSet().toList()..sort();
    notifyListeners();
    return _categories;
  }
}