import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const TrenRisetApp());
}

/// Tren Riset — aplikasi riset konten trending (YouTube + Facebook).
/// Bahasa UI: Bahasa Indonesia.
class TrenRisetApp extends StatelessWidget {
  const TrenRisetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tren Riset',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
