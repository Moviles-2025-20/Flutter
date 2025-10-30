import 'dart:io';

import 'package:app_flutter/main.dart';
import 'package:app_flutter/pages/FreeTime/view/free_time_view.dart';
import 'package:app_flutter/pages/weekly/viewmodel/weekly_challenge_view_model.dart';
import 'package:app_flutter/widgets/customHeader.dart';
import 'package:app_flutter/widgets/home_sections_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/pages/profile/viewmodels/profile_viewmodel.dart';
import 'package:app_flutter/pages/weekly/view/weekly_challenge_view.dart';

import '../../../widgets/recommendation_section.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, profileViewModel, child) {
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          return const Scaffold(
            body: Center(child: Text("Please log in")),
          );
        }

        final profilePhoto = profileViewModel.currentUser?.profile.photo;
        final profileImage = getProfileImage(profilePhoto);

        return Scaffold(
          backgroundColor: const Color(0xFFFEFAED),
          appBar: CustomHeader(
            userName: profileViewModel.currentUser?.profile.name ?? 
                     user.displayName ?? 
                     "User",
            profileImage: profileImage,
            onNotificationTap: () {
              print('Notification tapped');
            },
            onSearchSubmitted: (query) {
              print('Search: $query');
            },
          ),
          body: ListView(
            padding: EdgeInsets.all(20),
            children: [
                // Body Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HomeSectionsCard(
                          onCardTap: (cardType) {
                            final mainPageState =
                            context.findAncestorStateOfType<MainPageState>();

                            switch (cardType) { 
                              case CardType.weeklyChallenge:
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChangeNotifierProvider(
                                      create: (_) => WeeklyChallengeViewModel(),
                                      child:  WeeklyChallengeView(),
                                    ),
                                  ),
                                );
                                break;
                              

                              case CardType.FreeTimeEvents:
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FreeTimeView(userId: user.uid),
                                    ),
                                  );
                                }
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


                        // Carga dinámica de recomendaciones con FutureBuilder
                        RecommendationsSection(),


                        const SizedBox(height: 30),

                      ],
                    ),
                  ),
                ),
              ],
            )
            
        );
          
      },
    );
  }

  ImageProvider getProfileImage(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return const AssetImage("assets/images/profileimg.png");
    } else if (photoPath.startsWith('http')) {
      return NetworkImage(photoPath);
    } else {
      return FileImage(File(photoPath));
    }
  }
}