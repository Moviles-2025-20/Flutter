
import 'package:app_flutter/pages/wishMeLuck/model/wish_me_luck_event.dart';
import 'package:app_flutter/pages/wishMeLuck/viewmodel/wish_me_luck_view_model.dart';
import 'package:app_flutter/widgets/MagicBall/component_detail.dart';
import 'package:flutter/material.dart';

class MotivationalMessageCard extends StatelessWidget {
  final WishMeLuckViewModel viewModel;

  const MotivationalMessageCard({
    Key? key,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB74D), width: 2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Color(0xFFFF9800),
            size: 28,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              viewModel.getMotivationalMessage(),
              style: const TextStyle(
                color: Color(0xFFE65100),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// EVENT DETAILS CARD WIDGET
// ============================================
class EventDetailsCard extends StatelessWidget {
  final WishMeLuckEvent event;

  const EventDetailsCard({
    Key? key,
    required this.event,
  }) : super(key: key);

  Color _getColorForEvent(WishMeLuckEvent event) {
    if (event.isPositive) return const Color(0xFF4CAF50);
    if (event.isNegative) return const Color(0xFFED6275);
    return const Color(0xFFFFA726);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 800),
      opacity: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventTypeChips(
                eventTypes: event.eventType,
                color: _getColorForEvent(event),
              ),
              const SizedBox(height: 15),
              EventTitle(title: event.name),
              const SizedBox(height: 10),
              EventDescription(description: event.description),
              const SizedBox(height: 20),
              EventInfoSection(event: event),
              const SizedBox(height: 20),
              //EventStatsSection(stats: event.stats),
            ],
          ),
        ),
      ),
    );
  }
}