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

  String getTranslatedKey(String baseKey, String langCode) {
    switch (langCode.toLowerCase()) {
      case 'ru':
        return '${baseKey}_RU';
      case 'kk':
      case 'kz':
        return '${baseKey}_KZ';
      default:
        return baseKey;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSimilarClinics(
    String category,
    String country,
    String selectedLanguageCode,
  ) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String categoryField;
    String nameField;
    String countryField;
    String cityFiled;
    switch (selectedLanguageCode) {
      case 'ru':
        categoryField = 'Category_RU';
        nameField = 'Clinics_RU';
        countryField = 'Country_RU';
        cityFiled = 'City_RU';
        break;
      case 'kk':
        categoryField = 'Category_KZ';
        nameField = 'Clinics_KZ';
        countryField = 'Country_KZ';
        cityFiled = 'City_KZ';
        break;
      default:
        categoryField = 'Category';
        nameField = 'Clinics';
        countryField = 'Country';
        cityFiled = 'City';
    }

    QuerySnapshot clinicSnapshot =
        await firestore
            .collection('translation_clinics')
            .where(categoryField, isEqualTo: category)
            .where(countryField, isEqualTo: country)
            .get();

    List<Map<String, dynamic>> fetchedClinics =
        clinicSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'name': data[nameField] ?? '',
            'rating': data['rating'] ?? 0,
            'reviews': data['Review'] ?? [],
            'availability': data['Availability'] ?? '',
            'country': data[countryField] ?? '',
            'city': data[cityFiled] ?? '',
          };
        }).toList();

    return fetchedClinics;
  }

Future<Map<String, dynamic>?> getClinicByName(
  String clinicName,
  String selectedLanguageCode,
) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String nameField;
  String countryField;
  String cityField;
  switch (selectedLanguageCode) {
    case 'ru':
      nameField = 'Clinics_RU';
      countryField = 'Country_RU';
      cityField = 'City_RU';
      break;
    case 'kk':
      nameField = 'Clinics_KZ';
      countryField = 'Country_KZ';
      cityField = 'City_KZ';
      break;
    default:
      nameField = 'Clinics';
      countryField = 'Country';
      cityField = 'City';
  }

  logger.w("🔍 Searching for clinic: '${clinicName.trim()}' using field '$nameField'");

  QuerySnapshot snapshot = await firestore
      .collection("translation_clinics")
      .where(nameField, isEqualTo: clinicName.trim())
      .limit(1)
      .get();

  if (snapshot.docs.isNotEmpty) {
    Map<String, dynamic> clinicData = snapshot.docs.first.data() as Map<String, dynamic>;

    return {
      'name': clinicData[nameField] ?? 'Unknown',
      'rating': clinicData['rating'] ?? 0,
      'reviews': (int.tryParse(clinicData['Review'].toString()) ?? 0).abs(),
      'availability': clinicData['Availability'] ?? '',
      'country': clinicData[countryField] ?? '',
      'city': clinicData[cityField] ?? '',
    };
  }

  logger.w("Clinic '$clinicName' not found in Firestore.");
  return null;
}


  Future<String> analyzeClinic(
    String clinicName,
    String category,
    String country,
    String selectedLanguageCode,
  ) async {
    loadingMessage.value = ".....";

    List<Map<String, dynamic>> similarClinics = await fetchSimilarClinics(
      category,
      country,
      selectedLanguageCode,
    );

    logger.w(similarClinics);

    if (similarClinics.isEmpty) {
      return "No similar clinics found for category '$category'.";
    }

    Map<String, dynamic>? targetClinic = await getClinicByName(clinicName, selectedLanguageCode);
    logger.w(targetClinic);

    if (targetClinic == null || targetClinic['name'] == null) {
      return "Clinic '$clinicName' not found in the database.";
    }

    similarClinics.sort(
      (a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0),
    );

    String prompt;
    switch (selectedLanguageCode) {
      case 'ru':
        prompt = """
Проанализируй клинику '${targetClinic['name']}' в категории '$category'.  
Сравни её с другими похожими клиниками на основе:  

- ⭐ Средняя оценка: ${targetClinic['rating']}  
- 💬 Отзывы: ${targetClinic['reviews']}  
- 🌍 Страна: ${targetClinic['country']}  
- 🕒 Доступность: ${targetClinic['availability']}  

Похожие клиники в этой категории:  
${similarClinics.map((c) => "- ${c['name']}: ${c['rating']}⭐, ${c['country']}").join("\n")}  

На основе этих данных сделай краткий AI-анализ, объясни, чем эта клиника лучше или хуже остальных.
""";
        break;
      case 'kk':
        prompt = """
'${targetClinic['name']}' клиникасын '$category' санатында талдаңыз.  
Оны басқа ұқсас клиникалармен салыстырыңыз:  

- ⭐ Орташа рейтинг: ${targetClinic['rating']}  
- 💬 Пікірлер саны: ${targetClinic['reviews']}  
- 🌍 Ел: ${targetClinic['country']}  
- 🕒 Қолжетімділік: ${targetClinic['availability']}  

Бұл санаттағы басқа ұқсас клиникалар:  
${similarClinics.map((c) => "- ${c['name']}: ${c['rating']}⭐, ${c['country']}").join("\n")}  

Осы деректер негізінде қысқа AI-талдау жасаңыз, бұл клиниканың басқалардан артықшылықтарын немесе кемшіліктерін түсіндіріңіз.
""";
        break;
      default:
        prompt = """
Analyze the clinic '${targetClinic['name']}' in the category '$category'.  
Compare it with other similar clinics based on:  

- ⭐ Average Rating: ${targetClinic['rating']}  
- 💬 Reviews: ${targetClinic['reviews']}  
- 🌍 Country: ${targetClinic['country']}  
- 🕒 Availability: ${targetClinic['availability']}  

Other similar clinics in this category:  
${similarClinics.map((c) => "- ${c['name']}: ${c['rating']}⭐, ${c['country']}").join("\n")}  

Based on this data, provide a concise AI-driven analysis explaining why this clinic is better or worse than others.
""";
    }

    return await getGeminiResponse(prompt);
  }

