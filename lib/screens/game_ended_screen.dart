import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class GameEndedScreen extends StatelessWidget {
  const GameEndedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Prendo la mappa dei players e la trasformo in lista
    final players = context
        .select((GameProvider gp) => gp.room?.players.values.toList()) ?? [];

    // Ordino la lista per punteggio decrescente
    players.sort((a, b) => b.score.compareTo(a.score));

    final gameProv = context.read<GameProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Partita finita")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Risultati finali",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // La classifica
            Expanded(
              child: ListView.separated(
                itemCount: players.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final p = players[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(p.nickname),
                    trailing: Text(
                      '${p.score} pt${p.score == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Bottone per tornare all'inizio
            ElevatedButton(
              onPressed: () async {
                await gameProv.leaveRoom();
              },
              child: const Text("Torna all'inizio"),
            ),
          ],
        ),
      ),
    );
  }
}
