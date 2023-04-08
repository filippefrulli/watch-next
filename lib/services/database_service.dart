import 'package:sqflite/sqflite.dart';
import '../../../database.dart';

class DatabaseService {
  static Future<List<Map>> getAllStreamingServices() async {
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

  static saveStreamingServices(List<int> selected, List<int> streamingIds, List<String> streamingLogos) async {
    Database? db = await DatabaseHelper.instance.database;
    int id;
    String logo;
    db!.rawQuery('DELETE FROM streaming_services');

    selected.asMap().forEach(
          (index, value) => {
            id = streamingIds[value],
            logo = streamingLogos[value],
            db.rawInsert('INSERT OR REPLACE INTO streaming_services(streaming_id, streaming_logo) VALUES($id, "$logo")')
          },
        );
  }
}
