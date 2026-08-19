import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:security_app/core/network/token_provider.dart';
import 'package:security_app/core/storage/token_storage.dart';
import 'package:security_app/firebase_options.dart';
import 'package:security_app/l10n/app_localizations.dart';
import 'package:security_app/presentation/providers/viewModel_provider.dart';
import 'package:security_app/screens/login.dart';
import 'package:security_app/presentation/providers/locale_provider.dart';
import 'package:security_app/screens/mainScreen.dart';
// import 'package:security_app/screens/messages.dart';
// import 'package:security_app/generated/l10n.dart'; // Generated after running flutter packages get
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  debugPrint("📩 Handling background message: ${message.messageId}");
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  bool? _loggedIn; // null = loading

  @override
  void initState() {
    super.initState();
    _initPushNotifications();
    _checkLogin();
  }
 
  Future<void> _checkLogin() async {
    final token = await TokenStorage.getTokens();
    setState(() => _loggedIn = token != null);
  }

  Future<void> _initPushNotifications() async {
    final fcm = FirebaseMessaging.instance;
    // Ask for notification permissions (iOS + Android 13+)
    final settings = await fcm.requestPermission();
    debugPrint("🔔 Permission: ${settings.authorizationStatus}");
 
    // Get FCM token
     final _fcmToken = await fcm.getToken();
    debugPrint("📲 FCM Token: $_fcmToken");
 if (_fcmToken != null) {
    final staffId = ref.read(securitymodelProvider).loginDetails.value?.first.staffId;
    if (staffId != null) {
      ref.read(securitymodelProvider.notifier).updateToken(staffId, _fcmToken);
    }
  }
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("🔥 Foreground: ${message.notification?.title}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.notification?.body ?? "New message")),
        );
      }
    });
 
    // When tapping a notification (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("➡️ Notification tapped: ${message.notification?.title}");
      // Example: Navigate to Notifications tab
      // Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen()));
    });
  }


  @override
  Widget build(BuildContext context) {
    // Watch for locale changes
    final locale = ref.watch(localeProvider);
    
    // Global System UI Setup
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness:
          !kIsWeb && Platform.isAndroid ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    if (_loggedIn == null) {
      return MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
          Locale('mr'),
          Locale('bn'),
          Locale('ta'),
          Locale('te'),
          Locale('ur'),
        ],
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // return MaterialApp(
    //   navigatorKey: navigatorKey,
    //   title: 'Security App',
    //   locale: locale,
    //   localizationsDelegates: const [
    //     AppLocalizations.delegate,
    //     GlobalMaterialLocalizations.delegate,
    //     GlobalWidgetsLocalizations.delegate,
    //     GlobalCupertinoLocalizations.delegate,
    //   ],
    //   supportedLocales: const [
    //     Locale('en'),
    //     Locale('hi'),
    //     Locale('mr'),
    //     Locale('bn'),
    //     Locale('ta'),
    //     Locale('te'),
    //     Locale('ur'),
    //   ],
    //   debugShowCheckedModeBanner: false,
    //   home: const SplashScreen(),
    // );
    return MaterialApp(
  navigatorKey: navigatorKey,
  scaffoldMessengerKey: rootScaffoldMessengerKey,
  title: 'Security App',
  debugShowCheckedModeBanner: false,
  locale: locale,

  builder: (context, child) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: child ?? const SizedBox.shrink(),
    );
  },

  home: const SplashScreen(),
);

  }
}

// SplashScreen
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    // Load saved tokens for auto-login
    await ref.read(tokenProvider.notifier).loadTokens();

    // Wait a bit for splash effect
    await Future.delayed(const Duration(seconds: 2));

    // Navigate based on token state
    final tokenState = ref.read(tokenProvider);
    if (!mounted) return;

    if (tokenState.isLoggedIn) {
      // MainTabScreen re-fetches user data into securitymodelProvider itself
      // on entry (its state is in-memory only and is wiped when the process
      // is killed from recents) — no need to block navigation on it here.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) =>MainTabScreen ()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MobileNumberScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get localized app title if needed
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (l10n != null) ...[
              const SizedBox(height: 20),
              Text(
                l10n.appTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}