// watch_detail_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class WatchDetailPage extends StatelessWidget {
  final Map<String, String> watch;
  final VoidCallback onAddToCart; // Callback function

  const WatchDetailPage({
    super.key,
    required this.watch,
    required this.onAddToCart, // Add this parameter
  });

  Future<void> _addToCart(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference cartRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('cart');

      // Check if the watch is already in the cart
      DataSnapshot snapshot = await cartRef.child(watch['title']!).get();
      if (snapshot.exists) {
        // Update quantity if the watch is already in the cart
        int currentQuantity = snapshot.child('quantity').value as int;
        await cartRef.child(watch['title']!).update({
          'quantity': currentQuantity + 1,
        });
      } else {
        // Add the watch to the cart with quantity 1
        await cartRef.child(watch['title']!).set({
          'image': watch['image'],
          'brand': watch['brand'],
          'title': watch['title'],
          'price': watch['price'],
          'quantity': 1,
          'timestamp': ServerValue.timestamp,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added to cart successfully")),
      );

      // Trigger the callback after adding to cart
      onAddToCart();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to add to cart")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2228),
        title: Text(watch['title'] ?? 'Watch Details',
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                watch['image']!,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              watch['brand'] ?? '',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              watch['title'] ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              watch['price'] ?? '',
              style: const TextStyle(
                fontSize: 22,
                color: Color(0xFFFECFB1),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Display each line of details
            ...watch['details']!.split('\n').map((line) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  line,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            // Add to Cart Button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D333A), // Set the background color
                  foregroundColor: Colors.white, // Set the text color
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Add padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Add rounded corners
                  ),
                ),
                onPressed: () => _addToCart(context),
                child: const Text("Add to Cart"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}