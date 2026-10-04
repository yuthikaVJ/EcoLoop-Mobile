import 'package:flutter/material.dart';

/// Swipeable photos with page dots and a "2/5" counter, like Facebook
/// Marketplace and Instagram. Dots and counter only appear for 2+ photos.
class ImageCarousel extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const ImageCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final _controller = PageController();
  // Only the dots and counter rebuild on swipe, not the photos.
  final _page = ValueNotifier<int>(0);

  @override
  void dispose() {
    _controller.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.itemCount;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: count,
          onPageChanged: (index) => _page.value = index,
          itemBuilder: widget.itemBuilder,
        ),
        if (count > 1) ...[
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: ValueListenableBuilder<int>(
                valueListenable: _page,
                builder: (context, page, _) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${page + 1}/$count',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: ValueListenableBuilder<int>(
              valueListenable: _page,
              builder: (context, page, _) => _PageDots(count: count, current: page),
            ),
          ),
        ],
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Photo ${current + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == current ? 8 : 6,
              height: i == current ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == current ? Colors.white : Colors.white54,
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
              ),
            ),
        ],
      ),
    );
  }
}
