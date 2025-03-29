import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/gemini.dart';
import 'package:flutter_application_1/history_screen.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<String> availableCountries = [];
  bool isClinicMode = false;
  String? selectedCategory;
  String? selectedCountry;
  String? selectedClinic;
  String? selectedChat;
  String? selectedDate;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _loadChats();
  }

void _loadChats() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? storedChats = prefs.getString("chats");

  if (storedChats != null && storedChats.isNotEmpty) {
    Map<String, dynamic> decodedChats = jsonDecode(storedChats);

    // ✅ Explicitly cast each chat entry to List<Map<String, dynamic>>
    Map<String, List<Map<String, dynamic>>> loadedChats = decodedChats.map(
      (key, value) => MapEntry(
        key,
        List<Map<String, dynamic>>.from(
          (value as List).map((e) => Map<String, dynamic>.from(e)),
        ),
      ),
    );

    setState(() {
      chats = loadedChats;
      messages = chats[selectedChat] ?? []; // Ensure messages are updated
    });
  } else {
    setState(() {
      chats.clear();
      messages.clear();
    });
  }
}





/*void _selectChat(String chatId) {
  setState(() {
    selectedChat = chatId;
    messages = chats[chatId]!;
  });
  _saveChatHistory();
  Navigator.pop(context);
}*/


  void _saveChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("chats", jsonEncode(chats));
  }

void _sendMessage() async {
  if (_controller.text.isEmpty || selectedChat == null) return;
  
  String userMessage = _controller.text.trim();
  String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

  setState(() {
    messages = messages ?? [];
    messages.add({
      "text": userMessage,
      "isUser": true,
      "date": dateKey,
    });

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

  setState(() {
    chats[newChatId] = []; 
    selectedChat = newChatId; 
    messages = []; 
  });

  _saveChats();
  _saveChatHistory();
  Navigator.pop(context);
}



/*
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


  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }
*/
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

  void _fetchCategories() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('clinics').get();

      List<String> allCategories =
          snapshot.docs
              .where(
                (doc) =>
                    doc.data() != null &&
                    (doc.data() as Map<String, dynamic>).containsKey(
                      'Category',
                    ),
              )
              .map((doc) => doc['Category'].toString().trim())
              .toSet()
              .toList();

      setState(() {
        messages.add({
          "text": "Select a clinic category:",
          "isUser": false,
          "buttons": allCategories,
        });
      });
    } catch (e) {
      logger.e("Error fetching categories: $e");
      setState(() {
        messages.add({
          "text": "Error fetching categories. Please try again.",
          "isUser": false,
        });
      });
    }
  }

  void _handleCategorySelection(String selected) async {
    setState(() {
      selectedCategory = selected;
    });

    QuerySnapshot countrySnapshot =
        await FirebaseFirestore.instance.collection('clinics').get();

    List<String> countries =
        countrySnapshot.docs
            .where(
              (doc) =>
                  (doc.data() as Map<String, dynamic>).containsKey(
                    'Category',
                  ) &&
                  (doc['Category'].toString().trim() == selectedCategory),
            )
            .map((doc) => doc['Country'].toString().trim())
            .toSet()
            .toList();

    if (countries.isEmpty) {
      setState(() {
        messages.add({
          "text": "No countries found for $selectedCategory.",
          "isUser": false,
        });
      });
      return;
    }

    setState(() {
      availableCountries = countries;
      messages.add({
        "text": "Select a country for $selectedCategory:",
        "isUser": false,
        "buttons": countries,
      });
    });
  }

  void _handleCountrySelection(String country) async {
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
            .collection('clinics')
            .where('Category', isEqualTo: selectedCategory)
            .where('Country', isEqualTo: country)
            .get();

    List<Map<String, dynamic>> fetchedClinics =
        clinicSnapshot.docs.map((doc) => {"name": doc['Clinics']}).toList();

    logger.w("Clinics in $country: $fetchedClinics");

    setState(() {
      if (fetchedClinics.isEmpty) {
        messages.add({
          "text": "No clinics found in $country.",
          "isUser": false,
        });
      } else {
        clinics = fetchedClinics;
        messages.add({
          "text": "Here are clinics in $country:",
          "isUser": false,
          "buttons": fetchedClinics.map((c) => c["name"]).toList(),
        });
      }
    });
  }

  void _selectClinic(String clinicName) {
    setState(() {
      selectedClinic = clinicName;
      messages.add({"text": "You selected: $clinicName", "isUser": true});
      messages.add({
        "text": "What would you like to see?",
        "isUser": false,
        "buttons": ["Analysis", "Articles about clinic"],
      });
    });
  }

  void _handleFinalOption(String option) async {
    GeminiAI ai = GeminiAI();
    setState(() {
      messages.add({"isUser": true, "text": option});
      messages.add({"isUser": false, "text": "Loading..."});
    });
    String response = "";

    if (option == "Analysis") {
      response = await ai.analyzeClinic(
        selectedClinic!,
        selectedCategory!,
        selectedCountry!,
      );
    } else if (option == "Articles about clinic") {
      response = await ai.findArticles(selectedClinic!);
    }

    setState(() {
      messages.removeLast();
      messages.add({"isUser": false, "text": response});
    });
    _saveChatHistory();
  }

void _loadChatHistory() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? storedHistory = prefs.getString("chat_history");

  if (storedHistory == null) {
    messages = []; 
  } else {
    setState(() {
      messages = List<Map<String, dynamic>>.from(jsonDecode(storedHistory));
    });
  }
}




  void _saveChatHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("chat_history", jsonEncode(messages));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text("AI Chat", style: theme.appBarTheme.titleTextStyle),
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
              leading: Icon(isClinicMode ? Icons.home : Icons.local_hospital_rounded),
              title: Text(isClinicMode ? "Main" : "Clinics"),
              onTap: _toggleClinicMode,
            ),

            Divider(),
            ListTile(
              leading: Icon(Icons.history),
              title: Text("History"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryScreen()),
                );
              },
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
                          const Text(
                            "Hi! You can ask anything.",
                            style: TextStyle(
                              fontSize: 16,
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
                                        : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                message["text"],
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black,
                                ),
                              ),
                            ),

                            if (isClinicMode &&
                                selectedCategory == null &&
                                index == messages.length - 1)
                              Wrap(
                                spacing: 8.0,
                                children:
                                    messages
                                        .where(
                                          (msg) => msg.containsKey("buttons"),
                                        )
                                        .expand(
                                          (msg) =>
                                              msg["buttons"] as List<String>,
                                        )
                                        .map(
                                          (category) => GestureDetector(
                                            onTap:
                                                () => _handleCategorySelection(
                                                  category,
                                                ),
                                            child: Chip(
                                              label: Text(
                                                category,
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
                                selectedCategory != null &&
                                selectedCountry == null &&
                                index == messages.length - 1)
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
                                                style: TextStyle(
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
                                    ["Analysis", "Articles about clinic"]
                                        .map(
                                          (option) => GestureDetector(
                                            onTap:
                                                isLoading
                                                    ? null
                                                    : () => _handleFinalOption(
                                                      option,
                                                    ),
                                            child: Chip(
                                              label: Text(
                                                option,
                                                style: TextStyle(
                                                  color:
                                                      isLoading
                                                          ? Colors.grey
                                                          : Colors.purple,
                                                ),
                                              ),
                                              backgroundColor:
                                                  isLoading
                                                      ? Colors.grey.shade300
                                                      : Colors.purple.shade50,
                                            ),
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
                              : "Ask anything...",
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

