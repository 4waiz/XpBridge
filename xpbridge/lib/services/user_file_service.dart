import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserFileService {
  static const String _fileName = 'users.txt';
  static const String _webStorageKey = 'users_data';

  // Test user that always works
  static const String _testEmail = 'test@test.com';
  static const String _testPassword = '123456';

  /// Get the file path for storing users (mobile/desktop only)
  static Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  /// Save a new user (email and password)
  static Future<bool> saveUser(String email, String password) async {
    try {
      // Check if user already exists
      if (await userExists(email)) {
        print('User already exists');
        return false;
      }

      final line = '$email,$password\n';

      if (kIsWeb) {
        // Web: use SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final existing = prefs.getString(_webStorageKey) ?? '';
        await prefs.setString(_webStorageKey, existing + line);
      } else {
        // Mobile/Desktop: use file
        final file = await _getFile();
        print('File path: ${file.path}');

        if (!await file.parent.exists()) {
          await file.parent.create(recursive: true);
        }

        await file.writeAsString(line, mode: FileMode.append);
      }

      print('User saved successfully');
      return true;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  /// Get all users data as string
  static Future<String> _getUsersData() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_webStorageKey) ?? '';
      } else {
        final file = await _getFile();
        if (!await file.exists()) {
          return '';
        }
        return await file.readAsString();
      }
    } catch (e) {
      return '';
    }
  }

  /// Check if a user with this email already exists
  static Future<bool> userExists(String email) async {
    // Test user always exists
    if (email.toLowerCase() == _testEmail) {
      return true;
    }

    try {
      final contents = await _getUsersData();
      print('Stored users data: "$contents"');
      print('Looking for email: $email');
      if (contents.isEmpty) return false;

      final lines = contents.split('\n');

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(',');
        if (parts.isNotEmpty && parts[0].toLowerCase() == email.toLowerCase()) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Validate user credentials (check if email and password match)
  static Future<bool> validateUser(String email, String password) async {
    // Test user always works
    if (email.toLowerCase() == _testEmail && password == _testPassword) {
      return true;
    }

    try {
      final contents = await _getUsersData();
      if (contents.isEmpty) return false;

      final lines = contents.split('\n');

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 2) {
          final storedEmail = parts[0].toLowerCase();
          final storedPassword = parts[1];

          if (storedEmail == email.toLowerCase() &&
              storedPassword == password) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
