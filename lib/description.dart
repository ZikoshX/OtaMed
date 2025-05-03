import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/l10n/app_localizations_en.dart';
import 'package:flutter_application_1/l10n/app_localizations_kk.dart';
import 'package:flutter_application_1/l10n/app_localizations_ru.dart';
import 'package:flutter_application_1/localization/app_localization.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class CreateClinicPage extends StatefulWidget {
  const CreateClinicPage({super.key});

  @override
  State<CreateClinicPage> createState() => _CreateClinicPageState();
}

class _CreateClinicPageState extends State<CreateClinicPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController ratingController = TextEditingController();
  final TextEditingController nameKZController = TextEditingController();
  final TextEditingController categoryKZController = TextEditingController();
  final TextEditingController addressKZController = TextEditingController();
  final TextEditingController descriptionKZController = TextEditingController();
  final TextEditingController countryKZController = TextEditingController();
  final TextEditingController cityKZController = TextEditingController();
  final TextEditingController nameRUController = TextEditingController();
  final TextEditingController categoryRUController = TextEditingController();
  final TextEditingController addressRUController = TextEditingController();
  final TextEditingController descriptionRUController = TextEditingController();
  final TextEditingController countryRUController = TextEditingController();
  final TextEditingController cityRUController = TextEditingController();
  final TextEditingController siteUrlController = TextEditingController();
  final TextEditingController reviewController = TextEditingController();
  final TextEditingController statusWorkController = TextEditingController();
  final TextEditingController availabilityController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<String> categories = [];
  String? selectedCategoryEn;
  String? selectedCategoryRu;
  String? selectedCategoryKk;

  // Function to get the highest clinic ID
