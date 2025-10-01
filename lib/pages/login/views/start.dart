import 'package:flutter/material.dart';

class Start extends StatelessWidget {
  const Start({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFAED),
      body: 
      
      Stack(
        children: [
          // CÍRCULOS DE FONDO
          Positioned(
            top: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFED6275), // azul transparente
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: -250,
            child: Container(
              width: 500,
              height: 500,
              decoration: const BoxDecoration(
                color: Color(0xFFE9A55B), // rojo transparente
                shape: BoxShape.circle,
              ),
            ),
          ),
          
      
      
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 20),
            const Text(
              'Parchandes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6389E2),
              ),
            ),
            const SizedBox(height: 150),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/start/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6389E2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // esquinas redondeadas opcional
                    )
                  ),
                  child: const Text("Log In", style: TextStyle(fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),)),
                ),
                const SizedBox(width: 20),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
              child: const Text("SKIP IT FOR NOW", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            ),
          ],
      ),
      ),
    ],
    ),
    );
  }
}