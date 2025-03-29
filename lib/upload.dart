import 'package:csv/csv.dart';
// ignore: unused_import
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

var logger = Logger();

Future<void> uploadCSVtoFirestore() async {
  final rawData = await rootBundle.loadString("parsing/kaz.csv");
  List<List<dynamic>> rows = const CsvToListConverter().convert(rawData);
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<String> headers = rows[0].map((e) => e.toString()).toList();
  for (int i = 1; i < rows.length; i++) {
    Map<String, dynamic> clinic = {};
    for (int j = 0; j < headers.length; j++) {
      String key = headers[j].replaceAll(RegExp(r'[./\[\]#?]'), '_').trim();
      clinic[key] = rows[i][j]?.toString().trim() ?? ''; 
    }
    String documentId = (clinic["name"] ?? clinic["address"] ?? "clinic_$i")
        .replaceAll(RegExp(r'[ ./\[\]#?]'), '_') 
        .toLowerCase()
        .trim();
    if (documentId.isEmpty) {
      documentId = "clinic_$i";
    }

    try {
      await firestore.collection("clinics").doc(documentId).set(clinic);
      logger.w("Uploaded: $documentId");
    } catch (e) {
      logger.e("Error uploading clinic: ${e.toString()}");
    }
  }

  logger.w("CSV data uploaded successfully!");
}
