// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_application_2/models/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    _loadCurrencyPreference();
  }

  Future<void> _loadCurrencyPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString('selectedCurrency') ?? "EUR";
    });
  }

  String? _selectedCurrency = "EUR"; // Default currency
  bool _darkTheme = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Dark Theme'),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ),
          ListTile(
            title: Text("Preferred Currency"),
            trailing: DropdownButton<String>(
              value: _selectedCurrency,
              onChanged: (String? newValue) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('selectedCurrency', newValue!);
                setState(() {
                  _selectedCurrency = newValue;
                });
              },
              items: <String>[
                'EUR',
                'RON',
                'USD',
                'GBP',
                'AED',
                'AFN',
                'ALL',
                'AMD',
                'ANG',
                'AOA',
                'ARS',
                'AUD',
                'AWG',
                'AZN',
                'BAM',
                'BBD',
                'BDT',
                'BGN',
                'BHD',
                'BIF',
                'BMD',
                'BND',
                'BOB',
                'BOV',
                'BRL',
                'BSD',
                'BTN',
                'BWP',
                'BYN',
                'BZD',
                'CAD',
                'CDF',
                'CHE',
                'CHF',
                'CHW',
                'CLF',
                'CLP',
                'CNY',
                'COP',
                'COU',
                'CRC',
                'CUP',
                'CVE',
                'CZK',
                'DJF',
                'DKK',
                'DOP',
                'DZD',
                'EGP',
                'ERN',
                'ETB',
                'FJD',
                'FKP',
                'GEL',
                'GHS',
                'GIP',
                'GMD',
                'GNF',
                'GTQ',
                'GYD',
                'HKD',
                'HNL',
                'HTG',
                'HUF',
                'IDR',
                'ILS',
                'INR',
                'IQD',
                'IRR',
                'ISK',
                'JMD',
                'JOD',
                'JPY',
                'KES',
                'KGS',
                'KHR',
                'KMF',
                'KPW',
                'KRW',
                'KWD',
                'KYD',
                'KZT',
                'LAK',
                'LBP',
                'LKR',
                'LRD',
                'LSL',
                'LYD',
                'MAD',
                'MDL',
                'MGA',
                'MKD',
                'MMK',
                'MNT',
                'MOP',
                'MRU',
                'MUR',
                'MVR',
                'MWK',
                'MXN',
                'MXV',
                'MYR',
                'MZN',
                'NAD',
                'NGN',
                'NIO',
                'NOK',
                'NPR',
                'NZD',
                'OMR',
                'PAB',
                'PEN',
                'PGK',
                'PHP',
                'PKR',
                'PLN',
                'PYG',
                'QAR',
                'RSD',
                'RUB',
                'RWF',
                'SAR',
                'SBD',
                'SCR',
                'SDG',
                'SEK',
                'SGD',
                'SHP',
                'SLE',
                'SLL',
                'SOS',
                'SRD',
                'SSP',
                'STN',
                'SVC',
                'SYP',
                'SZL',
                'THB',
                'TJS',
                'TMT',
                'TND',
                'TOP',
                'TRY',
                'TTD',
                'TWD',
                'TZS',
                'UAH',
                'UGX',
                'USN',
                'UYI',
                'UYU',
                'UYW',
                'UZS',
                'VED',
                'VES',
                'VND',
                'VUV',
                'WST',
                'XAF',
                'XAG',
                'XAU',
                'XBA',
                'XBB',
                'XBC',
                'XBD',
                'XCD',
                'XDR',
                'XOF',
                'XPD',
                'XPF',
                'XPT',
                'XSU',
                'XTS',
                'XUA',
                'XXX',
                'YER',
                'ZAR',
                'ZMW',
                'ZWL'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
