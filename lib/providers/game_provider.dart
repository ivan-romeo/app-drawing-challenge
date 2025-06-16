import 'dart:async';
import 'package:applicazione_test_firebase/models/player.dart';
import 'package:applicazione_test_firebase/models/room.dart';
import 'package:applicazione_test_firebase/providers/auth_provider.dart';
import 'package:applicazione_test_firebase/services/localstorage_service.dart';
import 'package:applicazione_test_firebase/utils/word_utils.dart';
import 'package:flutter/cupertino.dart';
import '../repositories/room_repository.dart';
import '../services/timer_service.dart';
enum AppRoute { onboarding, preLobby, lobby, game, gameEnded }
class GameProvider extends ChangeNotifier{

  AuthFirebaseProvider authFirebaseProvider;
  final TimerService _timerService;
  final RoomRepository roomRepository;
  final _localstorage = LocalStorageService();

  GameProvider({
    required this.authFirebaseProvider,
    required this.roomRepository,
    required TimerService timerService
  }) : _timerService = timerService;

  Room? _room;
  bool _isLoading = true;
  String? nickname;
  bool _startRequested = false;
  static const int maxRounds = 3;
  static const int lobbyCountdownDuration = 3;

  StreamSubscription<Room>? _roomSub;
  StreamSubscription<int>? _lobbyTimerSub;
  StreamSubscription<int>? _guessTimerSub;
  int lobbyCountdown  = 0;
  int guessCountdown = 0;


  String? get userId => authFirebaseProvider.uid;
  String? get roomId => _room?.name;
  bool get isLoading => _isLoading;
  bool get isSet => nickname != null;
  int? get round => _room?.round;
  Room? get room => _room;
  String? get currentWord => _room?.currentWord;
  String? get currentDrawerId => _room?.drawer_uid;
  bool get isDrawingTurn => _room?.drawer_uid == userId;
  AppRoute get route {
    if (!isSet) {
      return AppRoute.onboarding;
    }
    if (roomId == null || _room?.status == null) {
      return AppRoute.preLobby;
    }
    // round == null è impossibile qui, ma lo trattiamo come 0
    final r = round ?? 0;
    // **SE round == 0 -> resto in lobby** (che include pre‐countdown e countdown)
    if (r == 0) {
      return AppRoute.lobby;
    }

    // round > 0, controllo lo status
    if (_room?.status == StatusRoom.started) {
      return AppRoute.game;
    }
    if (_room?.status == StatusRoom.finished) {
      return AppRoute.gameEnded;
    }
    // fallback (non dovrebbe servire)
    return AppRoute.preLobby;
  }

