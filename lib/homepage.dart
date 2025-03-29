import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/description.dart';
import 'package:flutter_application_1/login.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/favorite_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

var logger = Logger();

class Homepage extends ConsumerStatefulWidget {
  final Set<String> favoriteClinics;
  final Function(String) toggleFavorite;
  final List<Map<String, String>> filteredClinics;
  final Function(List<Map<String, String>>) updateFilteredClinics;
  const Homepage({
    super.key,
    required this.favoriteClinics,
    required this.toggleFavorite,
    required this.filteredClinics,
    required this.updateFilteredClinics,
  });

  @override
  ConsumerState<Homepage> createState() => _HomepageState();
}

class _HomepageState extends ConsumerState<Homepage> {
  TextEditingController searchController = TextEditingController();
  String selectedTreatment = "";
  String selectedCountry = "";
  String selectedCity = "";
  List<String> categories = [];
  List<Map<String, String>> clinics = [];
  List<Map<String, String>> filteredClinics = [];
  List<String> previousSearches = [];
  List<Map<String, String>> clinicSuggestions = [];
  List<Map<String, String>> availableClinicsList = [];
  List<Map<String, dynamic>> favoriteClinics = [];
  bool isFiltered = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.filteredClinics.isEmpty) {
        widget.updateFilteredClinics([]);
      }
    });
  }


  Future<List<Map<String, String>>> fetchCategoriesAndClinics(
    String category,
    String country,
    String city,
  ) async {
    category = category.trim();
    country = country.trim();
    city = city.trim();
    var clinicsData =
        await FirebaseFirestore.instance
            .collection('clinics')
            .where('Category', isEqualTo: category)
            .where('Country', isEqualTo: country)
            .where('City', isEqualTo: city)
            .get();

    for (var doc in clinicsData.docs) {
      Map<String, String> clinicInfo = {
        "name": doc['Clinics'],
        "address": doc['Address'],
        "phone": doc['Phone_number'],
        "rating": doc['rating'],
        "review": doc['Review'],
        "description": doc['Description'],
        "site_url": doc['Site_url'],
        "availability": doc['Availability'],
      };
      clinics.add(clinicInfo);
    }
    return clinics;
  }

  void filterClinics(String query) {
    query = query.trim().toLowerCase();
    logger.w("Filtering with query: $query");
    logger.w("clinics before filtering: $clinics");

    filteredClinics =
        clinics
            .where(
              (clinic) =>
                  (clinic["name"] ?? "").toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  (clinic["address"] ?? "").toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  (clinic["category"] ?? "").toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();

    logger.w("Filtered Clinics: $filteredClinics");

    setState(() {
      clinicSuggestions = filteredClinics;
    });
  }

  void onSearchChanged() {
    if (searchController.text.isNotEmpty) {
      filterClinics(searchController.text);
    } else {
      setState(() {
        clinicSuggestions = [];
      });
    }
  }



  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void updateClinics(String category, String country, String city) async {
    if (isFiltered) {
      setState(() {
        filteredClinics.clear();
      });
    }
    List<Map<String, String>> fetchedClinics = await fetchCategoriesAndClinics(
      category,
      country,
      city,
    );
    if (fetchedClinics.isNotEmpty) {
      setState(() {
        filteredClinics = fetchedClinics;
        isFiltered = true;
      });
    } else {
      setState(() {
        filteredClinics.clear();
        isFiltered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
     final favoriteClinics = ref.watch(favoriteProvider.notifier);
    final favorites = ref.watch(favoriteProvider);
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
                          onChanged: (value) => onSearchChanged(),
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
                        final result = await showFilterPopup(context);
                        if (result != null) {
                          setState(() {
                            selectedTreatment = result["category"];
                            selectedCountry = result["country"];
                            selectedCity = result["city"];
                          });
                          updateClinics(
                            selectedTreatment,
                            selectedCountry,
                            selectedCity,
                          );
                          logger.w(
                            "Selected: $selectedTreatment, $selectedCountry, $selectedCity",
                          );
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                if (clinicSuggestions.isNotEmpty)
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: ListView.builder(
                        itemCount: clinicSuggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(clinicSuggestions[index]["name"] ?? ""),
                            subtitle: Text(
                              clinicSuggestions[index]["category"] ?? "",
                            ),
                            onTap: () {
                              searchController.text =
                                  clinicSuggestions[index]["name"] ?? "";
                              filterClinics(searchController.text);
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                                final isFavorite = favorites.any((c) => c["name"] == clinic["name"]);

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                ClinicDetail(clinic: clinic),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 5),
                                    child: Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.black
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              isDarkMode
                                                  ? Colors.white
                                                  : Colors.grey,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                isDarkMode
                                                    ? Colors.grey
                                                    : Colors.blueAccent,
                                            blurRadius: 5,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  clinic["name"]!,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color:
                                                        isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                              ),
                                               IconButton(
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border, 
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        favoriteClinics.toggleFavorite(clinic);
                        logger.w("Favorite Clinics Updated: $favoriteClinics");
                      },
                    ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  clinic['address']!,
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.phone,
                                                size: 14,
                                                color:
                                                    isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                clinic["phone"]?.isNotEmpty ==
                                                        true
                                                    ? clinic["phone"]!
                                                    : "No phone number",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                  fontStyle:
                                                      clinic["phone"]
                                                                  ?.isNotEmpty ==
                                                              true
                                                          ? FontStyle.normal
                                                          : FontStyle.italic,
                                                ),
                                              ),
                                            ],
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
                                          SizedBox(height: 8),
                                            buildClinicRating(
                                                clinic['rating']!,
                                                "${(int.tryParse(clinic['review']?.toString() ?? '0')?.abs() ?? 0)}",
                                              ),
                                        ],
                                      ),
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

Widget buildClinicRating(String rating, String reviewCount) {
  double ratingValue = double.tryParse(rating) ?? 0.0;
  int fullStars = ratingValue.floor();
  bool hasHalfStar = ratingValue - fullStars >= 0.5;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        rating,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),

      SizedBox(width: 4),
      ...List.generate(
        fullStars,
        (index) => Icon(Icons.star, color: Colors.amber, size: 16),
      ),
      if (hasHalfStar) Icon(Icons.star_half, color: Colors.amber, size: 16),

      SizedBox(width: 4),
      Text(
        "($reviewCount)",
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
    ],
  );
}

