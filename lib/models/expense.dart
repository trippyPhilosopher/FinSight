import 'package:isar/isar.dart';

part 'expense.g.dart';

@collection // database collection
class Expense {
  Id id = Isar.autoIncrement; // identifier for each expense with auto increment by the db

  @Index(type: IndexType.value) // create indexes on category
  late String category;

  late double amount;

  @Index(type: IndexType.value)// create indexes on date
  late DateTime date;

  // initialises an Expense object with category, amount, and date
  // id handled by the db
  Expense({
    this.id = Isar.autoIncrement,
    required this.category,
    required this.amount,
    required this.date,
  });
}

