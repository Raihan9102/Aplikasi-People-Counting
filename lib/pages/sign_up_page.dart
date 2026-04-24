import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<void> _signUp() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Lengkapi data & Password minimal 6 karakter")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Buat User di Firebase Auth
      UserCredential cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Simpan Data ke Realtime Database
      // Pastikan aturan (Rules) di Firebase Console sudah: { ".read": "true", ".write": "true" }
      await _dbRef.child('users').child(cred.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'user',
        'created_at': ServerValue.timestamp,
      });

      // 3. LOGOUT PAKSA (Kunci Utama)
      // Firebase otomatis login setelah createUser. Kita harus logout agar
      // AuthWrapper kembali ke LoginPage dan user bisa login secara manual.
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pendaftaran Berhasil! Silakan Login ulang."),
            backgroundColor: Colors.green,
          ),
        );

        // 4. Navigasi bersih ke Halaman Login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Terjadi kesalahan";
      if (e.code == 'email-already-in-use') {
        errorMsg = "Email ini sudah terdaftar.";
      }
      if (e.code == 'invalid-email') errorMsg = "Format email tidak valid.";
      if (e.code == 'weak-password') errorMsg = "Password terlalu lemah.";

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisikan warna biru dari gambar kanan
    const Color primaryBlue = Color(0xFF2962FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        // Hapus title untuk AppBar yang lebih bersih, seperti contoh kanan
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon - Warna Biru Penuh (seperti contoh kanan)
                Container(
                  height: 100, // Sedikit lebih besar
                  width: 100,
                  decoration: const BoxDecoration(
                      color: primaryBlue, shape: BoxShape.circle),
                  child: const Icon(Icons.visibility,
                      size: 60, color: Colors.white),
                ),
                const SizedBox(height: 30),

                // Teks "Sign Up" - Besar dan Hitam
                const Text("Sign Up",
                    style: TextStyle(
                        fontSize: 36, // Lebih besar
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                const SizedBox(height: 10),

                // Subtitle - Warna Abu-abu (seperti contoh kanan)
                const Text("Real-Time People Detection and Monitoring",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF757575))), // Warna abu-abu
                const SizedBox(height: 50),

                // Input Fields (Text Styles diperbarui agar lebih gelap)
                _buildField(
                    controller: _nameController,
                    label: "Full Name", // Bahasa Inggris seperti contoh kanan
                    hint: "John Doe", // Hint seperti contoh kanan
                    icon: Icons.person_outline,
                    primaryColor: primaryBlue),
                const SizedBox(height: 20),
                _buildField(
                    controller: _emailController,
                    label: "Email",
                    hint: "john@example.com", // Hint seperti contoh kanan
                    icon: Icons.email_outlined,
                    primaryColor: primaryBlue),
                const SizedBox(height: 20),
                _buildField(
                    controller: _passwordController,
                    label: "Password",
                    hint: "••••••••", // Hint seperti contoh kanan
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isVisible: _isPasswordVisible,
                    primaryColor: primaryBlue,
                    onToggle: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible)),
                const SizedBox(height: 50),

                // Tombol "Sign Up" - Warna Biru (seperti contoh kanan)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(
                          vertical: 18), // Sedikit lebih tinggi
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0, // Lebih flat seperti contoh kanan
                    ),
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text(
                            "Sign Up", // Bahasa Inggris seperti contoh kanan
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)), // Lebih besar
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color primaryColor, // Tambahkan parameter warna utama
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label lebih gelap dan tebal
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !isVisible,
          style: const TextStyle(
              fontSize: 16, color: Colors.black), // Teks input lebih gelap
          decoration: InputDecoration(
            // Prefix Icon berwarna biru
            prefixIcon: Icon(icon, color: primaryColor, size: 24),
            suffixIcon: isPassword
                ? IconButton(
                    // Suffix Icon berwarna abu-abu, berubah biru saat visible
                    icon: Icon(
                      isVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 22,
                      color: isVisible ? primaryColor : Colors.grey[600],
                    ),
                    onPressed: onToggle,
                  )
                : null,
            hintText: hint,
            // Hint text abu-abu muda
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            // Background field putih, seperti contoh kanan
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            // Border tipis abu-abu, seperti contoh kanan
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              // Border biru saat fokus
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
