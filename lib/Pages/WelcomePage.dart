import 'dart:convert';
import 'package:blogapp/Pages/HomePage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'EmailSignInPage.dart';
import 'EmailSignUpPage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:blogapp/constants.dart'; // Contains your main color (e.g., appColorNotifier)

class WelcomePage extends StatefulWidget {
  final Function(Locale locale) setLocale;

  const WelcomePage({super.key, required this.setLocale});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late Animation<Offset> animation1;
  late AnimationController _controller2;
  late Animation<Offset> animation2;
  String? selectedLanguage;

  bool _isLogin = false;
  late Map data;
  final facebookLogin = FacebookAuth.instance;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    animation1 = Tween<Offset>(
      begin: const Offset(0.0, 8.0),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(parent: _controller1, curve: Curves.easeOut),
    );

    _controller2 = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    animation2 = Tween<Offset>(
      begin: const Offset(0.0, 8.0),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(parent: _controller2, curve: Curves.elasticInOut),
    );

    _controller1.forward();
    _controller2.forward();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set selectedLanguage based on the current locale:
    selectedLanguage = Localizations.localeOf(context).languageCode == 'ar' ? "العربية" : "English";
  }

  // Language dialog method
  void _showLanguageDialog(BuildContext context) {
    List<String> languages = ["English", "العربية"];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectLanguage),
          content: SingleChildScrollView(
            child: Column(
              children: languages.map((language) {
                return RadioListTile<String>(
                  title: Text(language),
                  value: language,
                  groupValue: selectedLanguage,
                  onChanged: (value) {
                    setState(() {
                      selectedLanguage = value;
                    });
                    Locale newLocale = (value == "العربية")
                        ? const Locale('ar', 'AE')
                        : const Locale('en', 'US');
                    widget.setLocale(newLocale);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the current language is Arabic.
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Build the Row that reverses its children for Arabic.
    final List<Widget> authRowChildren = isArabic
        ? [
      // In Arabic: "Sign In" comes first, then "Already have an account?"
      InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => EmailSignInPage(setLocale: widget.setLocale),
          ));
        },
        child: Text(
          AppLocalizations.of(context)!.signIn,
          style: const TextStyle(
            color: Colors.blueAccent,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
            decorationColor: Colors.blue,
            decorationThickness: 2,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        AppLocalizations.of(context)!.alreadyHaveAnAccount,
        style: const TextStyle(fontSize: 17),
      ),
    ]
        : [
      // For English (and other LTR languages): "Already have an account?" then "Sign In"
      Text(
        AppLocalizations.of(context)!.alreadyHaveAnAccount,
        style: const TextStyle(fontSize: 17),
      ),
      const SizedBox(width: 10),
      InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => EmailSignInPage(setLocale: widget.setLocale),
          ));
        },
        child: Text(
          AppLocalizations.of(context)!.signIn,
          style: const TextStyle(
            color: Colors.blueAccent,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
            decorationColor: Colors.blue,
            decorationThickness: 2,
          ),
        ),
      ),
    ];

    // Wrap in Directionality to force LTR (prevents mirror effect)
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        // Top bar with language-change icon (using main color from appColorNotifier)
        body: Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    appColorNotifier.value.withOpacity(0.7),
                  ],
                  begin: const FractionalOffset(0.0, 1.0),
                  end: const FractionalOffset(0.0, 1.0),
                  stops: const [0.0, 1.0],
                  tileMode: TileMode.repeated,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 60.0),
                child: Column(
                  children: [
                    // Your branded image
                    ClipOval(
                      child: Image.asset(
                        "assets/Hajzi.png",
                        width: 250,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    SlideTransition(
                      position: animation1,
                      child: Text(
                        AppLocalizations.of(context)!.welcome1, // Localized welcome message
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    boxContainer("assets/google.png", AppLocalizations.of(context)!.signUpWithGoogle, null),
                    const SizedBox(height: 20),
                    boxContainer("assets/Facebook_logo.png", AppLocalizations.of(context)!.signUpWithFacebook, onFBLogin),
                    const SizedBox(height: 20),
                    boxContainer("assets/email.png", AppLocalizations.of(context)!.signUpWithEmail, onEmailClick),
                    const SizedBox(height: 30),
                    SlideTransition(
                      position: animation2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: authRowChildren, // Use our conditionally built list.
                      ),
                    )
                  ],
                ),
              ),
            ),
            // Language-change icon in upper-right corner
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.language, color: appColorNotifier.value),
                  onPressed: () => _showLanguageDialog(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  onFBLogin() async {
    await FacebookAuth.instance.logOut();
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['email'],
      loginBehavior: LoginBehavior.webOnly,
    );

    switch (result.status) {
      case LoginStatus.success:
        final accessToken = result.accessToken;
        if (accessToken != null) {
          final token = accessToken.tokenString;
          final response = await http.get(
            Uri.parse("https://graph.facebook.com/v2.12/me?fields=name,picture,email&access_token=$token"),
          );
          final data1 = json.decode(response.body);
          setState(() {
            _isLogin = true;
            data = data1;
          });
        }
        break;
      case LoginStatus.cancelled:
      case LoginStatus.failed:
        setState(() {
          _isLogin = false;
        });
        break;
      case LoginStatus.operationInProgress:
        break;
    }
  }

  Future fbPaypass() {
    return Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => HomePage(setLocale: widget.setLocale, filterState: 0,)));
  }

  onEmailClick() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => EmailSignUpPage(setLocale: widget.setLocale,)));
  }

  Widget boxContainer(String path, String text, VoidCallback? onClick) {
    return kIsWeb
        ? SlideTransition(
      position: animation2,
      child: InkWell(
        onTap: onClick,
        child: Container(
          height: 50,
          width: 400,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
              child: Row(
                children: [
                  Image.asset(
                    path,
                    height: 30,
                    width: 30,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        : SlideTransition(
      position: animation2,
      child: InkWell(
        onTap: onClick,
        child: Container(
          height: 60,
          width: MediaQuery.of(context).size.width - 120,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Row(
                children: [
                  Image.asset(
                    path,
                    height: 35,
                    width: 35,
                  ),
                  const SizedBox(width: 20),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
