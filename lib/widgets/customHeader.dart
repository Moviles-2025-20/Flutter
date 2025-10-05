import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget {
  final String userName;
  final String profileImagePath;
  final VoidCallback onNotificationTap;
  final Function(String) onSearchSubmitted;

  const CustomHeader({
    Key? key,
    required this.userName,
    required this.profileImagePath,
    required this.onNotificationTap,
    required this.onSearchSubmitted,
  }) : super(key: key);

 @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF6389E2),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          // Profile and notification row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ProfileSection(
                userName: userName,
                profileImagePath: profileImagePath,
              ),
              _NotificationButton(onTap: onNotificationTap),
            ],
          ),
          SizedBox(height: 5),
        ],
      ),
    );
  }
}


class _ProfileSection extends StatelessWidget {
  final String userName;
  final String profileImagePath;

  const _ProfileSection({
    required this.userName,
    required this.profileImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
       CircleAvatar(
        radius: 25,
        backgroundImage: profileImagePath != null
            ? NetworkImage(profileImagePath)
            : AssetImage('assets/images/default_profile.png') as ImageProvider,
      ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            Text(
              'Hi, $userName!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NotificationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.pushNamed(context, '/notifications');
      },
      child: Icon(
        Icons.notifications_outlined,
        color: Colors.white,
        size: 35,
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final Function(String) onSubmitted;

  const _SearchBar({required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey[600]),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}