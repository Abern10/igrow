import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();
  
  User? _authUser;
  AppUser? _appUser;
  bool _isLoading = false;
  
  User? get authUser => _authUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  
  UserProvider() {
    _initializeUser();
    // Listen for authentication state changes
    _authService.authStateChanges.listen((user) {
      _authUser = user;
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _appUser = null;
        notifyListeners();
      }
    });
  }
  
  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();
    _authUser = _authService.currentUser;
    if (_authUser != null) {
      await _loadUserData(_authUser!.uid);
    }
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> _loadUserData(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _appUser = await _firebaseService.getUserData(userId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _authService.signInWithEmailAndPassword(email, password);
      
      // After successful authentication, load user data
      if (_authUser != null) {
        await _loadUserData(_authUser!.uid);
      }
      
      return true;
    } catch (e) {
      print('Error signing in: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> registerWithEmailPassword(String email, String password, String firstName, String lastName) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Create auth user
      UserCredential credential = await _authService.registerWithEmailAndPassword(email, password);
      
      // Create user document with the entered first and last name
      final user = AppUser(
        uid: credential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        coins: 100, // Default starting coins
      );
      
      await _firebaseService.saveUserData(user);
      
      // After saving, refresh the user data from Firestore.
      if (credential.user != null) {
        await _loadUserData(credential.user!.uid);
      }
      
      return true;
    } catch (e) {
      print('Error registering: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final credential = await _authService.signInWithGoogle();
      
      if (credential == null || credential.user == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final existingUser = await _firebaseService.getUserData(credential.user!.uid);
      
      if (existingUser == null) {
        // Create a new user document for Google sign-in users
        String displayName = credential.user!.displayName ?? '';
        String firstName = '';
        String lastName = '';
        
        // Try to split display name into first and last name
        if (displayName.contains(' ')) {
          List<String> names = displayName.split(' ');
          firstName = names.first;
          lastName = names.last;
        } else {
          firstName = displayName;
        }
        
        final newUser = AppUser(
          uid: credential.user!.uid,
          email: credential.user!.email ?? '',
          firstName: firstName,
          lastName: lastName,
          photoURL: credential.user!.photoURL,
          coins: 100, // Default starting coins
        );
        
        await _firebaseService.saveUserData(newUser);
      } else {
        await _firebaseService.updateLastLogin(credential.user!.uid);
      }
      
      // Load the user data
      await _loadUserData(credential.user!.uid);
      
      return true;
    } catch (e) {
      print('Error signing in with Google: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authService.signOut();
      _appUser = null;
    } catch (e) {
      print('Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateCoins(int newCoins) async {
    try {
      if (_appUser != null) {
        await _firebaseService.updateUserCoins(_appUser!.uid, newCoins);
        _appUser = _appUser!.copyWith(coins: newCoins);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating coins: $e');
    }
  }

  Future<void> refreshUserData() async {
    if (_authUser == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _appUser = await _firebaseService.getUserData(_authUser!.uid);
      print('DEBUG: Refreshed user data: firstName=${_appUser?.firstName}, lastName=${_appUser?.lastName}');
    } catch (e) {
      print('Error refreshing user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}