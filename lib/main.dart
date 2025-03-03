import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:watchhub/firebase.dart';
import 'package:watchhub/watch_detail.dart';
import 'package:watchhub/wishlist.dart';
import 'watch_data.dart'; // Import the watch data
import 'package:watchhub/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'purchase.dart'; // Import the new file
import 'package:watchhub/admin_screen.dart';
import 'package:watchhub/splashscreen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.platformOptions);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WatchHub',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1F2228),
        textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
      ),
      home: const SplashScreen(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? _user;
  String _username = 'Guest';
  String _role ='user';
  String _sortBy = 'default'; // Sorting criteria
  final TextEditingController _searchController = TextEditingController(); // Search controller
  String _searchQuery = ''; // Search query
  final FocusNode _searchFocusNode = FocusNode(); // Add this line
  List<String> _wishlistItems = [];
  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }
  void _handlePurchase(BuildContext context, List<Map<String, dynamic>> cartItems, double totalPrice) async {
    final purchaseHandler = PurchaseHandler(
      context,
      _scaffoldKey,
      cartItems: cartItems,
      totalPrice: totalPrice,
    );
    purchaseHandler.handlePurchase();
  }
  void dispose() {
    _searchFocusNode.dispose(); // Dispose the FocusNode
    super.dispose();
  }

  Future<String?> _showAddAddressDialog(BuildContext context) async {
    final TextEditingController _addressController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Address", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: "Enter your address",
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cancel
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (_addressController.text.isNotEmpty) {
                  Navigator.pop(context, _addressController.text); // Return new address
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter an address")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }


  Future<Map<String, dynamic>> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid);
          await _fetchWishlist();
      DataSnapshot snapshot = await userRef.get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    }
    return {};
  }

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
        setState(() {
          _wishlistItems = values.keys.cast<String>().toList();
        });
      } else {
        setState(() {
          _wishlistItems = [];
        });
      }
    }
  }
  void _toggleWishlist(Map<String, String> watch) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to add to wishlist")),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    DatabaseReference wishlistRef = FirebaseDatabase.instance.ref()
        .child('users')
        .child(user.uid)
        .child('wishlist')
        .child(watch['title']!);

    bool isInWishlist = _wishlistItems.contains(watch['title']!);

    if (isInWishlist) {
      await wishlistRef.remove();
      setState(() {
        _wishlistItems.remove(watch['title']!);
      });
    } else {
      await wishlistRef.set(watch);
      setState(() {
        _wishlistItems.add(watch['title']!);
      });
    }
  }
  void _showCart(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference cartRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('cart');

      DataSnapshot snapshot = await cartRef.get();
      if (snapshot.exists) {
        List<Map<String, dynamic>> cartItems = [];
        double totalPrice = 0;

        snapshot.children.forEach((element) {
          final item = Map<String, dynamic>.from(element.value as Map);
          item['key'] = element.key; // Add the Firebase key for removal

          // Clean the price string and parse it into a double
          String cleanedPrice = item['price'].replaceAll(RegExp(r'[^0-9.]'), '');
          item['price'] = double.parse(cleanedPrice);

          cartItems.add(item);
          totalPrice += (item['price'] * item['quantity']);
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: const Color(0xFF2D333A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    "Your Cart",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              final item = cartItems[index];
                              return Card(
                                color: const Color(0xFF1F2228),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      // Left Column: Image
                                      Image.asset(
                                        item['image'],
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(width: 12),

                                      // Right Column: Title, Price & Quantity
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // 1st Row: Title
                                            Text(
                                              item['title'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),

                                            // 2nd Row: Price & Quantity Buttons
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  "\$${item['price'].toStringAsFixed(2)}",
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.remove, color: Colors.white),
                                                      onPressed: () async {
                                                        if (item['quantity'] > 1) {
                                                          await cartRef.child(item['key']!).update({
                                                            'quantity': item['quantity'] - 1,
                                                          });
                                                          setState(() {
                                                            item['quantity']--;
                                                            totalPrice -= item['price'];
                                                          });
                                                        } else {
                                                          await cartRef.child(item['key']!).remove();
                                                          setState(() {
                                                            cartItems.removeAt(index);
                                                            totalPrice -= item['price'];
                                                          });
                                                        }
                                                      },
                                                    ),
                                                    Text(
                                                      "${item['quantity']}",
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.add, color: Colors.white),
                                                      onPressed: () async {
                                                        await cartRef.child(item['key']!).update({
                                                          'quantity': item['quantity'] + 1,
                                                        });
                                                        setState(() {
                                                          item['quantity']++;
                                                          totalPrice += item['price'];
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Total: \$${totalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F2228),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _handlePurchase(context, cartItems, totalPrice), // Call the purchase flow
                          child: const Text(
                            "Purchase",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F2228),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to the LoginScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LandingPage()),
                            );
                          }, // Call the purchase flow

                          child: const Text(
                            "Continue Shopping",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your cart is empty")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to view your cart")),
      );
    }
  }

  void _showUserProfileModal(BuildContext context) async {
    final TextEditingController _nameController = TextEditingController(text: _username);
    final Map<String, dynamic> userData = await _fetchUserData();
    bool isEditing = false; // Track whether the user is editing the profile

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2D333A),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "User Profile",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Display Username (editable only when isEditing is true)
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Name",
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    enabled: isEditing, // Enable editing only when isEditing is true
                  ),
                  const SizedBox(height: 20),

                  // Display Phone Number (if exists)
                  if (userData['phone'] != null)
                    ListTile(
                      leading: const Icon(Icons.phone, color: Colors.white),
                      title: Text(
                        "Phone: ${userData['phone']}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  if (userData['phone'] == null && isEditing)
                    ElevatedButton(
                      onPressed: () {
                        // Add functionality to add phone number
                        _showAddPhoneNumberDialogs(context);
                      },
                      child: const Text("Add Phone Number"),
                    ),

                  const SizedBox(height: 20),

                  // Display Addresses (if exists)
                  if (userData['addresses'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Addresses:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        ...(userData['addresses'] as Map).entries.map((entry) {
                          return ListTile(
                            leading: const Icon(Icons.location_on, color: Colors.white),
                            title: Text(
                              entry.value['address'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "Added on: ${DateTime.fromMillisecondsSinceEpoch(entry.value['timestamp']).toString()}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  if ((userData['addresses'] == null || userData['addresses'].isEmpty) && isEditing)
                    ElevatedButton(
                      onPressed: () {
                        _showAddAddressDialogs(context);
                      },
                      child: const Text("Add Address"),
                    ),

                  const SizedBox(height: 20),

                  // Edit Profile or Save Changes Button
                  if (!isEditing)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isEditing = true; // Enable editing mode
                        });
                      },
                      child: const Text("Edit Profile"),
                    ),
                  if (isEditing)
                    ElevatedButton(
                      onPressed: () async {
                        if (_nameController.text.isNotEmpty) {
                          await _updateUserName(_nameController.text);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Save Changes"),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddPhoneNumberDialogs(BuildContext context) {
    final TextEditingController _phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Phone Number", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _phoneController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Enter your phone number",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (_phoneController.text.isNotEmpty) {
                  await _updatePhoneNumber(_phoneController.text);
                  Navigator.pop(context); // Close the dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a phone number")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePhoneNumber(String phone) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid);

      await userRef.update({'phone': phone});
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        const SnackBar(content: Text("Phone number updated successfully")),
      );
    }
  }
  Future<void> _updateUserName(String newName) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid);

      await userRef.update({'username': newName});
      setState(() {
        _username = newName;
      });

      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        const SnackBar(content: Text("Username updated successfully")),
      );
    }
  }

  void _showAddAddressDialogs(BuildContext context) async {
    final TextEditingController _addressController = TextEditingController();
    int addressCount = await _getAddressCount();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Delivery Address ($addressCount/3)", style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: _addressController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Enter your delivery address",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (_addressController.text.isNotEmpty) {
                  if (addressCount < 3) {
                    await _saveAddressToFirebase(_addressController.text);
                    Navigator.pop(context); // Close the dialog
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You can only save up to 3 addresses")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter an address")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAddressToFirebase(String address) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('addresses');

      // Fetch the current number of addresses
      DataSnapshot snapshot = await userRef.get();
      if (snapshot.exists && snapshot.children.length >= 3) {
        ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
          const SnackBar(content: Text("You can only save up to 3 addresses")),
        );
        return;
      }

      // Push a new address to the database
      await userRef.push().set({
        'address': address,
        'timestamp': ServerValue.timestamp,
      });

      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        const SnackBar(content: Text("Address saved successfully")),
      );
    } else {
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        const SnackBar(content: Text("You must be logged in to save an address")),
      );
    }
  }

  Future<int> _getAddressCount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('addresses');

      DataSnapshot snapshot = await userRef.get();
      return snapshot.exists ? snapshot.children.length : 0;
    }
    return 0;
  }
  void _checkCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (user != null) {
      // Fetch username and role from SharedPreferences
      String? savedUsername = prefs.getString('username');
      String? savedRole = prefs.getString('role');

      if (savedUsername != null && savedRole != null) {
        // If username and role are already saved locally, use them
        setState(() {
          _user = user;
          _username = savedUsername;
          _role = savedRole;
        });
      } else {
        // Fetch user data from Firebase if not saved locally
        DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users').child(user.uid);
        DataSnapshot snapshot = await userRef.get();

        if (snapshot.exists) {
          // Fetch username and role from Firebase
          String username = snapshot.child('username').value.toString();
          String role = snapshot.child('role').value.toString();

          // Save username and role to local storage
          await prefs.setString('username', username);
          await prefs.setString('role', role);

          setState(() {
            _user = user;
            _username = username;
            _role = role;
          });
        } else {
          // If no user data in Firebase, use email or 'Guest' and default role
          String username = user.email ?? 'Guest';
          String role = 'user'; // Default role

          // Save username and role to local storage
          await prefs.setString('username', username);
          await prefs.setString('role', role);

          setState(() {
            _user = user;
            _username = username;
            _role = role;
          });
        }
      }

      // Fetch wishlist data after user is logged in
      await _fetchWishlist();
    } else {
      // If no user is logged in, clear the saved username and role
      await prefs.remove('username');
      await prefs.remove('role');
      setState(() {
        _user = null;
        _username = 'Guest';
        _role = 'user'; // Reset role to default
        _wishlistItems = [];
      });
    }
  }
  // Sorting function (now moved to WatchData)
  List<Map<String, String>> _sortWatches(List<Map<String, String>> watches) {
    return WatchData.sortWatches(watches, _sortBy);
  }

  // Filter watches based on search query (now moved to WatchData)
  List<Map<String, String>> _filterWatches(List<Map<String, String>> watches) {
    return WatchData.filterWatches(watches, _searchQuery);
  }

  void _showSortOptions(BuildContext context) {
    FocusScope.of(context).unfocus(); // Unfocus the TextField
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.black87.withOpacity(0.9),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Sort By",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.grey),
                _buildSortOption(context, "Price: Low to High", Icons.arrow_upward, 'priceLowToHigh'),
                _buildSortOption(context, "Price: High to Low", Icons.arrow_downward, 'priceHighToLow'),
                _buildSortOption(context, "Name: A to Z", Icons.sort_by_alpha, 'nameAtoZ'),
                _buildSortOption(context, "Name: Z to A", Icons.sort_by_alpha_outlined, 'nameZtoA'),
                _buildSortOption(context, "Brand: A to Z", Icons.storefront, 'brandAtoZ'),
                _buildSortOption(context, "Brand: Z to A", Icons.store, 'brandZtoA'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(BuildContext context, String title, IconData icon, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: () {
        setState(() {
          _sortBy = value; // Update sorting criteria
        });
        Navigator.pop(context);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      hoverColor: Colors.grey.withOpacity(0.2),
    );
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await FirebaseAuth.instance.signOut();
    setState(() {
      _user = null;
      _username = 'Guest';
      _wishlistItems = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildSidebar(),
      appBar:AppBar(
        backgroundColor: const Color(0xFF1F2228),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () => _showCart(context), // Open the cart
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: _user != null
                ? CircleAvatar(
              radius: 15,
              backgroundImage: AssetImage('assets/images/user.jpg'),
            )
                : const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              if (_user != null) {
                _showUserProfileModal(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 20),
          _buildHeader(),
          Expanded(child: _buildWatchGrid()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: const Color(0xFF2D333A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1F2228)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display user image if logged in, otherwise use default icon
                _user != null
                    ? CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/images/user.jpg'),
                )
                    : const Icon(Icons.account_circle, size: 50, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  _user != null ? "Hello, $_username!" : "Hello, Guest!",
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.white),
            title: const Text("Home", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.white),
            title: const Text("Home", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          // Add the Admin Page button conditionally
          if (_role == 'admin')
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.white),
              title: const Text("Admin Page", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminScreen()),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.white),
            title: const Text("Add Delivery Addresses", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              _showAddAddressDialog(context); // Open the address pop-up
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text("Settings", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.white),
            title: const Text("Wishlist", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              if (_user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please login to view your wishlist")),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WishlistScreen()),
                );
              }
            },
          ),
          _user != null
              ? ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text("Logout", style: TextStyle(color: Colors.white)),
            onTap: () {
              _logout();
              Navigator.pop(context);
            },
          )
              : ListTile(
            leading: const Icon(Icons.login, color: Colors.white),
            title: const Text("Sign In", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Navigate to the LoginScreen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode, // Assign the FocusNode
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search Brand Names Here',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: const Color(0xFF2D333A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value; // Update search query
          });
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Popular Watches',
            style: GoogleFonts.lato(
              textStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.grid_view, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: () {
                  _showSortOptions(context); // Show sorting options
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

// Modify _buildWatchCard in _LandingPageState
  Widget _buildWatchCard(Map<String, String> watch) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF2D333A),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 9),
                Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: SizedBox(
                    height: 80,
                    child: Image.asset(watch['image']!, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  watch['title']!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  watch['details']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                Row(
                  children: [
                    Text(
                      watch['price']!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFFECFB1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_checkout,
                          color: Colors.white,
                          size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WatchDetailPage(
                              watch: watch,
                              onAddToCart: () => _showCart(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF959BA2), width: 1.5),
              ),
              child: Text(
                watch['brand']!,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF959BA2),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                _wishlistItems.contains(watch['title']!)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: _wishlistItems.contains(watch['title']!)
                    ? Colors.red
                    : Colors.white,
              ),
              onPressed: () => _toggleWishlist(watch),
            ),
          ),
        ],
      ),
    );
  }

// Update _buildWatchGrid in _LandingPageState
  Widget _buildWatchGrid() {
    List<Map<String, String>> filteredWatches =
    WatchData.filterWatches(WatchData.watches, _searchQuery);
    List<Map<String, String>> sortedWatches =
    WatchData.sortWatches(filteredWatches, _sortBy);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 10),
        itemCount: sortedWatches.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.7,
        ),
        itemBuilder: (context, index) {
          return _buildWatchCard(sortedWatches[index]);
        },
      ),
    );
  }
}

