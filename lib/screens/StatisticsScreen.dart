import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/models/car.dart';
import 'package:flutter_application_2/models/spending.dart';
import 'package:flutter_application_2/services/currency_service.dart';
import 'package:flutter_application_2/services/utilities.dart';

class StatisticsScreen extends StatefulWidget {
  final Car car;

  const StatisticsScreen({Key? key, required this.car}) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Spending> spendings = [];
  Map<String, double> conversionRates = {};
  Map<String, double> rates = {};
  String selectedCurrency =
      'USD'; // Default currency// Default currency set to EUR

  @override
  void initState() {
    super.initState();
    //conversionRates = getConversionRates();
    //fetchSpendings();
    fetchAndConvertSpendings();
    CurrencyService()
        .fetchConversionRates(selectedCurrency)
        .then((fetchedRates) {
      setState(() {
        rates = fetchedRates;
      });
    }).catchError((error) {
      print('Error fetching rates: $error');
    });
  }

  // Map<String, double> getConversionRates() {
  //   // Mock conversion rates, replace with actual rates from your API or database
  //   return {'USD': 1.0, 'EUR': 1.18, 'RON': 0.22, 'GBP': 1.30};
  // }

  Map<DateTime, double> spendingByDate = {};

  void aggregateAndConvertSpendings() {
    Map<DateTime, double> tempMap = {};
    for (var spending in spendings) {
      DateTime date =
          DateTime(spending.date.year, spending.date.month, spending.date.day);
      double convertedAmount =
          convertAmountToSelectedCurrency(spending.amount, spending.currency);
      tempMap[date] = (tempMap[date] ?? 0) + convertedAmount;
    }

    setState(() {
      spendingByDate = tempMap;
    });

    print("Aggregated Spending Dates: ${spendingByDate.keys.toList()}");
    print("Aggregated Spending Values: ${spendingByDate.values.toList()}");
  }

//kindofworks

  void fetchAndConvertSpendings() async {
    try {
      await fetchSpendings();
      print("Spendings after fetch: ${spendings.length}"); // Debug print

      var rates =
          await CurrencyService().fetchConversionRates(selectedCurrency);
      print("Conversion Rates: $rates"); // Debug print

      List<Spending> convertedSpendings = [];
      for (var spending in spendings) {
        double rate = rates[spending.currency] ?? 1.0;
        double convertedAmount = spending.amount * (1 / rate);
        convertedSpendings.add(Spending(
          id: spending.id,
          category: spending.category,
          amount: convertedAmount,
          odometer: spending.odometer,
          currency: selectedCurrency,
          date: spending.date,
        ));
      }

      print("Converted Spendings: ${convertedSpendings.length}"); // Debug print

      setState(() {
        spendings = convertedSpendings;
      });
    } catch (e) {
      print('Error fetching or converting spendings: $e');
    }
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

    // Directly update the state here inside fetchSpendings
    setState(() {
      spendings = fetchedSpendings;
    });
  }

  double convertAmountToSelectedCurrency(double amount, String currency) {
    double rateFrom =
        conversionRates[currency] ?? 1.0; // Fallback to 1 if no rate found
    double rateTo = conversionRates[selectedCurrency] ??
        1.0; // Fallback to 1 if no rate found
    double convertedAmount = (amount / rateFrom) * rateTo;
    print(
        "Converting $amount from $currency to $selectedCurrency at rate $rateFrom to $rateTo results in $convertedAmount");
    return convertedAmount;
  }

  List<PieChartSectionData> _getPieChartSections() {
    Map<String, double> categoryTotals = {};
    for (var spending in spendings) {
      double convertedAmount =
          convertAmountToSelectedCurrency(spending.amount, spending.currency);
      categoryTotals.update(
          spending.category, (existing) => existing + convertedAmount,
          ifAbsent: () => convertedAmount);
    }

    int index = 0;
    final double radius = 110; // Chart radius
    final double fontSize = 12; // Font size for labels

    return categoryTotals.entries.map((entry) {
      final color = Colors.primaries[index++ % Colors.primaries.length];
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
      );
    }).toList();
  }

  List<FlSpot> getSpots() {
    List<FlSpot> spots = [];
    List<DateTime> sortedDates = spendingByDate.keys.toList()..sort();
    for (var date in sortedDates) {
      spots.add(FlSpot(
          date.millisecondsSinceEpoch.toDouble(), spendingByDate[date]!));
      print(
          "Spot: X=${date.millisecondsSinceEpoch.toDouble()}, Y=${spendingByDate[date]}");
    }
    return spots;
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: getSpots(),
          isCurved: true,
          barWidth: 2,
          color: Colors.blue,
          belowBarData: BarAreaData(show: false),
          dotData: FlDotData(show: false),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    print("Building Chart with spots: ${getSpots().length}");
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
                fetchAndConvertSpendings(); // Trigger data fetching and conversion
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
                height:
                    300, // Fixed height for the entire block containing the pie chart
                child: PieChart(
                  PieChartData(
                    sections: _getPieChartSections(),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
            SizedBox(height: 24),
            // Text("Spending Over Time",
            //     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              height: 220,
              child: LineChart(mainData()),
            ),
          ],
        ),
      ),
    );
  }
}
