import 'package:flutter/material.dart';

class HeaderSectionWML extends StatelessWidget {
  final int? lastWished;
  const HeaderSectionWML({Key? key, this.lastWished}) : super(key: key);
  

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Need some luck?",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Let the magic 8-ball find your perfect event!",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            if (lastWished != null) ...[
              Text(
                "Last time you wished luck for:",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                "$lastWished days ago",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            
          ],
    )]);
  }
}
