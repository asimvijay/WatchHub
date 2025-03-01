// purchase.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PurchaseHandler {
  final BuildContext context;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Map<String, dynamic>> cartItems;
  final double totalPrice;

  PurchaseHandler(
      this.context,
      this.scaffoldKey, {
        required this.cartItems,
        required this.totalPrice,
      });

  // Static coupon codes with their discounts
  static final Map<String, double> _validCoupons = {
    'WATCH10': 0.10,
    'HUB20': 0.20,
    'TIMESALE': 0.15,
  };

  // Current applied coupon
  String? _appliedCoupon;
  double _discount = 0.0;

  /// Displays a dialog for payment method selection.
  Future<void> _showPaymentMethodSelection() async {
    String? selectedMethod = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: const Text(
          "Select Payment Method",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaymentMethodTile("Credit/Debit Card", Icons.credit_card),
            _buildPaymentMethodTile("PayPal", Icons.account_balance_wallet),
            _buildPaymentMethodTile("Apple Pay", Icons.phone_iphone),
          ],
        ),
      ),
    );

    if (selectedMethod == "Credit/Debit Card") {
      await _showCardPaymentForm();
    } else {
      // For other methods, provide immediate feedback.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selected payment method: $selectedMethod"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Helper widget to build each payment method option.
  ListTile _buildPaymentMethodTile(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () => Navigator.pop(context, title),
    );
  }

  /// Shows the card payment form with fields for card details and an optional coupon code.
  Future<void> _showCardPaymentForm() async {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final TextEditingController _cardController = TextEditingController();
    final TextEditingController _expiryController = TextEditingController();
    final TextEditingController _cvcController = TextEditingController();
    final TextEditingController _couponController = TextEditingController();

    bool showCouponField = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text(
            "Card Details",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: _cardController,
                    label: "Card Number",
                    hint: "4242 4242 4242 4242",
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                    value!.replaceAll(" ", "").length != 16
                        ? "Invalid card number"
                        : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _expiryController,
                          label: "MM/YY",
                          hint: "12/25",
                          validator: (value) =>
                          value!.length != 5 ? "Invalid expiry" : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: _cvcController,
                          label: "CVC",
                          hint: "123",
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                          value!.length != 3 ? "Invalid CVC" : null,
                        ),
                      ),
                    ],
                  ),
                  if (showCouponField)
                    _buildTextField(
                      controller: _couponController,
                      label: "Coupon Code",
                    ),
                  TextButton(
                    onPressed: () =>
                        setState(() => showCouponField = !showCouponField),
                    child: Text(
                      showCouponField ? "Hide Coupon" : "Apply Coupon",
                      style: const TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
              const Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (showCouponField &&
                      _couponController.text.isNotEmpty &&
                      !_validateCoupon(
                          _couponController.text.trim().toUpperCase())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid coupon code")),
                    );
                    return;
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a styled text field widget.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: validator,
      ),
    );
  }

  /// Validates the provided coupon code.
  bool _validateCoupon(String code) {
    code = code.trim().toUpperCase();
    if (_validCoupons.containsKey(code)) {
      _appliedCoupon = code;
      _discount = _validCoupons[code]!;
      return true;
    }
    return false;
  }

  /// Shows the address selection or addition dialog.
  Future<String?> _selectOrAddAddress() async {
    final addresses = await _fetchUserAddresses();
    if (addresses.isEmpty) {
      return await _showAddAddressDialog();
    }

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: const Text(
          "Select Address",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...addresses.map(
                    (address) => ListTile(
                  title: Text(address,
                      style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context, address),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final newAddress = await _showAddAddressDialog();
                  if (newAddress != null) Navigator.pop(context, newAddress);
                },
                child: const Text(
                  "Add New Address",
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Displays a phone number input dialog.
  Future<String?> _showPhoneNumberInput() async {
    final TextEditingController _phoneController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: const Text(
          "Receiver Phone Number",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter phone number for delivery updates",
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              if (_phoneController.text.isNotEmpty) {
                Navigator.pop(context, _phoneController.text.trim());
              }
            },
            child: const Text("Confirm",
                style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  /// Retrieves the list of saved addresses from the database.
  Future<List<String>> _fetchUserAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(user.uid)
        .child('addresses')
        .get();

    return snapshot.children.map((child) {
      return child.child('address').value.toString();
    }).toList();
  }

  /// Displays a dialog to add a new address.
  Future<String?> _showAddAddressDialog() async {
    final TextEditingController _controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: const Text(
          "Add Address",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter full delivery address",
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              if (_controller.text.isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseDatabase.instance
                      .ref()
                      .child('users')
                      .child(user.uid)
                      .child('addresses')
                      .push()
                      .set({
                    'address': _controller.text.trim(),
                    'timestamp': ServerValue.timestamp,
                  });
                  Navigator.pop(context, _controller.text.trim());
                }
              }
            },
            child: const Text("Save",
                style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  /// Shows the address and phone input dialogs,
  /// saves the order concurrently while displaying a loader for 5 seconds,
  /// then shows a success animation.
  Future<void> _showAddressAndPhoneInput() async {
    String? address = await _selectOrAddAddress();
    if (address == null) return;

    String? phone = await _showPhoneNumberInput();
    if (phone == null) return;

    // Start saving the order concurrently.
    final orderSaveFuture = _saveOrderToDatabase(address, phone);
    // Display loader for a fixed 5 seconds.
    await _showVerificationLoader();
    // Wait for the order to be saved if not already completed.
    await orderSaveFuture;
    await _showSuccessAnimation();
  }
  Future<void> _showVerificationLoader() async {
    // Show the dialog without awaiting its completion.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        backgroundColor: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/animations/loader_animate.json', height: 100),
              const SizedBox(height: 20),
              const Text(
                "Verifying Payment...",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    // Wait for exactly 5 seconds.
    await Future.delayed(const Duration(seconds: 5));
    // Dismiss the loader.
    Navigator.pop(context);
  }


  /// Displays a success animation after payment verification.
  Future<void> _showSuccessAnimation() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/animations/success.json', height: 150),
            const SizedBox(height: 10),
            const Text(
              "Payment Successful!",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Your order will arrive within 3 days\nOrder Total: \$${(totalPrice * (1 - _discount)).toStringAsFixed(2)}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK",
                style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  /// Saves the order data to the database and clears the cart.
  Future<void> _saveOrderToDatabase(String address, String phone) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final orderRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(user.uid)
        .child('orders')
        .push();

    await orderRef.set({
      'timestamp': ServerValue.timestamp,
      'items': cartItems
          .map((item) => {
        'title': item['title'],
        'price': item['price'],
        'quantity': item['quantity'],
      })
          .toList(),
      'total': totalPrice * (1 - _discount),
      'address': address,
      'phone': phone,
      'status': 'processing',
      'couponUsed': _appliedCoupon,
      'discount': _discount,
    });

    // Clear cart after purchase.
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(user.uid)
        .child('cart')
        .remove();
  }

  /// Entry point to handle the purchase flow.
  void handlePurchase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to complete purchase")),
      );
      return;
    }

    await _showPaymentMethodSelection();
    await _showAddressAndPhoneInput();
  }
}
