import 'package:flutter/foundation.dart';

/// Selected tab in [MainShell]. Rewards is index 3.
class ShellTab {
  ShellTab._();

  static final index = ValueNotifier<int>(0);

  /// Fires when the user taps the tab that is already selected.
  /// Tabs listen to this to scroll back to the top.
  static final reselected = TabReselectNotifier();

  static void go(int i) => index.value = i;
}

class TabReselectNotifier extends ChangeNotifier {
  int? _tab;

  /// Index of the tab that was tapped again.
  int? get tab => _tab;

  void fire(int i) {
    _tab = i;
    notifyListeners();
  }
}
