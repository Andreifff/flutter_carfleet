import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_2/models/spending.dart';

class CurrencyService {
  final String apiKey = '5faf84befdff9e13c3101071';
  final String baseUrl = 'https://api.exchangerate-api.com/v4/latest/';
  // final String baseUrl =
  //     'https://v6.exchangerate-api.com/v6/5faf84befdff9e13c3101071/latest/RON';

  Future<double> getConversionRate(
      String baseCurrency, String targetCurrency) async {
    String fullUrl = '$baseUrl$baseCurrency';
    print("Fetching conversion rates from: $fullUrl");

    final response = await http.get(Uri.parse(fullUrl));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      double toRate =
          data['rates'][targetCurrency] ?? 1.0; // Rate from base to target
      double fromRate =
          1 / (data['rates'][baseCurrency] ?? 1.0); // Inverse rate for base

      double conversionRate = (baseCurrency == "USD" || targetCurrency == "USD")
          ? toRate
          : fromRate * toRate;

      print(
          'Conversion rate from $baseCurrency to $targetCurrency: $conversionRate');
      return conversionRate;
    } else {
      print('Failed to fetch rates: ${response.statusCode} ${response.body}');
      throw Exception('Failed to fetch currency rates');
    }
  }

  // Convert list of spendings to a specified base currency
  Future<List<Spending>> convertSpendingsToBaseCurrency(
      List<Spending> spendings, String baseCurrency) async {
    var rates = await fetchConversionRates(baseCurrency);
    List<Spending> convertedSpendings = [];
    for (var spending in spendings) {
      double rate = rates[spending.currency] ?? 1.0;
      double convertedAmount = spending.amount * (1 / rate);
      print(
          'Converting ${spending.amount} ${spending.currency} to $baseCurrency at rate $rate: $convertedAmount');
      convertedSpendings.add(Spending(
        id: spending.id,
        category: spending.category,
        amount: convertedAmount,
        odometer: spending.odometer,
        currency: baseCurrency,
        date: spending.date,
      ));
    }
    return convertedSpendings;
  }

  Future<Map<String, double>> fetchConversionRates(String baseCurrency) async {
    String fullUrl = '$baseUrl$baseCurrency';
    final response = await http.get(Uri.parse(fullUrl));
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      Map<String, double> rates = {};
      jsonResponse['rates'].forEach((key, value) {
        rates[key] = value.toDouble();
      });
      //print('Fetched rates for $baseCurrency: $rates');
      return rates;
    } else {
      throw Exception('Failed to fetch rates for $baseCurrency');
    }
  }
}
