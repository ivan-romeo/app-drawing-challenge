import 'package:applicazione_test_firebase/providers/game_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/guess.dart';
import '../providers/guesses_provider.dart';


class SendGuessWidget extends StatelessWidget {
  SendGuessWidget({super.key});
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final GuessesProvider guessesProvider = context.read<GuessesProvider>();
    final GameProvider gameProvider = context.read<GameProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Scrivi la parola…",
              ),
              onSubmitted: (_) => _submitGuess(gameProvider,guessesProvider),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _submitGuess(gameProvider,guessesProvider),
            child: const Text("Invia"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitGuess(GameProvider gameProvider,GuessesProvider guessesProvider) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final isCorrect = text.toLowerCase() == gameProvider.room?.currentWord?.toLowerCase();

    final guess = Guess(
      userId:    gameProvider.userId!,
      text:      text,
      timestamp: DateTime.now().toUtc(),
      correct:   isCorrect,
      nickname: gameProvider.nickname!,
      round: gameProvider.round!,
    );

    // invio al Realtime Database
    await guessesProvider.addGuess(guess);
    _controller.clear();
  }
}
