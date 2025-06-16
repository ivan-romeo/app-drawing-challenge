class Player{
  String nickname;
  String uid;
  int score;
  bool ready;

  Player({required this.nickname, this.score = 0, this.ready = false,required this.uid});

  factory Player.fromMap(Map<String,dynamic> map){
    return Player(
      uid: map['uid'],
      nickname: map['nickname'],
      score: map['score'],
      ready: map['ready'],
    );
  }

  Map<String,dynamic> toMap(){
    return {
      'uid':uid,
      'nickname':nickname,
      'score':score,
      'ready': ready
    };
  }
}