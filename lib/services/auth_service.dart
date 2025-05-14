import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Get current authenticated user
  User? get currentUser => _auth.currentUser;
  
  // Get current user ID
  String? get userId => _auth.currentUser?.uid;
  
  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return result;
    } catch (e) {
      developer.log('Error in registerWithEmailAndPassword: $e', name: 'AuthService');
      rethrow;
    }
  }
  
  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return result;
    } catch (e) {
      developer.log('Error in signInWithEmailAndPassword: $e', name: 'AuthService');
      rethrow;
    }
  }
  
  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      developer.log('Error in signInWithGoogle: $e', name: 'AuthService');
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out of Google if signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Sign out of Firebase
      await _auth.signOut();
    } catch (e) {
      developer.log('Error in signOut: $e', name: 'AuthService');
      rethrow;
    }
  }
  
  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      developer.log('Error in sendPasswordResetEmail: $e', name: 'AuthService');
      rethrow;
    }
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }
  
  // Get user display name
  String? get userDisplayName => _auth.currentUser?.displayName;
  
  // Get user email
  String? get userEmail => _auth.currentUser?.email;
  
  // Get user photo URL
  String? get userPhotoURL => _auth.currentUser?.photoURL;
  
  // Update user profile
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      if (currentUser != null) {
        await currentUser!.updateDisplayName(displayName);
        await currentUser!.updatePhotoURL(photoURL);
      }
    } catch (e) {
      developer.log('Error in updateUserProfile: $e', name: 'AuthService');
      rethrow;
    }
  }
}