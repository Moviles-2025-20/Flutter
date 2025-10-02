
import 'package:app_flutter/pages/wishMeLuck/model/wish_me_luck_event.dart';
import 'package:app_flutter/pages/wishMeLuck/viewmodel/wish_me_luck_view_model.dart';
import 'package:app_flutter/widgets/MagicBall/events_magic_ball.dart';
import 'package:flutter/material.dart';

class Magic8BallCard extends StatelessWidget {
  final WishMeLuckViewModel viewModel;
  final Animation<double> shakeAnimation;

  const Magic8BallCard({
    Key? key,
    required this.viewModel,
    required this.shakeAnimation,
  }) : super(key: key);

  Color _getColorForEvent(WishMeLuckEvent? event) {
    if (event == null) return const Color(0xFF6389E2);
    if (event.isPositive) return const Color(0xFF4CAF50);
    if (event.isNegative) return const Color(0xFFED6275);
    return const Color(0xFFFFA726);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        final double shake = shakeAnimation.value;
        final double offset = (shake * 20 * (shake < 0.5 ? 1 : -1));

        return Transform.translate(
          offset: Offset(offset, 0),
          child: Transform.rotate(
            angle: shake * 0.3 * (shake < 0.5 ? 1 : -1),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 200),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getColorForEvent(viewModel.currentEvent),
                    _getColorForEvent(viewModel.currentEvent)
                        .withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: _getColorForEvent(viewModel.currentEvent)
                        .withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Magic 8-Ball',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Magic8Ball(viewModel: viewModel),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


class Magic8Ball extends StatelessWidget {
  final WishMeLuckViewModel viewModel;

  const Magic8Ball({
    Key? key,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 1.0, end: viewModel.isLoading ? 0.95 : 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: BallContent(viewModel: viewModel),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


class BallContent extends StatelessWidget {
  final WishMeLuckViewModel viewModel;

  const BallContent({
    Key? key,
    required this.viewModel,
  }) : super(key: key);

  Color _getColorForEvent(WishMeLuckEvent event) {
    if (event.isPositive) return const Color(0xFF4CAF50);
    if (event.isNegative) return const Color(0xFFED6275);
    return const Color(0xFFFFA726);
  }

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const LoadingState();
    }

    if (viewModel.currentEvent != null) {
      return EventPreview(
        event: viewModel.currentEvent!,
        color: _getColorForEvent(viewModel.currentEvent!),
      );
    }

    return const DefaultState();
  }
}


class LoadingState extends StatelessWidget {
  const LoadingState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF6389E2),
            strokeWidth: 3,
          ),
          SizedBox(height: 15),
          Text(
            'Finding your luck...',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


class EventPreview extends StatelessWidget {
  final WishMeLuckEvent event;
  final Color color;

  const EventPreview({
    Key? key,
    required this.event,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EventImage(event: event, color: color),
          const SizedBox(height: 12),
          EventName(name: event.name),
          const SizedBox(height: 8),
          if (event.eventType.isNotEmpty)
            EventTypeChip(type: event.eventType.first, color: color),
        ],
      ),
    );
  }
}


class DefaultState extends StatelessWidget {
  const DefaultState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '8',
        style: TextStyle(
          fontSize: 100,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}