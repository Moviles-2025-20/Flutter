import 'package:app_flutter/pages/news/views/news.dart';
import 'package:flutter/material.dart';

import '../pages/notification.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final VoidCallback onNotificationTap;
  final Function(String) onSearchSubmitted;
  final ImageProvider profileImage;


  const CustomHeader({
    Key? key,
    required this.userName,
    required this.profileImage,
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Expanded(child: _ProfileSection(
                      userName: userName,
                      profileImage: profileImage,
                    ),
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
  final ImageProvider profileImage;


  const _ProfileSection({
    required this.userName,
    required this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: profileImage),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome',
                softWrap: true,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                'Hi, $userName!',
                maxLines: 1,  
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
      icon: const Icon(Icons.description, color: Colors.white),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NewsView(),
          ),
        );
      },
    );
  }
}