import 'dart:io' show Directory;
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;

class DatabaseHelper {
  static const _databaseName = "movies.db";
  static const _databaseVersion = 1;

  static const movieTable = 'movie';
  static const tvTable = 'tv';
  static const actorTable = 'actor';
  static const directorTable = 'director';
  static const movieActorTable = 'movie_actor';
  static const composerTable = 'composer';
  static const watchlistTable = 'watchlist';
  static const streamingServicesTable = 'streaming_services';

  static const movieId = 'movie_id';
  static const adult = 'adult';
  static const budget = 'budget';
  static const imdbId = 'imdb_id';
  static const originalLanguage = 'original_language';
  static const originalTitle = 'original_title';
  static const overview = 'overview';
  static const popularity = 'popularity';
  static const posterPath = 'poster';
  static const releaseDate = 'release_date';
  static const revenue = 'revenue';
  static const runtime = 'runtime';
  static const status = 'status';
  static const title = 'title';
  static const voteAverage = 'vote_average';
  static const voteCount = 'vote_count';
  static const score = 'score';

  static const tvId = 'tv_id';
  //static final originalLanguage = 'original_language';
  static const originalName = 'original_name';
  //static final overview = 'overview';
  //static final popularity = 'popularity';
  //static final posterPath = 'poster';
  //static final status = 'status';
  static const name = 'name';
  //static final voteAverage = 'vote_average';
  //static final voteCount = 'vote_count';
  //static final score = 'score';

  static const actorId = 'actor_id';
  static const actorName = 'actor_name';
  static const actorPic = 'actor_pic';
  static const actorOrder = 'actor_order';
  static const actorBirthday = 'actor_birthday';
  static const actorGender = 'actor_gender';
  static const actorBio = 'actor_bio';

  static const directorId = 'director_id';
  static const directorName = 'director_name';
  static const directorPic = 'director_pic';
  static const directorBirthday = 'director_birthday';
  static const directorGender = 'director_gender';
  static const directorBio = 'director_bio';

  static const composerId = 'composer_id';
  static const composerName = 'composer_name';
  static const composerPic = 'composer_pic';
  static const composerBirthday = 'composer_birthday';
  static const composerGender = 'composer_gender';
  static const composerBio = 'composer_bio';

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
          CREATE TABLE $movieTable (
            $movieId INTEGER PRIMARY KEY,
            $adult BOOLEAN,
            $budget INTEGER,
            $imdbId INTEGER,
            $originalLanguage TEXT,
            $originalTitle TEXT,
            $overview TEXT,
            $popularity FLOAT,
            $posterPath TEXT,
            $releaseDate TEXT,
            $revenue INTEGER,
            $runtime INTEGER,
            $status TEXT,
            $title TEXT NOT NULL,
            $voteAverage FLOAT,
            $voteCount FLOAT,
            $score INTEGER
          )
          ''');

    await db.execute('''
          CREATE TABLE $tvTable (
            $tvId INTEGER PRIMARY KEY,
            $originalLanguage TEXT,
            $originalName TEXT,
            $overview TEXT,
            $popularity FLOAT,
            $posterPath TEXT,
            $status TEXT,
            $name TEXT NOT NULL,
            $voteAverage FLOAT,
            $voteCount FLOAT,
            $score INTEGER
          )
          ''');

    await db.execute('''
          CREATE TABLE $actorTable (
            $actorId INTEGER PRIMARY KEY,
            $actorName TEXT NOT NULL,
            $actorPic TEXT,
            $actorBirthday TEXT,
            $actorGender INTEGER,
            $actorBio TEXT
          )
          ''');

    await db.execute('''
          CREATE TABLE $directorTable (
            $directorId INTEGER PRIMARY KEY,
            $directorName TEXT NOT NULL,
            $directorPic TEXT,
            $directorBirthday TEXT,
            $directorGender INTEGER,
            $directorBio TEXT
          )
          ''');

    await db.execute('''
          CREATE TABLE $movieActorTable (
            $movieId INTEGER,
            $actorId INTEGER,
            $actorOrder INTEGER,
            PRIMARY KEY ($movieId, $actorId)
          )
          ''');

    await db.execute('''
          CREATE TABLE $composerTable (
            $composerId INTEGER PRIMARY KEY,
            $composerName TEXT NOT NULL,
            $composerPic TEXT,
            $composerBirthday TEXT,
            $composerGender INTEGER,
            $composerBio TEXT
          )
          ''');

    await db.execute('''
          CREATE TABLE $watchlistTable (
            $movieId INTEGER PRIMARY KEY,
            $title TEXT NOT NULL,
            $posterPath TEXT,
            $releaseDate TEXT,
            $overview TEXT
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
