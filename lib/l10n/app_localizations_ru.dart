// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get settings => 'Настройки';

  @override
  String get language => 'Язык';

  @override
  String get account => 'Аккаунт';

  @override
  String get personal_info => 'Персональные данные';

  @override
  String get notifications => 'Уведомления';

  @override
  String get dark_mode => 'Черный фон';

  @override
  String get help => 'Помощь';

  @override
  String get logout => 'Выйти';
}
