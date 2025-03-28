import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashIntro extends StatefulWidget {
  const SplashIntro({super.key});

  @override
  State<SplashIntro> createState() => _SplashIntroState();
}

class _SplashIntroState extends State<SplashIntro> {
  final LiquidController liquidController = LiquidController();

  @override
  Widget build(BuildContext context) {
    final pages = [
      const SplashPage(
        color: Colors.deepPurple,
        imagePath: 'assets/images/sf/3.png',
        title: 'Bienvenue sur Bakan',
        subtitle: 'Votre outil tout-en-un pour la gestion de vos activités.',
      ),
      const SplashPage(
        color: Colors.orangeAccent,
        imagePath: 'assets/images/sf/9.png',
        title: 'Gérez vos ventes',
        subtitle: 'Suivi de vos ventes, produits, et revenus en temps réel.',
      ),
      const SplashPage(
        color: Colors.green,
        imagePath: 'assets/images/sf/6.png',
        title: 'Maîtrisez vos finances',
        subtitle: 'Visualisez entrées, dépenses et bénéfices avec clarté.',
      ),
      const SplashPage(
        color: Colors.blueAccent,
        imagePath: 'assets/images/sf/11.png',
        title: 'Gérez vos clients',
        subtitle: 'Un CRM simplifié pour rester proche de votre clientèle.',
      ),
      SplashPage(
        color: Colors.teal,
        imagePath: 'assets/images/sf/4.png',
        title: "Passez à l'action !",
        subtitle: 'Commençons à travailler ensemble maintenant.',
        isLast: true,
        onDone: () => _finishIntro(context),
      ),
    ];

    return Scaffold(
      body: LiquidSwipe(
        pages: pages,
        enableLoop: false,
        fullTransitionValue: 300,
        slideIconWidget: const Icon(Icons.arrow_back_ios, color: Colors.white),
        positionSlideIcon: 0.8,
        liquidController: liquidController,
      ),
    );
  }

  Future<void> _finishIntro(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_intro', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }
}

class SplashPage extends StatelessWidget {
  final Color color;
  final String imagePath;
  final String title;
  final String subtitle;
  final bool isLast;
  final VoidCallback? onDone;

  const SplashPage({
    super.key,
    required this.color,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    this.isLast = false,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Image.asset(imagePath, height: 300),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 19, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            if (isLast)
              ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  foregroundColor: color,
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: const Text('Commencer'),
              ),
          ],
        ),
      ),
    );
  }
}
