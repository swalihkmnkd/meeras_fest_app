import 'package:flutter/material.dart';
import 'package:meeras_fest_app/home_provider.dart';
import 'package:meeras_fest_app/profileProvider.dart';
import 'package:meeras_fest_app/resultProvider.dart';
import 'package:provider/provider.dart';

import 'bottom_bar.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ResultProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
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

