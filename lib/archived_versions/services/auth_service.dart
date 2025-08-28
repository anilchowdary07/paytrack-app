import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:payment_reminder_app/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '985067771215-5v39nuqc1biotlosfoi4pv0jeh2rjrnl.apps.googleusercontent.com'
        : null,
  );

  // Create a user object from Firebase user
  AppUser? _userFromFirebaseUser(User? user) {
    return user != null ? AppUser.fromFirebaseUser(user) : null;
  }

  // Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null; // The user canceled the sign-in
    }
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );
    return _userFromFirebaseUser(userCredential.user);
  }

  // Sign in with email & password
  Future<AppUser?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _userFromFirebaseUser(result.user);
  }

  // Register with email & password
  Future<AppUser?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _userFromFirebaseUser(result.user);
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('AuthService: Starting logout process...');

      // Check if user is currently signed in
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('AuthService: No user currently signed in');
        return;
      }

      print(
        'AuthService: User ${currentUser.email} is signed in, proceeding with logout',
      );

      // Sign out from Firebase Auth
      await _auth.signOut();
      print('AuthService: Firebase Auth sign out completed');

      // Sign out from Google Sign In
      await _googleSignIn.signOut();
      print('AuthService: Google Sign In sign out completed');

      print('AuthService: Logout process completed successfully');
    } catch (e) {
      print('AuthService: Error during logout: $e');
      // Re-throw the error so it can be handled by the UI
      rethrow;
    }
  }

  // Auth state changes
  Stream<AppUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }
}
