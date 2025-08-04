import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'message_model.dart';

class LocalDatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'messages.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            senderId TEXT,
            senderName TEXT,
            chatId TEXT,
            text TEXT,
            timestamp TEXT,
            isSynced INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  static Future<List<Message>> getUnsyncedMessages(String currentUserId, String chatId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'isSynced = ? AND chatId = ?',
      whereArgs: [0, chatId],
    );

    return result.map((map) => Message.fromMap(map, currentUserId)).toList();
  }


  static Future<void> markMessageAsSynced(String messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }


  static Future<void> insertMessage(Message message) async {
    final db = await database;
    await db.insert(
      'messages',
      message.toSQLiteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Message>> getSQLiteMessagesForChat(String chatId, String currentUserId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );

    return result.map((map) => Message.fromMap(map, currentUserId)).toList();
  }

  static Future<bool> messageExists(String messageId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
    return result.isNotEmpty;
  }


}
