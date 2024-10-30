import 'package:expense_tracker/services/forecast_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import 'screens/home_screen.dart';
import 'screens/new_expense_screen.dart';
import 'screens/import_dataset_screen.dart';
import 'screens/pie_chart_screen.dart';
import 'services/expense_provider.dart';
import 'models/expense.dart';
import 'screens/expense_forecast_screen.dart';
import 'services/expense_forecaster.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [ExpenseSchema],
    directory: dir.path,
    inspector: true,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ExpenseProvider(isar)),
        Provider<ExpenseForecaster>(
          create: (_) => ExpenseForecaster(isar),
        ),
        ChangeNotifierProxyProvider<ExpenseForecaster, ForecastProvider>(
          create: (context) => ForecastProvider(context.read<ExpenseForecaster>()),
          update: (context, forecaster, previous) => 
            previous ?? ForecastProvider(forecaster),
        ),
      ],
      child: MaterialApp(
        title: 'Expense Tracker',
        theme: ThemeData(
          primarySwatch: Colors.grey,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
        routes: {
          '/new_expense': (context) => const NewExpenseScreen(),
          '/import_dataset': (context) => const ImportDatasetScreen(),
          '/piechart': (context) => const PieChartScreen(),
          '/forecast': (context) => const ExpenseForecastScreen(),
        },
      ),
    ),
  );
}
