import '../models/player.dart';
import '../models/room.dart';

abstract class RoomRepository {
  Future<bool> createRoom(Room room);
  Future<Room?> joinRoom(String roomId, Player player);
  Future<void> updateRoomData(String roomId, Map<String, dynamic> data);
  Future<void> deleteRoom(String roomId);
  Stream<Room> watchRoom(String roomId);
  Future<void> startLobbyCountdown(String roomId, int durationSec);
  Future<void> advanceGameRound({
    required String roomId,
    required int nextRound,
    required String nextDrawerUid,
    required String currentWord,
    required int guessDuration,
  });
  Future<void> finishGame(String roomId);
  Future<bool> togglePlayerReady({
    required String roomId,
    required String userId,
  });
  /// Rimuove [userId] da room [roomId]; se dopo la rimozione
  /// non rimane nessun player, cancella la stanza.
  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  });
}