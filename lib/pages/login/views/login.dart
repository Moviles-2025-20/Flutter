import 'dart:ffi';

import 'package:app_flutter/pages/login/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Consumer<AuthViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isAuthenticated) {
            return _buildAuthenticatedView(viewModel);
          }
          return _buildLoginView(context, viewModel);
        },
      ),
    );
  }

  Widget _buildLoginView(BuildContext context, AuthViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose your login method',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            
            // Google Login Button
            _buildLoginButton(
              context: context,
              label: 'Login with Google',
              icon: Icons.g_mobiledata,
              color: Colors.red,
              onPressed: viewModel.isLoading 
                  ? null 
                  : () => viewModel.loginWithGoogle(),
            ),
            
            const SizedBox(height: 16),
            
            // GitHub Login Button
            _buildLoginButton(
              context: context,
              label: 'Login with GitHub',
              icon: Icons.code,
              color: Colors.black,
              onPressed: viewModel.isLoading 
                  ? null 
                  : () => Void //viewModel.loginWithGithub(),
            ),
            
            const SizedBox(height: 16),
            
            // Other
            _buildLoginButton(
              context: context,
              label: 'Login with Microsoft',
              icon: Icons.business,
              color: Colors.orange,
              onPressed: viewModel.isLoading 
                  ? null 
                  : () => Void //viewModel.other(),
            ),
            
            const SizedBox(height: 20),
            
            // Loading indicator
            if (viewModel.isLoading)
              const CircularProgressIndicator(),
            
            // Error message
            if (viewModel.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  viewModel.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

   Widget _buildAuthenticatedView(AuthViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (viewModel.user?.photoURL != null)
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(viewModel.user!.photoURL!),
            ),
          const SizedBox(height: 20),
          Text(
            'Welcome, ${viewModel.user?.displayName ?? "User"}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            viewModel.user?.email ?? '',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: viewModel.isLoading 
                ? null 
                : () => viewModel.logout(),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

  


/*
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
}*/