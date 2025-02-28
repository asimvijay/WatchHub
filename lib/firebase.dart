import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get platformOptions {
    return const FirebaseOptions(
      apiKey: "AIzaSyB_ofhDa-pmUsVRY1WugXuJlibMluMbrNU",
      authDomain: "crop2x-native.firebaseapp.com",
      projectId: "crop2x-native",
      storageBucket: "crop2x-native.appspot.com",
      messagingSenderId: "370673218398",
      appId: "1:370673218398:web:c856287d96c64c1501d5cf",
      measurementId: "G-Z4ZXZSY0ZS", // Optional for analytics
    );
  }
}
