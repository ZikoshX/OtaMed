import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

var logger = Logger();

class AuthServices {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<UserCredential?> signinWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        logger.w("User cancelled Google Sign-In.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      logger.w("Signed in as: ${userCredential.user?.displayName}");
      return userCredential;
    } catch (error) {
      logger.w("Google Sign-In Error: $error");
      return null;
    }
  }
  Future<UserCredential?> signInWithApple() async {
    if (!Platform.isIOS) {
      logger.w("Sign in with Apple is only supported on iOS.");
      return null;
    }

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );

    final oAuthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    return await auth.signInWithCredential(oAuthCredential);
  }

  Future<UserCredential?> loginwithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      final googleAuth = await googleUser?.authentication;
      final cred = GoogleAuthProvider.credential(
        idToken: googleAuth?.accessToken,
        accessToken: googleAuth?.idToken,
      );
      return auth.signInWithCredential(cred);
    } catch (e) {
      logger.w(e.toString());
    }
    return null;
  }

  Future<String> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && name.isNotEmpty && password.isNotEmpty) {
        UserCredential credential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await firestore.collection("users").doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'uid': credential.user!.uid,
        });
        logger.i("User added to Firestore");
        res = "success";
      } else {
        res = "Please fill in all the fields.";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        res = "This email is already registered.";
      } else if (e.code == 'weak-password') {
        res =
            "The password is too weak. The password should be at least 6 charachers.";
      } else if (e.code == 'invalid-email') {
        res = "The email address is not valid.";
      } else {
        res = e.message ?? "An error occurred.";
      }
    } catch (e) {
      res = "An unknown error occurred.";
    }
    return res;
  }

  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isEmpty || password.isEmpty) {
        return "Please fill in all the fields.";
      }
      await auth.signInWithEmailAndPassword(email: email, password: password);
      res = "success";
    } on FirebaseAuthException catch (e) {
      logger.w("Firebase Auth Error Code: ${e.code}");
      if (e.code == 'invalid-credential') {
        res = "Incorrect email or password. Please try again.";
      } else if (e.code == 'invalid-email') {
        res = "The email address is not valid.";
      } else if (e.code == 'user-disabled') {
        res = "This account has been disabled.";
      } else {
        res = "An error occurred. Please try again.";
      }
    } catch (e) {
      logger.w("General Exception: $e");
      res = "Something went wrong. Please try again later.";
    }
    return res;
  }

  /*Future<String> signInwithGoogle() async {
    String res = 'Some error occured!';
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return "Sign-in process was canceled.";
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      res = 'success';
    } on FirebaseAuthException catch (e) {
      logger.w("Firebase Auth Error Code: ${e.code}");
      if (e.code == 'account-exists-with-different-credential') {
        res = "An account already exists with a different sign-in method.";
      } else if (e.code == 'invalid-credential') {
        res = "Invalid credentials. Please try again.";
      } else {
        res = "An error occurred. Please try again.";
      }
    } catch (e) {
      logger.w("General Exception: $e");
      res = "Something went wrong. Please try again later.";
    }
    return res;
  }*/
}
