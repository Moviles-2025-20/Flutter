import 'package:app_flutter/pages/inicio.dart';
import 'package:flutter/material.dart';
import 'dart:async';


class Carga extends StatefulWidget {
  const Carga({super.key});

  @override
  State<Carga> createState() => _CargaState();
}

class _CargaState extends State<Carga> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Inicio()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  const Color(0xFFFEFAED),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            const Text(
              'Parchandes',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6389E2),
              ),
            ), 
            const SizedBox(height: 20),
            const CircularProgressIndicator(), 
          ],
        ),
      ),
    );
  }
}
