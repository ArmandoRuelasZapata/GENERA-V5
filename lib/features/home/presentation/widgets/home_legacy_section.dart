import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/features/home/presentation/providers/home_data_provider.dart';
import 'package:theoriginallab_v2/shared/widgets/glass_card.dart';
import 'package:theoriginallab_v2/shared/utils/url_helper.dart';

class HomeLegacySection extends ConsumerStatefulWidget {
  const HomeLegacySection({super.key});

  @override
  ConsumerState<HomeLegacySection> createState() => _HomeLegacySectionState();
}

class _HomeLegacySectionState extends ConsumerState<HomeLegacySection> {
  final PageController _topController =
      PageController(viewportFraction: AppSpacing.carouselCardViewport);
  final PageController _bottomController =
      PageController(viewportFraction: 0.5);
  int _topIndex = 0;
  int _bottomIndex = 0;
  Timer? _topTimer;
  Timer? _bottomTimer;
  int _lastTopCount = 0;
  int _lastBottomCount = 0;

  @override
  void dispose() {
    _topTimer?.cancel();
    _bottomTimer?.cancel();
    _topController.dispose();
    _bottomController.dispose();
    super.dispose();
  }

  void _startTopTimer(int count) {
    _topTimer?.cancel();
    if (count <= 1) return;
    _topTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      final next = (_topIndex + 1) % count;
      _topController.animateToPage(
        next,
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeInOut,
      );
    });
  }

  void _startBottomTimer(int count) {
    _bottomTimer?.cancel();
    if (count <= 1) return;
    _bottomTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      final next = (_bottomIndex + 1) % count;
      _bottomController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _syncTimers({
    required int topCount,
    required int bottomCount,
  }) {
    if (_lastTopCount != topCount) {
      _lastTopCount = topCount;
      _startTopTimer(topCount);
    }
    if (_lastBottomCount != bottomCount) {
      _lastBottomCount = bottomCount;
      _startBottomTimer(bottomCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(homeAdsProvider);
    final horizontalAdsAsync = ref.watch(homeHorizontalAdsProvider);

    return horizontalAdsAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (horizontalAds) {
        return adsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (ads) {
            if (horizontalAds.isEmpty && ads.isEmpty) {
              return const SizedBox.shrink();
            }

            final normalizedHorizontalAds = horizontalAds
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .where((ad) {
              final imageUrl =
                  (ad['image_url'] ?? ad['image'] ?? '').toString().trim();
              return imageUrl.isNotEmpty &&
                  !imageUrl.contains('via.placeholder.com');
            }).toList();

            final normalizedAds = ads
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .where((ad) {
              final imageUrl =
                  (ad['image_url'] ?? ad['image'] ?? '').toString();
              final url = (ad['url'] ?? ad['cta_url'] ?? '').toString().trim();
              return !imageUrl.contains('via.placeholder.com') && url != '#';
            }).toList();

            final itemAds = normalizedAds
                .where((ad) => (ad['ad_type'] ?? 'banner') == 'item')
                .toList();

            _syncTimers(
              topCount: normalizedHorizontalAds.length,
              bottomCount: itemAds.length,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (normalizedHorizontalAds.isNotEmpty) ...[
                  SizedBox(
                    height: 180,
                    child: PageView.builder(
                      controller: _topController,
                      itemCount: normalizedHorizontalAds.length,
                      onPageChanged: (i) => setState(() => _topIndex = i),
                      itemBuilder: (context, index) {
                        final ad = normalizedHorizontalAds[index];
                        final imageUrl =
                            (ad['image_url'] ?? ad['image'] ?? '').toString();
                        final url =
                            (ad['url'] ?? ad['cta_url'] ?? '').toString();
                        final canOpen =
                            url.trim().isNotEmpty && url.trim() != '#';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GlassCard(
                            enableBlur: false,
                            padding: EdgeInsets.zero,
                            onTap: canOpen
                                ? () => UrlHelper.openUrl(context, url)
                                : null,
                            child: imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.cardRadius),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      memCacheWidth: 600,
                                      maxWidthDiskCache: 1200,
                                      errorWidget: (_, __, ___) => const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child:
                                        Icon(Icons.image, color: Colors.grey),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.smallGap),
                ],
                if (itemAds.isNotEmpty) ...[
                  SizedBox(
                    height: 160,
                    child: PageView.builder(
                      controller: _bottomController,
                      itemCount: itemAds.length,
                      onPageChanged: (i) => setState(() => _bottomIndex = i),
                      itemBuilder: (context, index) {
                        final ad = itemAds[index];
                        final title =
                            (ad['titulo'] ?? ad['title'] ?? 'Publicidad')
                                .toString();
                        final imageUrl =
                            (ad['image_url'] ?? ad['image'] ?? '').toString();
                        final url =
                            (ad['url'] ?? ad['cta_url'] ?? '').toString();
                        final canOpen =
                            url.trim().isNotEmpty && url.trim() != '#';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: GlassCard(
                            enableBlur: false,
                            padding: EdgeInsets.zero,
                            onTap: canOpen
                                ? () => UrlHelper.openUrl(context, url)
                                : null,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              AppSpacing.cardRadius),
                                          child: CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            memCacheWidth: 500,
                                            maxWidthDiskCache: 1000,
                                            errorWidget: (_, __, ___) =>
                                                const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 24,
                                                color: Colors.white54,
                                              ),
                                            ),
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(Icons.image,
                                              color: Colors.grey),
                                        ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.cardRadius),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.08),
                                          Colors.black.withValues(alpha: 0.2),
                                          Colors.black.withValues(alpha: 0.45),
                                        ],
                                        stops: const [0.25, 0.6, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 10,
                                  right: 10,
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      title,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.7),
                                            offset: const Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
