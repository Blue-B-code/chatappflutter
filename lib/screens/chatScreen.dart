import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  String getChatId() {
    if (currentUser == null) return "";
    final ids = [currentUser!.uid, widget.peerId]..sort();
    return ids.join("-");
  }

  void sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || currentUser == null) return;

    final chatId = getChatId();

    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': currentUser!.uid,
      'senderName': currentUser!.displayName,
      'senderPhotoUrl': currentUser!.photoURL,
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chatId = getChatId();
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == currentUser!.uid;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(message['text']),
                      ),
                    );
                  },
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
