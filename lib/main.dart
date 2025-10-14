import 'package:app_flutter/firebase_options.dart';
import 'package:app_flutter/pages/events/view/event_list_view.dart';
import 'package:app_flutter/pages/login/viewmodels/auth_viewmodel.dart';
import 'package:app_flutter/pages/login/viewmodels/register_viewmodel.dart';
import 'package:app_flutter/pages/profile/viewmodels/profile_viewmodel.dart';
import 'package:app_flutter/pages/wishMeLuck/view/wish_me_luck_view.dart';
import 'package:app_flutter/util/analytics_service.dart';
import 'package:app_flutter/util/auth_service.dart';
import 'package:app_flutter/util/crash_analytics.dart';
import 'package:app_flutter/util/google_api_key.dart';
import 'package:app_flutter/pages/events/viewmodel/comment_viewmodel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'pages/home/home.dart';
import 'pages/profile/views/profile.dart';
import 'pages/login/views/loading_view.dart';
import 'pages/login/views/start.dart';
import 'pages/login/views/login.dart';
import 'pages/login/views/register.dart';

void main() async{
  
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final crashTracker = CrashTracker();
  await crashTracker.initializeCrashlytics();
  

  await RemoteConfigService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = AnalyticsService();
    analytics.activarFirebase;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authService: AuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => CommentViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Parchandes',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        navigatorObservers: [analytics.getAnalyticsObserver()],
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
            '/': (context) => const LoadingView(),
            '/start': (context) => const Start(),
            '/start/login': (context) => const Login(),
            '/home': (context) => const MainPage(),
            '/wishMeLuck': (context) => const WishMeLuckView(),
          },
        onGenerateRoute: (settings) {
          if (settings.name == '/register') {
            final uid = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (_) => RegisterViewModel(),
                child: RegisterView(uid: uid),
              ),
            );
          }
          return null;
        },
      ),
          
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index , {Map<String, dynamic>? arguments}) {
    setState(() {
      _selectedIndex = index;
    });
    if (arguments == null && index == 1) {
      _navigatorKeys[index].currentState?.pushReplacementNamed(
        '/',
        arguments: {},
      );
    }
  }

  void selectTab(int index, {Map<String, dynamic>? arguments}) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Si hay argumentos y es el tab de eventos (1), navegar con argumentos
    if (arguments != null && index == 1) {
      _navigatorKeys[index].currentState?.pushReplacementNamed(
        '/',
        arguments: arguments,
      );
    }
  }

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());
  List<GlobalKey<NavigatorState>> get navigatorKeys => _navigatorKeys;
  @override
  Widget build(BuildContext context) {


  return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Navigator(
            key: _navigatorKeys[0],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (_) => Home(), // tu pantalla principal
              );
            },
          ),
          Navigator(
            key: _navigatorKeys[1],
            onGenerateRoute: (settings) {
              final args = (settings.arguments is Map)
                ? Map<String, dynamic>.from(settings.arguments as Map)
                : null;
              final startWithMap = args?['startWithMapView'] as bool? ?? false;
              return MaterialPageRoute(
                builder: (_) => EventsMapListView(startWithMapView: startWithMap),
              );
            },
          ),
          Navigator(
            key: _navigatorKeys[2],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (_) => WishMeLuckView(),
              );
            },
          ),
          Navigator(
            key: _navigatorKeys[3],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (_) => ProfilePage(),
              );
            },
          ),
        ],
      ),
        bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF6389E2),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.event_outlined), activeIcon: Icon(Icons.event), label: "Events"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: "Wish Luck"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}