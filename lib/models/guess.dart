class Guess {
  final String userId;
  final String nickname;
  final String text;
  final DateTime timestamp;
  final bool correct;
  final int round;

  Guess({
    required this.userId,
    required this.nickname,
    required this.text,
    required this.timestamp,
    required this.correct,
    required this.round,
  });

  factory Guess.fromMap(Map<String,dynamic> m) => Guess(
    userId:    m['userId']    as String,
    nickname:  m['nickname']  as String,
    text:      m['text']      as String,
    timestamp: DateTime.parse(m['timestamp'] as String),
    correct:   m['correct']   as bool,
    round:     m['round']     as int,
  );

  Map<String,dynamic> toMap() => {
    'userId':    userId,
    'nickname':  nickname,
    'text':      text,
    'timestamp': timestamp.toIso8601String(),
    'correct':   correct,
    'round':     round,
  };
}
