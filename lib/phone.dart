import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ClinicPhoneWidget extends StatelessWidget {
  final String? phoneNumber;
  final bool isDarkMode;

  const ClinicPhoneWidget({
    super.key,
    required this.phoneNumber,
    required this.isDarkMode,
  });

  void _callNumber(BuildContext context, String phone) async {
    final Uri phoneUri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch phone call")),
      );
    }
  }

  void _showCallDialog(BuildContext context, String phone) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Confirm Call"),
          content: Text("Do you want to call $phone?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _callNumber(context, phone);
              },
              child: const Text("Call"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return phoneNumber != null && phoneNumber!.isNotEmpty
        ? Row(
            children: [
              IconButton(
                icon: Icon(Icons.phone, color: isDarkMode ? Colors.white : Colors.blue),
                onPressed: () => _showCallDialog(context, phoneNumber!),
              ),
              Text(
                phoneNumber!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontStyle: FontStyle.normal,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          )
        : Text(
            "No phone number",
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white : Colors.black,
              fontStyle: FontStyle.italic,
            ),
          );
  }
}
