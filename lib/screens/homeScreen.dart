import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'chatScreen.dart';
import 'loginScreen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discussions"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();

              if (!mounted) return;

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final users = snapshot.data!.docs
              .where((doc) => doc['uid'] != currentUser?.uid)
              .toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final name = user['name'] ?? 'Nom inconnu';
              final photoUrl = user['photoUrl'] ?? '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                  photoUrl != '' ? NetworkImage(photoUrl) : null,
                  child: photoUrl == '' ? const Icon(Icons.person) : null,
                ),
                title: Text(name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        peerId: user['uid'],
                        peerName: name,
                        peerPhotoUrl: photoUrl,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
