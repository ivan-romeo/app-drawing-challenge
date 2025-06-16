import 'dart:async';

class TimerService {
  Stream<int> startCountdown(int durationSec) {
    return Stream<int>.periodic(
      const Duration(seconds: 1),
          (tick) => durationSec - tick - 1,
    ).take(durationSec);
  }
}
