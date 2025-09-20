import 'package:app_flutter/pages/home.dart';
import 'package:flutter/material.dart';

import 'pages/carga.dart';
import 'pages/inicio.dart';
import 'pages/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parchandes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const Carga(),
        '/inicio': (context) => const Inicio(),
        '/inicio/login': (context) => const Login(),
        '/home': (context) => const Home(),
      },
    );
  }
}
