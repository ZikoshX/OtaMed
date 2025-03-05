// ignore: unused_import
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

class CsvService {
  List<List<dynamic>> _data = [];

  Future<void> loadCSV() async {
    final rawData = await rootBundle.loadString("assets/data.csv");
    _data = const CsvToListConverter().convert(rawData);
  }

  List<List<dynamic>> filterData({String? category, String? country, String? city}) {
    return _data.where((row) {
      final matchesCategory = category == null || row[1] == category;
      final matchesCountry = country == null || row[2] == country;
      final matchesCity = city == null || row[3] == city;
      return matchesCategory && matchesCountry && matchesCity;
    }).toList();
  }

  List<List<dynamic>> get data => _data;
}
