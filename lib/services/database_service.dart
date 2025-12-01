import 'package:sqflite/sqflite.dart';
import '../utils/database.dart';

class DatabaseService {
  static Future<List<Map>> getAllSeen() async {
    Database? db = await DatabaseHelper.instance.database;

    return await db!.rawQuery('SELECT TOP 50 * FROM already_watched ORDER BY date DESC');
  }

  static Future<void> insertSeenMovie(int movieId) async {
    Database? db = await DatabaseHelper.instance.database;

    await db!.rawInsert(
        'INSERT OR REPLACE INTO already_watched (movie_id, date) VALUES (?, ?)', [movieId, DateTime.now().toString()]);
  }

  static Future<List<Map>> getAllNotInterested() async {
    Database? db = await DatabaseHelper.instance.database;

    return await db!.rawQuery('SELECT TOP 50 * FROM not_interested ORDER BY date DESC');
  }

  static Future<void> insertNotInterested(int movieId) async {
    Database? db = await DatabaseHelper.instance.database;

    await db!.rawInsert(
        'INSERT OR REPLACE INTO not_interested (movie_id, date) VALUES (?, ?)', [movieId, DateTime.now().toString()]);
  }

  static Future<List<Map<String, Object?>>> getAllStreamingServices() async {
    Database? db = await DatabaseHelper.instance.database;

    return await db!.rawQuery('SELECT * FROM streaming_services');
  }

  static Future<List<int>> getStreamingServicesIds() async {
    Database? db = await DatabaseHelper.instance.database;
    List<int> streamingIds = [];

    var queryResult = await db!.rawQuery('SELECT * FROM streaming_services');
    for (var value in queryResult) {
      streamingIds.add(value['streaming_id'] as int);
    }
    return streamingIds;
  }

  static Future<void> saveStreamingServices(Map<int, String> streamingServices) async {
    Database? db = await DatabaseHelper.instance.database;
    int id;
    String logo;
    db!.rawQuery('DELETE FROM streaming_services');

    streamingServices.forEach(
      (key, value) {
        id = key;
        logo = value;
        db.rawInsert('INSERT OR REPLACE INTO streaming_services(streaming_id, streaming_logo) VALUES($id, "$logo")');
      },
    );
  }
}
