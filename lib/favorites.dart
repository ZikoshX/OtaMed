import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_application_1/favorite_provider.dart';
import 'package:flutter_application_1/description.dart';
import 'package:flutter_application_1/localization/app_localization.dart';

class FavoritesPage extends ConsumerWidget {
    const FavoritesPage({
    super.key,
    required List<Map<String, dynamic>> favoriteClinics,
    required void Function(String clinicName) toggleFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteClinics = ref.watch(favoriteProvider);
    final favoriteNotifier = ref.watch(favoriteProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = theme.textTheme.bodyMedium?.color;
    final isDarkMode = theme.brightness == Brightness.dark;
    final appLocalizations = AppLocalizations.of(context);
    
    if (appLocalizations == null) {
      return Scaffold(body: Center(child: Text('Localizations not available')));
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          appLocalizations.translate('favorites'),
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: favoriteClinics.isNotEmpty
            ? ListView.builder(
                itemCount: favoriteClinics.length,
                itemBuilder: (context, index) {
                  final clinic = favoriteClinics[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ClinicDetail(clinic: clinic),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:  Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    clinic["name"] ?? "",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    softWrap: true,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    favoriteNotifier.toggleFavorite(clinic);
                                  },
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                              Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    clinic['address'] ?? "No address",
                                    style: TextStyle(color: textColor),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: Theme.of(context).iconTheme.color
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  clinic["phone"]?.isNotEmpty == true
                                      ? clinic["phone"]!
                                      : "No phone number",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor,
                                    fontStyle:
                                        clinic["phone"]?.isNotEmpty == true
                                            ? FontStyle.normal
                                            : FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            buildClinicRating(
                              clinic['rating'] ?? "0.0",
                              "${(int.tryParse(clinic['review']?.toString() ?? '0')?.abs() ?? 0)}",context
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            :  Center(
                child: Text(
                  "No favorite clinics yet.",
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
              ),
      ),
    );
  }

  Widget buildClinicRating(String rating, String reviewCount, BuildContext context) {
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
            color: Theme.of(context).textTheme.bodyMedium?.color
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
}
