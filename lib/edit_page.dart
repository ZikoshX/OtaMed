import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class EditPage extends StatefulWidget {
  final Map<String, dynamic> clinic;
  final String langCode;
  const EditPage({super.key, required this.clinic, required this.langCode});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late TextEditingController nameController;
  late TextEditingController categoryController;
  late TextEditingController countryController;
  late TextEditingController cityController;
  late TextEditingController addressController;
  late TextEditingController descriptionController;
  late TextEditingController ratingController;
  late TextEditingController reviewController;
  late TextEditingController phoneController;
  late TextEditingController siteUrlController;
  late TextEditingController availabilityController;

  @override
  void initState() {
    super.initState();

    //final categoryKey = getTranslatedCategoryField(widget.langCode);
    //final countryKey = getTranslatedKey('Country', widget.langCode);
    //final cityKey = getTranslatedKey('City', widget.langCode);
    //final descriptionKey = getTranslatedKey('Description', widget.langCode);

    nameController = TextEditingController(text: widget.clinic['name']);
    categoryController = TextEditingController(text: widget.clinic['category']);
    countryController = TextEditingController(text: widget.clinic['Country']);
    cityController = TextEditingController(text: widget.clinic['City']);
    addressController = TextEditingController(text: widget.clinic['address']);
    descriptionController = TextEditingController(
      text: widget.clinic['description'],);
    ratingController = TextEditingController(
      text: widget.clinic['rating']?.toString() ?? "",);
    reviewController = TextEditingController(
      text: widget.clinic['review']?.toString() ?? "",);
    phoneController = TextEditingController(text: widget.clinic['phone']);
    siteUrlController = TextEditingController(text: widget.clinic['site_url']);
    availabilityController = TextEditingController(
      text: widget.clinic['availability'],);
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

  String getTranslatedCategoryField(String langCode) {
    if (langCode == 'ru') return 'Category_RU';
    if (langCode == 'kk') return 'Category_KZ';
    return 'Category';
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    countryController.dispose();
    cityController.dispose();
    addressController.dispose();
    descriptionController.dispose();
    ratingController.dispose();
    reviewController.dispose();
    phoneController.dispose();
    siteUrlController.dispose();
    availabilityController.dispose();
    super.dispose();
  }

  void saveClinicDetails() {
    final updatedClinic = {
      "name": nameController.text,
      "category": categoryController.text,
      "Country": countryController.text,
      "City": cityController.text,
      "address": addressController.text,
      "description": descriptionController.text,
      "rating": double.tryParse(ratingController.text) ?? 0.0,
      "review": int.tryParse(reviewController.text) ?? 0,
      "phone": phoneController.text,
      "site_url": siteUrlController.text,
      "availability": availabilityController.text,
    };

    logger.i("Saved Clinic Data: $updatedClinic");

    Navigator.pop(context, updatedClinic);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // final textColor = theme.textTheme.bodyMedium?.color;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final nameLabel = getTranslatedNameLabel(widget.langCode);
    final categoryLabel = getTranslatedCategoryLabel(widget.langCode);
    final countryabel = getTranslatedCountryLabel(widget.langCode);
    final cityLabel = getTranslatedCityLabel(widget.langCode);
    final addressLabel = getTranslatedAddressLabel(widget.langCode);
    final descriptionLabel = getTranslatedDescriptionLabel(widget.langCode);
    final ratingLabel = getTranslatedRatingLabel(widget.langCode);
    final reviewLabel = getTranslatedReviewLabel(widget.langCode);
    final phoneLabel = getTranslatedPhoneLabel(widget.langCode);
    final websiteLabel = getTranslatedWebsiteLabel(widget.langCode);



    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text("Edit Clinic")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildTextField(nameLabel, nameController),
            buildTextField(categoryLabel, categoryController),
            buildTextField(countryabel, countryController),
            buildTextField(cityLabel, cityController),
            buildTextField(addressLabel, addressController),
            buildTextField(descriptionLabel, descriptionController, maxLines: 3),
            buildTextField(
              ratingLabel,
              ratingController,
              keyboardType: TextInputType.number,
            ),
            buildTextField(
              reviewLabel,
              reviewController,
              keyboardType: TextInputType.number,
            ),
            buildTextField(phoneLabel, phoneController),
            buildTextField(websiteLabel, siteUrlController),
            buildTextField("", availabilityController),
            const SizedBox(height: 10),
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
                    onPressed: saveClinicDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Save",
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
    );
  }

  String getTranslatedNameLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'ru':
        return 'Имя'; // Russian translation for "Name"
      case 'kk':
        return 'Аты'; // Kazakh translation for "Name"
      default:
        return 'Name'; // Default to English
    }
  }

  String getTranslatedCategoryLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'ru':
        return 'Категория'; // Russian translation for "Name"
      case 'kk':
        return 'Категория'; // Kazakh translation for "Name"
      default:
        return 'Category'; // Default to English
    }
  }

  String getTranslatedCountryLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'ru':
        return 'Страна'; // Russian translation for "Name"
      case 'kk':
        return 'Мемлекет'; // Kazakh translation for "Name"
      default:
        return 'Country'; // Default to English
    }
  }

  String getTranslatedCityLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'ru':
        return 'Город'; // Russian translation for "Name"
      case 'kk':
        return 'Қала'; // Kazakh translation for "Name"
      default:
        return 'City'; // Default to English
    }
  }

  String getTranslatedAddressLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'ru':
        return 'Адрес'; // Russian translation for "Name"
      case 'kk':
        return 'Мекен-жай'; // Kazakh translation for "Name"
      default:
        return 'Address'; // Default to English
    }
  }
    String getTranslatedDescriptionLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'ru':
        return 'Описание'; // Russian translation for "Name"
      case 'kk':
        return 'Сипаттама'; // Kazakh translation for "Name"
      default:
        return 'Description'; // Default to English
    }
  }
  String getTranslatedRatingLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'ru':
        return 'Рейтинг'; // Russian translation for "Name"
      case 'kk':
        return 'Рейтинг'; // Kazakh translation for "Name"
      default:
        return 'Rating'; // Default to English
    }
  }
  String getTranslatedReviewLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'ru':
        return 'Отзыв'; // Russian translation for "Name"
      case 'kk':
        return 'Комментарий'; // Kazakh translation for "Name"
      default:
        return 'Review'; // Default to English
    }
  }
  String getTranslatedPhoneLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'ru':
        return 'Телефон'; // Russian translation for "Name"
      case 'kk':
        return 'Телефон'; // Kazakh translation for "Name"
      default:
        return 'Phone'; // Default to English
    }
  }
  String getTranslatedWebsiteLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'ru':
        return 'Сайт ссылка'; // Russian translation for "Name"
      case 'kk':
        return 'Сайт сілтемесі'; // Kazakh translation for "Name"
      default:
        return 'Website'; // Default to English
    }
  }


  Widget buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
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
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor),
          fillColor: Theme.of(context).textTheme.bodyMedium?.color,
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
