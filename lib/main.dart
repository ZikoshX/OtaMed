import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/admin_page.dart';
import 'package:flutter_application_1/admins_hpage.dart';
import 'package:flutter_application_1/create_page.dart';
import 'package:flutter_application_1/ai_chat.dart';
import 'package:flutter_application_1/favorites.dart';
import 'package:flutter_application_1/homepage.dart';
import 'package:flutter_application_1/localization/app_localization.dart';
import 'package:flutter_application_1/localization/language_provider.dart';
import 'package:flutter_application_1/login.dart';
import 'package:flutter_application_1/notification_service.dart';
import 'package:flutter_application_1/settings.dart';
import 'dart:ui';
import 'package:flutter_application_1/theme/theme.dart';
import 'package:flutter_application_1/theme/theme_provider.dart';
// ignore: unused_import
import 'package:flutter_application_1/upload.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

var logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //uploadCSVtoFirestore();
  FirebaseAuth.instance.setLanguageCode(
    PlatformDispatcher.instance.locale.languageCode,
  );
  NotificationService().initNotification();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(appThemeStateNotifier);
    final locale = ref.watch(languageProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MyThemes.lightTheme,
      darkTheme: MyThemes.darkTheme,
      themeMode: appTheme.isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ru'), Locale('kk')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Login(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> favoriteClinics = [];
  List<Map<String, String>> filteredClinics = [];
  final Set<String> favoriteClinicNames = {};
  int selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      Homepage(
        favoriteClinics: favoriteClinicNames,
        toggleFavorite: toggleFavorite,
        filteredClinics: filteredClinics,
        updateFilteredClinics: updateFilteredClinics,
      ),
      AiChat(),
      FavoritesPage(
        favoriteClinics: favoriteClinics,
        toggleFavorite: toggleFavorite,
      ),
      const SettingPage(),
    ];
  }

  void toggleFavorite(String clinicName) {
    setState(() {
      if (favoriteClinicNames.contains(clinicName)) {
        favoriteClinicNames.remove(clinicName);
      } else {
        favoriteClinicNames.add(clinicName);
      }

      logger.w("Updated Favorites: $favoriteClinicNames");
    });
  }

  void updateFilteredClinics(List<Map<String, String>> newClinics) {
    setState(() {
      filteredClinics = newClinics;
    });
  }

  void changeTabIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: changeTabIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            label: "AI Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: "Favorites",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<Map<String, String>> filteredClinics = [];
  Set<String> favoriteClinicNames = {};
  int selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeAdminpage(
        favoriteClinics: favoriteClinicNames,
        filteredClinics: filteredClinics,
        updateFilteredClinics: updateFilteredClinics,
      ),
      const CreateClinicPage(),
      const SettingPageAdmin(),
    ];
  }

  void toggleFavorite(String clinicName) {
    setState(() {
      if (favoriteClinicNames.contains(clinicName)) {
        favoriteClinicNames.remove(clinicName);
      } else {
        favoriteClinicNames.add(clinicName);
      }

      logger.w("Updated Favorites: $favoriteClinicNames");
    });
  }

  void updateFilteredClinics(List<Map<String, String>> newClinics) {
    setState(() {
      filteredClinics = newClinics;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize),
            label: 'Home',
          ),
            BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
