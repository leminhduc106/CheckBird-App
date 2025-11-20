import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';

class Authentication {
  static User? user;
  static final GoogleSignIn _googleSignIn = _buildGoogleSignIn();

  static GoogleSignIn _buildGoogleSignIn() {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      return GoogleSignIn(
        clientId: DefaultFirebaseOptions.ios.iosClientId,
      );
    }

    return GoogleSignIn();
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
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
