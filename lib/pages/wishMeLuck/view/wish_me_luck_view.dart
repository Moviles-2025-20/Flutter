import 'package:app_flutter/pages/wishMeLuck/viewmodel/wish_me_luck_view_model.dart';
import 'package:app_flutter/widgets/MagicBall/button_wish_me_luck.dart';
import 'package:app_flutter/widgets/MagicBall/event_card_magic_ball.dart';
import 'package:app_flutter/widgets/MagicBall/events_magic_ball.dart';
import 'package:app_flutter/widgets/MagicBall/header_section.dart';
import 'package:app_flutter/widgets/MagicBall/magic_ball.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _triggerShake() async {
    for (int i = 0; i < 3; i++) {
      await _shakeController.forward();
      await _shakeController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WishMeLuckViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Wish Me Luck',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
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
                const HeaderSectionWML(),
                const SizedBox(height: 30),

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