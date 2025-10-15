import 'package:app_flutter/main.dart';
import 'package:app_flutter/pages/login/viewmodels/register_viewmodel.dart';
import 'package:app_flutter/pages/login/views/register.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _hasRedirected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFAED),
      body: Consumer<AuthViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isAuthenticated) {
            // Trigger redirect after 5 seconds
            _handleRedirect(viewModel);
            return _buildAuthenticatedView(viewModel);
          }
          return _buildLoginView(context, viewModel);
        },
      ),
    );
  }

  void _handleRedirect(AuthViewModel viewModel) {
    if (_hasRedirected) return; // Evitar múltiples redirecciones
    
    _hasRedirected = true;
    
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      
      // Verificar si es primera vez
      if (viewModel.isFirstTimeUser) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/register',
          ModalRoute.withName('/start/login'),
          arguments: viewModel.user!.uid,
        );


      } else {
        Navigator.of(context).pushReplacementNamed('/home');
        print('Navigator stack después de ir a home: ${Navigator.of(context).canPop()}');

      }
    });
  }

  @override
  void dispose() {
    _hasRedirected = false;
    super.dispose();
  }

  Widget _buildLoginView(BuildContext context, AuthViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Login",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFED6275),
            ),
          ),
          const SizedBox(height: 40),
          
          const Text(
            'Choose your login method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),

          // Google Login Button
          _buildLoginButton(
            context: context,
            label: 'Login with Google',
            icon: Icons.g_mobiledata,
            color: const Color(0xFFED6275),
            onPressed: viewModel.isLoading ? null : () => viewModel.loginWithGoogle(),
          ),

          const SizedBox(height: 16),

          // GitHub Login Button
          _buildLoginButton(
            context: context,
            label: 'Login with GitHub',
            icon: Icons.code,
            color: Colors.black,
            onPressed: viewModel.isLoading ? null : () => viewModel.loginWithGithub(),
          ),

          const SizedBox(height: 16),

          // Facebook Login Button
          _buildLoginButton(
            context: context,
            label: 'Login with Facebook',
            icon: Icons.facebook, // icono de Facebook
            color: const Color(0xFF1877F2), // azul Facebook
            onPressed: viewModel.isLoading
                ? null
                : () {
              viewModel.loginWithFacebook();
            },
          ),

          const SizedBox(height: 30),

          // Loading indicator
          if (viewModel.isLoading)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFED6275)),
            ),

          // Error message
          if (viewModel.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  viewModel.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedView(AuthViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (viewModel.user?.photoURL != null)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFED6275),
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(viewModel.user!.photoURL!),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFED6275),
                  width: 3,
                ),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFED6275),
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          
          const SizedBox(height: 30),
          
          const Text(
            'Welcome!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFED6275),
            ),
          ),
          
          const SizedBox(height: 10),
          
          Text(
            viewModel.user?.displayName ?? "User",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            viewModel.user?.email ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Countdown indicator
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 3, end: 0),
            duration: const Duration(seconds: 3),
            builder: (context, value, child) {
              return Column(
                children: [
                  Text(
                    'Redirecting in $value seconds...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (5 - value) / 5,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFED6275)),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 30),
          
          Row(
            children: [
              
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED6275),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Ir inmediatamente sin esperar
                    if (viewModel.isFirstTimeUser) {
                      // Primera vez: ir a registro con uid
                      Navigator.pushReplacementNamed(
                        context,
                        '/register',
                        arguments: viewModel.user!.uid,
                      );
                    } else {
                       final mainPageState =
                            context.findAncestorStateOfType<MainPageState>();
                      mainPageState?.selectTab(0);
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  },
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
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
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
      ),
    );
  }
}