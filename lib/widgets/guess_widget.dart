import 'package:applicazione_test_firebase/widgets/drawing_board_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/game_provider.dart';
import '../providers/guesses_provider.dart';
import '../models/guess.dart';

class GuessingArea extends StatefulWidget {
  const GuessingArea({Key? key}) : super(key: key);

  @override
  State<GuessingArea> createState() => _GuessingAreaState();
}

class _GuessingAreaState extends State<GuessingArea> {
  final _controller = TextEditingController();
  bool guessedCorrectly = false;

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        // 1) Mostro il disegno dal documento Firestore rooms/{roomId}
        Expanded(
          child: DrawingBoard()
        ),


      ],
    );
  }



}
