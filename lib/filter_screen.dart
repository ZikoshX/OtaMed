// lib/state/filter_state.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

var logger = Logger();

  class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FilterScreenState createState() => _FilterScreenState();
}
class _FilterScreenState extends State<FilterScreen> {
  Future<Map<String, dynamic>?> showFilterPopup(
    BuildContext context, {
    String? initialTreatment,
    String? initialContinent,
    String? initialCountry,
    String? initialCity,
  }) async {
    String? selectedTreatment = initialTreatment;
    String? selectedContinent = initialContinent;
    String? selectedCountry = initialCountry;
    String? selectedCity = initialCity;

    final ScrollController scrollController = ScrollController();

    List<String> availableCountries = ["Europe", "Asia", "Eurasia"];
    Map<String, List<String>> countryCities = {
      "Europe": ["Germany", "France", "United Kingdom", "Italy", "Switzerland"],
      "Asia": ["South Korea", "Japan"],
      "Eurasia": ["Kazakhstan", "Russia", "Uzbekistan"],
    };

    Map<String, List<String>> citiesByCountry = {
      "Germany": ["Berlin", "Munich", "Hamburg"],
      "France": ["Paris"],
      "United Kingdom": ["London"],
      "Italy": ["Rome", "Milan"],
      "Switzerland": ["Zurich", "Geneva"],
      "South Korea": ["Seoul"],
      "Japan": ["Tokyo", "Osaka"],
      "Kazakhstan": ["Almaty", "Astana", "Shymkent"],
      "Russia": ["Moscow", "Saint Petersburg"],
      "Uzbekistan": ["Tashkent", "Samarkand"],
    };

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
                        children: [
                          "Plastic surgery clinic",
                          "Orthopedic clinic",
                          "Oncological clinics",
                          "Neurosurgery",
                        ].map((treatment) {
                          bool isSelected = selectedTreatment == treatment;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedTreatment = treatment;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Text(
                                treatment,
                                style: TextStyle(
                                  color: isSelected
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
                          "Choose continent",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: availableCountries.map((continent) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedContinent = continent;
                                selectedCountry = null;
                                selectedCity = null;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                                color: selectedContinent == continent
                                    ? Colors.blueAccent
                                    : Colors.white,
                              ),
                              child: Text(
                                continent,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: selectedContinent == continent
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      // Additional filtering options like countries and cities
                      if (selectedContinent != null) ...[
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
                          children: countryCities[selectedContinent]!
                              .map((country) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCountry = country;
                                  selectedCity = null;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                  color: selectedCountry == country
                                      ? Colors.blueAccent
                                      : Colors.white,
                                ),
                                child: Text(
                                  country,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: selectedCountry == country
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (selectedCountry != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 5),
                          child: Text(
                            "Cities",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: citiesByCountry[selectedCountry]!
                              .map((city) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCity = city;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                  color: selectedCity == city
                                      ? Colors.blueAccent
                                      : Colors.white,
                                ),
                                child: Text(
                                  city,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: selectedCity == city
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Фильтр")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              // Call the filter popup
              var result = await showFilterPopup(
                context,
                initialTreatment: 'Plastic surgery clinic',
                initialContinent: 'Europe',
                initialCountry: 'Germany',
                initialCity: 'Berlin',
              );

              if (result != null) {
                logger.w("Selected filters: ${result['category']}, ${result['country']}, ${result['city']}");
              }
            },
            child: Text("Применить фильтр"),
          ),
        ],
      ),
    );
  }
  
 
}

