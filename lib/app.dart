import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/history_page.dart';
import 'pages/profile_page.dart';
//import 'pages/scan_page.dart'; // Jika ada fitur scan
import 'package:firebase_auth/firebase_auth.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentIndex = 0;

  // List halaman sesuai dengan file yang Anda miliki di folder pages
  final List<Widget> _pages = [
    const HomePage(),
    const HistoryPage(),
    //const ScanPage(), // Tambahkan jika Anda memiliki scan_page.dart
    ProfilePage(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
    //detail
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed, // Agar icon tidak geser jika > 3
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          //BottomNavigationBarItem(
          // icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
