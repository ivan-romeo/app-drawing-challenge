import 'dart:async';

import 'package:applicazione_test_firebase/models/guess.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';

class GuessesProvider extends ChangeNotifier {
  final _db = FirebaseDatabase.instance;
  StreamSubscription<DatabaseEvent>? _sub;

  String? roomId;
  int currentRound = 0;

  // Lista unica di tutti i messaggi, accumulati
  final List<Guess> guesses = [];

  /// Handler per cambiare stanza
  void updateRoomId(String? newRoomId) {
    if (newRoomId == roomId) return;
    roomId = newRoomId;
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    if (roomId == null) return;
    guesses.clear();
    _sub = _db
        .ref('rooms/$roomId/guesses')
        .onChildAdded
        .listen((evt) {
      final m = Map<String,dynamic>.from(evt.snapshot.value as Map);
      guesses.add(Guess.fromMap(m));
      notifyListeners();
    });
  }

  Future<void> addGuess(Guess g) async {
    // salvo incluso il round corrente e nickname
    await _db
        .ref('rooms/$roomId/guesses')
        .push()
        .set(g.toMap());
  }

  /// Solo aggiorno il round corrente, senza toccare la lista
  void newRound(int r) {
    if (r == currentRound) return;
    currentRound = r;
    notifyListeners();
  }
  Future<void> clearAllGuesses() async {
    if (roomId != null) {
      await _db.ref('rooms/$roomId/guesses').remove();
    }
    guesses.clear();
    notifyListeners();
  }
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
