


import 'package:app_flutter/main.dart';
import 'package:app_flutter/widgets/customHeader.dart';
import 'package:app_flutter/widgets/home_sections_card.dart';
import 'package:app_flutter/widgets/recommendation_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/pages/profile/viewmodels/profile_viewmodel.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFAED),
      body: SafeArea(
        child: Consumer<ProfileViewModel>(
          builder: (context, profileViewModel, child) {
            final user = FirebaseAuth.instance.currentUser;

            if (user == null) {
              // Usuario no ha iniciado sesión
              return const Center(child: Text("Please log in"));
            }

            final profilePhoto = profileViewModel.currentUser?.profile.photo;

            String profileImagePath;
            if (profilePhoto != null && profilePhoto.isNotEmpty) {
              profileImagePath = profilePhoto.startsWith('http')
                  ? profilePhoto
                  : profilePhoto; // ruta local
            } else {
              profileImagePath = 'assets/images/default_profile.png';
            }

            return Column(
              children: [
                CustomHeader(
                  userName: profileViewModel.currentUser?.profile.name ?? user.displayName ?? "User",
                  profileImagePath: profileImagePath,
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
                        HomeSectionsCard(
                          onCardTap: (cardType) {
                            final mainPageState =
                            context.findAncestorStateOfType<MainPageState>();

                            switch (cardType) {
                              case CardType.weeklyChallenge:
                                break;
                              case CardType.personalityQuiz:
                                break;
                              case CardType.wishMeLuck:
                                mainPageState?.selectTab(2);
                                break;
                              case CardType.map:
                                mainPageState?.selectTab(1, arguments: {'startWithMapView': true});
                                break;
                            }
                          }
                        ),

                        const SizedBox(height: 30),

                        _SectionTitle(title: "Daily recommendation"),
                        const SizedBox(height: 15),

                        RecommendationCard(
                          title: 'Festival en el Chorro',
                          description:
                          'Déjate llevar por la energía de la música en vivo y disfruta una noche única en el Chorro.',
                          imagePath: 'assets/images/chorro_quevedo.png',
                          time: 'Today • 6:00 pm',
                          duration: '12 min',
                          tagColor: const Color(0xFF6389E2),
                          onTap: () {
                            print('Festival card tapped');
                          },
                        ),

                        const SizedBox(height: 30),

                        _SectionTitle(title: "Close to you"),
                        const SizedBox(height: 15),

                        RecommendationCard(
                          title: 'Obra de teatro',
                          description:
                          'Vive la magia del teatro con una obra que te atrapará desde el primer acto.',
                          imagePath: 'assets/images/teatro.jpg',
                          location: 'El bobo',
                          time: 'Tomorrow',
                          tagColor: const Color(0xFFE9A55B),
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
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}
