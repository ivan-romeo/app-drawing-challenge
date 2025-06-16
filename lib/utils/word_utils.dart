
String getRandomWord() {
  final words = ['cane', 'gatto', 'barca', 'montagna', 'telefono'];
  words.shuffle();
  return words.first;
}