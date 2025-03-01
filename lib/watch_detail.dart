// watch_detail_page.dart
import 'package:flutter/material.dart';

class WatchDetailPage extends StatelessWidget {
  final Map<String, String> watch;

  const WatchDetailPage({super.key, required this.watch});

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
          ],
        ),
      ),
    );
  }
}