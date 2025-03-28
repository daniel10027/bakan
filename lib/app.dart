import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bakan/config/theme.dart';
import 'package:bakan/views/auth/login_page.dart';
import 'package:bakan/views/auth/register_page.dart';
import 'package:bakan/views/auth/password_reset.dart';
import 'package:bakan/views/dashboard/home_page.dart';
import 'package:bakan/views/products/add_product_page.dart';
import 'package:bakan/views/sales/sales_page.dart';
import 'package:bakan/views/sales/sales_history_page.dart';
import 'package:bakan/views/splash/splash_intro.dart';
import 'package:bakan/views/wallet/stat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final seenIntro = prefs.getBool('seen_intro') ?? false;
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(BakanApp(showIntro: !seenIntro, isLoggedIn: isLoggedIn));
}

class BakanApp extends StatelessWidget {
  final bool showIntro;
  final bool isLoggedIn;

  const BakanApp(
      {super.key, required this.showIntro, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bakan',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF004D40), Color(0xFF00796B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            child ?? const SizedBox(),
          ],
        );
      },
      initialRoute: getInitialRoute(),
      routes: {
        '/intro': (_) => const SplashIntro(),
        '/login': (_) => const LoginPage(),
        '/reset_password': (_) => const ResetPasswordPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const HomePage(),
        '/add_product': (_) => const AddProductPage(),
        '/sales': (_) => const SalesPage(),
        '/sales_history': (_) => const SalesHistoryPage(),
        '/wallet_stats': (_) => const WalletStatsPage(),
      },
    );
  }

  String getInitialRoute() {
    if (showIntro) {
      return '/intro';
    } else if (isLoggedIn) {
      return '/home';
    } else {
      return '/login';
    }
  }
}
