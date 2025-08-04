import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'homeScreen.dart';

class SmsCodeScreen extends StatefulWidget {
  final String verificationId;

  const SmsCodeScreen({super.key, required this.verificationId});

  @override
  State<SmsCodeScreen> createState() => _SmsCodeScreenState();
}

class _SmsCodeScreenState extends State<SmsCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;

  Future<void> _verifyCode() async {
    final smsCode = _codeController.text.trim();
    if (smsCode.isEmpty) return;

    setState(() => _isVerifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      print("Erreur de vérification du code : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Code incorrect ou expiré.")),
      );
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vérification du code")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("Entrez le code reçu par SMS"),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Code SMS",
              ),
            ),
            const SizedBox(height: 20),
            _isVerifying
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _verifyCode,
              child: const Text("Vérifier"),
            ),
          ],
        ),
      ),
    );
  }
}
