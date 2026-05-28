import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:theoriginallab_v2/shared/utils/url_helper.dart';
import 'package:theoriginallab_v2/shared/widgets/shimmer_widgets.dart';
import '../../data/models/slider_model.dart';

class SliderCarousel extends StatefulWidget {
  final List<SliderModel> sliders;
  final double height;

  const SliderCarousel({super.key, required this.sliders, this.height = 200});

  @override
  State<SliderCarousel> createState() => _SliderCarouselState();
}

class _SliderCarouselState extends State<SliderCarousel> {
  late final PageController _controller;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
    if (widget.sliders.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        final next = (_currentIndex + 1) % widget.sliders.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _openUrl(String url) {
    String formattedUrl = url.trim();
    if (formattedUrl.startsWith('http://')) {
      formattedUrl = 'https://${formattedUrl.substring(7)}';
    } else if (!formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }
    UrlHelper.openUrl(context, formattedUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sliders.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.sliders.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final slider = widget.sliders[index];
              return GestureDetector(
                onTap: () => _openUrl(slider.url),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: slider.image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const ShimmerImagePlaceholder(),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.sliders.asMap().entries.map((entry) {
            final isActive = _currentIndex == entry.key;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isActive
                    ? const Color(0xFF2695CE)
                    : const Color(0xFFC9D9E8).withValues(alpha: 0.6),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
