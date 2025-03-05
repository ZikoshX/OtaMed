import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>(
  (ref) => LanguageNotifier(),
);

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('en')); 

  void changeLanguage(Locale newLocale) {
    if (state != newLocale) {
      state = newLocale;
    }
  }
}
