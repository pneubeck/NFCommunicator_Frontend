import 'package:nfcommunicator_frontend/models/user_data.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    // If _database is null, initialize it
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get the path to the database file
    String path = join(await getDatabasesPath(), 'tasks.db');

    // Open or create the database at the specified path
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Create the tasks table
        await db.execute('''
          CREATE TABLE UserData(
            userId INTEGER PRIMARY KEY,
            userName TEXT            
          )
        ''');
      },
    );
  }

  Future<int> insertUserData(UserData userData) async {
    final Database db = await database;
    await db.delete('UserData');
    return await db.insert(
      'UserData',
      userData.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<UserData> getUserData() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'UserData',
      limit: 1,
    );
    var userDataList = List.generate(maps.length, (i) {
      return UserData(userId: maps[i]['userId'], userName: maps[i]['userName']);
    });
    if (userDataList.length != 1)
    {
      throw 'Invalid number of rows returned from UserData. Something is off!';
    }
    return userDataList[0];
  }
}
