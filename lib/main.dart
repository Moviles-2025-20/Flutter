import 'package:app_flutter/firebase_options.dart';
import 'package:app_flutter/pages/Quiz/view/quizView.dart';
import 'package:app_flutter/pages/Quiz/viewmodel/quizViewModel.dart';
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
import 'package:app_flutter/util/local_DB_service.dart';
import 'package:app_flutter/util/recommendation_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final localUserService = LocalUserService();
  await localUserService.database;

  final crashTracker = CrashTracker();
  await crashTracker.initializeCrashlytics();

  await RecommendationsStorageService().preloadCacheFromStorage();

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
              builder: (context) {
                final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
                return ChangeNotifierProvider(
                  create: (_) => RegisterViewModel(authViewModel: authViewModel),
                  child: RegisterView(uid: uid),
                );
              },
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
  final List<int> _navigationStack = [0]; // Pila de navegación de tabs

  final List<GlobalKey<NavigatorState>> _navigatorKeys =
  List.generate(4, (_) => GlobalKey<NavigatorState>());

  final Set<int> _visitedIndices = {0};
  Map<String, dynamic>? _pendingMapArgs;

  void selectTab(int index, {Map<String, dynamic>? arguments}) {
    if (_navigationStack.isNotEmpty && _navigationStack.last == index) return;

    if (index == 1 && arguments != null) {
      _pendingMapArgs = arguments;
    }

    setState(() {
      _selectedIndex = index;
      _navigationStack.add(index);
      _visitedIndices.add(index);
    });

    if (arguments != null && index == 1) {
      _navigatorKeys[index].currentState?.pushReplacementNamed(
        '/',
        arguments: arguments,
      );
    }

    debugPrint('Navigation stack: $_navigationStack');
  }

  void _onItemTapped(int index, {Map<String, dynamic>? arguments}) {
    if (_navigationStack.isNotEmpty && _navigationStack.last == index) return;

    setState(() {
      _selectedIndex = index;
      _navigationStack.add(index);
      _visitedIndices.add(index); 
    });

    if (arguments != null && index == 1) {
      _navigatorKeys[index].currentState?.pushReplacementNamed(
        '/',
        arguments: arguments,
      );
    }

    debugPrint('Navigation stack: $_navigationStack');
  }

  Future<bool> _onWillPop() async {
    final currentNavigator = _navigatorKeys[_selectedIndex].currentState;

    // Si la pantalla actual dentro del tab puede hacer pop
    if (currentNavigator?.canPop() ?? false) {
      currentNavigator?.pop();
      return false;
    }

    // Si hay historial de tabs
    if (_navigationStack.length > 1) {
      setState(() {
        _navigationStack.removeLast();
        _selectedIndex = _navigationStack.last;
      });
      debugPrint('Back to tab: $_selectedIndex');
      return false;
    }

    // Si estás en el tab principal (Home), muestra confirmación antes de salir
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la app?'),
        content: const Text('¿Seguro que deseas cerrar Parchandes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    return shouldExit ?? false; // true cierra la app, false la mantiene
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _visitedIndices.contains(0) 
                ? Navigator(
                    key: _navigatorKeys[0],
                    onGenerateRoute: (settings) {
                      return MaterialPageRoute(builder: (_) => Home());
                    },
                  )
                : const SizedBox.shrink(),
            _visitedIndices.contains(1)
                ? Navigator(
                    key: _navigatorKeys[1],
                    onGenerateRoute: (settings) {
                      // Optimization: Check for pending args or settings.arguments
                      final args = _pendingMapArgs ?? 
                          ((settings.arguments is Map)
                              ? Map<String, dynamic>.from(settings.arguments as Map)
                              : null);
                              
                      // Clear pending args after use to avoid reusing them unexpectedly
                      if (_pendingMapArgs != null) {
                         _pendingMapArgs = null;
                      }
                      final startWithMap =
                          args?['startWithMapView'] as bool? ?? false;
                          
                      return MaterialPageRoute(
                        builder: (_) =>
                            EventsMapListView(startWithMapView: startWithMap),
                      );
                    },
                  )
                : const SizedBox.shrink(),
            _visitedIndices.contains(2)
                ? Navigator(
                    key: _navigatorKeys[2],
                    onGenerateRoute: (settings) {
                      return MaterialPageRoute(builder: (_) => const WishMeLuckView());
                    },
                  )
                : const SizedBox.shrink(),
            _visitedIndices.contains(3)
                ? Navigator(
                    key: _navigatorKeys[3],
                    onGenerateRoute: (settings) {
                      return MaterialPageRoute(builder: (_) => const ProfilePage());
                    },
                  )
                : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF6389E2),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: "Home"),
            BottomNavigationBarItem(
                icon: Icon(Icons.event_outlined),
                activeIcon: Icon(Icons.event),
                label: "Events"),
            BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_outlined),
                activeIcon: Icon(Icons.auto_awesome),
                label: "Wish Luck"),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: "Profile"),
          ],
        ),
      ),
    );
  }
}