Future<String> getNextClinicId() async {
  try {
    // Query to get all clinic IDs
    QuerySnapshot snapshot = await firestore
        .collection('translation_clinics')
        .orderBy('clinic_id', descending: true) 
        .limit(1) 
        .get();

    if (snapshot.docs.isEmpty) {
      return "clinic_1";
    } else {
      String latestId = snapshot.docs.first.id;
      int latestNumber = int.parse(latestId.split('_')[1]);
      return "clinic_${latestNumber + 1}";
    }
  } catch (e) {
    logger.w("Error getting next clinic ID: $e");
    return "clinic_1"; 
  }
}

  Future<void> uploadClinic() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final category = selectedCategoryEn ?? '';
    final country = countryController.text.trim();
    final city = cityController.text.trim();
    final address = addressController.text.trim();
    final nameKZ = nameKZController.text.trim();
    final descriptionKZ = descriptionKZController.text.trim();
    final categoryKZ = selectedCategoryKk ?? '';
    final countryKZ = countryKZController.text.trim();
    final cityKZ = cityKZController.text.trim();
    final addressKZ = addressKZController.text.trim();
    final nameRU = nameRUController.text.trim();
    final descriptionRU = descriptionRUController.text.trim();
    final categoryRU = selectedCategoryRu ?? '';
    final countryRU = countryRUController.text.trim();
    final cityRU = cityRUController.text.trim();
    final addressRU = addressRUController.text.trim();
    final phone = phoneController.text.trim();
    final review = reviewController.text.trim();
    final siteUrl = siteUrlController.text.trim();
    final statusWork = statusWorkController.text.trim();
    final availability = availabilityController.text.trim();
    final rating = double.tryParse(ratingController.text.trim()) ?? 0.0;

    if (name.isEmpty || address.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

try {
  String newClinicId = await getNextClinicId();

  await firestore.collection('translation_clinics').doc(newClinicId).set({
    'Clinics': name,
    'Description': description,
    'Category': category,
    'Country': country,
    'City': city,
    'Address': address,
    'Phone_number': phone,
    'rating': rating,
    'Review': review,
    'Site_url': siteUrl,
    'Status_working': statusWork,
    'Availability': availability,
    'Clinics_KZ': nameKZ,
    'Description_kZ': descriptionKZ,
    'Category_KZ': categoryKZ,
    'Country_KZ': countryKZ,
    'City_KZ': cityKZ,
    'Address_KZ': addressKZ,
    'Clinics_RU': nameRU,
    'Description_RU': descriptionRU,
    'Category_RU': categoryRU,
    'Country_RU': countryRU,
    'City_RU': cityRU,
    'Address_RU': addressRU,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // ignore: use_build_context_synchronously
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Clinic uploaded successfully")),
  );

      nameController.clear();
      addressController.clear();
      phoneController.clear();
      ratingController.clear();
      nameKZController.clear();
      addressKZController.clear();
      phoneController.clear();
      nameRUController.clear();
      addressRUController.clear();
      categoryController.clear();
      categoryKZController.clear();
      categoryRUController.clear();
      countryController.clear();
      countryKZController.clear();
      countryRUController.clear();
      cityController.clear();
      cityKZController.clear();
      cityRUController.clear();
      descriptionController.clear();
      descriptionKZController.clear();
      descriptionRUController.clear();
      siteUrlController.clear();
      reviewController.clear();
      statusWorkController.clear();
      availabilityController.clear();
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final colorScheme = theme.colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appLocalizations = AppLocalizations.of(context);
    final AppLocalizationsEn en = AppLocalizationsEn();
    final AppLocalizationsRu ru = AppLocalizationsRu();
    final AppLocalizationsKk kk = AppLocalizationsKk();

final List<DropdownMenuItem<String>> englishItems = [
  DropdownMenuItem(value: en.plastic_surgery, child: Text(en.plastic_surgery)),
  DropdownMenuItem(value: en.orthopedic, child: Text(en.orthopedic)),
  DropdownMenuItem(value: en.oncological, child: Text(en.oncological)),
  DropdownMenuItem(value: en.neurosurgery, child: Text(en.neurosurgery)),
  DropdownMenuItem(value: en.ent, child: Text(en.ent)),
  DropdownMenuItem(value: en.gastroenterology, child: Text(en.gastroenterology)),
  DropdownMenuItem(value: en.urology, child: Text(en.urology)),
  DropdownMenuItem(value: en.ophthalmology, child: Text(en.ophthalmology)),
  DropdownMenuItem(value: en.dermatology, child: Text(en.dermatology)),
  DropdownMenuItem(value: en.physical, child: Text(en.physical)),
];


    final List<DropdownMenuItem<String>> russianItems = [
      DropdownMenuItem(value: ru.plastic_surgery, child: Text(ru.plastic_surgery)),
      DropdownMenuItem(value: ru.orthopedic, child: Text(ru.orthopedic)),
      DropdownMenuItem(value: ru.oncological, child: Text(ru.oncological)),
      DropdownMenuItem(value: ru.neurosurgery, child: Text(ru.neurosurgery)),
      DropdownMenuItem(value: ru.ent, child: Text(ru.ent)),
      DropdownMenuItem(
        value: ru.gastroenterology,
        child: Text(ru.gastroenterology),
      ),
      DropdownMenuItem(value: ru.urology, child: Text(ru.urology)),
      DropdownMenuItem(value: ru.ophthalmology, child: Text(ru.ophthalmology)),
      DropdownMenuItem(value: ru.dermatology, child: Text(ru.dermatology)),
      DropdownMenuItem(value: ru.physical, child: Text(ru.physical)),
    ];

    final List<DropdownMenuItem<String>> kazakhItems = [
      DropdownMenuItem(value: kk.plastic_surgery, child: Text(kk.plastic_surgery)),
      DropdownMenuItem(value: kk.orthopedic, child: Text(kk.orthopedic)),
      DropdownMenuItem(value: kk.oncological, child: Text(kk.oncological)),
      DropdownMenuItem(value: kk.neurosurgery, child: Text(kk.neurosurgery)),
      DropdownMenuItem(value: kk.ent, child: Text(kk.ent)),
      DropdownMenuItem(
        value: kk.gastroenterology,
        child: Text(kk.gastroenterology),
      ),
      DropdownMenuItem(value: kk.urology, child: Text(kk.urology)),
      DropdownMenuItem(value: kk.ophthalmology, child: Text(kk.ophthalmology)),
      DropdownMenuItem(value: kk.dermatology, child: Text(kk.dermatology)),
      DropdownMenuItem(value: kk.physical, child: Text(kk.physical)),
    ];

    if (appLocalizations == null) {
      return Scaffold(body: Center(child: Text('Localizations not available')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Add Clinic",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "🏥 ${appLocalizations.translate('name')}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              buildTextField(
                "In English/На английском/Ағылшынша",
                nameController,
              ),
              buildTextField(
                "In Kazakh/На казахском/Қазақша",
                nameKZController,
              ),
              buildTextField("In Russian/На русском/Орысша", nameRUController),
              const SizedBox(height: 20),

              Text(
                "📝 ${appLocalizations.translate('description')}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              buildTextField(
                "In English/На английском/Ағылшынша",
                descriptionController,
              ),
              buildTextField(
                "In Kazakh/На казахском/Қазақша",
                descriptionKZController,
              ),
              buildTextField(
                "In Russian/На русском/Орысша",
                descriptionRUController,
              ),
              const SizedBox(height: 20),

              Text(
                "📂 ${appLocalizations.translate('category')}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: DropdownButton<String>(
                  value: selectedCategoryEn,
                  hint: Text("Select Category"),
                  items: englishItems,
                  onChanged: (val) => setState(() => selectedCategoryEn = val),
                  isExpanded: false,
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: DropdownButton<String>(
                  value: selectedCategoryRu,
                  hint: Text("Выберите категорию"),
                  items: russianItems,
                  onChanged: (val) => setState(() => selectedCategoryRu = val),
                  isExpanded: false,
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: DropdownButton<String>(
                  value: selectedCategoryKk,
                  hint: Text("Санатты таңдаңыз"),
                  items: kazakhItems,
                  onChanged: (val) => setState(() => selectedCategoryKk = val),
                  isExpanded: false,
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              SizedBox(height: 16),
              const SizedBox(height: 20),

              Text(
                "📍 ${appLocalizations.translate('address')}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              buildTextField(
                "County \nIn English/На английском/Ағылшынша",
                countryController,
              ),
              buildTextField(
                "In Kazakh/На казахском/Қазақша",
                countryKZController,
              ),
              buildTextField(
                "In Russian/На русском/Орысша",
                countryRUController,
              ),
              buildTextField(
                "City \nIn English/На английском/Ағылшынша",
                cityController,
              ),
              buildTextField(
                "In Kazakh/На казахском/Қазақша",
                cityKZController,
              ),
              buildTextField("In Russian/На русском/Орысша", cityRUController),
              buildTextField(
                "Address \nIn English/На английском/Ағылшынша",
                addressController,
              ),
              buildTextField(
                "In Kazakh/На казахском/Қазақша",
                addressKZController,
              ),
              buildTextField(
                "In Russian/На русском/Орысша",
                addressRUController,
              ),
              const SizedBox(height: 20),

              Text(
                "☎️ ${appLocalizations.translate('phone')}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              buildTextField(
                "Only number/Только цифры/Тек сандар",
                phoneController,
              ),
              buildTextField("Link/Ссылка/Сілтеме", siteUrlController),
              const SizedBox(height: 20),

              Text(
                "⭐ ${appLocalizations.translate('other')}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              buildTextField(
                "Rating/Рейтинг/Рейтинг",
                ratingController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              buildTextField(
                "Review/Отзыв/",
                reviewController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              buildTextField("Availability", availabilityController),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: uploadClinic,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Add",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final borderColor =
        Theme.of(context).brightness == Brightness.dark
            ? Colors.white70
            : Colors.grey[700];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters, 
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor ?? Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor ?? Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
