import 'dart:async';
import 'package:applicazione_test_firebase/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/guess.dart';
import '../providers/guesses_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/drawing_board_widget.dart';
import '../widgets/send_guess_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameProvider _gameProv;
  late final GuessesProvider _guessProv;
  StreamSubscription<void>? _gameSub;
  StreamSubscription<void>? _guessSub;
  int? _prevRound;
  bool _roundEndTriggered = false;

  @override
  void initState() {
    super.initState();
    // Post-frame per assicurarsi che il context abbia i provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gameProv  = context.read<GameProvider>();
      _guessProv = context.read<GuessesProvider>();

      // 1) Listener sul cambio di round: resetto il flag di fine round e il "guessedCorrect"
      _gameSub = _gameProv.addListenerStream().listen((_) {
        final r = _gameProv.round;
        if (r != null && r != _prevRound) {
          _prevRound = r;
          _roundEndTriggered = false;
        }
      });

      // 2) Listener sulle nuove guesses: se qualcuno (diverso dal drawer) azzecca,
      //    l’owner lancia startGame()
      _guessSub = _guessProv.addListenerStream().listen((_) {
        final room = _gameProv.room;
        if (room == null || _roundEndTriggered) return;

        final nonDrawer = room.players.keys
            .where((u) => u != room.drawer_uid)
            .toSet();
        final hasCorrect = _guessProv.guesses.any((g) =>
        g.correct == true && nonDrawer.contains(g.userId)
        );

        if (hasCorrect) {
          _roundEndTriggered = true;
          if (_gameProv.userId == room.owner_uid) {
            _gameProv.startGame();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _gameSub?.cancel();
    _guessSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Solo qui recupero i valori per la UI
    final gp = context.read<GameProvider>();
    final roomId     = context.select((GameProvider gp) => gp.roomId);
    final isDrawer   = context.select((GameProvider gp) => gp.isDrawingTurn);
    final word       = context.select((GameProvider gp) => gp.currentWord);

    if (roomId == null) {
      return const Center(child: Text("Nessuna stanza selezionata"));
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        gp.leaveRoom();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(onPressed: () => _gameProv.leaveRoom()),
          title: Selector<GameProvider,int>(
            selector: (_, gp) => gp.guessCountdown,
            builder: (_, remSec, __) {
              final round = context.read<GameProvider>().round ?? 0;
              return Text("Round $round – Tempo: $remSec s",
                  style: const TextStyle(fontWeight: FontWeight.bold));
            },
          ),
          centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [ Color(0xFF00C9FF), Color(0xFF92FE9D) ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ➤ Canvas di disegno
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.4,
                      child:  DrawingBoard(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // ➤ Lista dei guess
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Consumer<GuessesProvider>(
                          builder: (_, prov, __) => _buildChatList(prov.guesses),
                        ),
                      ),
                    ),
                  ),
                ),
// Divider grafico
                Container(
                  height: 4,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // ➤ Input o messaggio “tempo scaduto”
                const SizedBox(height: 8),

                // Input o istruzioni drawer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: isDrawer
                      ? Text(
                    "Disegna: $word",
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium!
                        .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  )
                      :  SendGuessWidget(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
Widget _buildChatList(List<Guess> allGuesses) {
  final widgets = <Widget>[];
  int? lastRound;

  for (var g in allGuesses) {
    if (g.round != lastRound) {
      // aggiungo un separatore
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '--- Round ${g.round} ---',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey),
          ),
        ),
      );
      lastRound = g.round;
    }
    widgets.add(
      ListTile(
        leading: CircleAvatar(child: Text(g.nickname[0])),
        title: Text(g.nickname),
        subtitle: Text(g.text),
        trailing: Icon(
          g.correct ? Icons.check_circle : Icons.radio_button_unchecked,
          color: g.correct ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  return ListView(
    reverse: true,
    children: widgets.reversed.toList(), // per avere il più recente in basso o in alto
  );
}