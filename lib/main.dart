import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:bakan/app.dart';
import 'package:bakan/database/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  await DBHelper.initDb();

  // Chargement des préférences partagées pour vérifier l'introduction et l'état de connexion
  final prefs = await SharedPreferences.getInstance();
  final seenIntro = prefs.getBool('seen_intro') ?? false;
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Lancer l'application avec les paramètres appropriés
  runApp(BakanApp(
    showIntro: !seenIntro,
    isLoggedIn: isLoggedIn,
  ));
}
