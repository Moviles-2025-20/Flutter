import 'package:app_flutter/firebase_options.dart';
import 'package:app_flutter/pages/listEvents.dart';
import 'package:app_flutter/pages/login/viewmodels/auth_viewmodel.dart';
import 'package:app_flutter/pages/login/viewmodels/register_viewmodel.dart';
import 'package:app_flutter/util/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/home/home.dart';
import 'pages/detailEvent.dart';
import 'pages/profile.dart';
import 'pages/login/views/loading_view.dart';
import 'pages/login/views/start.dart';
import 'pages/login/views/login.dart';
import 'pages/login/views/register.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => AuthViewModel(
        authService: AuthService(),
      ),
        child:MaterialApp(
          title: 'Parchandes',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const LoadingView(),
            '/start': (context) => const Start(),
            '/start/login': (context) => const Login(),
            '/home': (context) => const MainPage(),}
            ,
          onGenerateRoute: (settings) {
            if (settings.name == '/register') {
              final uid = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider(
                  // ⬅️ ENVUELVE CON PROVIDER AQUÍ
                  create: (_) => RegisterViewModel(),
                  child: RegisterView(uid: uid),
                ),
              );
            }
            return null;
          },

        )
    );
  } 
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    Home(),
    ListEvents(),
    DetailEvent(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Demo Navigation"),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3C5BA9),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "",
          ),
        ],
      ),
    );
  }
}