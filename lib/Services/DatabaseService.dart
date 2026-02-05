import 'dart:io';
import 'package:firebase_database/firebase_database.dart'; //
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  // Use FirebaseDatabase instead of Firestore
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<String?> getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      var iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    }
    return null;
  }

  Future<void> initializeUser() async {
    try {
      String? rawDeviceId = await getDeviceId();
      if (rawDeviceId == null) return;

      // Sanitize the ID: Replace ALL invalid characters with underscores
      // This RegExp catches . # $ [ ] and /
      String deviceId = rawDeviceId.replaceAll(RegExp(r'[.#$\[\]]'), '_');

      final userSnapshot = await _dbRef.child('User').child(deviceId).get();

      if (!userSnapshot.exists) {
        // Get current date for the initial entry
        String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

        await _dbRef.child('User').child(deviceId).set({
          'ProfileImage': '',
          'UserName': 'Visitor user',
          'Email': 'visiter@gmail.com',
          'Age': '0',
          'Gender': '',
          'District': '',
          'TotalCompletedQuizCount': 0,
          'TotalWrongAnsweredQuizCount': 0,
          'TotalCorrectAnsweredQuizCount': 0,
          // Matching the double "Quiz progress" layer from your image
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
        print("Realtime DB: New visitor created with correct nested structure.");
      }
    } catch (e) {
      print("Realtime DB Error: $e");
    }
  }
}

//correct