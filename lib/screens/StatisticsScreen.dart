import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_2/models/car.dart';
import 'package:flutter_application_2/models/spending.dart';
import 'package:flutter_application_2/services/utilities.dart'; // Assuming this exists and has CurrencyUtil

class StatisticsScreen extends StatefulWidget {
  final Car car;

  const StatisticsScreen({Key? key, required this.car}) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Spending> spendings = [];
  String selectedCurrency = 'USD'; // Default currency
  DateTime startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime endDate = DateTime(DateTime.now().year, 12, 31);
  @override
  void initState() {
    super.initState();
    fetchSpendings();
  }

  Future<void> fetchSpendings() async {
    final spendingsSnapshot = await FirebaseFirestore.instance
        .collection('cars')
        .doc(widget.car.id)
        .collection('spendings')
        .get();

    List<Spending> fetchedSpendings = spendingsSnapshot.docs.map((doc) {
      return Spending.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    setState(() {
      spendings = fetchedSpendings;
    });
  }

  double convertAmountToSelectedCurrency(double amount, String currency) {
    Map<String, double> conversionRates = {
      'USD': 1.0,
      'EUR': 1.18,
      'RON': 0.24,
      // Add other mock rates here
    };

    // Convert amount from original currency to USD
    double amountInUSD = amount / (conversionRates[currency] ?? 1.0);
    // Convert USD to selected currency
    return amountInUSD * (conversionRates[selectedCurrency] ?? 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics for ${widget.car.make} ${widget.car.model}'),
        actions: [
          DropdownButton<String>(
            value: selectedCurrency,
            icon: Icon(Icons.arrow_downward),
            onChanged: (String? newValue) {
              setState(() {
                selectedCurrency = newValue!;
              });
            },
            items: CurrencyUtil.currencies
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (spendings.isNotEmpty)
              Container(
                height: 300, // Specify a fixed height for the chart
                child: PieChart(
                  PieChartData(
                    sections: _getPieChartSections(),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections() {
    Map<String, double> categoryTotals = {};
    for (var spending in spendings) {
      String category = spending.category;
      double amount =
          convertAmountToSelectedCurrency(spending.amount, spending.currency);

      categoryTotals.update(
          category, (existingAmount) => existingAmount + amount,
          ifAbsent: () => amount);
    }

    int index = 0;
    // Adjust these values as needed for better visibility and readability
    final double radius = 110; // Increase the radius for a bigger chart
    final double fontSize = 14; // Adjust font size for better readability
    final double titlePositionPercentageOffset =
        0.55; // Adjust title position closer or farther from the center

    return categoryTotals.entries.map((entry) {
      final color = Colors.primaries[index % Colors.primaries.length];
      index++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title:
            '${entry.key}: ${entry.value.toStringAsFixed(2)} $selectedCurrency',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: titlePositionPercentageOffset,
      );
    }).toList();
  }
}
