import 'package:app_flutter/pages/wishMeLuck/viewmodel/wish_me_luck_view_model.dart';
import 'package:app_flutter/widgets/MagicBall/button_wish_me_luck.dart';
import 'package:app_flutter/widgets/MagicBall/event_card_magic_ball.dart';
import 'package:app_flutter/widgets/MagicBall/events_magic_ball.dart';
import 'package:app_flutter/widgets/MagicBall/header_section.dart';
import 'package:app_flutter/widgets/MagicBall/magic_ball.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';

class WishMeLuckView extends StatelessWidget {
  
  const WishMeLuckView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WishMeLuckViewModel(),
      child: const _WishMeLuckContent(),
    );
  }
}

class _WishMeLuckContent extends StatefulWidget {
  const _WishMeLuckContent({Key? key}) : super(key: key);
  

  @override
  State<_WishMeLuckContent> createState() => _WishMeLuckContentState();
}

class _WishMeLuckContentState extends State<_WishMeLuckContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  int lastWishedTime = 0; // inicializamos con 0

  final WishMeLuckViewModel _viewModel = WishMeLuckViewModel();

  // Variables para el acelerómetro
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isShaking = false;
  DateTime? _lastShakeTime;
  static const double _shakeThreshold = 10.0; // Umbral de sensibilidad ESO SE CAMBIO PARA PROBAR EN EMULADOR ERA 15
  static const int _shakeCooldown = 3000; // Cooldown de 3 segundos entre sacudidas


  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Cargamos la variable asincrónica
    _loadLastWishedTime();
    _initAccelerometer();
  }

  Future<void> _loadLastWishedTime() async {
    lastWishedTime = await _viewModel.calculateDaysSinceLastWished();
    setState(() {}); // refresca la UI para que HeaderSectionWML reciba el valor
  }

  void _initAccelerometer() {
    _accelerometerSubscription = accelerometerEventStream().listen(
          (AccelerometerEvent event) {
        _detectShake(event);
      },
      onError: (error) {
        debugPrint('Error en acelerómetro: $error');
      },
    );
  }

  void _detectShake(AccelerometerEvent event) {
    // Calcular la magnitud total del movimiento
    final double magnitude = sqrt(
        event.x * event.x +
            event.y * event.y +
            event.z * event.z
    );

    // Si la magnitud supera el umbral
    if (magnitude > _shakeThreshold) {
      final now = DateTime.now();

      // Verificar cooldown
      if (_lastShakeTime == null ||
          now.difference(_lastShakeTime!).inMilliseconds > _shakeCooldown) {

        if (!_isShaking) {
          _isShaking = true;
          _lastShakeTime = now;
          _onShakeDetected();
        }
      }
    }
  }

  Future<void> _onShakeDetected() async {
    final viewModel = context.read<WishMeLuckViewModel>();

    // No hacer nada si ya está cargando
    if (viewModel.isLoading) {
      _isShaking = false;
      return;
    }

    debugPrint('Sacudida detectada!');

    // Vibración (opcional)
    HapticFeedback.mediumImpact();

    await _triggerShake();
    await Future.delayed(const Duration(milliseconds: 1500));
    await viewModel.wishMeLuck();

    _isShaking = false;
  }

  Future<void> _triggerShake() async {
    for (int i = 0; i < 3; i++) {
      await _shakeController.forward();
      await _shakeController.reverse();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WishMeLuckViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Wish Me Luck',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6389E2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enviamos la variable al Header
                HeaderSectionWML(
                  lastWished: lastWishedTime,
                ),
                const SizedBox(height: 30),

                // Indicador de que puede sacudir el teléfono
                if (!viewModel.isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6389E2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6389E2).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.vibration,
                          color: Color(0xFF6389E2),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Shake your phone or tap the button below!',
                            style: TextStyle(
                              color: Color(0xFF6389E2),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                Magic8BallCard(
                  viewModel: viewModel,
                  shakeAnimation: _shakeAnimation,
                ),
                const SizedBox(height: 25),

                if (viewModel.currentEvent != null)
                  MotivationalMessage(viewModel: viewModel),

                if (viewModel.currentEvent != null) const SizedBox(height: 20),

                if (viewModel.currentEvent != null)
                  EventPreviewCard(event: viewModel.currentEvent!)
                else
                  const EmptyState(),

                const SizedBox(height: 25),

                WishMeLuckButton(
                  viewModel: viewModel,
                  onPressed: () async {
                    _triggerShake();
                    await Future.delayed(const Duration(milliseconds: 1500));
                    viewModel.wishMeLuck();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
