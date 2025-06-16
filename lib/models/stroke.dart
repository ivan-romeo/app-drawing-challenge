import 'package:flutter/material.dart';

class Stroke {
  final String userId;
  final List<Offset> points;
  final double strokeWidth;
  final DateTime? timestamp;

  Stroke({
    required this.userId,
    required this.points,
    this.strokeWidth = 4.0,
    this.timestamp,
  });

  void appendPoint(Offset p) => points.add(p);

  Stroke copyWithoutPoints(){
    return Stroke(userId: userId, points: []);
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'points': points
        .map((p) => {
      'x': p.dx,
      'y': p.dy,
    })
        .toList(),
    'strokeWidth': strokeWidth,
    if (timestamp != null)
      'ts': timestamp!.toUtc().toIso8601String(),
  };

  factory Stroke.fromMap(Map<String, dynamic> m) {
    return Stroke(
      userId: m['userId'] as String,
      points: (m['points'] as List)
          .map((pt) => Offset(
        (pt['x'] as num).toDouble(),
        (pt['y'] as num).toDouble(),
      ))
          .toList(),
      strokeWidth: (m['strokeWidth'] as num).toDouble(),
      timestamp: m['ts'] != null
          ? DateTime.parse(m['ts'] as String).toUtc()
          : null,
    );
  }
}
