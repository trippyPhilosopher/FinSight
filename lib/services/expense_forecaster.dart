import 'package:isar/isar.dart';
import 'dart:math';
import '/models/expense.dart';

class ExpenseForecaster {
  // retrieving expense data
  final Isar isar;
  // number of decision trees in the RF
  final int numberOfTrees;
  // seed for the random number generator
  final Random random;
  // number of days to forecast
  final int forecastDays;
  // size of the sliding window
  final int windowsize;

  ExpenseForecaster(
    this.isar, {
    this.numberOfTrees = 10,
    int randomSeed = 42,
    this.forecastDays = 7,
    this.windowsize = 30,
  }) : random = Random(randomSeed);

  Future<List<Map<String, dynamic>>> forecastNextWeek() async {
    // retrieve all expenses from the database.
    final expenses = await isar.expenses.where().findAll();
    // Sort expenses by date in ascending order.
    expenses.sort((a, b) => a.date.compareTo(b.date));

    // group expenses by category.
    Map<String, List<Expense>> categorisedExpenses = _groupExpensesByCategory(expenses);
    // get categories with enough data for forecasting.
    List<String> validCategories = _getValidCategories(categorisedExpenses);
    // map to store forecasts for each category
    Map<String, List<double>> forecasts = {}; 

    for (var category in validCategories) {
      // get expenses for the current category.
      List<Expense> categoryExpenses = categorisedExpenses[category]!;

      // create features and lables
      List<List<double>> features = _createFeatures(categoryExpenses);
      List<double> labels = _createLabels(categoryExpenses);

      if (features.isNotEmpty && labels.isNotEmpty) {
        // train the random forest
        List<SimpleDT> forest = _trainRandomForest(features, labels);
        // generate forecasts for each category
        List<double> categoryForecast = _generateForecast(forest, categoryExpenses);
        // store the forecast.
        forecasts[category] = categoryForecast;
      }
    }
    // format and return the forecasts.
    return _formatForecast(forecasts);
  }

  // group expenses by their category.
  Map<String, List<Expense>> _groupExpensesByCategory(List<Expense> expenses) {
    Map<String, List<Expense>> grouped = {};
    for (var expense in expenses) {
      // add expense to its category.
      grouped.putIfAbsent(expense.category, () => []).add(expense);
    }
    return grouped;
  }

  // get categories with at least 30 expenses.
  List<String> _getValidCategories(Map<String, List<Expense>> categorisedExpenses) {
    return categorisedExpenses.entries
        // filter categories with enough data.
        .where((entry) => entry.value.length >= windowsize)
        // extract category names.
        .map((entry) => entry.key) 
        .toList();
  }

  // create feature sets from historical expenses
  List<List<double>> _createFeatures(List<Expense> expenses) {
    if (expenses.length < windowsize + 1) {
      return [];
    }
    
    List<List<double>> features = [];
    for (int i = 0; i <= expenses.length - windowsize - 1; i++) {
      features.add(expenses
          .sublist(i, i + windowsize)
          .map((expense) => expense.amount)
          .toList());
    }
    return features;
  }

  // create labels for forecasting from historical expenses
  List<double> _createLabels(List<Expense> expenses) {
    if (expenses.length < windowsize + 1) {
      return [];
    }
    
    return expenses
        .sublist(windowsize)
        .map((expense) => expense.amount)
        .toList();
  }

  // train multiple decision trees with bootstrap sampling
  List<SimpleDT> _trainRandomForest(List<List<double>> features, List<double> labels) {
    return List.generate(numberOfTrees, (_) {
      // create a decision tree model
      final model = SimpleDT(maxDepth: 5, random: random);
      List<int> sampleIndices = List.generate(
          // generate random sample indices.
          features.length, (_) => random.nextInt(features.length));

      List<List<double>> sampledFeatures =
          // sample features
          sampleIndices.map((index) => features[index]).toList();
      List<double> sampledLabels =
          // sample labels
          sampleIndices.map((index) => labels[index]).toList(); 
      // train the model
      model.fit(sampledFeatures, sampledLabels);
      return model;
    });
  }

  // generate forecasts using the trained random forest
  List<double> _generateForecast(List<SimpleDT> forest, List<Expense> expenses) {
    List<double> forecast = [];
    if (expenses.length < windowsize) {
      return forecast;
    }
    
    List<double> lastKnownAmounts = expenses
        .sublist(expenses.length - windowsize)
        .map((expense) => expense.amount)
        .toList();

    for (int i = 0; i < forecastDays; i++) {
      double prediction = forest
          .map((tree) => tree.forecast(lastKnownAmounts))
          .reduce((a, b) => a + b) / numberOfTrees;
      forecast.add(prediction);
      lastKnownAmounts = [...lastKnownAmounts.sublist(1), prediction];
    }

    return forecast;
  }

