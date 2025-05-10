import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    // If _database is null, initialize it
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    // Get the path to the database file
    String path = join(await getDatabasesPath(), 'tasks.db');

    // Open or create the database at the specified path
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Create the tasks table
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY,
            title TEXT,
            description TEXT,
            completed INTEGER
          )
        ''');
      },
    );
  }
}