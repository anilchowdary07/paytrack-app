// Simplified services - Firebase disabled
class AuthService {
  static get userId => 'guest_user';

  static Future<void> signOut() async {
    // Firebase auth disabled
  }

  static Future<void> signUp(String email, String password) async {
    // Firebase auth disabled
  }

  static Future<void> signIn(String email, String password) async {
    // Firebase auth disabled
  }
}
