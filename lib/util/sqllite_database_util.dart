import 'package:nfcommunicator_frontend/models/contact.dart';
import 'package:nfcommunicator_frontend/models/message.dart';
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
      version: 4,
      onCreate: (Database db, int version) async {
        // Create the tasks table
        await db.execute('''
          CREATE TABLE UserData(
            userId INTEGER PRIMARY KEY,
            userName TEXT            
          )
        ''');
        await db.execute('''
          CREATE TABLE Contact(            
            userId INTEGER PRIMARY KEY,
            userName TEXT,
            publicKey TEXT            
          )
        ''');
        await db.execute('''
          CREATE TABLE Chats(
            chatId INTEGER PRIMARY KEY,
            chatType INTEGER,
            userId INTEGER,
            groupChatId INTEGER            
          )
        ''');
        await db.execute('''
          CREATE TABLE Messages(
            messageId INTEGER PRIMARY KEY,
            creationDate TEXT,
            lastUpdateDate Text,
            deletionDate TEXT,
            messageSentDate TEXT,
            senderUserId INTEGER,
            recipientUserId INTEGER,
            messageType INTEGER,
            groupChatId INTEGER,
            encryptedMessage BLOB,
            decryptedMessage TEXT,   
            decryptedMessageBlob BLOB         
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        for (int version = oldVersion; version < newVersion; version++) {
          await _performDbOperationsVersionWise(db, version + 1);
        }
      },
    );
  }

  _performDbOperationsVersionWise(Database db, int version) async {
    switch (version) {
      case 3:
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Contact(            
            userId INTEGER PRIMARY KEY,
            userName TEXT,
            publicKey TEXT            
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Chats(
            chatId INTEGER PRIMARY KEY,
            chatType INTEGER,
            userId INTEGER,
            groupChatId INTEGER            
          )
        ''');
        break;
      case 4:
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Messages(
            messageId INTEGER PRIMARY KEY,
            creationDate TEXT,
            lastUpdateDate Text,
            deletionDate TEXT,
            messageSentDate TEXT,
            senderUserId INTEGER,
            recipientUserId INTEGER,
            messageType INTEGER,
            groupChatId INTEGER,
            encryptedMessage BLOB,
            decryptedMessage TEXT,   
            decryptedMessageBlob BLOB         
          )
        ''');
        break;
    }
  }

  Future<int> insertMessage(Message message) async {
    final Database db = await database;
    return await db.insert(
      'Messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<int> updateMessage(Message message) async {
    final Database db = await database;
    return await db.update(
      'Messages', 
      message.toMap(), 
      where: 'messageId = ${message.messageId}');
  }

  Future<List<Message>> getMessages(int userId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Messages',
      where: 'senderUserId = $userId OR recipientUserId = $userId',
    );
    var messageList = List.generate(maps.length, (i) {
      return Message.fromMap(maps[i]);
    });
    return messageList;
  }

  Future<int> insertContact(Contact contact) async {
    final Database db = await database;
    return await db.insert(
      'Contact',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<List<Contact>> getContacts() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Contact');
    var contactList = List.generate(maps.length, (i) {
      return Contact(
        userId: maps[i]['userId'],
        userName: maps[i]['userName'],
        publicKeyPem: maps[i]['publicKey'],
      );
    });
    return contactList;
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
    if (userDataList.length != 1) {
      throw 'Invalid number of rows returned from UserData. Something is off!';
    }
    return userDataList[0];
  }
}
