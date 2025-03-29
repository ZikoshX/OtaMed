import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class GeminiAI {
  final String apiKey = "AIzaSyD1V8tQHQ33Vqfc56FIVWFH6rDz-sMNMTQ";
  late GenerativeModel _model;
  ValueNotifier<String> loadingMessage = ValueNotifier<String>("");

  GeminiAI() {
    _model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);
  }

  Future<String> getGeminiResponse(String message) async {
    loadingMessage.value = ".....";
    try {
      final content = [Content.text(message)];
      final response = await _model.generateContent(content);

      return response.text ?? "No response from AI.";
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<List<Map<String, dynamic>>> fetchSimilarClinics(
    String category,
    String country,
  ) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    QuerySnapshot clinicSnapshot =
        await firestore
            .collection('clinics')
            .where('Category', isEqualTo: category)
            .where('Country', isEqualTo: country)
            .get();

    List<Map<String, dynamic>> fetchedClinics =
        clinicSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['Clinics'] ?? '',
            'rating': data['rating'] ?? 0,
            'reviews': data['Review'] ?? [],
            'availability': data['Availability'] ?? '',
            'country': data['Country'] ?? '',
            'city': data['City'] ?? '',
          };
        }).toList();

    return fetchedClinics;
  }

  Future<Map<String, dynamic>?> getClinicByName(String clinicName) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    logger.w("🔍 Searching for clinic: '${clinicName.trim().toLowerCase()}'");

    QuerySnapshot snapshot =
        await firestore
            .collection("clinics")
            .where("Clinics", isEqualTo: clinicName.trim())
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      Map<String, dynamic> clinicData =
          snapshot.docs.first.data() as Map<String, dynamic>;

      return {
        'name': clinicData['Clinics'] ?? 'Unknown',
        'rating': clinicData['rating'] ?? 0,
        'reviews': (int.tryParse(clinicData['Review'].toString()) ?? 0).abs(),
        'availability': clinicData['Availability'] ?? '',
        'country': clinicData['Country'] ?? '',
        'city': clinicData['City'] ?? '',
      };
    }

    logger.w("Clinic '$clinicName' not found in Firestore.");
    return null;
  }

  Future<String> analyzeClinic(
    String clinicName,
    String category,
    String country,
  ) async {
    loadingMessage.value = ".....";
    List<Map<String, dynamic>> similarClinics = await fetchSimilarClinics(
      category,
      country,
    );
    logger.w(similarClinics);
    if (similarClinics.isEmpty) {
      return "No similar clinics found for category '$category'.";
    }

    Map<String, dynamic>? targetClinic = await getClinicByName(clinicName);
    logger.w(targetClinic);
    if (targetClinic == null || targetClinic['name'] == null) {
      return "Clinic '$clinicName' not found in the database.";
    }

    similarClinics.sort(
      (a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0),
    );

    String prompt = """
  Analyze the clinic '${targetClinic['name']}' in the category '$category'.  
  Compare it with other similar clinics based on:  

  - ⭐ **Average Rating:** ${targetClinic['rating']}  
  - 💬 **Reviews:** ${targetClinic['reviews']}  
  - 🌍 **Country:** ${targetClinic['country']}  
  - 🕒 **Availability:** ${targetClinic['availability']}  

  Other similar clinics in this category:  
  ${similarClinics.map((c) => "- ${c['name']}: ${c['rating']}⭐, ${c['country']}").join("\n")}  

  Based on this data, provide a **concise AI-driven analysis** explaining why this clinic is **better or worse** than others.
  """;

    return await getGeminiResponse(prompt);
  }

  Future<String> findArticles(String clinicName) async {
    loadingMessage.value = ".....";
    Map<String, dynamic>? clinic = await getClinicByName(clinicName);

    if (clinic == null || clinic['name'] == null) {
      return "Clinic '$clinicName' not found in the database.";
    }

    String city = clinic['city'] ?? 'Unknown City';
    String country = clinic['country'] ?? 'Unknown Country';

    String prompt = """
  Find recent articles about the clinic '$clinicName' located in $city, $country.
  Summarize the key points and provide relevant insights.
  """;

    return await getGeminiResponse(prompt);
  }
}
