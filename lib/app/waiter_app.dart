import 'package:flutter/material.dart';

import 'package:untitled1/core/theme/app_theme.dart';
import 'package:untitled1/features/home/presentation/waiter_home_screen.dart';

class WaiterApp extends StatefulWidget {
  const WaiterApp({super.key});

  @override
  State<WaiterApp> createState() => _WaiterAppState();
}

class _WaiterAppState extends State<WaiterApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waiter View',
      themeMode: _themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: WaiterHomeScreen(onToggleTheme: _toggleTheme),
    );
  }
}
