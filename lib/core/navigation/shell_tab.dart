import 'package:flutter/foundation.dart';

/// Selected tab in [MainShell]. Rewards is index 3.
class ShellTab {
  ShellTab._();

  static const home = 0;
  static const nearby = 1;
  static const map = 2;
  static const rewards = 3;
  static const profile = 4;

  static final index = ValueNotifier<int>(0);

  /// Fires when the user taps the tab that is already selected.
  /// Tabs listen to this to scroll back to the top.
  static final reselected = TabReselectNotifier();

  static void go(int i) => index.value = i;
}

/// Admin panel bottom nav: Dashboard 0, Posts 1, Users 2, More 3.
class AdminShellTab {
  AdminShellTab._();

  static const dashboard = 0;
  static const posts = 1;
  static const users = 2;
  static const more = 3;

  static final reselected = TabReselectNotifier();
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
