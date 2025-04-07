import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign up method with email and password
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print("Password is too weak.");
      } else if (e.code == 'email-already-in-use') {
        print("Email is already registered.");
      } else if (e.code == 'invalid-email') {
        print("Invalid email format.");
      } else {
        print("Sign-up failed: ${e.message}");
      }
    } catch (e) {
      print("Unexpected error: $e");
    }
    return null;
  }

  // Sign in method with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print("No user found for this email.");
      } else if (e.code == 'wrong-password') {
        print("Incorrect password.");
      } else if (e.code == 'invalid-email') {
        print("Invalid email format.");
      } else {
        print("Sign-in failed: ${e.message}");
      }
    } catch (e) {
      print("Unexpected error: $e");
    }
    return null;
  }
}
