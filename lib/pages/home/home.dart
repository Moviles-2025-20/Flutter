import 'package:app_flutter/main.dart';
import 'package:app_flutter/widgets/customHeader.dart';
import 'package:app_flutter/widgets/home_sections_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/pages/profile/viewmodels/profile_viewmodel.dart';
import '../../widgets/recommendation_section.dart';
import '../FreeTime/view/free_time_view.dart';

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

        String profileImagePath;
        if (profilePhoto != null && profilePhoto.isNotEmpty) {
          profileImagePath = profilePhoto.startsWith('http')
              ? profilePhoto
              : profilePhoto;
        } else {
          profileImagePath = 'assets/images/default_profile.png';
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFEFAED),
          appBar: CustomHeader(
            userName: profileViewModel.currentUser?.profile.name ?? 
                     user.displayName ?? 
                     "User",
            profileImagePath: profileImagePath,
            onNotificationTap: () {
              print('Notification tapped');
            },
            onSearchSubmitted: (query) {
              print('Search: $query');
            },
          ),
          body: SingleChildScrollView(
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
                      case CardType.FreeTimeEvents:
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
                        mainPageState?.selectTab(
                          1,
                          arguments: {'startWithMapView': true},
                        );
                        break;
                    }
                  },
                ),
                const SizedBox(height: 30),
                RecommendationsSection(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}