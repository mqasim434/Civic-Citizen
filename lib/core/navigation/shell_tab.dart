import 'package:flutter/foundation.dart';

/// Selected tab in [MainShell]. Rewards is index 3.
class ShellTab {
  ShellTab._();

  static final index = ValueNotifier<int>(0);

  static void go(int i) => index.value = i;
}
