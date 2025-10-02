import 'package:flutter/material.dart';

enum CardType { weeklyChallenge, personalityQuiz, wishMeLuck, map }

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
          url: '/weeklyChallenge',
          onTap: () => onCardTap(CardType.weeklyChallenge),
        ),
        MindCard(
          title: 'Personality Quiz',
          color: Color(0xFFED6275),
          url: '/personalityQuiz',
          onTap: () => onCardTap(CardType.personalityQuiz),
        ),
        MindCard(
          title: 'Wish me Luck',
          color: Color(0xFFED6275),
          url: '/wishMeLuck',
          onTap: () => onCardTap(CardType.wishMeLuck),
        ),
        MindCard(
          title: 'Map',
          color: Color(0xFF6389E2),
          url: '/map',
          onTap: () => onCardTap(CardType.map),
        ),
      ],
    );
  }
}

class MindCard extends StatelessWidget {
  final String title;
  final Color color;
  final String url;
  final VoidCallback onTap;

  const MindCard({
    Key? key,
    required this.title,
    required this.color,
    required this.onTap,
    required this.url,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.pushNamed(context, url);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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