Future<String> findArticles(String clinicName, String selectedLanguageCode) async {
  loadingMessage.value = ".....";

  Map<String, dynamic>? clinic = await getClinicByName(clinicName, selectedLanguageCode);

  if (clinic == null || clinic['name'] == null) {
    return "Clinic '$clinicName' not found in the database.";
  }

  String city = clinic['city'] ?? 'Unknown City';
  String country = clinic['country'] ?? 'Unknown Country';

  String prompt = "";

switch (selectedLanguageCode) {
  case 'ru':
    prompt = """
Ты — ассистент, который помогает находить информацию.
Сделай вид, что ты ищешь в интернете  статьи про клинике '$clinicName', расположенной в городе $city, $country.
Используй только настоящие источники и ссылки, чтобы предоставить 3-5 статей с аннотациями даже если старые.
Формат:
- Название статьи
- Краткое содержание
- Ссылка в формате [Текст ссылки](https://реальная-ссылка.com)
""";
    break;
  case 'kk':
    prompt = """
Сен ақпарат табатын көмекшісің.
'$clinicName' клиникасы туралы $city, $country қаласында орналасқан барлық мақалаларды(3-5) тауып жатқандай бол.
Тек нақты ақпарат пен шын сілтемелерді қолданып, әр мақала үшін қысқаша сипаттама және сілтемені көрсет.
Формат:
- Мақала атауы
- Қысқаша сипаттама
- Сілтемені [Сілтеме мәтіні](https://настоящий-сілтеме.com) форматында бер.
""";
    break;
  default: 
    prompt = """
You are an assistant that helps find information.
Pretend you are searching the internet for all articles about the clinic '$clinicName' located in $city, $country.
Use only real sources and links. Provide 3-5 article summaries with titles and a real link for each.
Format:
- Article Title
- Short Summary
- Link in the format [Link Text](https://real-link.com)
""";
}


  return await getGeminiResponse(prompt);
}

}
