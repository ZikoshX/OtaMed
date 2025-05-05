import 'package:flutter/material.dart';
import 'package:flutter_application_1/localization/app_localization.dart';
import 'package:flutter_application_1/phone.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class ClinicDetail extends StatelessWidget {
  final Map<String, dynamic> clinic;

  const ClinicDetail({super.key, required this.clinic});

Widget buildWebsiteSection(String? siteUrl, BuildContext context) {
  if (siteUrl == null || siteUrl.isEmpty) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueAccent, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.language, size: 20, color: Colors.redAccent),
          SizedBox(width: 8),
          Text(
            "No Website Available",
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }

  siteUrl = siteUrl.trim();

  if (!(siteUrl.startsWith("http://") || siteUrl.startsWith("https://"))) {
    siteUrl = "https://$siteUrl";
  }

  final RegExp urlRegex = RegExp(r'^(https?:\/\/[^\s/]+)');
  final match = urlRegex.firstMatch(siteUrl);
  if (match != null) {
    siteUrl = match.group(0)!; 
  } else {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent, width: 1),
      ),
      child: Text("Invalid Website URL", style: TextStyle(color: Colors.red)),
    );
  }

  final Uri url = Uri.tryParse(siteUrl) ?? Uri.parse("https://google.com");

  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blueAccent, width: 1),
    ),
    child: InkWell(
      onTap: () async {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          logger.w("Error: Cannot launch $siteUrl");
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.language, size: 20, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              siteUrl,
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}




  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appLocalizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
      child: Padding(

        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                clinic['name'] ?? 'No Name',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            Divider(
              color: Colors.blueAccent,
              thickness: 2,
              indent: 20,
              endIndent: 20,
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 22,
                        color: Colors.blueAccent,
                      ),
                      SizedBox(width: 5),
                      Text(
                        clinic['description'] ?? 'No Description Available',
                        style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 15),
            Text(appLocalizations!.translate("address"), style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 22,
                        color: Colors.blueAccent,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${clinic['address'] ?? ''}, ${clinic['city'] ?? ''} ${clinic['country'] ?? ''}",
                          style: TextStyle(fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 15),
            Text(appLocalizations.translate("rating_desc"), style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        double rating =
                            double.tryParse(clinic['rating'].toString()) ?? 0.0;
                        if (index < rating.floor()) {
                          return Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          );
                        } else if (index < rating) {
                          return Icon(
                            Icons.star_half,
                            color: Colors.amber,
                            size: 20,
                          );
                        } else {
                          return Icon(
                            Icons.star_border,
                            color: Colors.grey,
                            size: 20,
                          );
                        }
                      }),
                      SizedBox(width: 8),
                      Text(
                        (double.tryParse(clinic['rating'].toString()) ?? 0.0) >
                                0
                            ? (double.tryParse(clinic['rating'].toString()) ??
                                    0.0)
                                .toStringAsFixed(1)
                            : "No Rating",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Text(appLocalizations.translate("rating_desc"), style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.reviews,
                        size: 22,
                        color: Colors.blueAccent,
                      ), 
                      SizedBox(width: 8),
                      Text(
                        "${(int.tryParse(clinic['review']?.toString() ?? '0')?.abs() ?? 0)} reviews",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Text(appLocalizations.translate("url"), style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [buildWebsiteSection(clinic['site_url'],context)],
            ),
            SizedBox(height: 15),
            Text(appLocalizations.translate("phone_number"), style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ClinicPhoneWidget(
                      phoneNumber: clinic["phone"],
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Text(appLocalizations.translate("avail"), style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time, 
                    size: 22,
                    color: Colors.blueAccent,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clinic['availability'] ?? 'No Availability Info',
                      style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
