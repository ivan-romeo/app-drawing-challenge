import 'package:applicazione_test_firebase/repositories/room_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/player.dart';
import '../models/room.dart';

class RoomFirestoreRepository implements RoomRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionRoomName);

  @override
  Future<bool> createRoom(Room room) async {
    final ref = _col.doc(room.name);
    if ((await ref.get()).exists) return false;
    await ref.set(room.toMap());
    return true;
  }

  @override
  Future<Room?> joinRoom(String roomId, Player player) async {
    final ref = _db.collection(collectionRoomName).doc(roomId);
    final snap = await ref.get();
    if (!snap.exists) return null;

    await ref.update({
      'players.${player.uid}': player.toMap(),
      'status': StatusRoom.lobby.name,
      'countdownStart': FieldValue.delete(),
      'countdownDuration': FieldValue.delete(),
    });

    // Rileggo e mappo su Room
    final updated = await ref.get();
    return Room.fromMap(updated.data()!);
  }

  @override
  Future<void> updateRoomData(String roomId, Map<String, dynamic> data) =>
      _col.doc(roomId).update(data);

  @override
  Future<void> deleteRoom(String roomId) =>
      _col.doc(roomId).delete();

  @override
  Stream<Room> watchRoom(String roomId) =>
      _col.doc(roomId).snapshots()
          .where((snap) => snap.exists && snap.data() != null)
          .map((snap) => Room.fromMap(snap.data()!));

  @override
  Future<void> startLobbyCountdown(String roomId, int durationSec) {
    final ref = _col.doc(roomId);
    return ref.update({
      'status'           : StatusRoom.started.name,
      'countdownStart'   : FieldValue.serverTimestamp(),
      'countdownDuration': durationSec,
    });
  }
  @override
  Future<void> advanceGameRound({
    required String roomId,
    required int nextRound,
    required String nextDrawerUid,
    required String currentWord,
    required int guessDuration,
  }) {
    return _col.doc(roomId).update({
      'round'            : nextRound,
      'drawer_uid'       : nextDrawerUid,
      'currentWord'      : currentWord,
      'status'           : StatusRoom.started.name,
      'guessStart'       : FieldValue.serverTimestamp(),
      'guessDuration'    : guessDuration,
      'countdownStart'   : FieldValue.delete(),
      'countdownDuration': FieldValue.delete(),
    });
  }
  @override
  Future<void> finishGame(String roomId) {
    return _col.doc(roomId).update({
      'status': StatusRoom.finished.name,
    });
  }

  @override
  Future<bool> togglePlayerReady({
    required String roomId,
    required String userId,
  }) async {
    final ref = _col.doc(roomId);
    final snap = await ref.get();
    if (!snap.exists) return false;

    // 1) Mappo subito il documento su Room
    final room = Room.fromMap(snap.data()!);

    // 2) Trovo il Player corrispondente
    final player = room.players[userId];
    if (player == null) return false;

    // 3) Calcolo il nuovo ready
    final newReady = !player.ready;

    // 4) Aggiorno solo il campo nested in Firestore
    await ref.update({
      'players.$userId.ready': newReady,
    });

    return true;
  }
  @override
  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    final ref = _col.doc(roomId);

    // 1) Leggo lo snapshot
    final snap = await ref.get();
    if (!snap.exists) {
      // già cancellata o mai esistita
      return;
    }

    // 2) Rimuovo il player
    try {
      await ref.update({'players.$userId': FieldValue.delete()});
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
      // altrimenti proseguo
    }

    // 3) Rileggere per controllare quanti ne restano
    final afterSnap = await ref.get();
    if (!afterSnap.exists) {
      return;
    }

    // 4) Mappo su Room per contare i players
    final room = Room.fromMap(afterSnap.data()!);
    if (room.players.isEmpty) {
      // nessun player rimasto → cancello la stanza
      await ref.delete();
    }
  }
}
