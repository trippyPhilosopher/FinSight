import 'package:expense_tracker/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class MyListTile extends StatelessWidget {
  final Expense expense;
  final Function(Expense) editAction;
  final Function(Expense) deleteAction;

  const MyListTile({
    super.key,
    required this.expense,
    required this.editAction,
    required this.deleteAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
      child: Slidable(
        key: ValueKey(expense.id),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.35,
          children: [
            SlidableAction(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(4),
              icon: Icons.edit,
              onPressed: (context) => editAction(expense),
            ),
            SlidableAction(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(4),
              icon: Icons.delete,
              onPressed: (context) => deleteAction(expense),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            title: Row(
              children: [
                Expanded(child: Text(expense.category)),
                Text('LKR ${expense.amount.toStringAsFixed(0)}'),
              ],
            ),
            subtitle: Text(DateFormat('yyyy-MM-dd').format(expense.date)),
          ),
        ),
      ),
    );
  }
}
