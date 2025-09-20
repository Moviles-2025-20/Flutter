import 'package:flutter/material.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  const Color(0xFFFEFAED),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Login",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color:Color(0xFFED6275),
              ),
            ),
            const SizedBox(height: 60),
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email, color: Color(0xFFED6275)),
                labelText: "Email",
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(164, 183, 132, 3), width: 1),
                ),
                // Línea inferior cuando está enfocado
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFED6275), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock, color:Color(0xFFED6275)),
                labelText: "Password",
                suffixIcon: const Icon(Icons.visibility),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(164, 183, 132, 3), width: 1),
                ),
                // Línea inferior cuando está enfocado
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFED6275), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(value: false, onChanged: (v) {}),
                const Text("Remember me"),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text("Forgot password?", style: TextStyle(color: Colors.black),),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFED6275),
                ),
                onPressed: () {},
                child: const Text("Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don’t have an account?"),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      color:Color(0xFFED6275),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
              child: const Text("SKIP IT FOR NOW", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}