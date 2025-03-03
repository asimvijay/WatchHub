import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:watchhub/login.dart'; // Import your login screen for logout navigation

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    try {
      DataSnapshot snapshot = await _dbRef.child("users").get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> usersMap = snapshot.value as Map;
        List<Map<String, dynamic>> users = [];

        // Loop through each user
        for (var entry in usersMap.entries) {
          String uid = entry.key;
          Map<String, dynamic> user = Map<String, dynamic>.from(entry.value);

          // Fetch addresses for the user
          DataSnapshot addressSnapshot = await _dbRef.child("users/$uid/addresses").get();
          if (addressSnapshot.exists) {
            Map<dynamic, dynamic> addressesMap = addressSnapshot.value as Map;
            List<Map<String, dynamic>> addresses = [];

            // Loop through each address
            addressesMap.forEach((key, addressData) {
              addresses.add(Map<String, dynamic>.from(addressData));
            });

            // Add addresses to the user data
            user["addresses"] = addresses;
          }

          users.add(user);
        }

        return users;
      } else {
        return [];
      }
    } catch (e) {
      throw Exception("Failed to fetch users: $e");
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F2228),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found."));
          } else {
            final users = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "User Management",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final addresses = user["addresses"] as List<Map<String, dynamic>>?;

                        return Card(
                          color: const Color(0xFF2D333A),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, color: Colors.white, size: 24),
                                    const SizedBox(width: 10),
                                    Text(
                                      user["username"] ?? "No Name",
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _buildUserInfoRow(Icons.email, user["email"] ?? "No Email"),
                                const SizedBox(height: 10),
                                _buildUserInfoRow(Icons.phone, user["phone"] ?? "No Phone"),
                                const SizedBox(height: 10),
                                if (addresses != null && addresses.isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Addresses:",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 5),
                                      ...addresses.map((address) {
                                        return Padding(
                                          padding: const EdgeInsets.only(left: 10, bottom: 5),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Address: ${address["address"] ?? "No Address"}",
                                                style: const TextStyle(fontSize: 14, color: Colors.white),
                                              ),
                                              Text(
                                                "Timestamp: ${address["timestamp"] ?? "No Timestamp"}",
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                const SizedBox(height: 10),
                                Text(
                                  "Role: ${user["role"] ?? "user"}",
                                  style: const TextStyle(fontSize: 16, color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildUserInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ],
    );
  }
}