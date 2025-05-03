import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

var logger = Logger();

Future<void> uploadCSVtoFirestore({int start = 1, int? end}) async {
  try {
    final rawData = await rootBundle.loadString("parsing/parse_others.csv");
    logger.i('✅ CSV Data loaded');

    List<List<dynamic>> rows = const CsvToListConverter().convert(rawData);
    List<String> headers = rows[0].map((e) => e.toString()).toList();

    end ??= rows.length; 

    final selectedRows = rows.sublist(start, end);
    final firestore = FirebaseFirestore.instance;

    WriteBatch batch = firestore.batch();
    int batchSize = 0;

  for (int i = 0; i < selectedRows.length; i++) {
  try {
    Map<String, dynamic> clinic = {};

    for (int j = 0; j < headers.length; j++) {
      String key = headers[j].replaceAll(RegExp(r'[./\[\]#?]'), '_').trim();
      var value = selectedRows[i][j]?.toString().trim();
      clinic[key] = (value == null || value.isEmpty) ? null : value;
    }
    clinic = sanitizeData(clinic);

    String documentId = (clinic["name"] ?? clinic["address"] ?? "clinic_${start + i}")
        .toString()
        .replaceAll(RegExp(r'[ ./\[\]#?]'), '_')
        .toLowerCase()
        .trim();

    if (documentId.isEmpty || documentId == "_") {
      documentId = "clinic_${start + i}";
    }

    validateFirestoreData(clinic, documentId); 

    batch.set(firestore.collection("translation_clinics").doc(documentId), clinic);
    batchSize++;

    logger.i("📝 Queued: $documentId");

    if (batchSize > 0) {
  await batch.commit();
  logger.i("✅ Final batch uploaded.");
}
  } catch (e) {
  logger.e("❌ Failed to commit final batch: $e");
  }
}


    if (batchSize > 0) {
      await batch.commit();
      logger.i("✅ Final batch uploaded.");
    }

    logger.i("🎉 Upload complete!");
  } catch (e) {
    logger.e("❗ Error in uploadCSVtoFirestore: $e");
  }
}

void validateFirestoreData(Map<String, dynamic> data, String documentId) {
  final invalidChars = RegExp(r'[./\[\]#]');
  
  // Проверяем все ключи
  for (final key in data.keys) {
    if (key.isEmpty || invalidChars.hasMatch(key)) {
      throw Exception("Invalid Firestore key: '$key'");
    }
  }

  // Если documentId пустое, заменяем на default
  if (documentId.isEmpty || invalidChars.hasMatch(documentId)) {
    throw Exception("Invalid document ID: '$documentId'");
  }
}

Map<String, dynamic> sanitizeData(Map<String, dynamic> data) {
  Map<String, dynamic> sanitizedData = {};
  
  // Пробегаем по всем ключам и заменяем пустые значения
  data.forEach((key, value) {
    // Если ключ пустой, заменяем на "unknown_key"
    if (key.isEmpty) {
      sanitizedData["unknown_key"] = value;
    } else {
      sanitizedData[key] = value;
    }
  });
  
  return sanitizedData;
}

