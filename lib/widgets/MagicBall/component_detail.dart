import 'package:app_flutter/pages/wishMeLuck/model/event.dart';
import 'package:app_flutter/pages/wishMeLuck/model/wish_me_luck_event.dart';
import 'package:flutter/material.dart';

class EventTypeChips extends StatelessWidget {
  final List<String> eventTypes;
  final Color color;

  const EventTypeChips({
    Key? key,
    required this.eventTypes,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (eventTypes.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: eventTypes
          .map((type) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ============================================
// EVENT TITLE WIDGET
// ============================================
class EventTitle extends StatelessWidget {
  final String title;

  const EventTitle({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ============================================
// EVENT DESCRIPTION WIDGET
// ============================================
class EventDescription extends StatelessWidget {
  final String description;

  const EventDescription({
    Key? key,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      description,
      style: TextStyle(
        color: Colors.grey[700],
        fontSize: 15,
        height: 1.5,
      ),
    );
  }
}

// ============================================
// EVENT INFO SECTION WIDGET
// ============================================
class EventInfoSection extends StatelessWidget {
  final WishMeLuckEvent event;

  const EventInfoSection({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InfoRow(
          icon: Icons.location_on,
          text: '${event.location.city} - ${event.location.address}',
        ),
        const SizedBox(height: 12),
        if (event.schedule.days.isNotEmpty)
          InfoRow(
            icon: Icons.calendar_today,
            text: event.schedule.days.join(', '),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InfoRow(
                icon: Icons.timer,
                text: '${event.metadata.durationMinutes} min',
              ),
            ),
            Expanded(
              child: InfoRow(
                icon: Icons.attach_money,
                text: event.metadata.cost,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================
// INFO ROW WIDGET
// ============================================
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({
    Key? key,
    required this.icon,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6389E2), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class EventStatsSection extends StatelessWidget {
  final EventStats stats;

  const EventStatsSection({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          StatItem(
            icon: Icons.star,
            value: stats.rating.toStringAsFixed(1),
            label: 'Rating',
            color: Colors.amber,
          ),
          StatItem(
            icon: Icons.trending_up,
            value: stats.popularity.toString(),
            label: 'Popularity',
            color: const Color(0xFF6389E2),
          ),
          StatItem(
            icon: Icons.check_circle,
            value: stats.totalCompletions.toString(),
            label: 'Done',
            color: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }
}

// ============================================
// STAT ITEM WIDGET
// ============================================
class StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatItem({
    Key? key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ============================================
// EMPTY STATE CARD WIDGET
// ============================================
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 7),
          Text(
            'Shake or Tap the button below',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'And let the magic 8-ball discover your perfect event!',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}