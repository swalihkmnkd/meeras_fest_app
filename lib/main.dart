import 'package:flutter/material.dart';
import 'package:meeras_fest_app/adminProvider.dart';
import 'package:meeras_fest_app/home_provider.dart';
import 'package:meeras_fest_app/profileProvider.dart';
import 'package:meeras_fest_app/register_provider.dart';
import 'package:meeras_fest_app/resultProvider.dart';
import 'package:provider/provider.dart';

import 'bottom_bar.dart';
import 'judge_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ResultProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => StudentEntryProvider()),
        ChangeNotifierProvider(create: (_) => JudgeProvider()),
        // Add more providers here
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home:  BottomBar(),
    );
  }
}

