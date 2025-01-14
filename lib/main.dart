import 'package:blogapp/Notifications/push_notifications.dart';
import 'package:blogapp/Screen/CameraFiles/CameraScreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'Pages/HomePage.dart';
import 'Pages/WelcomePage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Requests/RequestsScreen.dart';
import 'consts.dart'; // Generated localization files



final navigationKey=GlobalKey<NavigatorState>();

//function to listen to background changes
Future _firebaseBackgroundMessage(RemoteMessage message)async{
  
  if(message.notification!=null){
    print("Some Notification Recieved");
  }
}




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _setup(); // Initialize only on supported platforms
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyCcC5B1TMsrt2lRAKwYfcBGdxsEbymtuMw",
          authDomain: "hajziapp.firebaseapp.com",
          projectId: "hajziapp",
          storageBucket: "hajziapp.firebasestorage.app",
          messagingSenderId: "984409303005",
          appId: "1:984409303005:web:a9f763e8398d381037f834"),
    );
  }else{
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: "AIzaSyB60YJo_xmGnmPD7yoweRZkj2UzCLDoPUM",
          appId: "1:984409303005:android:9b6a013abd94d8f037f834",
          messagingSenderId: "984409303005",
          projectId: "hajziapp",
        ),
      );
      print("Firebase initialized successfully");
    }catch(e,stacktrace){
      print("Firebase initialization error: $e");
      print("Stacktrace: $stacktrace");
    }
  }

  FirebaseMessaging.instance.getToken().then((token) {
    print("Admin Device Token: $token");
  });


  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null && message.data["type"] == "blog_approval") {
      navigationKey.currentState?.pushNamed("/Requests/RequestsScreen",arguments: message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message,) {
    if (message.data["type"] == "blog_approval") {
      navigationKey.currentState?.pushNamed("/Requests/RequestsScreen",arguments: message);
    }
  });

  PushNotifications.init();
  // Listen to background notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessage);
  runApp(const MyApp());
}

Future<void> _setup() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if the app is running on the web before initializing Stripe
  if (!kIsWeb) {
    Stripe.publishableKey = stripePublishableKey; // Set your publishable key
  } else {
    debugPrint('Stripe is not initialized on web.');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget page =
      const Center(child: CircularProgressIndicator()); // default page value
  final storage = FlutterSecureStorage();
  Locale _locale = const Locale('en', 'US'); // Default locale

  @override
  void initState() {
    super.initState();
    checkLogin();
    _loadLanguagePreference();
  }

  /// Check if the user is logged in
  void checkLogin() async {
    String? token = await storage.read(key: "token");
    setState(() {
      page = token != null
          ? HomePage(setLocale: setLocale, filterState: 0)
          : WelcomePage(setLocale: setLocale);
    });
  }

  /// Load the saved language preference from storage
  void _loadLanguagePreference() async {
    String? storedLanguage = await storage.read(key: "language");
    if (storedLanguage != null) {
      setState(() {
        _locale = _getLocaleFromLanguage(storedLanguage);
      });
    }
  }

  /// Helper to map language to Locale
  Locale _getLocaleFromLanguage(String language) {
    switch (language) {
      case "Arabic":
        return const Locale('ar', 'AE');
      case "English":
      default:
        return const Locale('en', 'US');
    }
  }

  /// Set the locale dynamically and persist the language preference
  void setLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    String language = locale.languageCode == 'ar' ? "Arabic" : "English";
    await storage.write(key: "language", value: language);
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigationKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.openSansTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('ar'), // Arabic
      ],
      home: page,
      routes: {
        '/Requests/RequestsScreen': (context) => RequestsScreen(),
        '/Home': (context) => HomePage(setLocale: setLocale, filterState: 0),
        '/Welcome': (context) => WelcomePage(setLocale: setLocale),
      },
    );
  }
}
