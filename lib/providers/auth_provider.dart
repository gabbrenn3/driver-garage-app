import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserData(user.uid);
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? carModel,
    String? carPlate,
    String? garageName,
    String? ownerName,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final user = UserModel(
          id: credential.user!.uid,
          email: email,
          fullName: fullName,
          phone: phone,
          role: role,
          createdAt: DateTime.now(),
          carModel: carModel,
          carPlate: carPlate,
          garageName: garageName,
          ownerName: ownerName,
          latitude: latitude,
          longitude: longitude,
          address: address,
        );

        await _firestore.collection('users').doc(user.id).set(user.toMap());
        _currentUser = user;
        
        // Initialize notifications
        await NotificationService.initializeForUser(user.id);
        
        await _saveUserRole(role);
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _loadUserData(credential.user!.uid);
        await NotificationService.initializeForUser(credential.user!.uid);
        await _saveUserRole(_currentUser?.role ?? '');
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? carModel,
    String? carPlate,
    String? garageName,
    String? ownerName,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);
      
      final updatedUser = _currentUser!.copyWith(
        fullName: fullName,
        phone: phone,
        carModel: carModel,
        carPlate: carPlate,
        garageName: garageName,
        ownerName: ownerName,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );

      await _firestore.collection('users').doc(_currentUser!.id).update(updatedUser.toMap());
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update profile. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  Future<String?> getSavedUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}