import 'package:applicazione_test_firebase/models/stroke.dart';
import 'package:applicazione_test_firebase/providers/strokes_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';

class DrawingBoard extends StatelessWidget {
  DrawingBoard({super.key});

  final _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    print('buildd');
    GameProvider gameProvider = context.read<GameProvider>();
    final isDrawer = gameProvider.isDrawingTurn;
    final strokesProvider = Provider.of<StrokesProvider>(context,listen: false);
    final userId = gameProvider.userId!;

    return RepaintBoundary(
      key: _repaintKey,
      child: GestureDetector(
        onPanStart: (details) {
          // inizio un nuovo stroke

          if (!isDrawer) {
            print("🛑 Blocca disegno: non sei il disegnatore");
            return;
          }
          strokesProvider.setCurrentStroke(Stroke(
            userId: userId,
            points: [],
            strokeWidth: 4.0,
            timestamp: DateTime.now().toUtc(),
          ));
        },
        onPanUpdate: (details) {
          if (!isDrawer) {
            return;
          }
          print("✅ Disegno in corso");

          final box = _repaintKey.currentContext!
              .findRenderObject() as RenderBox;
          final local = box.globalToLocal(details.globalPosition);
          final w = box.size.width;
          final h = box.size.height;
          // calcolo normalizzato
          final nx = (local.dx / w).clamp(0.0, 1.0);
          final ny = (local.dy / h).clamp(0.0, 1.0);
          final cs = strokesProvider.currentStroke!;
          cs.points.add(Offset(nx, ny));
          strokesProvider.setCurrentStroke(cs);
        },
        onPanEnd: (_) {
          if (!isDrawer) {
            print("🛑 Blocca disegno: non sei il disegnatore");
            return;
          }
          if (strokesProvider.currentStroke != null) {
            strokesProvider.addStroke(strokesProvider.currentStroke!);
            strokesProvider.setCurrentStroke(null);
          }
        } ,
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            // prendo larghezza e altezza disponibili
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Consumer<StrokesProvider>(
              builder: (context, value, child){

                final allStrokes = [
                  ...value.strokes,
                  if (value.currentStroke != null) value.currentStroke!,
                ];
                return CustomPaint(
                  size: Size(w, h),
                  painter: _DrawingPainter(strokes: allStrokes,boardKey: _repaintKey),
                );
              }
            );
          },
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final GlobalKey boardKey;
  _DrawingPainter({required this.strokes,required this.boardKey});

  @override
  void paint(Canvas canvas, Size size) {
    // uso size del CustomPaint (lo stesso del Container)
    final w = size.width;
    final h = size.height;

    for (final s in strokes) {
      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = s.strokeWidth
        ..strokeCap = StrokeCap.round;

      for (var i = 0; i < s.points.length - 1; i++) {
        final n1 = s.points[i], n2 = s.points[i + 1];
        // ricostruisco i veri pixel
        final p1 = Offset(n1.dx * w, n1.dy * h);
        final p2 = Offset(n2.dx * w, n2.dy * h);
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
