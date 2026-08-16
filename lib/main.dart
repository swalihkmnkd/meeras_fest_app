import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:meeras_fest_app/admin/providers/adminProvider.dart';
import 'package:meeras_fest_app/home/home_provider.dart';
import 'package:meeras_fest_app/profile/profileProvider.dart';
import 'package:meeras_fest_app/registration/register_provider.dart';
import 'package:meeras_fest_app/result/resultProvider.dart';
import 'package:provider/provider.dart';

import 'admin/providers/programProvider.dart';
import 'admin/providers/score_calculator_provider.dart';
import 'firebase_options.dart';
import 'home/bottom_bar.dart';
import 'judges/judge_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ResultProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => StudentEntryProvider()),
        ChangeNotifierProvider(create: (_) => JudgeProvider()),
        ChangeNotifierProvider(create: (_) => ProgramProvider()),
        ChangeNotifierProvider(create: (_) => ScoreCalculatorProvider()),
        // Add more providers here
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: BottomBar(),
    );
  }
}