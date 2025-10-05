import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
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
    return AppBar(
      backgroundColor: Color(0xFF6389E2),
      elevation: 0,
      toolbarHeight: 100,
      automaticallyImplyLeading: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      flexibleSpace: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
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
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
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
          backgroundImage: profileImagePath.isNotEmpty
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
    return IconButton(
      icon: Icon(
        Icons.notifications_outlined,
        color: Colors.white,
        size: 35,
      ),
      onPressed: () {
        Navigator.pushNamed(context, '/notifications');
      },
    );
  }
}