  // Format the forecast data for output.
  List<Map<String, dynamic>> _formatForecast(Map<String, List<double>> forecasts) {
    List<Map<String, dynamic>> formattedForecast = [];
    // start date for forecast.
    DateTime startDate = DateTime.now().add(const Duration(days: 1));

    for (int i = 0; i < forecastDays; i++) {
      for (var category in forecasts.keys) {
        formattedForecast.add({
          // add forecast date
          'date': startDate.add(Duration(days: i)).toIso8601String(),
          // add category.
          'category': category,
          // add forecast amount.
          'amount': forecasts[category]?[i] ?? 0.0,
        });
      }
    }
    // return formatted forecast
    return formattedForecast;
  }
}

class SimpleDT {
  final int maxDepth; // maximum depth of the decision tree
  late _Node root; // root node of the tree
  final Random random; // random number generator

  // Constructor with default max depth
  SimpleDT({this.maxDepth = 5, required this.random}); 

  void fit(List<List<double>> X, List<double> y) {
    // build the decision tree using features and labels
    root = _buildTree(X, y, 0); 
  }

  double forecast(List<double> features) {
    // forecast using the decision tree 
    return _forecast(features, root);
  }
  // recursively builds the decision tree based on feature splits
  _Node _buildTree(List<List<double>> X, List<double> y, int depth) {
    if (depth >= maxDepth || X.isEmpty || y.isEmpty) {
      // create a leaf node
      return _LeafNode(y.isNotEmpty ? y.reduce((a, b) => a + b) / y.length : 0);
    }

    int bestFeature = 0;
    double bestSplit = 0;
    double bestScore = double.infinity;

    for (int feature = 0; feature < X[0].length; feature++) {
      for (var value in X.map((x) => x[feature]).toSet()) {
        // split data
        var splitResult = _split(X, y, feature, value);
        // calculate variance
        double score = _calculateVariance(splitResult.leftY, splitResult.rightY);
        if (score < bestScore) {
          bestScore = score;
          bestFeature = feature;
          bestSplit = value;
        }
      }
    }

    var splitResult = _split(X, y, bestFeature, bestSplit); // Split data using the best feature and split value.
    var leftChild = _buildTree(splitResult.leftX, splitResult.leftY, depth + 1); // Build left subtree.
    var rightChild = _buildTree(splitResult.rightX, splitResult.rightY, depth + 1); // Build right subtree.

    return _InternalNode(bestFeature, bestSplit, leftChild, rightChild); // Return internal node.
  }

  // split data into left and right subsets (based on a feature and value)
  SplitResult _split(List<List<double>> X, List<double> y, int feature, double value) {
    List<List<double>> leftX = [], rightX = [];
    List<double> leftY = [], rightY = [];

    for (int i = 0; i < X.length; i++) {
      if (X[i][feature] <= value) {
        leftX.add(X[i]);
        leftY.add(y[i]);
      } else {
        rightX.add(X[i]);
        rightY.add(y[i]);
      }
    }
    // return split result
    return SplitResult(leftX, leftY, rightX, rightY);
  }

  // calculate the variance for a split to figure out the best feature and value
  double _calculateVariance(List<double> leftY, List<double> rightY) {
    double leftMean = leftY.isNotEmpty ? leftY.reduce((a, b) => a + b) / leftY.length : 0;
    double rightMean = rightY.isNotEmpty ? rightY.reduce((a, b) => a + b) / rightY.length : 0;
    
    // sum of squared deviations
    double score = leftY.fold(0.0, (sum, y) => sum + pow(y - leftMean, 2)) +
        rightY.fold(0.0, (sum, y) => sum + pow(y - rightMean, 2)); 

    return score; // Return variance score.
  }

  // recursively forecast using the decision tree.
  double _forecast(List<double> features, _Node node) {
    if (node is _LeafNode) {
      return node.value; // return value of leaf node.
    } else if (node is _InternalNode) {
      return features[node.feature] <= node.split
          ? _forecast(features, node.left) // recurse to left child.
          : _forecast(features, node.right); // recurse to right child.
    }
    throw Exception('Invalid node type');
  }
}

// node in the decision tree.
abstract class _Node {}

// holds a value for the leaf node
class _LeafNode extends _Node {
  final double value; // value of the leaf node.
  _LeafNode(this.value); // constructor.
}

// internal node containing a feature, split value, and left/right children.
class _InternalNode extends _Node {
  final int feature; // feature used for splitting.
  final double split; // value used for splitting.
  final _Node left; // left child node.
  final _Node right; // right child node.
  _InternalNode(this.feature, this.split, this.left, this.right); // constructor.
}

// class representing the result of a data split.
class SplitResult {
  final List<List<double>> leftX; // left subset of features.
  final List<double> leftY; // left subset of labels.
  final List<List<double>> rightX; // right subset of features.
  final List<double> rightY; // right subset of labels.

  SplitResult(this.leftX, this.leftY, this.rightX, this.rightY); // constructor.
}
