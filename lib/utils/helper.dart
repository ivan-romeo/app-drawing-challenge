import 'dart:async';

import 'package:flutter/cupertino.dart';

extension ChangeNotifierStreams on ChangeNotifier {
  /// Emette un evento ogni volta che notifyListeners() viene chiamato.
  Stream<void> addListenerStream() {
    final controller = StreamController<void>();
    void listener() => controller.add(null);
    addListener(listener);
    // quando si chiude lo stream, rimuovo il listener
    controller.onCancel = () => removeListener(listener);
    return controller.stream;
  }
}