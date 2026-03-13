import 'package:flutter/material.dart';

/// Base scaffold with consistent safe area and optional scroll.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.body,
    this.child,
    this.actions,
    this.scroll = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  }) : assert(body == null || child == null, 'Provide either body or child');

  final String? title;
  final Widget? body;
  final Widget? child;
  final List<Widget>? actions;
  final bool scroll;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final content = child ?? body ?? const SizedBox.shrink();
    final padded = Padding(
      padding: padding,
      child: content,
    );
    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              actions: actions,
            )
          : null,
      body: SafeArea(
        child: scroll
            ? SingleChildScrollView(
                child: padded,
              )
            : padded,
      ),
    );
  }
}
