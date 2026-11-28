import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pilihan urutan daftar resep favorit.
enum FavoriteSort { newest, name }

/// Pengaturan aplikasi yang disimpan di HP dengan SharedPreferencesAsync.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  static const keyGrid = 'is_grid';
  static const keyDark = 'is_dark';
  static const keyFavoriteSort = 'favorite_sort';

  final SharedPreferencesAsync _prefs;

  // Nilai pengaturan aplikasi.
  bool _isGrid = false;
  bool _isDark = false;
  FavoriteSort _favoriteSort = FavoriteSort.newest;

  bool get isGrid => _isGrid;
  bool get isDark => _isDark;
  FavoriteSort get favoriteSort => _favoriteSort;

  ThemeMode get themeMode =>
      _isDark ? ThemeMode.dark : ThemeMode.light;

  /// Dipanggil sekali di main, sebelum runApp.
  Future<void> load() async {
    // Membaca pengaturan tampilan.
    _isGrid = await _prefs.getBool(keyGrid) ?? false;
    _isDark = await _prefs.getBool(keyDark) ?? false;

    // Membaca dan mengubah String menjadi enum FavoriteSort.
    final sortName = await _prefs.getString(keyFavoriteSort);
    _favoriteSort =
        FavoriteSort.values.asNameMap()[sortName] ??
            FavoriteSort.newest;

    notifyListeners();
  }

  Future<void> setGrid(bool value) async {
    _isGrid = value;
    notifyListeners();
    await _prefs.setBool(keyGrid, value);
  }

  Future<void> setDark(bool value) async {
    _isDark = value;
    notifyListeners();
    await _prefs.setBool(keyDark, value);
  }

  /// Mengubah urutan favorit dan menyimpannya secara lokal.
  Future<void> setFavoriteSort(FavoriteSort value) async {
    _favoriteSort = value;
    notifyListeners();
    await _prefs.setString(keyFavoriteSort, value.name);
  }
}