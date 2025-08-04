import 'package:chatapp/screens/sms_code_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homeScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _inputController = TextEditingController();
  bool _isSigningIn = false;

  // 🔐 Connexion Google
  Future<void> signInWithGoogle() async {
    setState(() => _isSigningIn = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isSigningIn = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = await userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'name': user.displayName,
          'email': user.email,
          'photoUrl': user.photoURL,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      print("Erreur Google Sign-In : $e");
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  // 🔐 Connexion par téléphone ou email
  Future<void> handleLogin() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    if (RegExp(r'^\+?\d{7,15}$').hasMatch(input)) {
      // Connexion téléphone (ex: "+2376xxxxxxx")
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: input,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        },
        codeSent: (verificationId, forceResendingToken) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SmsCodeScreen(verificationId: verificationId),
            ),
          );
        },

        codeAutoRetrievalTimeout: (verificationId) {},
        verificationFailed: (FirebaseAuthException error) {  },
      );
    } else if (input.contains('@')) {
      // Email : tu peux ici faire un login par mot de passe ou magic link
      print("Connexion par email non implémentée ici.");
    } else {
      print("Entrée invalide");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔤 Champ pour téléphone ou email
              TextField(
                controller: _inputController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email ou numéro de téléphone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 📲 Bouton Connexion
              ElevatedButton(
                onPressed: handleLogin,
                child: const Text("Se connecter"),
              ),
              const SizedBox(height: 24),

              // 🔘 Bouton Google avec icône "G"
              _isSigningIn
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                icon: Image.asset(
                  'assets/images/google_icon.png', // ajoute cette image à ton projet
                  height: 24,
                  width: 24,
                ),
                label: const Text("Se connecter avec Google"),
                onPressed: signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
