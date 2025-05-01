import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/edit_page.dart';
import 'package:flutter_application_1/localization/app_localization.dart';
import 'package:flutter_application_1/login.dart';
import 'package:logger/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

var logger = Logger();

class HomeAdminpage extends ConsumerStatefulWidget {
  final Set<String> favoriteClinics;
  final List<Map<String, String>> filteredClinics;
  final Function(List<Map<String, String>>) updateFilteredClinics;
  const HomeAdminpage({
    super.key,
    required this.favoriteClinics,
    required this.filteredClinics,
    required this.updateFilteredClinics,
  });

  @override
  ConsumerState<HomeAdminpage> createState() => _HomeAdminpageState();
}

class _HomeAdminpageState extends ConsumerState<HomeAdminpage> {
  TextEditingController searchController = TextEditingController();
  String selectedTreatment = "";
  String selectedCountry = "";
  String selectedCity = "";
  List<String> categories = [];
  List<Map<String, dynamic>> clinics = [];
  List<Map<String, dynamic>> filteredClinics = [];
  List<Map<String, dynamic>> localizedClinics = [];
  List<String> previousSearches = [];
  List<Map<String, dynamic>> clinicSuggestions = [];
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

  Future<List<Map<String, dynamic>>> fetchCategoriesAndClinics(
    String category,
    String country,
    String city,
    BuildContext context,
  ) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final localizedCategory = appLocalizations.translate(category);
    final langCode = appLocalizations.locale.languageCode;

    // Dynamic translation keys for the fields
    final translatedCategoryKey = getTranslatedCategoryField(langCode);
    final translatedCountryKey = getTranslatedKey('Country', langCode);
    final translatedCityKey = getTranslatedKey('City', langCode);
    final translatedClinicsKey = getTranslatedKey('Clinics', langCode);
    final translatedAddressKey = getTranslatedKey('Address', langCode);
    final translatedDescriptionKey = getTranslatedKey('Description', langCode);

    logger.w('Localized category name: $localizedCategory');
    logger.w('Querying with translatedCategoryKey: $translatedCategoryKey');

    // Query Firestore with translated fields
    final categorySnap =
        await FirebaseFirestore.instance
            .collection('translation_clinics')
            .where(translatedCategoryKey, isEqualTo: localizedCategory)
            .where(translatedCountryKey, isEqualTo: country)
            .where(translatedCityKey, isEqualTo: city)
            .get();
    // List<Map<String, dynamic>> localizedClinics = [];

