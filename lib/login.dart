import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:watchhub/main.dart'; // Main screen for users
import 'package:watchhub/admin_screen.dart'; // Admin screen for admins
import 'package:watchhub/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String?> _getUserRole(String uid) async {
    // Fetch the user's role from Firebase Realtime Database
    DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(uid);
    DataSnapshot snapshot = await userRef.child("role").get();
    return snapshot.value as String?;
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Fetch the user's role from Firebase Realtime Database
        String? role = await _getUserRole(userCredential.user!.uid);

        // Save the role in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', role ?? 'user'); // Default role is 'user' if not found

        // Always navigate to the LandingPage, regardless of the role
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LandingPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "This isn't a correct email";
      if (e.code == 'user-not-found') {
        errorMessage = "No user found with this email.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Incorrect password.";
      }

      // Show a popup with the error message
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Login Error", style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF1F2228),
            content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text("OK", style: TextStyle(color: Colors.orange)),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2228),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(

                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/images/logo1.webp',
                      width: 250,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Lottie.asset(
                    'assets/animations/login_animate.json',
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person, color: Colors.grey),
                      hintText: "Email",
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                      hintText: "Password",
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Login",
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?",
                          style: TextStyle(color: Colors.white)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (
                                context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                            "Register", style: TextStyle(color: Colors.orange)),
                      ),
                    ],
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