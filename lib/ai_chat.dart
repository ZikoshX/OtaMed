import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/gemini.dart';
import 'package:flutter_application_1/localization/app_localization.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

var logger = Logger();

class AiChat extends StatefulWidget {
  const AiChat({super.key});

  @override
  State<AiChat> createState() => _AiChatState();
}

class _AiChatState extends State<AiChat> {
  final TextEditingController _controller = TextEditingController();
  Map<String, List<Map<String, dynamic>>> chats = {};
  final GeminiAI _geminiAI = GeminiAI();
  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> clinics = [];
  List<String> availableCategories = [];
  List<String> availableCountries = [];
  bool isClinicMode = false;
  String? selectedCategory;
  String? selectedCountry;
  String? selectedClinic;
  String? selectedChat;
  String? selectedDateDrawerText;
  bool isLoading = false;
  String? selectedLanguageCode;
  String? pendingClinicName;

  List<Map<String, String>> availableLanguages = [
    {"label": "English", "code": "en"},
    {"label": "Русский", "code": "ru"},
    {"label": "Қазақша", "code": "kk"},
  ];

  @override
  void initState() {
    super.initState();
    //_loadChatHistory();
    _loadChats();
  }

  void _loadChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedChats = prefs.getString("chats");

    if (storedChats != null && storedChats.isNotEmpty) {
      Map<String, dynamic> decodedChats = jsonDecode(storedChats);

      Map<String, List<Map<String, dynamic>>> loadedChats = decodedChats.map(
        (key, value) => MapEntry(
          key,
          List<Map<String, dynamic>>.from(
            (value as List).map((e) => Map<String, dynamic>.from(e)),
          ),
        ),
      );
      String? savedCategory = prefs.getString("selectedCategory");
      String? savedCountry = prefs.getString("selectedCountry");
      String? savedClinic = prefs.getString("selectedClinic");

      setState(() {
        chats = loadedChats;
        messages = chats[selectedChat] ?? [];

        if (savedCategory != null) selectedCategory = savedCategory;
        if (savedCountry != null) selectedCountry = savedCountry;
        if (savedClinic != null) selectedClinic = savedClinic;
      });
    } else {
      setState(() {
        chats.clear();
        messages.clear();
      });
    }
  }

  void _saveChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("chats", jsonEncode(chats));
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    if (selectedChat == null) {
      // ignore: unnecessary_null_comparison
      String newChatId = "Chat ${chats != null ? chats.length + 1 : 1}";
      String creationDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      setState(() {
        chats[newChatId] = [
          {"date": creationDate, "text": "New Chat Started", "isUser": false},
        ];
        selectedChat = newChatId;
        messages = chats[newChatId]!;
      });

      _saveChats();
      _saveChatHistory();
    }

    String userMessage = _controller.text.trim();
    String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    setState(() {
      messages.add({"text": userMessage, "isUser": true, "date": dateKey});

      chats[selectedChat!] = List.from(messages);
    });

    _controller.clear();
    _saveChats();
    _saveChatHistory();

    String aiResponse = await _geminiAI.getGeminiResponse(userMessage);

    setState(() {
      messages.add({"text": aiResponse, "isUser": false});
      chats[selectedChat!] = List.from(messages);
    });

    _saveChats();
    _saveChatHistory();
  }

  void _startNewChat() {
    String newChatId = "Chat ${chats.length + 1}";
    String creationDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    setState(() {
      selectedLanguageCode = null;
      selectedCategory = null;
      selectedCountry = null;
      selectedClinic = null;

      chats[newChatId] = [
        {"date": creationDate, "text": "New Chat Started", "isUser": false},
      ];
      selectedChat = newChatId;
      messages = chats[newChatId]!;
    });

    _saveChats();
    _saveChatHistory();

    // 👇 Call language selector directly without delay
    _askLanguageSelection();
  }

  void _deleteChat(String chatId) {
    setState(() {
      chats.remove(chatId);
      if (selectedChat == chatId) {
        selectedChat = chats.isNotEmpty ? chats.keys.first : null;
        messages = selectedChat != null ? chats[selectedChat]! : [];
      }
    });
    _saveChats();
    _saveChatHistory();
  }

  Map<String, List<String>> groupChatsByDate() {
    Map<String, List<String>> groupedChats = {};

    chats.forEach((chatId, chatMessages) {
      if (chatMessages.isNotEmpty && chatMessages[0].containsKey('date')) {
        String creationDate = chatMessages[0]['date'];
        if (!groupedChats.containsKey(creationDate)) {
          groupedChats[creationDate] = [];
        }
        groupedChats[creationDate]!.add(chatId);
      }
    });

    return groupedChats;
  }

  void _toggleClinicMode() async {
    setState(() {
      if (isClinicMode) {
        isClinicMode = false;
        messages.add({
          "text": "Exited clinic search. You can ask me anything now.",
          "isUser": false,
        });
      } else {
        isClinicMode = true;
        selectedCategory = null;
        selectedCountry = null;
        clinics = [];
        availableCountries = [];
        _fetchCategories();
      }
    });
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

  String getTranslatedCountryField(String langCode) {
    if (langCode == 'ru') return 'Country_RU';
    if (langCode == 'kk') return 'Country_KZ';
    return 'Country';
  }

  String getTranslatedClinicsField(String langCode) {
    if (langCode == 'ru') return 'Clinics_RU';
    if (langCode == 'kk') return 'Clinics_KZ';
    return 'Clinics';
  }

  void _askLanguageSelection() {
    setState(() {
      messages.add({
        "text": "Please select your preferred language:",
        "isUser": false,
        "buttons": availableLanguages.map((lang) => lang['label']!).toList(),
      });
    });
  }

  void handleLanguageSelection(
    String selectedLanguage,
    BuildContext context,
  ) async {
    final selected = availableLanguages.firstWhere(
      (lang) => lang['label'] == selectedLanguage,
      orElse: () => {"label": "English", "code": "en"},
    );
    logger.w(selected);
    final selectedCode = selected['code'];
    if (selectedCode == null) {
      logger.w("Selected language has no code!");
      _askLanguageSelection();
      return;
    }

    setState(() {
      selectedLanguageCode = selectedCode;
      isClinicMode = true;
      selectedCategory = null;
      selectedCountry = null;
      selectedClinic = null;
      messages.add({
        "text": _getConfirmationMessage(selectedCode, selectedLanguage),
        "isUser": false,
      });
    });
    _fetchCategories();
  }

  String _getConfirmationMessage(String langCode, String selectedLanguage) {
    switch (langCode) {
      case 'ru':
        return "Вы выбрали: $selectedLanguage";
      case 'kk':
        return "Сіз таңдадыңыз: $selectedLanguage";
      default:
        return "You selected: $selectedLanguage";
    }
  }

  Future<void> _fetchCategories() async {
    if (selectedLanguageCode == null) {
      logger.w("No language selected, cannot fetch categories.");
      _askLanguageSelection();
      return;
    }

    final translatedCategoryKey = getTranslatedCategoryField(
      selectedLanguageCode!,
    );

    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('translation_clinics')
              .get();

      List<String> allCategories =
          snapshot.docs
              .where(
                (doc) => (doc.data() as Map<String, dynamic>).containsKey(
                  translatedCategoryKey,
                ),
              )
              .map(
                (doc) => (doc[translatedCategoryKey] ?? '').toString().trim(),
              )
              .where((category) => category.isNotEmpty)
              .toSet()
              .toList();

      if (allCategories.isEmpty) {
        setState(() {
          messages.add({"text": "No categories found.", "isUser": false});
        });
        return;
      }

      setState(() {
        availableCategories = allCategories;
        messages.add({
          "text": _getCategorySelectMessage(selectedLanguageCode!),
          "isUser": false,
          "buttons": allCategories,
        });
      });
    } catch (e) {
      logger.e("Error fetching categories: $e");
      setState(() {
        messages.add({
          "text": "Error fetching categories. Please try again later.",
          "isUser": false,
        });
      });
    }
  }

  void handleCategorySelection(String category) async {
    final langCode = selectedLanguageCode!;
    final categoryField = getTranslatedCategoryField(langCode);
    final countryField = getTranslatedCountryField(langCode);

    setState(() {
      selectedCategory = category;
    });

    setState(() {
      messages.add({
        "text": "${_getCategorySelectMessage(langCode)} $category",
        "isUser": false,
      });
    });

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance
            .collection('translation_clinics')
            .where(categoryField, isEqualTo: selectedCategory)
            .get();

    List<String> countries =
        snapshot.docs
            .where(
              (doc) => (doc.data() as Map<String, dynamic>).containsKey(
                countryField,
              ),
            )
            .map((doc) => doc[countryField].toString().trim())
            .toSet()
            .toList();

    if (countries.isEmpty) {
      setState(() {
        messages.add({
          "text": _getNoCountriesFoundMessage(langCode, selectedCategory!),
          "isUser": false,
        });
      });
      return;
    }
    setState(() {
      availableCountries = countries;
      messages.add({
        "text": _getCountrySelectMessage(langCode),
        "isUser": false,
        "buttons": availableCountries,
      });
    });
  }

  String _getNoCountriesFoundMessage(String langCode, String category) {
    switch (langCode) {
      case 'ru':
        return "Нет стран для категории $category.";
      case 'kk':
        return "$category санаты үшін елдер жоқ.";
      default:
        return "No countries found for $category.";
    }
  }

  String _getCountrySelectMessage(String langCode) {
    switch (langCode) {
      case 'ru':
        return "Теперь выберите страну:";
      case 'kk':
        return "Енді елді таңдаңыз:";
      default:
        return "Now select a country:";
    }
  }

  String _getCategorySelectMessage(String langCode) {
    switch (langCode) {
      case 'ru':
        return "Выберите категорию:";
      case 'kk':
        return "Санатты таңдаңыз:";
      default:
        return "Select a category:";
    }
  }

  void _handleCountrySelection(String country) async {
    final langCode = selectedLanguageCode!;
    final categoryField = getTranslatedCategoryField(langCode);
    final countryField = getTranslatedCountryField(langCode);
    final clinicsField = getTranslatedClinicsField(langCode);

    if (!availableCountries.contains(country)) {
      setState(() {
        messages.add({
          "text": "Invalid country. Please select from the available options.",
          "isUser": false,
        });
      });
      return;
    }

    setState(() {
      selectedCountry = country;
      clinics = [];
    });

    QuerySnapshot clinicSnapshot =
        await FirebaseFirestore.instance
            .collection('translation_clinics')
            .where(categoryField, isEqualTo: selectedCategory)
            .where(countryField, isEqualTo: selectedCountry)
            .get();

    List<Map<String, dynamic>> fetchedClinics =
        clinicSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {"name": data[clinicsField]?.toString().trim() ?? ""};
        }).toList();

    setState(() {
      if (fetchedClinics.isEmpty) {
        messages.add({
          "text": "No clinics found in $selectedCountry.",
          "isUser": false,
        });
      } else {
        clinics = fetchedClinics;
        messages.add({
          "text": _getClinicSelectMessage(langCode),
          "isUser": false,
          "buttons": fetchedClinics.map((c) => c["name"]).toList(),
        });
      }
    });
  }

  String _getClinicSelectMessage(String langCode) {
    switch (langCode) {
      case 'ru':
        return "Выберите клинику:";
      case 'kk':
        return "Аурухананы таңдаңыз:";
      default:
        return "Select a clinic:";
    }
  }

  void _selectClinic(String clinicName) {
    if (selectedLanguageCode == null) {
      pendingClinicName = clinicName;
      return;
    }

    final clinicMessage = _getClinicSelectedMessage(
      selectedLanguageCode!,
      clinicName,
    );

    setState(() {
      selectedClinic = clinicName;
      messages.add({"text": clinicMessage, "isUser": true});
    });
  }

  String _getClinicSelectedMessage(String langCode, String clinicName) {
    switch (langCode) {
      case 'ru':
        return "Вы выбрали: $clinicName";
      case 'kk':
        return "Сіз таңдадыңыз: $clinicName";
      default:
        return "You selected: $clinicName";
    }
  }

  List<String> _getOptionButtons(String? langCode) {
    switch (langCode) {
      case 'ru':
        return [
          "Анализ",
          "Статьи о клинике",
          "Показать список клиник",
          "Выбрать новую категорию",
        ];
      case 'kk':
        return [
          "Анализ",
          "Клиника туралы мақалалар",
          "Клиникалар тізімін көрсету",
          "Жаңа санатты таңдау",
        ];
      default:
        return [
          "Analysis",
          "Articles about clinic",
          "Show Clinic List",
          "Select New Category",
        ];
    }
  }

  Future<void> _handleFinalOption(String option) async {
    if (selectedCategory == null || selectedCountry == null) {
      setState(() {
        messages.add({
          "isUser": false,
          "text": _getCategorySelectMessage(selectedLanguageCode!),
        });
      });
      return;
    }

    final loadingMessage = _getLoadingMessage(selectedLanguageCode!);

    setState(() {
      messages.add({"isUser": false, "text": loadingMessage});
    });

    String response = "";
    final options = _getOptionButtons(selectedLanguageCode!);

    if (option == options[0]) {
      response = await _geminiAI.analyzeClinic(
        selectedClinic!,
        selectedCategory!,
        selectedCountry!,
        selectedLanguageCode!,
      );
    } else if (option == options[1]) {
      response = await _geminiAI.findArticles(
        selectedClinic!,
        selectedLanguageCode!,
      );
    }
    final remainingOption = option == options[0] ? options[1] : options[0];

    setState(() {
      messages.removeLast();

      if (response.isNotEmpty) {
        messages.add({"isUser": false, "text": response});
      } else {
        messages.add({
          "isUser": false,
          "text": "Sorry, no response available.",
        });
      }
      final optionButtons = <String>[
        remainingOption,
        getButtonLabel("Show Clinic List", selectedLanguageCode!),
        getButtonLabel("Select New Category", selectedLanguageCode!),
      ];

      messages.add({
        "isUser": false,
        "buttons": optionButtons,
        "category": selectedCategory,
        "country": selectedCountry,
      });
    });

    _saveChatHistory();
  }

  void _askCategorySelection() {
    setState(() {
      messages.add({
        "text": _getCategorySelectMessage(selectedLanguageCode!),
        "isUser": false,
        "buttons": availableCategories,
      });
    });
  }

  String getButtonLabel(String buttonKey, String languageCode) {
    switch (buttonKey) {
      case "Show Clinic List":
        switch (languageCode) {
          case "ru":
            return "Показать список клиник";
          case "kk":
            return "Клиникалар тізімін көрсету";
          default:
            return "Show Clinic List";
        }
      case "Select New Category":
        switch (languageCode) {
          case "ru":
            return "Выбрать новую категорию";
          case "kk":
            return "Жаңа санатты таңдау";
          default:
            return "Select New Category";
        }
      default:
        return buttonKey;
    }
  }

  void handleOptionSelection(
    String option, {
    String? category,
    String? country,
  }) {
    final effectiveCategory = category ?? selectedCategory;
    final effectiveCountry = country ?? selectedCountry;

    if (option == getButtonLabel("Show Clinic List", selectedLanguageCode!)) {
      if (effectiveCategory == null || effectiveCountry == null) {
        _askCategorySelection();
        return;
      }
      _handleClinicList(
        selectedCategory!,
        selectedCountry!,
        selectedLanguageCode!,
      );
    } else if (option ==
        getButtonLabel("Select New Category", selectedLanguageCode!)) {
      setState(() {
        selectedCategory = null;
        selectedCountry = null;
        selectedClinic = null;
        clinics = [];
      });
      _askCategorySelection();
    } else {
      _handleFinalOption(option);
    }
  }

  Future<void> _handleClinicList(
    String? category,
    String? country,
    String? languageCode,
  ) async {
    if (category == null || country == null || languageCode == null) {
      logger.e(
        "Missing required parameters: category=$category, country=$country, lang=$languageCode",
      );
      return;
    }

    final categoryField = getTranslatedCategoryField(languageCode);
    final countryField = getTranslatedCountryField(languageCode);
    final clinicsField = getTranslatedClinicsField(languageCode);

    logger.w(
      "Querying Firestore with: categoryField='$categoryField' (value: '$category'), countryField='$countryField' (value: '$country')",
    );

    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('translation_clinics')
              .where(categoryField, isEqualTo: category.trim())
              .where(countryField, isEqualTo: country.trim())
              .get();

      logger.w("Firestore returned ${snapshot.docs.length} documents");

      List<Map<String, dynamic>> fetchedClinics =
          snapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final clinicName = data[clinicsField]?.toString().trim() ?? "";
                logger.w("Clinic data: $data → Extracted name: '$clinicName'");
                return {"name": clinicName};
              })
              .where((c) => c["name"] != "")
              .toList();

      setState(() {
        clinics = fetchedClinics;
        selectedClinic = null;

        if (fetchedClinics.isEmpty) {
          messages.add({
            "text": getNoClinicsMessage(languageCode),
            "isUser": false,
            "buttons": ["Select New Category"],
          });
        } else {
          messages.add({
            "text": _getClinicSelectMessage(languageCode),
            "isUser": false,
            "buttons": fetchedClinics.map((c) => c["name"] as String).toList(),
          });
        }
      });
    } catch (e) {
      logger.e("Error fetching clinics: $e");
      setState(() {
        messages.add({
          "text": "Error loading clinics. Please try again.",
          "isUser": false,
          "buttons": ["Select New Category"],
        });
      });
    }
  }

  String _getLoadingMessage(String langCode) {
    switch (langCode) {
      case 'ru':
        return "Загружается...";
      case 'kk':
        return "Жүктелуде...";
      default:
        return "Loading...";
    }
  }

  String getNoClinicsMessage(String languageCode) {
    switch (languageCode) {
      case "ru":
        return "Нет клиник для этой категории. Пожалуйста, выберите новую категорию.";
      case "kk":
        return "Бұл санат үшін клиникалар табылмады. Жаңа санатты таңдаңыз.";
      default:
        return "No clinics found for this category. Please select a new category.";
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!success) {
        throw 'Could not launch $url';
      }
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _saveChatHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("chats", jsonEncode(chats));

    if (selectedCategory != null) {
      await prefs.setString("selectedCategory", selectedCategory!);
    }
    if (selectedCountry != null) {
      await prefs.setString("selectedCountry", selectedCountry!);
    }
    if (selectedClinic != null) {
      await prefs.setString("selectedClinic", selectedClinic!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color;
    final appLocalizations = AppLocalizations.of(context);

    if (appLocalizations == null) {
      return Scaffold(body: Center(child: Text('Localizations not available')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          appLocalizations.translate('ai_chat'),
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        elevation: 0,
        child: Column(
          children: [
            Container(
              color: Colors.blueAccent,
              height: 80,
              child: Center(child: SizedBox(height: 10)),
            ),
            ListTile(
              leading: Icon(
                isClinicMode ? Icons.home : Icons.local_hospital_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                isClinicMode
                    ? appLocalizations.translate('main')
                    : appLocalizations.translate('clinics'),
                style: TextStyle(color: textColor),
              ),
              onTap: _toggleClinicMode,
            ),
            Divider(color: Theme.of(context).dividerColor),
            ListTile(
              leading: Icon(
                Icons.add,
                color: Theme.of(context).iconTheme.color,
              ),
              title: Text(
                appLocalizations.translate('new_chat'),
                style: TextStyle(color: textColor),
              ),
              onTap: _startNewChat,
            ),
            Divider(color: Theme.of(context).dividerColor),
            Expanded(
              child: ListView.builder(
                itemCount: groupChatsByDate().length,
                itemBuilder: (context, index) {
                  String date = groupChatsByDate().keys.toList()[index];
                  List<String> chatIds = groupChatsByDate()[date]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          date,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      ...chatIds.map((chatId) {
                        return ListTile(
                          title: Text(
                            chatId,
                            style: TextStyle(color: textColor),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            onPressed: () => _deleteChat(chatId),
                          ),
                          onTap: () {
                            setState(() {
                              selectedChat = chatId;
                              messages = chats[chatId] ?? [];
                            });
                            _saveChats();
                            _saveChatHistory();
                            Navigator.pop(context);
                          },
                        );
                      }),
                      Divider(color: Theme.of(context).dividerColor),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child:
                messages.isEmpty
                    ? Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset("images/star.png", width: 38, height: 38),
                          const SizedBox(width: 10),
                          Text(
                            appLocalizations.translate('text'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isUser = message["isUser"] as bool;
                        return Column(
                          crossAxisAlignment:
                              isUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    isUser
                                        ? Colors.blueAccent
                                        : Colors.grey[400],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child:
                                  (message["text"] != null &&
                                          message["text"]
                                              .toString()
                                              .trim()
                                              .isNotEmpty)
                                      ? MarkdownBody(
                                        data: message["text"],
                                        onTapLink: (text, href, title) {
                                          if (href != null) {
                                            _launchURL(href);
                                          }
                                        },
                                        styleSheet: MarkdownStyleSheet(
                                          a: TextStyle(
                                            color: const Color.fromARGB(255, 15, 94, 130),
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      )
                                      : const Text("No message available"),
                            ),
                            if (selectedLanguageCode == null &&
                                message.containsKey("buttons") &&
                                index == messages.length - 1)
                              Wrap(
                                spacing: 8.0,
                                children:
                                    (message["buttons"] as List<dynamic>)
                                        .map(
                                          (langLabel) => GestureDetector(
                                            onTap:
                                                () => handleLanguageSelection(
                                                  langLabel,
                                                  context,
                                                ),
                                            child: Chip(
                                              label: Text(
                                                langLabel,
                                                style: const TextStyle(
                                                  color: Colors.deepPurple,
                                                ),
                                              ),
                                              backgroundColor:
                                                  Colors.deepPurple.shade50,
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            if (isClinicMode &&
                                selectedLanguageCode != null &&
                                selectedCategory == null &&
                                index == messages.length - 1)
                              Wrap(
                                spacing: 8.0,
                                children:
                                    availableCategories
                                        .map(
                                          (category) => GestureDetector(
                                            onTap:
                                                () => handleCategorySelection(
                                                  category,
                                                ),
                                            child: Chip(
                                              label: Text(
                                                category,
                                                style: const TextStyle(
                                                  color: Colors.blueAccent,
                                                ),
                                              ),
                                              backgroundColor:
                                                  Colors.blue.shade50,
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            if (isClinicMode &&
                                selectedCategory != null &&
                                selectedCountry == null &&
                                index == messages.length - 1 &&
                                availableCountries.isNotEmpty)
                              Wrap(
                                spacing: 8.0,
                                children:
                                    availableCountries
                                        .map(
                                          (country) => GestureDetector(
                                            onTap:
                                                () => _handleCountrySelection(
                                                  country,
                                                ),
                                            child: Chip(
                                              label: Text(
                                                country,
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                ),
                                              ),
                                              backgroundColor:
                                                  Colors.green.shade50,
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),

                            if (isClinicMode &&
                                selectedCategory != null &&
                                selectedCountry != null &&
                                clinics.isNotEmpty &&
                                selectedClinic == null &&
                                index == messages.length - 1)
                              Wrap(
                                spacing: 8.0,
                                children:
                                    clinics
                                        .map(
                                          (clinic) => GestureDetector(
                                            onTap:
                                                () => _selectClinic(
                                                  clinic['name'],
                                                ),
                                            child: Chip(
                                              label: Text(
                                                clinic['name'],
                                                style: TextStyle(
                                                  color: Colors.blueAccent,
                                                ),
                                              ),
                                              backgroundColor:
                                                  Colors.blue.shade50,
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            if (isClinicMode &&
                                selectedClinic != null &&
                                index == messages.length - 1)
                              Wrap(
                                spacing: 8.0,
                                children:
                                    _getOptionButtons(selectedLanguageCode!)
                                        .map(
                                          (option) => GestureDetector(
                                            onTap: () {
                                              handleOptionSelection(
                                                option,
                                                category: selectedCategory,
                                                country: selectedCountry,
                                              );
                                            },
                                            child: Chip(label: Text(option)),
                                          ),
                                        )
                                        .toList(),
                              ),
                          ],
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText:
                          isClinicMode
                              ? (selectedCategory == null
                                  ? "Enter clinic category (e.g., Dentist)"
                                  : (selectedCountry == null
                                      ? "Enter country from list"
                                      : (selectedClinic == null
                                          ? "Select a clinic"
                                          : "Choose an option")))
                              : appLocalizations.translate('ask_any'),
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                FloatingActionButton(
                  backgroundColor: Colors.blueAccent,
                  elevation: 0,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
