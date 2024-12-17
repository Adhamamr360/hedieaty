import 'package:firebase_auth/firebase_auth.dart';
import 'db_helper.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  // Sign up function, returning UserCredential
  Future<UserCredential> signUp(String emailAddress, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw e; // Forward the exception for handling in calling code
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }
  Future<UserCredential> signIn(String emailAddress, String password) async {
    try {
      // Attempt to sign in
      return await _auth.signInWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw e; // Forward the exception for handling in calling code
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }



  Future<void> signOut() async {
    if (_auth.currentUser != null) {
      try {
        // Firebase sign-out
        await _auth.signOut();
        print('User signed out successfully.');

      } catch (e) {
        print('Error during sign-out: $e');
      }
    } else {
      print('No user is currently signed in.');
    }
  }

}
