import 'package:csv/csv.dart';
// ignore: unused_import
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

var logger = Logger();

Future<void> uploadCSVtoFirestore() async {
  // Load CSV from assets
  final rawData = await rootBundle.loadString("parsing/parse_kz.csv");

  // Parse CSV
  List<List<dynamic>> rows = const CsvToListConverter().convert(rawData);

  // Get Firestore instance
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Assuming first row is headers
  List<String> headers = rows[0].map((e) => e.toString()).toList();

  // Upload rows to Firestore
  for (int i = 1; i < rows.length; i++) {
    Map<String, dynamic> clinic = {};
    for (int j = 0; j < headers.length; j++) {
      // Replace invalid characters in field names
      String key = headers[j].replaceAll(RegExp(r'[./\[\]#?]'), '_').trim();
      clinic[key] = rows[i][j]?.toString().trim() ?? ''; // Ensure value is a string
    }

    // Generate a safe document ID
    String documentId = (clinic["name"] ?? clinic["address"] ?? "clinic_$i")
        .replaceAll(RegExp(r'[ ./\[\]#?]'), '_') // Remove invalid characters
        .toLowerCase()
        .trim();

    // Ensure the document ID is not empty
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
