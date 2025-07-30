import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../datas/local_database_service.dart';
import '../datas/message_model.dart';
import '../datas/sync_service.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String? peerPhotoUrl;

  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    this.peerPhotoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  late String chatId;
  List<Message> _localMessages = [];
  StreamSubscription? _firestoreSubscription;

  String getChatId() {
    if (currentUser == null) return "";
    final ids = [currentUser!.uid, widget.peerId]..sort();
    return ids.join("-");
  }

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      chatId = getChatId();
      _syncAndLoadMessages();
      _listenToFirestoreChanges();
    }
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  Future<void> _syncAndLoadMessages() async {
    await SyncService.syncMessagesWithFirestore(chatId, currentUser!.uid);
    final local = await LocalDatabaseService.getMessagesForChat(
      chatId,
      currentUser!.uid,
    );
    setState(() {
      _localMessages = local;
    });
  }

  void _listenToFirestoreChanges() {
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty){
        await LocalDatabaseService.insertMessage(Message.fromFirestore(snapshot.docs[0].data(), chatId, snapshot.docs[0].id, currentUser!.uid));
        final local = await LocalDatabaseService.getMessagesForChat(
          chatId,
          currentUser!.uid,
        );
        setState(() {
          _localMessages = local;
        });
        //await _syncAndLoadMessages();
      }
    });
  }

  void sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || currentUser == null) return;

    final newId = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId) // Remplace chatId par la variable contenant l'ID du chat
        .collection('messages')
        .doc()
        .id;


    final message = Message(
      id: newId,
      text: text,
      timestamp: DateTime.now(),
      senderId: currentUser!.uid,
      senderName: currentUser!.displayName ?? "Moi",
      chatId: chatId,
      isSynced: false,
    );

    await LocalDatabaseService.insertMessage(message);
    final local = await LocalDatabaseService.getMessagesForChat(
      chatId,
      currentUser!.uid,
    );
    setState(() {
      _localMessages = local;
    });

    _controller.clear();
    await SyncService.syncOneMessageWithFirestore(message, chatId);

    //await _syncAndLoadMessages();
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return "$hour:$minute - $day/$month/$year";
  }

  @override
  Widget build(BuildContext context) {
    if (chatId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Utilisateur non connecté.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.peerPhotoUrl != null
                  ? NetworkImage(widget.peerPhotoUrl!)
                  : null,
              child: widget.peerPhotoUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(widget.peerName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _localMessages.length,
              itemBuilder: (context, index) {
                final message = _localMessages[index];
                final isMe = message.senderId == currentUser!.uid;

                return Align(
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 4 / 5,
                    ),
                    child: IntrinsicWidth(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _formatDateTime(message.timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                    const InputDecoration(hintText: "Écrire un message..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
