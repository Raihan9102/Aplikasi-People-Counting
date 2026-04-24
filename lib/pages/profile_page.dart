import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/app_user.dart';
import '../services/firebase_people_counter_service.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Logika cadangan nama user
  String _processDisplayName(String rawEmail) {
    if (rawEmail.isEmpty) return 'User';
    String localPart = rawEmail.split('@')[0];
    String cleaned = localPart.replaceAll(RegExp(r'[^a-zA-Z]'), ' ').trim();
    String firstWord = cleaned.split(' ')[0];
    return firstWord.isNotEmpty
        ? firstWord[0].toUpperCase() + firstWord.substring(1).toLowerCase()
        : 'User';
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF1F3F6);
    const Color primaryBlue = Color(0xFF2196F3);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Builder(
          builder: (context) => Text(
            'profile_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- LABEL ATAS (Berubah sesuai bahasa) ---
                    Builder(
                      builder: (context) => Text(
                        'settings_title'
                            .tr(), // Menggunakan key settings_title agar seragam
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- SECTION 1: USER INFO CARD ---
                    StreamBuilder<AppUser>(
                      stream: FirebasePeopleCounterService.userStream(
                          widget.userId),
                      builder: (context, snapshot) {
                        final authUser = FirebaseAuth.instance.currentUser;
                        final user = snapshot.data;

                        final String rawEmail = (user != null &&
                                user.email.isNotEmpty &&
                                user.email != '-')
                            ? user.email
                            : (authUser?.email ?? '');

                        final String displayName = (user != null &&
                                user.name.isNotEmpty &&
                                user.name != '-')
                            ? user.name
                            : _processDisplayName(rawEmail);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: const BoxDecoration(
                                  color: primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_outline,
                                    color: Colors.white, size: 40),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      rawEmail,
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.blueGrey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // --- JUDUL BAWAH (Berubah sesuai bahasa) ---
                    Builder(
                      builder: (context) => Text(
                        "settings_title".tr(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- SECTION 2: LANGUAGE SETTINGS CARD ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.language,
                                  color: primaryBlue),
                            ),
                            title: Builder(
                              builder: (context) => Text(
                                "language_option".tr(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black),
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.grey),
                          ),
                          const Divider(height: 1),
                          _buildLanguageOption(
                            context,
                            title: "English",
                            value: 'en_US',
                            groupValue: context.locale.toString(),
                            onChanged: () async {
                              await context.setLocale(const Locale('en', 'US'));
                              if (mounted) {
                                setState(() {}); // Trigger refresh UI
                              }
                            },
                            primaryColor: primaryBlue,
                          ),
                          const Divider(height: 1, indent: 20),
                          _buildLanguageOption(
                            context,
                            title: "Bahasa Indonesia",
                            value: 'id_ID',
                            groupValue: context.locale.toString(),
                            onChanged: () async {
                              await context.setLocale(const Locale('id', 'ID'));
                              if (mounted) {
                                setState(() {}); // Trigger refresh UI
                              }
                            },
                            primaryColor: primaryBlue,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- SECTION 3: LOGOUT BUTTON ---
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        side: const BorderSide(
                            color: Colors.redAccent, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      icon: const Icon(Icons.logout_outlined),
                      label: Builder(
                        builder: (context) => Text(
                          "logout_button".tr(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),

                    const Spacer(),
                    const SizedBox(height: 48),
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            "Detectra v1.0.0",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Real-Time People Detection and Monitoring",
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 12, color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String title,
    required String value,
    required String groupValue,
    required VoidCallback onChanged,
    required Color primaryColor,
  }) {
    final isSelected = (value == groupValue);

    return InkWell(
      onTap: onChanged,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[200]!,
              width: isSelected ? 2 : 1),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            title,
            style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.black87),
          ),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: primaryColor)
              : Icon(Icons.circle_outlined, color: Colors.grey[300]),
        ),
      ),
    );
  }
}
