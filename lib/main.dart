import 'package:applicazione_test_firebase/providers/auth_provider.dart';
import 'package:applicazione_test_firebase/providers/game_provider.dart';
import 'package:applicazione_test_firebase/providers/guesses_provider.dart';
import 'package:applicazione_test_firebase/providers/strokes_provider.dart';
import 'package:applicazione_test_firebase/repositories/room_firestore_repository.dart';
import 'package:applicazione_test_firebase/screens/root_router_screen.dart';
import 'package:applicazione_test_firebase/services/timer_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/room.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) {
          final auth = AuthFirebaseProvider();
          auth.loginAnonimously();
          return auth;
        }),
        ChangeNotifierProvider(create: (context){
          final _timerService = TimerService();
          final _roomRepository = RoomFirestoreRepository();
          final game = GameProvider(
            authFirebaseProvider: context.read<AuthFirebaseProvider>(),
            timerService: _timerService,
            roomRepository: _roomRepository
          );
          game.loadNickname();
          return game;
        }),
        ChangeNotifierProxyProvider<GameProvider,StrokesProvider>(
          create: (context) => StrokesProvider(),
          update: (ctx, gameProv, strokeProv) {
            final strokes = strokeProv!;

            final roomId = gameProv.roomId;
            final round = gameProv.round;

            if (roomId != null && strokes.roomId != roomId) {
              strokes.updateRoomId(roomId);
              debugPrint('StrokesProvider listening to room $roomId');
            }
            if(round != null){
              strokes.clearStrokesForNewRound(round);
            }

            return strokes;
          }
        ),
        ChangeNotifierProxyProvider<GameProvider,GuessesProvider>(
          create: (context) => GuessesProvider(),
          update: (ctx, gameProv, guessesProv) {
            final guesses = guessesProv!;

            final roomId = gameProv.roomId;
            final round = gameProv.round;
            final status = gameProv.room?.status;

            if (roomId != null && guesses.roomId != roomId) {
              guesses.updateRoomId(roomId);
              debugPrint('GuessesProvider listening to room $roomId');
            }
            if(round != null){
              guesses.newRound(round);
            }
            if (status != null && gameProv.room!.status == StatusRoom.finished) {
              guessesProv.clearAllGuesses();
            }

            return guesses;
          },
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            textTheme: TextTheme(

            )
        ),
        title: 'Indovina il Disegno',
        home: RootRouterScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}