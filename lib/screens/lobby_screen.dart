import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/room.dart';
import '../providers/game_provider.dart';
import '../screens/game_screen.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gp = context.read<GameProvider>();
    final roomId = context.select((GameProvider gp) => gp.roomId) ?? '';
    final players = context
        .select((GameProvider gp) => gp.room?.players.values.toList() ?? [])
      ..sort((a, b) => a.nickname.compareTo(b.nickname));
    final countdown = context.select((GameProvider gp) => gp.lobbyCountdown);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [ Color(0xFF00C9FF), Color(0xFF92FE9D) ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Titolo con ID stanza
                Text(
                  'Lobby: $roomId',
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Card con la lista dei giocatori
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          'Giocatori',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Divider(),
                        SizedBox(
                          height: 200,
                          child: ListView.separated(
                            itemCount: players.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, i) {
                              final p = players[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(p.nickname[0].toUpperCase()),
                                ),
                                title: Text(p.nickname),
                                trailing: Icon(
                                  Icons.circle,
                                  color: p.ready
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Countdown o bottone “Ready”
                if (countdown > 0) ...[
                  Text(
                    'Partenza in:',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$countdown',
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium!
                        .copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aspetta che tutti siano pronti...',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    players.length < 2
                        ? 'Servono almeno 2 giocatori'
                        : 'Sei pronto?',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      gp.toggleReady();
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Segna come pronto'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade700,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Se parte il gioco, naviga alla schermata di disegno
                if (countdown == 0 && gp.room?.status == StatusRoom.started)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const GameScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Inizia Partita'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
