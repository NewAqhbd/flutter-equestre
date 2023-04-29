import 'package:mysql1/mysql1.dart';

class DatabaseHelper {
  static Future<MySqlConnection> getConnection() async {
    final conn = await MySqlConnection.connect(ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      db: 'tp_centre_equestre',
    ));
    return conn;
  }

  static Future<List<Map<String, dynamic>>> getCours() async {
    final conn = await getConnection();
    final cours = await conn.query('SELECT * FROM cours');
    await conn.close();
    return cours.map((row) => row.fields).toList();
  }
}