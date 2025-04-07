import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Pages import
import 'package:walletway/AnalysisPage.dart';
import 'package:walletway/EntryPage.dart';
import 'package:walletway/Multic.dart';
import 'package:walletway/about_app.dart';
import 'package:walletway/billsplit.dart';
import 'package:walletway/expense_entry.dart';
import 'package:walletway/how_to_use.dart';
import 'package:walletway/profile.dart';
import 'package:walletway/settings.dart';
import 'package:walletway/stock.dart';
import 'package:walletway/user_authentication/homepg.dart';
import 'package:walletway/user_authentication/login_page.dart';
import 'package:walletway/user_authentication/signup.dart';

// Providers import
import 'package:walletway/providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and Notifications in parallel
  await Future.wait([
    _initializeFirebase(),
    _initializeNotifications(),
  ]);

  runApp(const MyApp());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("🔥 Error initializing Firebase: $e");
  }
}

Future<void> _initializeNotifications() async {
  AwesomeNotifications().initialize(
    'resource://drawable/ww',
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Notification channel for basic alerts',
        importance: NotificationImportance.High,
        defaultColor: Colors.blue,
        ledColor: Colors.blue,
        channelShowBadge: true,
      ),
    ],
  );

  // Request notification permission if not already granted
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String initialRoute = SignUpPage.routeName;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

    if (user != null && isLoggedIn) {
      setState(() {
        initialRoute = HomePage.routeName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MaterialApp(
        title: 'WalletWay',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: initialRoute,
        routes: {
          SignUpPage.routeName: (context) => const SignUpPage(),
          LoginPage.routeName: (context) => const LoginPage(),
          HomePage.routeName: (context) => const HomePage(),
          AnalysisPage.routeName: (context) => AnalysisPage(),
          ExpenseGoalsPage.routeName: (context) =>
          const ExpenseGoalsPage(title: 'Expense Goals'),
          ExpenseEntryPage.routeName: (context) => const ExpenseEntryPage(),
          CurrencyConverterPage.routeName: (context) =>
          const CurrencyConverterPage(),
          BillSplitPage.routeName: (context) => BillSplitPage(),
          StockRecommendationPage.routeName: (context) =>
              StockRecommendationPage(),
          SettingsPage.routeName: (context) => const SettingsPage(),
          ProfilePage.routeName: (context) => ProfilePage(username: 'User'),
          HowToUsePage.routeName: (context) => HowToUsePage(),
          WelcomePage.routeName: (context) => WelcomePage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
