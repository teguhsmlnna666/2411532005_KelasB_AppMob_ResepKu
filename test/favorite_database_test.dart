import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:resepku/data/favorite_database.dart';
import 'package:resepku/models/favorite.dart';
import 'package:resepku/models/recipe.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _rendang = Recipe(
  id: 1,
  name: 'Rendang',
  cuisine: 'Indonesian',
  difficulty: 'Hard',
  prepTimeMinutes: 30,
  cookTimeMinutes: 180,
  servings: 6,
  caloriesPerServing: 450,
  rating: 4.9,
  image: '',
  ingredients: ['Daging sapi', 'Santan', 'Cabai'],
  instructions: ['Tumis bumbu.', 'Masak dengan santan hingga kering.'],
);

const _soto = Recipe(
  id: 2,
  name: 'Soto Padang',
  cuisine: 'Indonesian',
  difficulty: 'Medium',
  prepTimeMinutes: 20,
  cookTimeMinutes: 60,
  servings: 4,
  caloriesPerServing: 300,
  rating: 4.7,
  image: '',
  ingredients: ['Daging sapi', 'Bihun'],
  instructions: ['Rebus daging.', 'Sajikan dengan kuah.'],
);

final _favRendang = Favorite(
  recipe: _rendang,
  savedAt: DateTime(2026, 10, 1),
);

final _favSoto = Favorite(
  recipe: _soto,
  savedAt: DateTime(2026, 10, 2),
);

void main() {
  sqfliteFfiInit();

  late FavoriteDatabase db;

  // Database dalam memori: setiap test mulai dari kosong.
  setUp(() {
    db = FavoriteDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() => db.close());

  test('insert lalu getAll, yang terbaru di atas', () async {
    await db.insert(_favRendang);
    await db.insert(_favSoto);

    final all = await db.getAll();

    expect(
      all.map((f) => f.recipe.name),
      ['Soto Padang', 'Rendang'],
    );
  });

  test('resep tersimpan utuh, termasuk bahan dan langkah', () async {
    await db.insert(_favRendang);

    final saved = (await db.getAll()).single;

    expect(saved.recipe.ingredients, _rendang.ingredients);
    expect(saved.recipe.instructions, hasLength(2));
    expect(saved.savedAt, DateTime(2026, 10, 1));
    expect(saved.cookedCount, 0);
  });

  test('insert id yang sama mengganti baris lama', () async {
    await db.insert(_favRendang);
    await db.insert(_favRendang.copyWith(note: 'versi baru'));

    final all = await db.getAll();

    expect(all, hasLength(1));
    expect(all.single.note, 'versi baru');
  });

  test('updateNote dan delete', () async {
    await db.insert(_favRendang);

    await db.updateNote(1, 'Kurangi santan');
    expect((await db.getAll()).first.note, 'Kurangi santan');

    await db.delete(1);
    expect(await db.getAll(), isEmpty);
  });

  test('incrementCooked menambah jumlah resep dimasak', () async {
    await db.insert(_favRendang);

    await db.incrementCooked(1);

    var result = await db.getAll();
    expect(result.single.cookedCount, 1);

    await db.incrementCooked(1);

    result = await db.getAll();
    expect(result.single.cookedCount, 2);
  });

  test('deleteAll menghapus semua favorit', () async {
    await db.insert(_favRendang);
    await db.insert(_favSoto);

    await db.deleteAll();

    expect(await db.getAll(), isEmpty);
  });

  test('migrasi versi 1 ke 3 tidak menghapus data lama', () async {
    final dir = await Directory.systemTemp.createTemp('resepku_test');
    final oldPath = p.join(dir.path, 'lama.db');

    // 1. Membuat database versi 1 tanpa kolom note dan cooked_count.
    final old = await databaseFactoryFfi.openDatabase(
      oldPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE favorites ('
            'id INTEGER PRIMARY KEY, '
            'name TEXT NOT NULL, '
            'data TEXT NOT NULL, '
            'saved_at INTEGER NOT NULL'
            ')',
          );
        },
      ),
    );

    // Memasukkan data menggunakan kolom yang tersedia pada versi 1.
    final row = _favRendang.toMap();

    await old.insert('favorites', {
      for (final column in ['id', 'name', 'data', 'saved_at'])
        column: row[column],
    });

    await old.close();

    // 2. Membuka file yang sama menggunakan database versi 3.
    final upgraded = FavoriteDatabase(
      factory: databaseFactoryFfi,
      path: oldPath,
    );

    final all = await upgraded.getAll();

    expect(all, hasLength(1));
    expect(all.single.recipe.name, 'Rendang');
    expect(all.single.note, '');
    expect(all.single.cookedCount, 0);

    // 3. Memastikan kolom baru dapat digunakan.
    await upgraded.updateNote(1, 'Pedas');
    await upgraded.incrementCooked(1);

    final updated = (await upgraded.getAll()).single;

    expect(updated.note, 'Pedas');
    expect(updated.cookedCount, 1);

    await upgraded.close();
    await dir.delete(recursive: true);
  });
}