import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bakan/database/db_helper.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final phoneController = TextEditingController();
  final otpControllers = List.generate(4, (_) => TextEditingController());
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();

  int currentStep = 0;
  String error = '';
  String generatedOtp = '';
  int countdown = 30;
  Timer? timer;

  void startTimer() {
    countdown = 30;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown == 0) {
        t.cancel();
        setState(() {});
      } else {
        setState(() {
          countdown--;
        });
      }
    });
  }

  void sendOTP() {
    generatedOtp = '1234'; // à remplacer par une vraie logique plus tard
    setState(() {
      currentStep = 1;
    });
    startTimer();
  }

  void validateOTP() {
    final enteredOtp = otpControllers.map((c) => c.text).join();
    if (enteredOtp == generatedOtp) {
      setState(() {
        currentStep = 2;
        error = '';
      });
    } else {
      setState(() {
        error = 'Code incorrect';
      });
    }
  }

  void resetPassword() async {
    if (newPassController.text != confirmPassController.text) {
      setState(() => error = 'Les mots de passe ne correspondent pas');
      return;
    }

    final res = await DBHelper.updateUserPassword(
      phoneController.text,
      newPassController.text,
    );

    if (res > 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mot de passe réinitialisé avec succès'),
      ));
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      setState(() => error = 'Erreur lors de la mise à jour');
    }
  }

  Widget buildPhoneStep() {
    return Column(
      children: [
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Numéro de téléphone',
            labelStyle: TextStyle(color: Colors.white),
            prefixIcon: Icon(Icons.phone, color: Colors.white),
            focusedBorder:
                OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white54)),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: sendOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Envoyer le code"),
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          child: const Text(
            "Déjà un compte ? Se connecter",
            style: TextStyle(color: Colors.white70),
          ),
        )
      ],
    );
  }

  Widget buildOtpStep() {
    return Column(
      children: [
        const Text('Entrez le code OTP reçu',
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            return Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: TextField(
                controller: otpControllers[i],
                maxLength: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white)),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        if (countdown > 0)
          Text("Renvoyer dans $countdown s",
              style: const TextStyle(color: Colors.white54))
        else
          TextButton(
            onPressed: sendOTP,
            child: const Text("Renvoyer le code",
                style: TextStyle(color: Colors.white)),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: validateOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Vérifier le code"),
          ),
        ),
      ],
    );
  }

  Widget buildPasswordStep() {
    return Column(
      children: [
        TextField(
          controller: newPassController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Nouveau mot de passe',
            labelStyle: TextStyle(color: Colors.white),
            prefixIcon: Icon(Icons.lock, color: Colors.white),
            focusedBorder:
                OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white54)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: confirmPassController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Confirmer mot de passe',
            labelStyle: TextStyle(color: Colors.white),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.white),
            focusedBorder:
                OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white54)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Réinitialiser le mot de passe"),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Image.asset('assets/images/sf/7.png', height: 300),
              const SizedBox(height: 24),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(error,
                      style: const TextStyle(color: Colors.redAccent)),
                ),
              if (currentStep == 0)
                buildPhoneStep()
              else if (currentStep == 1)
                buildOtpStep()
              else
                buildPasswordStep(),
            ],
          ),
        ),
      ),
    );
  }
}
