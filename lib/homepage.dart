import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/login.dart';
import 'package:logger/logger.dart';
// ignore: unused_import
import 'csv_service.dart';

var logger = Logger();

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  //late Future<List<Map<String, String>>> futureClinics;
  TextEditingController searchController = TextEditingController();
  String selectedTreatment = "";
  List<String> categories = [];
  List<Map<String, String>> clinics = [];
  List<Map<String, String>> filteredClinics = [];

  signout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchCategoriesAndClinics(selectedTreatment);
  }

  Future<List<Map<String, String>>> fetchCategoriesAndClinics(
    String category,
  ) async {
    var clinicsData =
        await FirebaseFirestore.instance
            .collection('clinics')
            .where('treatment', isEqualTo: category)
            .get();

    List<Map<String, String>> clinicsList = [];

    for (var doc in clinicsData.docs) {
      Map<String, String> clinicInfo = {
        "name": doc['Clinics'],
        "address": doc['Address'],
        "phone": doc['Phone_number'],
        "description": doc['Description'],
      };
      clinicsList.add(clinicInfo);
    }

    return clinicsList;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "OtaMed",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blueAccent,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: "Search",
                            hintStyle: TextStyle(color: Colors.white),
                            prefixIcon: Icon(Icons.search, color: Colors.white),
                            fillColor: Colors.white24,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    IconButton(
                      icon: Image.asset(
                        'images/filter.png',
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        String? result = await showFilterPopup(context);
                        if (result != null) {
                          setState(() {
                            selectedTreatment = result;
                          });
                          await fetchCategoriesAndClinics(result);
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  color: categories.isEmpty ? Colors.blue : Colors.transparent,
                  child: Column(
                    children: [
                      if (categories.isNotEmpty)
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedTreatment = category;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              padding: EdgeInsets.all(10),
              child:
                  filteredClinics.isNotEmpty
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Clinics:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredClinics.length,
                              itemBuilder: (context, index) {
                                var clinic = filteredClinics[index];
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 5),
                                  child: Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          isDarkMode
                                              ? Colors.grey[900]
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              isDarkMode
                                                  ? Colors.black54
                                                  : Colors.black,
                                          blurRadius: 5,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          clinic["name"]!,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color:
                                                isDarkMode
                                                    ? Colors.white
                                                    : Colors.blueAccent,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          "Address: ${clinic["address"]!}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          "Phone: ${clinic["phone"]!}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          clinic["description"]!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                      : Center(
                        child: Text(
                          "No clinics available",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> showFilterPopup(BuildContext context) async {
  String? selectedTreatment;
  String? selectedCountry;
  List<String> availableCountries = ["Europe", "Asia", "Eurasia"];
  Map<String, List<String>> countryCities = {
    "Europe": [
      "Germany",
      "France",
      "Great Britain",
      "Spain",
      "Italy",
      "Switzerland",
      "Austria",
      "Netherlands",
      "Sweden",
      "Turkey",
    ],
    "Asia": [
      "South Korea",
      "Japan",
      "China",
      "India",
      "Thailand",
      "Singapore",
      "Malaysia",
      "UAE",
      "Taiwan",
      "Vietnam",
    ],
    "Eurasia": ["Kazakhstan", "Russia", "Uzbekistan", "Azerbaijan", "Georgia"],
  };

  Map<String, List<String>> citiesByCountry = {
    "Germany": ["Berlin", "Munich", "Hamburg", "Frankfurt"],
    "France": ["Paris", "Lyon", "Marseille"],
    "Great Britain": ["London", "Manchester", "Edinburgh"],
    "Spain": ["Madrid", "Barselona"],
    "Italy": ["Rome", "Milan"],
    "Switzerland": ["Zurich", "Geneva"],
    "Austria": ["Vena"],
    "Netherlands": ["Amsterdam"],
    "Sweden": ["Stockholm"],
    "Turkey": ["Istanbul", "Ankara"],
    "South Korea": ["Seoul", "Pusan"],
    "Japan": ["Tokyo", "Osaka", "Kyoto"],
    "China": ["Beijing", "Shanghai", "Guangzhou"],
    "India": ["Delhi", "Mumbai", "Bangalore"],
    "Thailand": ["Bangkok", "Phuket"],
    "Singapore": ["Singapore"],
    "Malaysia": ["Kuala Lumpur"],
    "UAE": ["Dubai", "Abu Dhabi"],
    "Taiwan": ["Taipei"],
    "Vietnam": ["Hanoi", "Ho Chi Minh City"],
    "Kazakhstan": ["Almaty", "Astana", "Shymkent"],
    "Russia": ["Moscow", "Saint Petersburg", "Novosibirsk"],
    "Uzbekistan": ["Tashkent"],
    "Azerbaijan": ["Baku"],
    "Georgia": ["Tbilisi"],
  };
  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(10),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Filter",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 5),
                      child: Text(
                        "Type of Operations",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          [
                            "Plastic Surgery",
                            "Orthopedic",
                            "Oncological",
                            "Neurosurgery",
                          ].map((treatment) {
                            bool isSelected = selectedTreatment == treatment;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedTreatment = treatment;
                                });
                                Navigator.pop(context, treatment);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Colors.blueAccent
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Text(
                                  treatment,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 5),
                      child: Text(
                        "Type of Treatment",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          [
                            "ENT",
                            "Gastroenterology",
                            "Urology",
                            "Ophthalmology",
                            "Dermatology",
                            "Physical Therapy & Rehabilitation",
                          ].map((treatment) {
                            bool isSelected = selectedTreatment == treatment;
                            return GestureDetector(
                              onTap:
                                  () => setState(
                                    () => selectedTreatment = treatment,
                                  ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Colors.blueAccent
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Text(
                                  treatment,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 5),
                      child: Text(
                        "Country",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          availableCountries.map((continent) {
                            return GestureDetector(
                              onTap:
                                  () => setState(
                                    () => selectedCountry = continent,
                                  ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                  color:
                                      selectedCountry == continent
                                          ? Colors.blueAccent
                                          : Colors.white,
                                ),
                                child: Text(
                                  continent,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color:
                                        selectedCountry == continent
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    if (selectedCountry != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 5),
                        child: Text(
                          "City",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            countryCities[selectedCountry]!.map((country) {
                              return GestureDetector(
                                onTap:
                                    () => setState(
                                      () => selectedCountry = country,
                                    ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10),
                                    color:
                                        selectedCountry == country
                                            ? Colors.blueAccent
                                            : Colors.white,
                                  ),
                                  child: Text(
                                    country,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color:
                                          selectedCountry == country
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                    if (selectedCountry != null &&
                        citiesByCountry.containsKey(selectedCountry)) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 5),
                        child: Text(
                          "Cities in $selectedCountry",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        height: 200,
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children:
                                citiesByCountry[selectedCountry]!.map((city) {
                                  return GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      child: Text(
                                        city,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class CustomSearchDelegate extends SearchDelegate {
  final List<String> items;
  CustomSearchDelegate(this.items);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = "";
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return ListTile(title: Text(query));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> suggestions =
        items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
        );
      },
    );
  }
}
