import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // Sign in function
  Future<UserCredential> signIn(String emailAddress, String password) async {
    try {
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

  // Sign out function
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
