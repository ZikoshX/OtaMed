import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/help.dart';
import 'package:flutter_application_1/notification_service.dart';
import 'package:flutter_application_1/personal_info.dart';
import 'package:flutter_application_1/widget/dart_mode_switch.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' as riverpod;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/localization/app_localization.dart';
import 'package:flutter_application_1/localization/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

var logger = Logger();

class SettingPageAdmin extends riverpod.ConsumerStatefulWidget {
  const SettingPageAdmin({super.key});
  @override
  ConsumerState<SettingPageAdmin> createState() => _SettingPage();
}

class _SettingPage extends ConsumerState<SettingPageAdmin> {
  String? selectedLanguage = "EN";
  String userName = "";
  String imageUrl = "";
  bool notificationsEnabled = true;
  final NotificationService notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    fetchUserDatas();
    loadNotificationPreference();
  }

  void loadNotificationPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }


void fetchUserDatas() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String loggedInEmail = user.email!;
      logger.w('Logged-in User Email: $loggedInEmail');

      try {
        // Fetch user data first from the 'users' collection
      
  // Now fetch admin data from the 'admins' collection using the email field
        var adminDataSnapshot =
            await FirebaseFirestore.instance
                .collection("admins")
                .where("email", isEqualTo:  loggedInEmail)
                .get();

        logger.w('Admin data snapshot: ${adminDataSnapshot.docs.isEmpty ? 'No data' : 'Found data'}');

        if (adminDataSnapshot.docs.isNotEmpty) {
          var adminData = adminDataSnapshot.docs.first;
          logger.w('Admin data: ${adminData.data()}');
          setState(() {
            userName = adminData["name"] ?? "Unknown User";
            imageUrl = adminData["profileImage"] ?? "Unknown Image";
          });
        } else {
          logger.w("No admin data found for the email: $loggedInEmail");
        }
      } catch (e) {
        logger.w("Error fetching data: $e");
      }
    } else {
      logger.w("No user is logged in");
    }
  }

  signout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageNotifier = ref.read(languageProvider.notifier);
    final appLocalizations = AppLocalizations.of(context);

    if (appLocalizations == null) {
      return Scaffold(body: Center(child: Text('Localizations not available')));
    }

    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                child: Text(
                  appLocalizations.translate('account'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              buildSectionBlock(
                context,
                title: '',
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PersonalInfo()),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundImage:
                              imageUrl.isNotEmpty
                                  ? NetworkImage(imageUrl)
                                  : AssetImage("images/photo.jpeg")
                                      as ImageProvider,
                        ),
                        const SizedBox(width: 25),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName.isNotEmpty ? userName : "User",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            Text(
                              appLocalizations.translate('personal_info'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.chevron_right_outlined),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  appLocalizations.translate('settings'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              const SizedBox(height: 13),
              buildSectionBlock(
                context,
                title: '',
                children: [
                  ListTile(
                    leading: Icon(Icons.public, color: Colors.blueGrey),
                    title: Text(
                      appLocalizations.translate('language'),
                      style: TextStyle(color: textColor),
                    ),
                    trailing: DropdownButton<String>(
                      value: selectedLanguage,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedLanguage = newValue;
                          });
                          languageNotifier.changeLanguage(
                            Locale(newValue.toLowerCase()),
                          );
                        }
                      },
                      dropdownColor:
                          theme.dropdownMenuTheme.menuStyle?.backgroundColor
                              ?.resolve({}) ??
                          Colors.white,
                      style: TextStyle(color: textColor, fontSize: 16),
                      iconEnabledColor: theme.iconTheme.color,
                      items: [
                        DropdownMenuItem(
                          value: "EN",
                          child: Text(
                            "English",
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        DropdownMenuItem(
                          value: "RU",
                          child: Text(
                            "Русский",
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        DropdownMenuItem(
                          value: "KK",
                          child: Text(
                            "Қазақша",
                            style: TextStyle(color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                  Divider(color: Colors.grey.shade400),
                  ListTile(
                    leading: Icon(Icons.dark_mode, color: Colors.blueGrey),
                    title: Text(
                      appLocalizations.translate('dark_mode'),
                      style: TextStyle(color: textColor),
                    ),
                    trailing: DarkModeSwitch(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
                    InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(10),
              ),
              child:  ListTile(
                leading: Icon(Icons.help, color: Colors.blueGrey),
                title: Text(
                      appLocalizations.translate('help'),
                      style: TextStyle(color: textColor),
                    ),
              ),
            ),
          ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Icon(Icons.exit_to_app, color: Colors.blueGrey),
                  title: Text(
                    appLocalizations.translate('logout'),
                    style: TextStyle(color: textColor),
                  ),
                  onTap: signout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSectionBlock(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }
}
