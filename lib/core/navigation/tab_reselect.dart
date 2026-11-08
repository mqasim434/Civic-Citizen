import 'package:flutter/widgets.dart';

import 'shell_tab.dart';

/// Add to the State of a bottom-nav tab screen. [onTabReselected] runs when
/// the user taps that tab's button while the tab is already open.
mixin TabReselectListener<T extends StatefulWidget> on State<T> {
  /// Index of this screen in [MainShell]'s bottom nav.
  int get shellTabIndex;

  void onTabReselected();

  @override
  void initState() {
    super.initState();
    ShellTab.reselected.addListener(_handleTabReselected);
  }

  @override
  void dispose() {
    ShellTab.reselected.removeListener(_handleTabReselected);
    super.dispose();
  }

  void _handleTabReselected() {
    if (!mounted || ShellTab.reselected.tab != shellTabIndex) return;
    onTabReselected();
  }
}

/// Smoothly scrolls [controller] back to the top. If the user is far down,
/// it jumps close to the top first so the animation stays short.
void scrollToTop(ScrollController controller) {
  if (!controller.hasClients) return;
  final position = controller.position;
  if (position.pixels <= position.minScrollExtent) return;

  final viewport = position.viewportDimension;
  if (position.pixels > viewport * 3) {
    controller.jumpTo(viewport);
  }
  controller.animateTo(
    position.minScrollExtent,
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutCubic,
  );
}
