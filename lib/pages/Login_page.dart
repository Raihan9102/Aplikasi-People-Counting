import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_up_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final Color _primaryBlue = const Color(0xFF2962FF);

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan password tidak boleh kosong")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Proses Sign In ke Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // UPDATE: Memaksa navigasi ke root ('/') agar AuthWrapper di main.dart
      // merender ulang dan langsung mengarahkan ke Dashboard (App)
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login Gagal";
      if (e.code == 'user-not-found') errorMessage = "User tidak ditemukan";
      if (e.code == 'wrong-password') errorMessage = "Password salah";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Di dalam LoginPage.dart, update bagian pemanggilan GoogleSignIn
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // Masukkan Client ID yang Anda dapatkan dari Google Cloud Console ke sini
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            '349447263053-v3nj1ju6puseoscd4ev5l7tembunphnb.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      print("Error Google Sign-In: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In Gagal: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                      color: _primaryBlue, shape: BoxShape.circle),
                  child: const Icon(Icons.visibility,
                      size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text("Detector",
                    style:
                        TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const Text("Real-Time People Detection and Monitoring",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),

                // Field Email
                _buildField(
                    controller: _emailController,
                    label: "Email",
                    hint: "example@mail.com",
                    icon: Icons.email_outlined),
                const SizedBox(height: 20),

                // Field Password
                _buildField(
                  controller: _passwordController,
                  label: "Password",
                  hint: "••••••••",
                  icon: Icons.lock_outline,
                  isPassword: true,
                  isVisible: _isPasswordVisible,
                  onToggle: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                const SizedBox(height: 30),

                // Tombol Login
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Login",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Or sign in with"),
                const SizedBox(height: 20),

                // tombol google
                // Di dalam method build, cari bagian OutlinedButton.icon
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading
                      ? null
                      : _signInWithGoogle, // Panggil fungsi di atas
                  icon: const Icon(Icons.g_mobiledata,
                      size: 30, color: Colors.black),
                  label: const Text("Google",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 30),
                // Navigasi ke Daftar Akun
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignUpPage())),
                  child: RichText(
                    text: TextSpan(
                        text: "Don't have an account?",
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                              text: "Sign Up",
                              style: TextStyle(
                                  color: _primaryBlue,
                                  fontWeight: FontWeight.bold))
                        ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      {required TextEditingController controller,
      required String label,
      required String hint,
      required IconData icon,
      bool isPassword = false,
      bool isVisible = false,
      VoidCallback? onToggle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !isVisible,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                        isVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: onToggle)
                : null,
            hintText: hint,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryBlue, width: 2)),
          ),
        ),
      ],
    );
  }
}
