import 'package:flutter/material.dart';
import 'package:smart_trio_card/smart_trio_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Smart Trio Card'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late SmartTrioCardController carouselController;

  @override
  void initState() {
    carouselController = SmartTrioCardController(tickerProvider: this, animationDuration: const Duration(milliseconds: 200), autoPlayInterval: const Duration(seconds: 1), autoPlay: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SmartTrioCard(
          background: Container(),
          params: SmartTrioCardParams(
            cardHeight: 214,
            cardWidth: 340,
          ),
          children: [
            _buildCreditCard(colors: [Color(0xFF8B4513), Color(0xFFA0522D), Color(0xFFCD853F), Color(0xFFDEB887)]),
            _buildCreditCard(colors: [Color(0xFFFFE4E1), Color(0xFFF0E68C), Color(0xFFDAA520), Color(0xFFB8860B)]),
            _buildCreditCard(colors: [Color(0xFFE6B800), Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF8C00)]),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard({List<Color>? colors}) {
    return Container(
      width: 340,
      height: 214,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors ?? [Color(0xFFE6B800), Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF8C00)], stops: [0.0, 0.3, 0.7, 1.0]),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
            ),
          ),
          Positioned(
            top: 100,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
            ),
          ),
          // Travel label
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
              child: const Text(
                'travel',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          // Platinum label
          Positioned(
            top: 16,
            left: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
              child: const Text(
                'Platinum',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          // Chip
          Positioned(
            top: 70,
            left: 24,
            child: Container(
              width: 32,
              height: 24,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(4)),
              child: Column(
                children: [
                  Container(width: 28, height: 2, margin: const EdgeInsets.only(top: 4), color: Colors.grey[400]),
                  Container(width: 28, height: 2, margin: const EdgeInsets.only(top: 2), color: Colors.grey[400]),
                  Container(width: 28, height: 2, margin: const EdgeInsets.only(top: 2), color: Colors.grey[400]),
                  Container(width: 28, height: 2, margin: const EdgeInsets.only(top: 2), color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          // Card Number
          Positioned(
            bottom: 60,
            left: 24,
            child: const Text(
              '**** **** **** 9010',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 2, fontFamily: 'monospace'),
            ),
          ),
          // VISA Logo (left)
          Positioned(
            bottom: 16,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: const Text(
                'VISA',
                style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
              ),
            ),
          ),
          // SA Logo (right)
          Positioned(
            bottom: 16,
            right: 24,
            child: Container(
              width: 32,
              height: 24,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(4)),
              child: const Center(
                child: Text(
                  'SA',
                  style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
