import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class AuthFirebaseProvider extends ChangeNotifier{
  final _firebaseAuth = FirebaseAuth.instance;
  User? _user;
  String? get uid => user?.uid;
  bool _isLoading = true;
  User? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> loginAnonimously() async{
    if(_firebaseAuth.currentUser != null){
      _user = _firebaseAuth.currentUser;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final cred = await _firebaseAuth.signInAnonymously();
      _user = cred.user;
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}