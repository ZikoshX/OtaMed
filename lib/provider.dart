import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClinicNotifier extends StateNotifier<List<Map<String, String>>> {
  ClinicNotifier() : super([]);

  void updateFilteredClinics(List<Map<String, String>> newClinics) {
    state = newClinics;
  }
}


final clinicProvider = StateNotifierProvider<ClinicNotifier, List<Map<String, String>>>(
  (ref) => ClinicNotifier(),
);
