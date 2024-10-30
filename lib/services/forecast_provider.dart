import 'package:flutter/foundation.dart';
import '../services/expense_forecaster.dart';

class ForecastProvider extends ChangeNotifier {
  final ExpenseForecaster _forecaster;
  List<Map<String, dynamic>> _forecastData = [];
  bool _isLoading = false;
  DateTime? _lastForecastTime;

  ForecastProvider(this._forecaster);

  List<Map<String, dynamic>> get forecastData => _forecastData;
  bool get isLoading => _isLoading;

  Future<void> loadForecast() async {
    if (_forecastData.isEmpty || _shouldRegenerateForecast()) {
      await generateForecast();
    }
  }

  bool _shouldRegenerateForecast() {
    if (_lastForecastTime == null) return true;
    return DateTime.now().difference(_lastForecastTime!) > const Duration(hours: 24);
  }

  Future<void> generateForecast() async {
    _isLoading = true;
    notifyListeners();

    try {
      final forecast = await _forecaster.forecastNextWeek();
      _forecastData = forecast;
      _lastForecastTime = DateTime.now();
    } catch (e) {
      print('Error generating forecast: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}