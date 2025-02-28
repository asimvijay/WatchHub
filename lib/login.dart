import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:watchhub/register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF1F2228),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                color: Colors.black, // Black background for the logo
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  'assets/images/logo1.webp', // Replace with your logo path
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
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person, color: Colors.grey),
                  hintText: "Email",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                  hintText: "Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final email = _emailController.text;
                    final password = _passwordController.text;
                    print("Email: $email, Password: $password");
                  },
                  child: const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?", style: TextStyle(color: Colors.white)),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to the LoginScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text("Register", style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.facebook, color: Colors.green), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.message, color: Colors.green), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.linked_camera, color: Colors.green), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.search, color: Colors.green), onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
