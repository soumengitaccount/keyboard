import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DictionaryDatabase {
  DictionaryDatabase._();

  static final DictionaryDatabase instance = DictionaryDatabase._();

  Database? _database;

  Future<void> initialize() async {
    sqfliteFfiInit();

    databaseFactory = databaseFactoryFfi;

    final dbPath = await databaseFactory.getDatabasesPath();

    final path = join(
      dbPath,
      "avro_dictionary.db",
    );

    _database = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE user_words(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL UNIQUE,
        frequency INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Database get db {
    if (_database == null) {
      throw StateError(
        "DictionaryDatabase.initialize() was not called.",
      );
    }

    return _database!;
  }

  Future<void> addWord(
    String word,
  ) async {
    final existing = await db.query(
      "user_words",
      where: "word = ?",
      whereArgs: [word],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert(
        "user_words",
        {
          "word": word,
          "frequency": 1,
        },
      );
    } else {
      await db.rawUpdate(
        '''
        UPDATE user_words
        SET frequency = frequency + 1
        WHERE word = ?
        ''',
        [word],
      );
    }
  }

  Future<List<String>> search(String prefix, {int limit = 20}) async {
    final rows = await db.query(
      "user_words",
      where: "word LIKE ?",
      whereArgs: ["$prefix%"],
      orderBy: "frequency DESC",
      limit: limit,
    );

    return rows.map((e) => e["word"] as String).toList();
  }

  Future<void> deleteWord(
    String word,
  ) async {
    await db.delete(
      "user_words",
      where: "word=?",
      whereArgs: [word],
    );
  }
}
