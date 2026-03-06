import 'dart:io' show Directory;
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;

class DatabaseHelper {
  static const _databaseName = "movies.db";
  static const _databaseVersion = 4;

  static const streamingServicesTable = 'streaming_services';
  static const streamingId = 'streaming_id';
  static const streamingLogo = 'streaming_logo';

  static const watchlistTable = 'watchlist';
  static const watchlistId = 'id';
  static const watchlistTitle = 'title';
  static const watchlistIsMovie = 'is_movie';
  static const watchlistPosterPath = 'poster_path';
  static const watchlistDateAdded = 'date_added';

  static const watchedTable = 'watched';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database? _database;
  Future<Database?> get database async {
    if (_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it doesn't exist)
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  static Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Create tables for a fresh install
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $streamingServicesTable (
        $streamingId INTEGER PRIMARY KEY,
        $streamingLogo TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $watchlistTable (
        $watchlistId INTEGER PRIMARY KEY,
        $watchlistTitle TEXT NOT NULL,
        $watchlistIsMovie INTEGER NOT NULL,
        $watchlistPosterPath TEXT,
        $watchlistDateAdded TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $watchedTable (
        media_id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        is_movie INTEGER NOT NULL,
        poster_path TEXT,
        rating INTEGER NOT NULL,
        date_watched TEXT NOT NULL,
        overview TEXT,
        genre_names TEXT
      )
    ''');
  }

  // Migration for upgrades
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop old tables if they exist
      await db.execute('DROP TABLE IF EXISTS already_watched');
      await db.execute('DROP TABLE IF EXISTS not_interested');
      // Create new watchlist table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $watchlistTable (
          $watchlistId INTEGER PRIMARY KEY,
          $watchlistTitle TEXT NOT NULL,
          $watchlistIsMovie INTEGER NOT NULL,
          $watchlistPosterPath TEXT,
          $watchlistDateAdded TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $watchedTable (
          media_id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,
          is_movie INTEGER NOT NULL,
          poster_path TEXT,
          rating INTEGER NOT NULL,
          date_watched TEXT NOT NULL,
          overview TEXT,
          genre_names TEXT
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE $watchedTable ADD COLUMN genre_names TEXT',
      );
    }
  }
}
