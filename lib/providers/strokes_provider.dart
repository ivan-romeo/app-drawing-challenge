import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';

import '../models/stroke.dart';

class StrokesProvider extends ChangeNotifier{

  final _databaseFirebase = FirebaseDatabase.instance;
  StreamSubscription<DatabaseEvent>? _streamSub;

  String? _roomId;
  int currentRound = 0;
  List<Stroke> strokes = [];
  Stroke? currentStroke;

  get roomId => _roomId;

  get pathStrokes => 'rooms/$_roomId/strokes';
  void updateRoomId(String newRoomId){
    if(newRoomId == _roomId) return;

    _roomId = newRoomId;
    strokes = [];
    print('[STROKES PROVIDER] ${_roomId}');
    _listenStrokes();
  }

  void setCurrentStroke(Stroke? stroke){
    currentStroke = stroke;
    notifyListeners();
  }

  void _listenStrokes () {
    _streamSub?.cancel();
    _streamSub = _databaseFirebase
      .ref()
      .child(pathStrokes)
      .onChildAdded
      .listen((evt) {
        print('nuovo strocke');
        final s = Stroke.fromMap(
            Map<String,dynamic>.from(evt.snapshot.value as Map)
        );
        strokes.add(s);
        notifyListeners();
      });
  }

  Future<void> addStroke(Stroke stroke) async{
    await _databaseFirebase.ref().child(pathStrokes).push().set(stroke.toMap());
  }

  Future<void> clearStrokesForNewRound(int newRound) async {
    if (newRound == currentRound) return;

    currentRound = newRound;
    strokes.clear();
    notifyListeners();

    if (roomId != null) {
      await _databaseFirebase.ref().child('rooms/$roomId/strokes').remove();
    }
  }

  @override
  void dispose() async{
    await _streamSub?.cancel();
    super.dispose();
  }
}