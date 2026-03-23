import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'dart:math'; // Required for random character generation

class DatabaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Uuid _uuid = const Uuid();

  // Helper function to generate a unique 8-character ID
  String _generateUserTag() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<String> getDeviceId() async {
    try {
      String? deviceId = await _secureStorage.read(key: 'device_id');
      if (deviceId == null) {
        deviceId = _uuid.v4();
        await _secureStorage.write(key: 'device_id', value: deviceId);
      }
      return deviceId;
    } catch (e) {
      debugPrint("Secure Storage Error: $e");
      await _secureStorage.deleteAll();
      String newId = _uuid.v4();
      await _secureStorage.write(key: 'device_id', value: newId);
      return newId;
    }
  }

  Future<void> initializeUser() async {
    try {
      String deviceId = await getDeviceId();
      String sanitizedId = deviceId.replaceAll(RegExp(r'[.#$\[\]]'), '_');

      final userSnapshot = await _dbRef.child('User').child(sanitizedId).get();

      if (!userSnapshot.exists) {
        String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

        // Generate the new unique 8-character ID
        String userTag = _generateUserTag();

        await _dbRef.child('User').child(sanitizedId).set({
          'ProfileImage': '',
          'UserName': 'Visitor user',
          'Email': 'visiter@gmail.com',
          'Age': 'Age',
          'Gender': 'Gender',
          'PhoneNumber': 'None',
          'UserTag': userTag,
          'TotalCompletedQuizCount': 0,
          'TotalWrongAnsweredQuizCount': 0,
          'TotalCorrectAnsweredQuizCount': 0,
          'MyPoints': 0,
          'CompetitionPoints': 0,
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
        debugPrint("Realtime DB: New visitor created with Tag: $userTag");
      }
    } catch (e) {
      debugPrint("Realtime DB Error: $e");
    }
  }
}