import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Map<String, dynamic>> _wishlistItems = [];

  Future<void> _fetchWishlist() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference wishlistRef = FirebaseDatabase.instance.ref()
          .child('users')
          .child(user.uid)
          .child('wishlist');

      DataSnapshot snapshot = await wishlistRef.get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> values = snapshot.value as Map;
        List<Map<String, dynamic>> items = [];
        values.forEach((key, value) {
          items.add(Map<String, dynamic>.from(value));
        });
        setState(() {
          _wishlistItems = items;
        });
      } else {
        setState(() {
          _wishlistItems = [];
        });
      }
    }
  }

  Future<void> _removeFromWishlist(String title) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference wishlistRef = FirebaseDatabase.instance.ref()
          .child('users')
          .child(user.uid)
          .child('wishlist')
          .child(title);

      await wishlistRef.remove();
      await _fetchWishlist();
    }
  }

  Future<void> _addToCart(Map<String, dynamic> item) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference cartRef = FirebaseDatabase.instance.ref()
          .child('users')
          .child(user.uid)
          .child('cart');

      // Check if the item already exists in the cart
      DataSnapshot snapshot = await cartRef.child(item['title']!).get();
      if (snapshot.exists) {
        // Update quantity if the item already exists
        int currentQuantity = snapshot.child('quantity').value as int;
        await cartRef.child(item['title']!).update({
          'quantity': currentQuantity + 1,
        });
      } else {
        // Add new item to the cart
        await cartRef.child(item['title']!).set({
          'title': item['title'],
          'image': item['image'],
          'price': item['price'],
          'quantity': 1, // Default quantity
        });
      }

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${item['title']} added to cart!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to add items to the cart")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wishlist", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F2228),
        actions: [

        ],
      ),
      body: _wishlistItems.isEmpty
          ? const Center(
        child: Text(
          "Your wishlist is empty",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _wishlistItems.length,
        itemBuilder: (context, index) {
          final item = _wishlistItems[index];
          return Card(
            color: const Color(0xFF2D333A),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  item['image']!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                item['title']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                item['price']!,
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () => _addToCart(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeFromWishlist(item['title']!),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

