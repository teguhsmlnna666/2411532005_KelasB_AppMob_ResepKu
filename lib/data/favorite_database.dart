import 'package:path/path.dart' as p;
import 'package:resepku/models/favorite.dart';
import 'package:sqflite/sqflite.dart';

/// Kontrak penyimpanan favorit.
abstract interface class FavoriteStore {
  Future<List<Favorite>> getAll();
  Future<void> insert(Favorite favorite);
  Future<void> updateNote(int id, String note);
  Future<void> delete(int id);
  Future<void> deleteAll();
  Future<void> incrementCooked(int id);
}

/// Implementasi FavoriteStore menggunakan SQLite.
class FavoriteDatabase implements FavoriteStore {
  FavoriteDatabase({DatabaseFactory? factory, String? path})
      : _factory = factory ?? databaseFactorySqflitePlugin,
        _path = path;

  static const _table = 'favorites';

  /// Versi 1: id, name, data, saved_at.
  /// Versi 2: tambah kolom note.
  /// Versi 3: tambah kolom cooked_count.
  static const _version = 3;

  final DatabaseFactory _factory;
  final String? _path;
  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final path =
        _path ?? p.join(await _factory.getDatabasesPath(), 'resepku.db');

    return _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  /// Membuat tabel untuk instalasi baru.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        data TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        cooked_count INTEGER NOT NULL DEFAULT 0,
        saved_at INTEGER NOT NULL
      )
    ''');
  }

  /// Memperbarui struktur database tanpa menghapus data lama.
  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    final columns = await db.rawQuery(
      'PRAGMA table_info($_table)',
    );

    final columnNames = columns
        .map((column) => column['name'] as String)
        .toSet();

    if (!columnNames.contains('note')) {
      await db.execute(
        "ALTER TABLE $_table ADD COLUMN note TEXT NOT NULL DEFAULT ''",
      );
    }

    if (!columnNames.contains('cooked_count')) {
      await db.execute(
        'ALTER TABLE $_table '
        'ADD COLUMN cooked_count INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  // READ: semua favorit, yang terbaru disimpan di atas.
  @override
  Future<List<Favorite>> getAll() async {
    final db = await _database;
    final rows = await db.query(
      _table,
      orderBy: 'saved_at DESC',
    );

    return rows.map(Favorite.fromMap).toList();
  }

  // CREATE: id yang sudah ada diganti, bukan error.
  @override
  Future<void> insert(Favorite favorite) async {
    final db = await _database;

    await db.insert(
      _table,
      favorite.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // UPDATE: hanya kolom note pada baris dengan id tertentu.
  @override
  Future<void> updateNote(int id, String note) async {
    final db = await _database;

    await db.update(
      _table,
      {'note': note},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE: satu baris berdasarkan id.
  @override
  Future<void> delete(int id) async {
    final db = await _database;

    await db.delete(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE ALL: menghapus seluruh baris pada tabel favorit.
  @override
  Future<void> deleteAll() async {
    final db = await _database;
    await db.delete(_table);
  }

  // UPDATE: menambah jumlah resep yang sudah dimasak.
  @override
  Future<void> incrementCooked(int id) async {
    final db = await _database;

    await db.rawUpdate(
      'UPDATE $_table SET cooked_count = cooked_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}