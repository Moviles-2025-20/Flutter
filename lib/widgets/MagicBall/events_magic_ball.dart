
import 'package:app_flutter/pages/wishMeLuck/model/wish_me_luck_event.dart';
import 'package:flutter/material.dart';

class EventImage extends StatelessWidget {
  final WishMeLuckEvent event;
  final Color color;

  const EventImage({
    Key? key,
    required this.event,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (event.metadata.imageUrl.isNotEmpty &&
        event.metadata.imageUrl != 'TEST') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          event.metadata.imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.event,
        size: 40,
        color: color,
      ),
    );
  }
}


class EventName extends StatelessWidget {
  final String name;

  const EventName({
    Key? key,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      name.length > 30 ? '${name.substring(0, 30)}...' : name,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class EventTypeChip extends StatelessWidget {
  final String type;
  final Color color;

  const EventTypeChip({
    Key? key,
    required this.type,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}