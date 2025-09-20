import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text(
          "Profile",
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF3C5BA9),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Foto y datos
            Row(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage("assets/profileimg.png"), // pon tu imagen
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Juliana Torres",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("Major - Communications"),
                    Text("Age - 21"),
                    Text("Personality - Extroverted"),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            // --- Preferencias
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("My preferences",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Chip(
                  label: Text("Browse More"),
                  backgroundColor: Colors.grey,
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(label: Text("Music",style: TextStyle(color: Colors.white),), backgroundColor: Color(
                    0xFFE3944F)),
                Chip(
                    label: Text("Asian community",style: TextStyle(color: Colors.white),),
                    backgroundColor: Color(
                        0xFFE3944F)),
                Chip(label: Text("Exchange",style: TextStyle(color: Colors.white),), backgroundColor: Color(
                    0xFFE3944F)),
                Chip(
                    label: Text("Social activities",style: TextStyle(color: Colors.white),),
                    backgroundColor: Color(
                        0xFFE3944F)),
                Chip(label: Text("Sports",style: TextStyle(color: Colors.white),), backgroundColor: Color(
                    0xFFE3944F)),
                Chip(label: Text("Art",style: TextStyle(color: Colors.white),), backgroundColor: Color(
                    0xFFE3944F)),
              ],
            ),
            const SizedBox(height: 30),
            Divider(
              color: Colors.grey,
              thickness: 1,
              indent: 0,
              endIndent: 0,
            ),
            const SizedBox(height: 30),
            // --- Botones
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xEA1266B6),
                  minimumSize: const Size(double.infinity, 40)),
              onPressed: () {},
              child: const Text("Change your password",
                style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xEA1266B6),
                  minimumSize: const Size(double.infinity, 40)),
              onPressed: () {},
              child: const Text("Change your profile information",style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA9892),
                  minimumSize: const Size(double.infinity, 40)),
              onPressed: () {},
              icon: const Icon(Icons.send,
                color: Colors.white, // aquí cambias el color
                size: 30, ),
              label: const Text("Log Out",style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA9892),
                  minimumSize: const Size(double.infinity, 40)),
              onPressed: () {},
              child: const Text("Delete your account",style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),),
            ),
          ],
        ),
      ),
    );
  }
}