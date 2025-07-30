import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_database_service.dart';
import 'message_model.dart';

class SyncService {
  /// Synchronise les messages entre Firestore et SQLite pour un chat donné
  static Future<void> syncMessagesWithFirestore(String chatId, String currentUserId) async {
    try {
      // Vérifie la connectivité Internet
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (!isOnline) {
        print('🔌 Aucun accès Internet. Synchronisation annulée.');
        return;
      }

      print('🌐 Connexion détectée. Début de la synchronisation...');

      final firestore = FirebaseFirestore.instance;

      // 1️⃣ Récupérer tous les messages depuis Firestore
      final firestoreMessagesSnapshot = await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      final firestoreMessages = firestoreMessagesSnapshot.docs
          .map((doc) => Message.fromFirestore(
        doc.data(),
        chatId,
        doc.id,
        currentUserId,
      ))
          .toList();

      // 2️⃣ Récupérer les messages locaux
      final localMessages = await LocalDatabaseService.getMessagesForChat(
        chatId,
        currentUserId,
      );

      final localMessageIds = localMessages.map((m) => m.id).toSet();

      // 3️⃣ 🔽 Firestore → SQLite
      for (var msg in firestoreMessages) {
        if (!localMessageIds.contains(msg.id)) {
          await LocalDatabaseService.insertMessage(msg);
          print('📥 Message téléchargé depuis Firestore : ${msg.id}');
        }
      }

      // 4️⃣ 🔼 SQLite → Firestore : envoyer uniquement les messages non synchronisés
      final unsyncedMessages = await LocalDatabaseService.getUnsyncedMessages(currentUserId, chatId);
      for (var localMsg in unsyncedMessages) {
        SyncService.syncOneMessageWithFirestore(localMsg, chatId);
      }


      print('✅ Synchronisation complète terminée.');
    } catch (e) {
      print('❌ Erreur pendant la synchronisation : $e');
    }
  }

  static Future<void> syncOneMessageWithFirestore(Message message, String chatId)async {
    final firestore = FirebaseFirestore.instance;
    final docRef = firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id);

    await docRef.set(message.toFirestoreMap());
    print('📤 Message envoyé à Firestore : ${message.id}');

    await LocalDatabaseService.markMessageAsSynced(message.id);
    print('✅ Message marqué comme synchronisé : ${message.id}');
  }

}
