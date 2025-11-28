import 'package:flutter/material.dart';

import '../util/quizConstant.dart';

enum CardType { weeklyChallenge, FreeTimeEvents, MoodQuiz, map }

class HomeSectionsCard extends StatelessWidget {
  final Function(CardType) onCardTap;

  const HomeSectionsCard({
    Key? key,
    required this.onCardTap,
  }) : super(key: key);

@override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MindSectionHeader(),
        SizedBox(height: 20),
        _MindCardsGrid(onCardTap: onCardTap),
      ],
    );
  }
}

class _MindSectionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's on your mind today?",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Choose what fits you best!",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }
}

class _MindCardsGrid extends StatelessWidget {
  final Function(CardType) onCardTap;

  const _MindCardsGrid({required this.onCardTap});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 2.2,
      children: [
        MindCard(
          title: 'Weekly Challenge',
          color: Color(0xFF6389E2),
          onTap: () => onCardTap(CardType.weeklyChallenge),
        ),
        MindCard(
          title: 'Free Time Events',
          color: Color(0xFFED6275),
          onTap: () => onCardTap(CardType.FreeTimeEvents),
        ),
        FutureBuilder<List<IconData>>(
          future: QuizStorageManager.getHomeIcons(),
          builder: (context, snapshot) {
            final icons = snapshot.data ?? [Icons.psychology];

            return MindCard(
              title: 'Mood Quiz',
              color: Color(0xFFED6275),
              onTap: () => onCardTap(CardType.MoodQuiz),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: icons
                    .map(
                      (icon) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                )
                    .toList(),
              ),
            );
          },
        ),

        MindCard(
          title: 'Map',
          color: Color(0xFF6389E2),
          onTap: () => onCardTap(CardType.map),
        ),
      ],
    );
  }
}


class MindCard extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onTap;
  final Widget? leading;

  const MindCard({
    Key? key,
    required this.title,
    required this.color,
    required this.onTap,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Aquí llamamos al callback
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) leading!,
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}