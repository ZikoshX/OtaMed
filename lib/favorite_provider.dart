import 'package:hooks_riverpod/hooks_riverpod.dart';

class FavoriteProvider extends StateNotifier<List<Map<String, dynamic>>> {
  FavoriteProvider() : super([]);

  void toggleFavorite(Map<String, dynamic> clinic) {
    state = state.any((c) => c["name"] == clinic["name"])
        ? state.where((c) => c["name"] != clinic["name"]).toList()
        : [...state, clinic];
  }
}

final favoriteProvider =
    StateNotifierProvider<FavoriteProvider, List<Map<String, dynamic>>>(
        (ref) => FavoriteProvider());
