import 'package:app_flutter/widgets/customHeader.dart';
import 'package:app_flutter/widgets/homeSectionsCard.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header Component
            CustomHeader(
              userName: 'Juliana',
              profileImagePath: 'assets/profile.jpg',
              onNotificationTap: () {
                // Handle notification tap
                print('Notification tapped');
              },
              onSearchSubmitted: (query) {
                // Handle search
                print('Search: $query');
              },
            ),
            
            // Body Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mind Section Component
                    HomeSectionsCard(
                      onCardTap: (cardType) {
                        print('Card tapped: $cardType');
                      },
                    ),
                    
                    SizedBox(height: 30),
                    
                    // Daily recommendation section
                    _SectionTitle(title: "Daily recommendation"),
                    SizedBox(height: 15),
                    
                    RecommendationCard(
                      title: 'Festival en el Chorro',
                      description: 'Déjate llevar por la energía de la música en vivo y disfruta una noche única en el Chorro.',
                      imagePath: 'assets/festival.jpg',
                      time: 'Today • 6:00 pm',
                      duration: '12 min',
                      tagColor: Colors.blue[400]!,
                      onTap: () {
                        print('Festival card tapped');
                      },
                    ),
                    
                    SizedBox(height: 30),
                    
                    // Close to you section
                    _SectionTitle(title: "Close to you"),
                    SizedBox(height: 15),
                    
                    RecommendationCard(
                      title: 'Obra de teatro',
                      description: 'Vive la magia del teatro con una obra que te',
                      imagePath: 'assets/teatro.jpg',
                      location: 'El bobo',
                      time: 'Tomorrow',
                      tagColor: Colors.orange[400]!,
                      showLocationInfo: true,
                      onTap: () {
                        print('Teatro card tapped');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }
}