import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:resepku/data/favorite_database.dart';
import 'package:resepku/models/favorite.dart';
import 'package:resepku/models/recipe.dart';

/// Daftar resep favorit yang disimpan di memori dan FavoriteStore.
class FavoriteProvider extends ChangeNotifier {
  FavoriteProvider(this._store);

  final FavoriteStore _store;
  List<Favorite> _items = [];

  UnmodifiableListView<Favorite> get items =>
      UnmodifiableListView(_items);

  int get count => _items.length;

  bool isFavorite(Recipe recipe) =>
      _items.any((f) => f.recipe.id == recipe.id);

  /// Mengisi memori dari penyimpanan saat aplikasi dibuka.
  Future<void> load() async {
    _items = await _store.getAll();
    notifyListeners();
  }

  Future<void> toggle(Recipe recipe) async {
    if (isFavorite(recipe)) {
      _items.removeWhere((f) => f.recipe.id == recipe.id);
      notifyListeners();
      await _store.delete(recipe.id);
    } else {
      final favorite = Favorite(
        recipe: recipe,
        savedAt: DateTime.now(),
      );

      _items.insert(0, favorite);
      notifyListeners();
      await _store.insert(favorite);
    }
  }

  Future<void> updateNote(int id, String note) async {
    final index = _items.indexWhere((f) => f.recipe.id == id);
    if (index < 0) return;

    _items[index] = _items[index].copyWith(note: note);
    notifyListeners();
    await _store.updateNote(id, note);
  }

  /// Menghapus seluruh resep favorit dari memori dan penyimpanan.
  Future<void> clear() async {
    if (_items.isEmpty) return;

    _items.clear();
    notifyListeners();
    await _store.deleteAll();
  }

  /// Menambah jumlah resep yang sudah dimasak.
  Future<void> incrementCooked(int id) async {
    final index = _items.indexWhere(
      (f) => f.recipe.id == id,
    );

    if (index < 0) return;

    _items[index] = _items[index].copyWith(
      cookedCount: _items[index].cookedCount + 1,
    );

    notifyListeners();
    await _store.incrementCooked(id);
  }
}