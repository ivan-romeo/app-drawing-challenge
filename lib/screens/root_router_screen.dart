import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'on_boarding_screen.dart';
import 'pre_lobby_screen.dart';
import 'lobby_screen.dart';
import 'game_screen.dart';
import 'game_ended_screen.dart';

class RootRouterScreen extends StatelessWidget {
  const RootRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('build_root');
    // Ricostruisco SOLO quando `route` cambia
    final route = context.select((GameProvider gp) => gp.route);

    switch (route) {
      case AppRoute.onboarding:
        return const OnBoardingScreen();
      case AppRoute.preLobby:
        return const PreLobbyScreen();
      case AppRoute.lobby:
        return const LobbyScreen();
      case AppRoute.game:
        return const GameScreen();
      case AppRoute.gameEnded:
        return const GameEndedScreen();
    }
  }
}