Future<Map<String, dynamic>?> showFilterPopup(
  BuildContext context, {
  String? selectedTreatment,
  String? selectedContinent,
  String? selectedCountry,
  String? selectedCity,
}) async {
  final ScrollController scrollController = ScrollController();
  Map<String, Map<String, List<String>>> listData = {};

  void scrollToSection(double offset) {
  Future.delayed(Duration(milliseconds: 300), () {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        offset,
        duration: Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      logger.w("ScrollController is not attached to any scroll view.");
    }
  });
}


  void scrollToCountries(String treatment) {
    if (listData.containsKey(treatment)) {
      List<String> countries = listData[treatment]!.keys.toList();

      if (countries.length > 1) {
        scrollToSection(150);
      }
    }
  }

  void scrollToCities() {
    scrollToSection(200);
  }

  Future<Map<String, List<String>>> fetchCountriesAndCities(
    String treatment,
  ) async {
    treatment = treatment.trim();

    var treatmentSnapshot =
        await FirebaseFirestore.instance
            .collection('clinics')
            .where('Category', isEqualTo: treatment)
            .get();

    if (treatmentSnapshot.docs.isEmpty) {
      logger.w("No data found for treatment: $treatment");
      return {};
    }

    Map<String, List<String>> countryCityMap = {};

    for (var doc in treatmentSnapshot.docs) {
      String country = doc['Country'];
      String city = doc['City'];

      if (country.isNotEmpty && city.isNotEmpty) {
        countryCityMap.putIfAbsent(country, () => []);
        if (!countryCityMap[country]!.contains(city)) {
          countryCityMap[country]!.add(city);
        }
      }
    }

    listData[treatment] = countryCityMap;

    logger.w("Fetched treatment data: $listData");

    return countryCityMap;
  }

  return showDialog<Map<String, dynamic>>(
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
                controller: scrollController,
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
                          onPressed: () {
                            Navigator.pop(context);
                          },
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
                            "Plastic surgery clinic",
                            "Orthopedic clinic",
                            "Oncological clinics",
                            "Neurosurgery",
                          ].map((treatment) {
                            bool isSelected = selectedTreatment == treatment;
                            return GestureDetector(
                              onTap: () async {
                                setState(() {
                                  selectedTreatment = treatment;
                                  selectedCountry = null;
                                  selectedCity = null;
                                });
                                var fetchedData = await fetchCountriesAndCities(
                                  treatment,
                                );
                                setState(() {
                                  listData[treatment] = fetchedData;
                                });
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
                            "Ent clinics",
                            "Gastroenterology clinics",
                            "Urology  clinics",
                            "Ophthalmology  clinics",
                            "Dermatology clinics",
                            "Physical Therapy & Rehabilitation Clinic",
                          ].map((treatment) {
                            bool isSelected = selectedTreatment == treatment;
                            return GestureDetector(
                              onTap: () async {
                                setState(() {
                                  selectedTreatment = treatment;
                                  selectedCountry = null;
                                  selectedCity = null;
                                });
                                var fetchedData = await fetchCountriesAndCities(
                                  treatment,
                                );

                                setState(() {
                                  listData[treatment] = fetchedData;
                                });
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
                    if (selectedTreatment != null &&
                        listData.containsKey(selectedTreatment) &&
                        listData[selectedTreatment]!.isNotEmpty) ...[
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
                            listData[selectedTreatment]!.keys.map((country) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCountry = country;
                                    selectedCity = null;
                                  });
                                  scrollToCountries(selectedTreatment!);
                                },
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
                        listData[selectedTreatment]!.containsKey(
                          selectedCountry,
                        )) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 5),
                        child: Text(
                          "Cities in $selectedCountry",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 200,
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children:
                                    listData[selectedTreatment]![selectedCountry]!
                                        .map((city) {
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                selectedCity = city;
                                              });
                                              scrollToCities();
                                              if (selectedTreatment != null &&
                                                  selectedCountry != null &&
                                                  selectedCity != null) {
                                                if (Navigator.canPop(context)) {
                                                  Navigator.pop(context, {
                                                    "category":
                                                        selectedTreatment,
                                                    "country": selectedCountry,
                                                    "city": selectedCity,
                                                  });
                                                }
                                              } else {
                                                logger.w(
                                                  "Please select a treatment, country, and city first.",
                                                );
                                              }
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 15,
                                                vertical: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color:
                                                      Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? Colors.white70
                                                          : Colors.grey,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color:
                                                    Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? Colors.black54
                                                        : Colors.white,
                                              ),
                                              child: Text(
                                                city,
                                                style: TextStyle(
                                                  color:
                                                      Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          );
                                        })
                                        .toList(),
                              ),
                            ),
                          ),
                        ],
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
