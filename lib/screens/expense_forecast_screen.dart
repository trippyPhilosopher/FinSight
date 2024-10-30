import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/forecast_provider.dart';
import '../widgets/forecast_bar_chart.dart';
import '../widgets/forecast_table_widget.dart';

class ExpenseForecastScreen extends StatefulWidget {
  const ExpenseForecastScreen({super.key});

  @override
  _ExpenseForecastScreenState createState() => _ExpenseForecastScreenState();
}

class _ExpenseForecastScreenState extends State<ExpenseForecastScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    return Consumer<ForecastProvider>(
      builder: (context, forecastProvider, child) {
        if (forecastProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (forecastProvider.forecastData.isEmpty) {
          return const Center(child: Text('No forecast data available'));
        } else {
          return _buildForecastContent(forecastProvider.forecastData);
        }
      },
    );
  }

  Widget _buildForecastContent(List<Map<String, dynamic>> forecastData) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          ForecastBarChart(forecastData: forecastData),
          ForecastTableWidget(forecastData: forecastData),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'Next Week\'s Expense Forecast',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => context.read<ForecastProvider>().generateForecast(),
      tooltip: 'Regenerate Forecast',
      backgroundColor: const Color.fromRGBO(66, 66, 66, 1),
      foregroundColor: Colors.white,
      child: const Icon(Icons.refresh),
    );
  }
}
