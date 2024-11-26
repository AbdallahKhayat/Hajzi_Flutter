import 'package:blogapp/Blog/addBlog.dart';
import 'package:blogapp/Profile/MainProfile.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'Pages/HomePage.dart';
import 'Pages/WelcomePage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'consts.dart'; // Generated localization files

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _setup(); // Initialize only on supported platforms
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
  Widget page = const Center(child: CircularProgressIndicator()); // default page value
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
    );
  }
}
























// import 'package:blogapp/Blog/addBlog.dart';
// import 'package:blogapp/Profile/MainProfile.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'Pages/HomePage.dart';
// import 'Pages/WelcomePage.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//
// import 'consts.dart'; // Generated localization files
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await _setup();
//   runApp(const MyApp());
// }
// Future<void> _setup() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   Stripe.publishableKey = stripePublishableKey;
// }
// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   Widget page = const Center(child: CircularProgressIndicator()); //default page value
//   final storage = FlutterSecureStorage();
//   Locale _locale = const Locale('en', 'US'); // Default locale
//
//   @override
//   void initState() {
//     super.initState();
//     checkLogin();
//     _loadLanguagePreference();
//   }
//
//   /// Check if the user is logged in
//   void checkLogin() async {
//     String? token = await storage.read(key: "token");
//     setState(() {
//       page = token != null ? HomePage(setLocale: setLocale,filterState: 0,) : WelcomePage(setLocale: setLocale,);
//     });
//   }
//
//   /// Load the saved language preference from storage
//   void _loadLanguagePreference() async {
//     String? storedLanguage = await storage.read(key: "language");
//     if (storedLanguage != null) {
//       setState(() {
//         _locale = _getLocaleFromLanguage(storedLanguage);
//       });
//     }
//   }
//
//   /// Helper to map language to Locale
//   Locale _getLocaleFromLanguage(String language) {
//     switch (language) {
//       case "Arabic":
//         return const Locale('ar', 'AE');
//       case "English":
//       default:
//         return const Locale('en', 'US');
//     }
//   }
//
//   /// Set the locale dynamically and persist the language preference
//   void setLocale(Locale locale) async {
//     setState(() {
//       _locale = locale;
//     });
//     String language = locale.languageCode == 'ar' ? "Arabic" : "English";
//     await storage.write(key: "language", value: language);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         textTheme: GoogleFonts.openSansTextTheme(
//           Theme.of(context).textTheme,
//         ),
//       ),
//       locale: _locale,
//       localizationsDelegates: const [
//         AppLocalizations.delegate,
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//       ],
//       supportedLocales: const [
//         Locale('en'), // English
//         Locale('ar'), // Arabic
//       ],
//       home: page,
//     );
//   }
// }
//
//
//
//
//
//
// // import 'package:blogapp/Blog/addBlog.dart';
// // import 'package:blogapp/Profile/MainProfile.dart';
// // import 'package:flutter/material.dart';
// //
// // import 'Pages/HomePage.dart';
// // import 'Pages/WelcomePage.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// //
// // void main() {
// //   runApp(const MyApp());
// // }
// //
// // class MyApp extends StatefulWidget {
// //   const MyApp({super.key});
// //
// //   @override
// //   State<MyApp> createState() => _MyAppState();
// // }
// //
// // class _MyAppState extends State<MyApp> {
// //   Widget page=WelcomePage();// we will use token so that if the user is logged in
// //   final storage = new FlutterSecureStorage();//and closes the app , the user stays logged in in homepage
// //
// //   @override
// //   void initState() {
// //     // TODO: implement initState
// //     super.initState();
// //
// //   }
// //
// //   void checkLogin()async{
// //     String? token=await storage.read(key: "token");
// //     if(token!=null){
// //       setState(() {
// //         page=HomePage(); // so if there is token it means user logged in then stay homepage
// //       });
// //     }else{
// //       setState(() {
// //         page=WelcomePage();// so if there is no token it means user not logged in then page is WelcomePage
// //       });
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       theme: ThemeData(
// //         textTheme: GoogleFonts.openSansTextTheme(
// //           Theme.of(context).textTheme,
// //         ),
// //
// //       ),
// //       home:page,
// //     );
// //   }
// // }
