import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class DatabaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Uuid _uuid = const Uuid();

  String _generateUserTag() {
    const chars = 'ABCDEFGHIJKLMNPQRSTUVWXYZ123456789';
    final rnd = Random.secure();
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

  Future<void> updateDeviceId(String newDeviceId) async {
    await _secureStorage.write(key: 'device_id', value: newDeviceId);
  }

  // Now returns the UserTag if a new user was created, else returns null
  Future<String?> initializeUser() async {
    try {
      String deviceId = await getDeviceId();
      String sanitizedId = deviceId.replaceAll(RegExp(r'[.#$\[\]]'), '_');

      final userSnapshot = await _dbRef.child('User').child(sanitizedId).get();

      if (!userSnapshot.exists) {
        String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
        String userTag = '';
        bool isUnique = false;

        while (!isUnique) {
          userTag = _generateUserTag();
          final tagCheck = await _dbRef.child('User')
              .orderByChild('UserTag')
              .equalTo(userTag)
              .get();

          if (!tagCheck.exists) {
            isUnique = true;
          }
        }

        await _dbRef.child('User').child(sanitizedId).set({
          'ProfileImage': '',
          'UserName': 'Visitor user',
          'Email': 'visiter@gmail.com',
          'Age': 'Age',
          'Gender': 'Gender',
          'PhoneNumber': 'None',
          'UserTag': userTag,
          'Pin': '', // Initialized as empty
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
        return userTag;
      }
      return null;
    } catch (e) {
      debugPrint("Realtime DB Error: $e");
      return null;
    }
  }
}