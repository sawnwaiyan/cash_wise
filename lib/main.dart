import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/entry_provider.dart';
import 'providers/budget_provider.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style to match dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:            Colors.transparent,
    statusBarIconBrightness:   Brightness.light,
    systemNavigationBarColor:  AppTheme.navyCard,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const CashWiseApp());
}

class CashWiseApp extends StatelessWidget {
  const CashWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EntryProvider()..loadCycle()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()..loadMonth()),
      ],
      child: MaterialApp(
        title:        'CashWise',
        debugShowCheckedModeBanner: false,
        theme:        AppTheme.dark,
        home:         const MainShell(),
      ),
    );
  }
}