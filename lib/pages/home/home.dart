
import 'package:app_flutter/main.dart';
import 'package:app_flutter/widgets/customHeader.dart';
import 'package:app_flutter/widgets/home_sections_card.dart';
import 'package:app_flutter/widgets/recommendation_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      backgroundColor: const Color(0xFFFEFAED),
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = snapshot.data;

            if (user == null) {
              // Usuario no ha iniciado sesión
              return const Center(child: Text("Please log in"));
            }

            // Usuario autenticado
            return Column(
              children: [
                CustomHeader(
                  userName: user.displayName ?? "User",
                  profileImagePath: user.photoURL ?? 'assets/images/default_profile.png',
                  onNotificationTap: () {
                    print('Notification tapped');
                  },
                  onSearchSubmitted: (query) {
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
                        final mainPageState = context.findAncestorStateOfType<MainPageState>();
                        
                        switch(cardType) {
                          case CardType.weeklyChallenge:
                            // Agregar cuando ya este el WeeklyChallenge
                            /*mainPageState?.navigatorKeys[0].currentState?.push(
                              MaterialPageRoute(builder: (_) => WeeklyChallengePage()),
                            );*/ 
                            break;
                            
                          case CardType.personalityQuiz:
                          /*
                            mainPageState?.navigatorKeys[0].currentState?.push(
                              MaterialPageRoute(builder: (_) => PersonalityQuizPage()),
                            );*/
                            break;
                            
                          case CardType.wishMeLuck:
                            // Cambia a la tab WishMeLuck (2)
                            mainPageState?.selectTab(2);
                            break;
                            
                          case CardType.map:
                            // Agregar cuando ya este el Map
                            /*
                            mainPageState?.navigatorKeys[0].currentState?.push(
                              MaterialPageRoute(builder: (_) => MapPage()),
                            );*/
                            break;
                        }
                      },
                    ),
                    
                    SizedBox(height: 30),
                    
                    // Daily recommendation section
                    _SectionTitle(title: "Daily recommendation"),
                    SizedBox(height: 15),
                    
                    RecommendationCard(
                      title: 'Festival en el Chorro',
                      description: 'Déjate llevar por la energía de la música en vivo y disfruta una noche única en el Chorro.',
                      imagePath: 'assets/images/chorro_quevedo.png',
                      time: 'Today • 6:00 pm',
                      duration: '12 min',
                      tagColor: Color(0xFF6389E2),
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
                      description: 'Vive la magia del teatro con una obra que te atrapará desde el primer acto.',
                      imagePath: 'assets/images/teatro.jpg',
                      location: 'El bobo',
                      time: 'Tomorrow',
                      tagColor: Color(0xFFE9A55B),
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
        );
      },
      
    )
    )
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
        color: Colors.black,
      ),
    );
  }
}

