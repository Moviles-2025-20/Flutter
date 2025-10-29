import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/pages/login/viewmodels/auth_viewmodel.dart';
import 'dart:async';

class Start extends StatefulWidget {
  const Start({super.key});

  @override
  State<Start> createState() => _StartState();
}

class _StartState extends State<Start> {
  bool _hasInternet = true;
  bool _isCheckingInternet = true;
  Timer? _internetCheckTimer;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    // Verificar internet periódicamente cada 5 segundos
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _internetCheckTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicCheck() {
    _internetCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkInternetConnection();
    });
  }

  Future<void> _checkInternetConnection() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final hasInternet = await authViewModel.hasInternetConnection();
    
    if (mounted) {
      setState(() {
        _hasInternet = hasInternet;
        _isCheckingInternet = false;
      });
    }
  }

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
                // Mensaje de error si no hay internet
                if (!_hasInternet && !_isCheckingInternet)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wifi_off,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No internet connection',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _hasInternet && !_isCheckingInternet
                          ? () {
                              Navigator.pushNamed(context, '/start/login');
                            }
                          : null, // Deshabilitar si no hay internet
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6389E2),
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: _isCheckingInternet
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              "Log In",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
          ],
      ),
      ),
    ],
    ),
    );
  }
}