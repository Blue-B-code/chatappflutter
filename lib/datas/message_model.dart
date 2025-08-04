import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  final String senderId;
  final String senderName;
  final bool isSynced;
  final String chatId;

  // 🆕 Champ local, non persisté
  final bool isMe;

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.senderId,
    required this.senderName,
    this.isMe = false,
    this.isSynced = false,
    required this.chatId,
  });

  // 🔁 convertir un map Firestore en objet Message
  factory Message.fromFirestore(
      Map<String, dynamic> data, String chatId, String id, String currentUserId) {
    return Message(
      id: id,
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      isMe: data['senderId'] == currentUserId,
      chatId: chatId, // 🔁 Important pour SQLite
    );
  }

  // 🔁 Convertit un objet message en Map pour Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'text': text,
      'timestamp': timestamp, // Firestore accepte un DateTime
      'senderId': senderId,
      'senderName': senderName,
    };
  }


  // 📤 convertir un objet message en map pour SQLite
  Map<String, dynamic> toSQLiteMap() {
    return {
      'id': id,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'senderId': senderId,
      'senderName': senderName,
      'isSynced': isSynced ? 1 : 0,
      'chatId': chatId,
    };
  }

  // 🔁 Convertir un map SQLite en objet Message
  factory Message.fromMap(Map<String, dynamic> map, String currentUserId) {
    return Message(
      id: map['id'],
      text: map['text'],
      timestamp: DateTime.parse(map['timestamp']),
      senderId: map['senderId'],
      senderName: map['senderName'],
      isMe: map['senderId'] == currentUserId,
      isSynced: map['isSynced'] == 1,
      chatId: map['chatId'],
    );
  }
}
