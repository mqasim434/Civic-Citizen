import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../routes/app_router.dart';
import '../../features/posts/services/post_service.dart';

/// Listens for post deep links and navigates to post detail.
class DeepLinkListener extends StatefulWidget {
  const DeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  String? _lastHandled;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handle(initial);
      }
    } catch (_) {
      // Ignore cold-start link failures.
    }
    _sub = _appLinks.uriLinkStream.listen(_handle);
  }

  Future<void> _handle(Uri uri) async {
    final postId = _extractPostId(uri);
    if (postId == null || postId.isEmpty) return;
    if (_lastHandled == postId) return;
    _lastHandled = postId;

    // Let splash / auth settle briefly on cold start.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    try {
      final post = await context.read<PostService>().getPost(postId);
      if (!mounted) return;
      if (post == null) {
        ScaffoldMessenger.of(navigatorKey.currentContext ?? context)
            .showSnackBar(
          const SnackBar(content: Text('Post not found or no longer available.')),
        );
        return;
      }
      navigatorKey.currentState?.pushNamed(
        AppConstants.routePostDetail,
        arguments: post,
      );
    } catch (_) {
      // User may still be on login; ignore.
    } finally {
      // Allow reopening the same link later.
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (_lastHandled == postId) _lastHandled = null;
      });
    }
  }

  static const _httpsHosts = {
    AppConstants.sharePostHttpsHost,
    'civic-citizen-3d0af.firebaseapp.com',
  };

  /// Supports:
  /// - civiccitizen://post/{id}
  /// - https://civic-citizen-3d0af.web.app/post/{id}
  String? _extractPostId(Uri uri) {
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (uri.scheme == AppConstants.sharePostScheme &&
        host == AppConstants.sharePostHost &&
        segments.isNotEmpty) {
      return segments.first;
    }

    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        _httpsHosts.contains(host) &&
        segments.length >= 2 &&
        segments.first == 'post') {
      return segments[1];
    }

    // Fallback: .../post/{id} on any host
    final postIdx = segments.indexOf('post');
    if (postIdx >= 0 && postIdx + 1 < segments.length) {
      return segments[postIdx + 1];
    }
    return null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
