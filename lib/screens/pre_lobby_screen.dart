import 'package:applicazione_test_firebase/screens/on_boarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';

class PreLobbyScreen extends StatefulWidget {
  const PreLobbyScreen({super.key});

  @override
  State<PreLobbyScreen> createState() => _PreLobbyScreenState();
}

class _PreLobbyScreenState extends State<PreLobbyScreen> {
  late final TextEditingController _roomController;

  @override
  void initState() {
    super.initState();
    _roomController = TextEditingController();
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.read<GameProvider>();
    final nickname = gp.nickname ?? 'Giocatore';

    return Scaffold(
      body: Container(
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
              children: [
                // Titolo di benvenuto
                Text(
                  'Benvenuto, $nickname!',
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Card con il form
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Entra o crea una stanza',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),

                        // TextField per il nome stanza
                        TextField(
                          controller: _roomController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.meeting_room_rounded),
                            hintText: 'Nome stanza',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Pulsanti Crea / Entra
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final room = _roomController.text.trim();
                                  if (room.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Inserisci un nome stanza'),
                                      ),
                                    );
                                    return;
                                  }
                                  final ok = await gp.makeRoom(room);
                                  if (!ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Nome stanza non disponibile'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Crea'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final room = _roomController.text.trim();
                                  if (room.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Inserisci un nome stanza'),
                                      ),
                                    );
                                    return;
                                  }
                                  final ok = await gp.joinRoom(room);
                                  if (!ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Stanza non trovata'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.login),
                                label: const Text('Entra'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.green.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Bottone per cambiare nickname
                TextButton(
                  onPressed: () {
                    gp.deleteNickname();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const OnBoardingScreen()),
                    );
                  },
                  child: const Text(
                    'Cambia Nickname',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                    ),
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