    for (var doc in categorySnap.docs) {
      localizedClinics.add({
        "name": doc[translatedClinicsKey] ?? doc['Clinics'],
        "category": doc[translatedCategoryKey] ?? doc['Category'],
        "City": doc[translatedCityKey] ?? doc['City'],
        "Country": doc[translatedCountryKey] ?? doc['Country'],
        "address": doc[translatedAddressKey] ?? doc['Address'],
        "phone": doc['Phone_number'],
        "rating": doc['rating'],
        "review": doc['Review'],
        "description": doc[translatedDescriptionKey] ?? doc['Description'],
        "site_url": doc['Site_url'],
        "availability": doc['Availability'],
      });

      for (var doc in categorySnap.docs) {
        localizedClinics.add({
          "id": doc.id,
          "name": doc[translatedClinicsKey] ?? doc['Clinics'],
          "category": doc[translatedCategoryKey] ?? doc['Category'],
          "City": doc[translatedCityKey] ?? doc['City'],
          "Country": doc[translatedCountryKey] ?? doc['Country'],
          "address": doc[translatedAddressKey] ?? doc['Address'],
          "phone": doc['Phone_number'],
          "rating": doc['rating'],
          "review": doc['Review'],
          "description": doc[translatedDescriptionKey] ?? doc['Description'],
          "site_url": doc['Site_url'],
          "availability": doc['Availability'],
        });
      }
    }
      return localizedClinics;
    }

  void filterClinics(String query) {
  final q = query.trim().toLowerCase();

  final results = localizedClinics.where((clinic) {
    final name = (clinic["name"] ?? "").toString().toLowerCase();
    final address = (clinic["address"] ?? "").toString().toLowerCase();
    return name.contains(q) || address.contains(q);
  }).toList();
  final seenNames = <String>{};
  final uniqueResults = results.where((clinic) {
    final name = (clinic["name"] ?? "").toString();
    return seenNames.add(name); 
  }).toList();

  setState(() {
    filteredClinics = uniqueResults;
    if (searchController.text.trim().toLowerCase() == q && q.isNotEmpty) {
      clinicSuggestions = uniqueResults;
    }
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
      List<Map<String, dynamic>> fetchedClinics =
          await fetchCategoriesAndClinics(category, country, city, context);
      if (fetchedClinics.isNotEmpty) {
        setState(() {
          localizedClinics = fetchedClinics;
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

    Future<void> deleteClinic(String docId) async {
      try {
        await FirebaseFirestore.instance
            .collection('translation_clinics')
            .doc(docId)
            .delete();
        logger.i("Clinic deleted: $docId");
      } catch (e) {
        logger.e("Delete failed: $e");
      }
    }

@override
Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final isDarkMode = theme.brightness == Brightness.dark;
      final colorScheme = theme.colorScheme;
      return Scaffold(
        backgroundColor: colorScheme.surface,
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
                mainAxisSize: MainAxisSize.min,
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
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.white,
                              ),
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
                  SizedBox(height: 12),
                  if (clinicSuggestions.isNotEmpty)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      constraints: BoxConstraints(maxHeight: 130),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: clinicSuggestions.length,
                        separatorBuilder:
                            (context, index) =>
                                Divider(color: Colors.grey.shade300, height: 8),
                        itemBuilder: (context, index) {
                          final clinic = clinicSuggestions[index];
                          return InkWell(
                            onTap: () {
                              final selectedName = clinic["name"] ?? "";
                              //filterClinics(searchController.text);
                              setState(() {
                                filterClinics(selectedName);
                                clinicSuggestions.clear();
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      clinic["name"] ?? "",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
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
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                              ),
                            ),
                            SizedBox(height: 10),
                            Expanded(
                              child: ListView.builder(
                                itemCount: filteredClinics.length,
                                itemBuilder: (context, index) {
                                  var clinic = filteredClinics[index];

                                  return GestureDetector(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 5,
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color:
                                                isDarkMode
                                                    ? Colors.white
                                                    : Colors.grey,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorScheme.onSurface,
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    clinic["name"]!,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.color,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.edit,
                                                        color: Colors.orange,
                                                      ),
                                                      onPressed: () async {
                                                        final langCode =
                                                            AppLocalizations.of(
                                                                  context,
                                                                )!
                                                                .locale
                                                                .languageCode;
                                                        final updatedClinic =
                                                            await Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (
                                                                      _,
                                                                    ) => EditPage(
                                                                      clinic:
                                                                          clinic,
                                                                      langCode:
                                                                          langCode,
                                                                    ),
                                                              ),
                                                            );

                                                        if (updatedClinic !=
                                                                null &&
                                                            updatedClinic
                                                                is Map<
                                                                  String,
                                                                  dynamic
                                                                >) {
                                                          setState(() {
                                                            final index =
                                                                filteredClinics
                                                                    .indexWhere(
                                                                      (c) =>
                                                                          c["name"] ==
                                                                          clinic["name"],
                                                                    );
                                                            if (index != -1) {
                                                              filteredClinics[index] =
                                                                  updatedClinic;
                                                            }
                                                            final filteredIndex = filteredClinics
                                                                .indexWhere(
                                                                  (c) =>
                                                                      c["name"] ==
                                                                      clinic["name"],
                                                                );
                                                            if (filteredIndex !=
                                                                -1) {
                                                              filteredClinics[filteredIndex] =
                                                                  updatedClinic;
                                                            }
                                                          });

                                                          logger.i(
                                                            "Updated Clinic in UI: $updatedClinic",
                                                          );
                                                        }
                                                      },
                                                    ),

                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () async {
                                                        bool?
                                                        confirmed = await showDialog(
                                                          context: context,
                                                          builder:
                                                              (
                                                                context,
                                                              ) => AlertDialog(
                                                                title: Text(
                                                                  "Delete Clinic",
                                                                ),
                                                                content: Text(
                                                                  "Are you sure you want to delete this clinic?",
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed:
                                                                        () => Navigator.pop(
                                                                          context,
                                                                          false,
                                                                        ),
                                                                    child: Text(
                                                                      "Cancel",
                                                                    ),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed:
                                                                        () => Navigator.pop(
                                                                          context,
                                                                          true,
                                                                        ),
                                                                    child: Text(
                                                                      "Delete",
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                        );

                                                        if (confirmed == true) {
                                                          final docId =
                                                              clinic['id'];
                                                          await deleteClinic(
                                                            docId,
                                                          );
                                                          updateClinics(
                                                            selectedTreatment,
                                                            selectedCountry,
                                                            selectedCity,
                                                          );
                                                          logger.w(
                                                            "Clinic deleted: ${clinic['name']}",
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),

                                            SizedBox(height: 5),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: 14,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).iconTheme.color,
                                                ),
                                                SizedBox(width: 5),
                                                Expanded(
                                                  child: Text(
                                                    clinic['address']!,
                                                    style: TextStyle(
                                                      color:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.color,
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
                                                      Theme.of(
                                                        context,
                                                      ).iconTheme.color,
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
                                                        Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.color,
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
                                                    Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            buildClinicRating(
                                              clinic['rating']?.toString() ??
                                                  "0.0",
                                              "${(int.tryParse(clinic['review']?.toString() ?? '0')?.abs() ?? 0)}",
                                              context,
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
Widget buildClinicRating(
    String rating,
    String reviewCount,
    BuildContext context,
  ) {
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
            color: Theme.of(context).textTheme.bodyMedium?.color,
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
    Map<String, Map<String, dynamic>> listData = {};

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

    Future<Map<String, dynamic>> fetchCountriesAndCategories(
      String treatment,
      BuildContext context,
    ) async {
      final appLocalizations = AppLocalizations.of(context)!;
      final localizedCategory = appLocalizations.translate(treatment);
      final langCode = appLocalizations.locale.languageCode;

      final translatedCountryKey = getTranslatedKey('Country', langCode);
      final translatedCityKey = getTranslatedKey('City', langCode);
      final translatedCategoryKey = getTranslatedCategoryField(langCode);

      logger.w('Localized category name: $localizedCategory');
      logger.w('Querying with translatedCategoryKey: $translatedCategoryKey');

      final categorySnap =
          await FirebaseFirestore.instance
              .collection('translation_clinics')
              .where(translatedCategoryKey, isEqualTo: localizedCategory)
              .get();
      if (categorySnap.docs.isEmpty) {
        logger.w("No data found for treatment: $treatment");
        return {};
      }
      logger.w('Categories from Firestore:', categorySnap);

      final Map<String, List<String>> countryCityMap = {};

      for (var doc in categorySnap.docs) {
        final country = doc[translatedCountryKey] ?? doc['Country'].toString();
        final city = doc[translatedCityKey] ?? doc['City'].toString();

        if (country.isNotEmpty && city.isNotEmpty) {
          countryCityMap.putIfAbsent(country, () => []);
          if (!countryCityMap[country]!.contains(city)) {
            countryCityMap[country]!.add(city);
          }
        }
      }
      return countryCityMap;
    }

    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color;
    final appLocalizations = AppLocalizations.of(context);
    return showDialog<Map<String, dynamic>>(
      // ignore: use_build_context_synchronously
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
                          appLocalizations!.translate('type_operations'),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            [
                              appLocalizations.translate('plastic_surgery'),
                              appLocalizations.translate('orthopedic'),
                              appLocalizations.translate('oncological'),
                              appLocalizations.translate('neurosurgery'),
                            ].map((treatment) {
                              bool isSelected = selectedTreatment == treatment;
                              return GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    selectedTreatment = treatment as String?;
                                    selectedCountry = null;
                                    selectedCity = null;
                                  });
                                  //final langCode = appLocalizations.locale.languageCode;
                                  var fetchedData =
                                      await fetchCountriesAndCategories(
                                        treatment,
                                        context,
                                      );
                                  setState(() {
                                    listData[treatment] = fetchedData;
                                  });
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    scrollToCountries(treatment);
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
                                            ? (theme.brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.blue)
                                            : theme.scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          theme.brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  child: Text(
                                    treatment,
                                    style: TextStyle(
                                      color: textColor,
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
                          appLocalizations.translate('type_treatment'),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            [
                              appLocalizations.translate('ent'),
                              appLocalizations.translate('gastroenterology'),
                              appLocalizations.translate('urology'),
                              appLocalizations.translate('ophthalmology'),
                              appLocalizations.translate('dermatology'),
                              appLocalizations.translate('physical'),
                            ].map((treatment) {
                              bool isSelected = selectedTreatment == treatment;
                              return GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    selectedTreatment = treatment;
                                    selectedCountry = null;
                                    selectedCity = null;
                                  });
                                  //final langCode = appLocalizations.locale.languageCode;
                                  var fetchedData =
                                      await fetchCountriesAndCategories(
                                        treatment,
                                        context,
                                      );
                                  setState(() {
                                    listData[treatment] = fetchedData;
                                  });
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    scrollToCountries(treatment);
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
                                            ? (theme.brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.blue)
                                            : theme.scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          theme.brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  child: Text(
                                    treatment,
                                    style: TextStyle(
                                      color: textColor,
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
                                    });
                                    scrollToCountries(selectedTreatment!);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            theme.brightness == Brightness.dark
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      color:
                                          selectedCountry == country
                                              ? (theme.brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.blue)
                                              : Colors.transparent,
                                    ),
                                    child: Text(
                                      country,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                      if (selectedCountry != null &&
                          listData[selectedTreatment] != null &&
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
                                      listData[selectedTreatment]![selectedCountry]!.map<
                                        Widget
                                      >((city) {
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
                                                  "category": selectedTreatment,
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
                                              color:
                                                  theme.scaffoldBackgroundColor,
                                              border: Border.all(
                                                color:
                                                    theme.brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              city,
                                              style: TextStyle(
                                                color: textColor,
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
