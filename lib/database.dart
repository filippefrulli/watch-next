import 'dart:io' show Directory;
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;

class DatabaseHelper {
  static const _databaseName = "movies.db";
  static const _databaseVersion = 1;

  static const alreadyWatchedTable = 'already_watched';
  static const streamingServicesTable = 'streaming_services';

  static const movieId = 'movie_id';

  static const streamingId = 'streaming_id';
  static const streamingLogo = 'streaming_logo';

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
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreateMovie, onConfigure: _onConfigure);
  }

  static Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // SQL code to create the database table
  Future _onCreateMovie(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $alreadyWatchedTable (
            $movieId INTEGER PRIMARY KEY
          )
          ''');

    await db.execute('''
          CREATE TABLE $streamingServicesTable (
            $streamingId INTEGER PRIMARY KEY,
            $streamingLogo TEXT NOT NULL
          )
          ''');
  }
}