  Future<void> loadNickname() async {
    nickname = await _localstorage.getString('nickname');
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setNickname(String value) async {
    nickname = value;
    await _localstorage.setString('nickname', value);
    notifyListeners();
  }

  Future<void> deleteNickname() async {
    await _localstorage.remove('nickname');
    notifyListeners();
  }

  Future<bool> makeRoom(String roomId)async{
    final room = Room(
      round: 0,
      name: roomId,
      status: StatusRoom.lobby,
      owner_uid: authFirebaseProvider.uid!,
      created_at: DateTime.timestamp(),
      players: {
        authFirebaseProvider.uid!:Player(nickname:nickname!,score: 0,uid: authFirebaseProvider.uid!),
      }
    );
    final status = await roomRepository.createRoom(room);
    if(status){
      _room = room;
      notifyListeners();
      _listenRoom();
    }
    return status;
  }

  Future<bool> joinRoom(String roomId) async {
    final player = Player(
      nickname: nickname!,
      uid: authFirebaseProvider.uid!,
    );
    final room = await roomRepository.joinRoom(roomId,player);
    if(room != null){
      _room = room;
      notifyListeners();
      _listenRoom();
      return true;
    }
    return false;
  }

  void _checkAllReady() {
    final r = _room;
    if (r == null || r.status != StatusRoom.lobby) return;
    if (_startRequested) return;
    if (r.players.length < 2) return;

    final allReady = r.players.values.every((p) => p.ready);
    if (allReady && userId == r.owner_uid) {
      _startRequested = true;
      _setLobbyCountDown();
    }
  }

  Future<bool> _listenRoom() async{
    if(_room?.name == null) {
      return false;
    }
    _roomSub?.cancel();
    _roomSub = roomRepository.watchRoom(_room!.name).listen(_onRoomData);
    return true;
  }

  void _onRoomData(Room updated) {
    _room = updated;
    notifyListeners();
    _checkAllReady();

    if (updated.status == StatusRoom.started) {
      if (updated.countdownStart != null && updated.countdownDuration != null) {
        _startSyncedLobbyCountdown(
          updated.countdownStart!,
          updated.countdownDuration!,
        );
      }
      if (updated.guessStart != null && updated.guessDuration != null) {
        _startSyncedGuessCountdown(
          updated.guessStart!,
          updated.guessDuration!,
        );
      }
    }
  }

  Future<void> _setLobbyCountDown() async{
    if (_room?.name == null) return;
    await roomRepository.startLobbyCountdown(_room!.name, lobbyCountdownDuration);
  }

  void _startSyncedLobbyCountdown(DateTime serverStart, int durationSec) {
    // 1) calcolo quanti secondi sono già trascorsi rispetto al server
    final elapsed = DateTime.now()
        .toUtc()
        .difference(serverStart.toUtc())
        .inSeconds;

    // 2) quanti secondi restano
    final remaining = (durationSec - elapsed).clamp(0, durationSec);

    // 3) avvio il countdown solo dei secondi rimanenti
    _lobbyTimerSub?.cancel();
    _lobbyTimerSub = _timerService
        .startCountdown(remaining)
        .listen((secsLeft) {
      lobbyCountdown = secsLeft;
      notifyListeners();
    }, onDone: () {
      _lobbyTimerSub = null;
      if (_room != null && userId == _room!.owner_uid) {
        startGame();
      }
    });
  }

  void _startSyncedGuessCountdown(DateTime serverStart, int durationSec) {
    final elapsed = DateTime.now()
        .toUtc()
        .difference(serverStart.toUtc())
        .inSeconds;
    final remaining = (durationSec - elapsed).clamp(0, durationSec);

    _guessTimerSub?.cancel();
    _guessTimerSub = _timerService
      .startCountdown(remaining)
      .listen(
        (secsLeft) {
          guessCountdown = secsLeft;
          notifyListeners();
        },
        onDone: () {
          _guessTimerSub = null;
          if (_room != null && userId == _room!.owner_uid) {
            startGame();
          }
      });
  }

  Future<void> startGame() async {
    final room = _room;
    if (room == null) return;

    // se ho già finito i round
    if (room.round >= maxRounds) {
      await roomRepository.finishGame(room.name);
      room.status = StatusRoom.finished;
      notifyListeners();
      return;
    }

    // 1) calcolo nextRound e drawer
    final nextRound  = room.round + 1;
    final uids       = room.players.keys.toList();
    final nextDrawer = uids[nextRound % uids.length];
    final word       = getRandomWord();
    const guessSec   = 60;

    // 2) delego al repository l’update (senza toccare i ready)
    await roomRepository.advanceGameRound(
      roomId        : room.name,
      nextRound     : nextRound,
      nextDrawerUid : nextDrawer,
      currentWord   : word,
      guessDuration : guessSec,
    );

    // 3) pulisco il flag di start requests e notifica
    _startRequested = false;
    notifyListeners();
  }

  Future<bool> toggleReady() async {
    if (_room?.name == null || userId == null) return false;
    final status = await roomRepository.togglePlayerReady(
      roomId: _room!.name,
      userId: userId!,
    );
    return status;
  }

  void _resetLocalState() {
    _room = null;
    _roomSub?.cancel();
    _roomSub = null;
    _startRequested  = false;
    // CANCELLO i timer in corso
    _lobbyTimerSub?.cancel();
    _lobbyTimerSub = null;
    _guessTimerSub?.cancel();
    _guessTimerSub = null;
    // resetto i valori in memoria
    _startRequested  = false;
    lobbyCountdown   = 0;
    guessCountdown   = 0;
    notifyListeners();
  }

  Future<void> leaveRoom() async {
    if (_room?.name == null || userId == null) return;

    // 3) chiamo il repository
    await roomRepository.leaveRoom(
      roomId: _room!.name,
      userId: userId!,
    );
    _resetLocalState();
  }

  Future<void> _endGame() async {
    if (_room?.name == null) {
      return;
    }
    await roomRepository.finishGame(_room!.name);
  }

  @override
  void dispose() {
    _resetLocalState();
    super.dispose();
  }
}