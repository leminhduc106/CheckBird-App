import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';

class Authentication {
  static User? user;
  static final GoogleSignIn _googleSignIn = _buildGoogleSignIn();

  static GoogleSignIn _buildGoogleSignIn() {
    if (kIsWeb) {
      // For web, use signInWithPopup directly via Firebase Auth
      // GoogleSignIn package has limited web support
      return GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return GoogleSignIn(
        clientId: DefaultFirebaseOptions.ios.iosClientId,
      );
    }

    return GoogleSignIn();
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // For web, use Firebase Auth's signInWithPopup directly
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final UserCredential loggedInUser =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
        user = loggedInUser.user;

        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .set({'username': user!.displayName}, SetOptions(merge: true));
        }

        return loggedInUser;
      }

      // For mobile platforms, use google_sign_in package
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google Sign-In aborted by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final UserCredential loggedInUser =
          await FirebaseAuth.instance.signInWithCredential(credential);
      user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'username': user!.displayName}, SetOptions(merge: true));

      return loggedInUser;
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('Firebase Auth error: ${e.code} -> ${e.message}\n$stackTrace');
      return null;
    } catch (e, stackTrace) {
      debugPrint('Unexpected Google sign-in error: $e\n$stackTrace');
      return null;
    }
  }

  // Email/Password Authentication
  static Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = userCredential.user;

      // Check if email is verified
      if (user != null && !user!.emailVerified) {
        // Sign out immediately if email not verified
        await FirebaseAuth.instance.signOut();
        user = null;
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before signing in.',
        );
      }

      // Update user profile in Firestore
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .set({'email': user!.email}, SetOptions(merge: true));
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Email sign-in error: ${e.code} -> ${e.message}');
      rethrow; // Re-throw to handle in UI
    } catch (e) {
      debugPrint('Unexpected email sign-in error: $e');
      rethrow;
    }
  }

  static Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = userCredential.user;

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await user?.updateDisplayName(displayName);
        await user?.reload();
        user = FirebaseAuth.instance.currentUser;
      }

      // Send email verification
      await user?.sendEmailVerification();

      // Create user profile in Firestore
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .set({
          'email': user!.email,
          'username': displayName ?? user!.email?.split('@')[0],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Sign out the user immediately so they can't use the app until verified
      await FirebaseAuth.instance.signOut();
      user = null;

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Email sign-up error: ${e.code} -> ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected email sign-up error: $e');
      rethrow;
    }
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.code} -> ${e.message}');
      rethrow;
    }
  }

  static Future<void> sendEmailVerification() async {
    try {
      await user?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      debugPrint('Email verification error: ${e.code} -> ${e.message}');
      rethrow;
    }
  }

  static bool get isEmailVerified => user?.emailVerified ?? false;

  static Future<void> signOut() async {
    user = null;
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
  }

  static Future<void> deleteUserAccount() async {
    try {
      if (user != null) {
        await FirebaseAuth.instance.currentUser?.delete();
        // TODO: Remove firebase Database relate this user
        signOut();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "requires-recent-login") {
        await _reauthenticateAndDelete();
        signOut();
      }
    }
  }

  static Future<void> _reauthenticateAndDelete() async {
    try {
      final providerData =
          FirebaseAuth.instance.currentUser?.providerData.first;

      if (GoogleAuthProvider().providerId == providerData?.providerId) {
        await FirebaseAuth.instance.currentUser!
            .reauthenticateWithProvider(GoogleAuthProvider());
      }

      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      // Handle exceptions
    }
  }
}
