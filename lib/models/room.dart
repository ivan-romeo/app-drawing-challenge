import 'package:applicazione_test_firebase/models/player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusRoom { lobby, started, finished }
const String collectionRoomName = 'rooms';

class Room {
  String name;
  String? currentWord;
  String owner_uid;
  String? drawer_uid;
  StatusRoom status;
  DateTime created_at;
  DateTime? countdownStart;
  int? countdownDuration;
  DateTime? guessStart;
  int? guessDuration;
  int round;
  Map<String, Player> players;

  Room({
    required this.name,
    this.players = const {},
    this.status = StatusRoom.lobby,
    required this.owner_uid,
    this.drawer_uid,
    required this.created_at,
    this.round = 0,
    this.currentWord,
    this.countdownStart,
    this.countdownDuration,
    this.guessDuration,
    this.guessStart,
  });

  factory Room.fromMap(Map<String, dynamic> map){
    final rawPlayers = (map['players'] as Map?) ?? {};
    final parsedPlayers = rawPlayers.map((uid, raw) {
      return MapEntry(
        uid as String,
        Player.fromMap((raw as Map).cast<String, dynamic>()),
      );
    });

    final ts = map['countdownStart'] as Timestamp?;
    final start = ts?.toDate();

    return Room(
      name: map['name'] as String,
      owner_uid: map['owner_uid'] as String,
      created_at: (map['created_at'] as Timestamp).toDate(),
      players: parsedPlayers,
      currentWord: map['currentWord'] as String?,
      round: map['round'] as int? ?? 0,
      drawer_uid: map['drawer_uid'] as String?,
      status: StatusRoom.values.firstWhere(
            (e) => e.name == (map['status'] as String),
        orElse: () => StatusRoom.lobby,  // fallback sicuro
      ),
      countdownStart: start,
      countdownDuration: map['countdownDuration'] as int?,
      guessStart: (map['guessStart'] as Timestamp?)?.toDate(),
      guessDuration: map['guessDuration'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'currentWord': currentWord,
      'owner_uid': owner_uid,
      'drawer_uid': drawer_uid,
      'status': status.name,
      'created_at': created_at,
      'round': round,
      'players': players.map((uid, p) => MapEntry(uid, p.toMap())),
    };

    // se countdownStart/Duration sono valorizzati, li includo
    if (countdownStart != null) {
      map['countdownStart'] = countdownStart;
    }
    if (countdownDuration != null) {
      map['countdownDuration'] = countdownDuration;
    }
    if (guessStart != null) {
      map['guessStart'] = guessStart;
    }
    if (guessDuration != null) {
      map['guessDuration'] = guessDuration;
    }

    return map;
  }

}
