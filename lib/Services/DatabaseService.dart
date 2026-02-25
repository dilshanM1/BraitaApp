import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

class DatabaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Uuid _uuid = const Uuid();

  Future<String> getDeviceId() async {
    try {
      // 1. Try to read the ID
      String? deviceId = await _secureStorage.read(key: 'device_id');

      // 2. If it doesn't exist, create it
      if (deviceId == null) {
        deviceId = _uuid.v4();
        await _secureStorage.write(key: 'device_id', value: deviceId);
      }

      return deviceId;
    } catch (e) {
      // 3. FIX: Catch the 'BAD_DECRYPT' error from Play Store re-signing
      debugPrint("Secure Storage Error (Decrypt failed): $e");

      // Clear the corrupted storage
      await _secureStorage.deleteAll();

      // Generate a fresh ID so the app can continue to the Home Screen
      String newId = _uuid.v4();
      await _secureStorage.write(key: 'device_id', value: newId);
      return newId;
    }
  }

  Future<void> initializeUser() async {
    try {
      // This will now always return a string and never crash the app
      String deviceId = await getDeviceId();
      // Sanitize the ID for Firebase keys
      String sanitizedId = deviceId.replaceAll(RegExp(r'[.#$\[\]]'), '_');

      final userSnapshot = await _dbRef.child('User').child(sanitizedId).get();

      if (!userSnapshot.exists) {
        String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

        await _dbRef.child('User').child(sanitizedId).set({
          'ProfileImage': '',
          'UserName': 'Visitor user',
          'Email': 'visiter@gmail.com',
          'Age': 'Age',
          'Gender': 'Gender',
          'District': 'District',
          'TotalCompletedQuizCount': 0,
          'TotalWrongAnsweredQuizCount': 0,
          'TotalCorrectAnsweredQuizCount': 0,
          'MyPoints': 0,
          'QuizProgress': {
            'QuizProgress': {
              formattedDate: {
                'RemainingQuizCount': 20,
                'CorrectQuizCount': 0,
                'WrongQuizCount': 0,
                'Date': formattedDate,
              }
            }
          },
        });
        debugPrint("Realtime DB: New visitor created.");
      }
    } catch (e) {
      debugPrint("Realtime DB Error: $e");
    }
  }
}