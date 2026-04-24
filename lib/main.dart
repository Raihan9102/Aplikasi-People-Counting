import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'app.dart';
import 'pages/detail_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

// Tambahkan baris ini untuk inisialisasi Google Sign-In di Web jika meta tag tidak terbaca
  if (DefaultFirebaseOptions.currentPlatform.apiKey.isNotEmpty) {
    // Opsional: Anda bisa melakukan konfigurasi tambahan di sini jika diperlukan
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('id', 'ID')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // AuthWrapper akan otomatis mengatur mau ke mana
      home: const AuthWrapper(),
      routes: {
        DetailPage.routeName: (context) => const DetailPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Gunakan StreamBuilder untuk memantau perubahan Auth
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Jika sedang loading, tampilkan indikator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // Jika user terdeteksi login
        if (snapshot.hasData && snapshot.data != null) {
          return const App();
        }

        // Jika tidak ada user
        return const LoginPage();
      },
    );
  }
}
