import 'package:flutter/material.dart';

/// Horizontal image slider for post detail; tap opens a fullscreen gallery.
class PostImageGallery extends StatefulWidget {
  const PostImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 260,
  });

  final List<String> imageUrls;
  final double height;

  @override
  State<PostImageGallery> createState() => _PostImageGalleryState();
}

class _PostImageGalleryState extends State<PostImageGallery> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenImageViewer(
          imageUrls: widget.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urls = widget.imageUrls;
    if (urls.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              return GestureDetector(
                onTap: () => _openFullscreen(i),
                child: Hero(
                  tag: 'post-image-${urls[i]}-$i',
                  child: Image.network(
                    urls[i],
                    width: double.infinity,
                    height: widget.height,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (urls.length > 1)
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(urls.length, (i) {
                      final active = i == _index;
                      return Container(
                        width: active ? 8 : 6,
                        height: active ? 8 : 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.45),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '${_index + 1}/${urls.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FullscreenImageViewer extends StatefulWidget {
  const _FullscreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.imageUrls.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.imageUrls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final url = widget.imageUrls[i];
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Hero(
                tag: 'post-image-$url-$i',
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Opens the fullscreen photo viewer (used by the post details thumbnail).
void openPostImageViewer(
  BuildContext context,
  List<String> imageUrls, {
  int initialIndex = 0,
}) {
  if (imageUrls.isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _FullscreenImageViewer(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
    ),
  );
}
