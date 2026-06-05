import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_sign_in_service.dart';

class AuthProvider extends ChangeNotifier {
  final GoogleSignInService _service = GoogleSignInService();
  GoogleSignInAccount? _user;
  bool _loading = false;

  GoogleSignInAccount? get user => _user;
  bool get isSignedIn => _user != null;
  bool get loading => _loading;
  String? get displayName => _user?.displayName;
  String? get email => _user?.email;
  String? get photoUrl => _user?.photoUrl;

  Future<GoogleSignInAccount?> signIn() async {
    _loading = true;
    notifyListeners();

    try {
      _user = await _service.signIn();
    } catch (_) {}

    _loading = false;
    notifyListeners();
    return _user;
  }

  Future<void> signOut() async {
    await _service.signOut();
    _user = null;
    notifyListeners();
  }
}
