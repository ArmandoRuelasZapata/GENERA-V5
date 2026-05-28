import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/features/home/presentation/screens/success_stories_screen.dart';
import 'package:theoriginallab_v2/shared/widgets/glass_card.dart';

class HomeSuccessStories extends StatefulWidget {
  final List<dynamic> items;

  const HomeSuccessStories({super.key, required this.items});

  @override
  State<HomeSuccessStories> createState() => _HomeSuccessStoriesState();
}

class _HomeSuccessStoriesState extends State<HomeSuccessStories> {
  late final PageController _controller;
  int _currentIndex = 0;
  Timer? _timer;

  static const List<String> _imageNames = [
    'Ferratelle.jpg',
    'Karla.jpg',
    'pastor.jpg',
    'insignia.jpg',
    'AGsoprte.jpg',
    'valleamor.jpg',
    'Heelcro Rey.jpg',
    'AULAIEM.jpg',
    'Rodval.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.85);
    if (widget.items.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (!mounted) return;
        final next = (_currentIndex + 1) % widget.items.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 2000),
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

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Casos de Éxito',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SuccessStoriesScreen(),
                    ),
                  );
                },
                child: const Text('Ver todos'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionTitleGap),
        SizedBox(
          height: 100,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final subtitle = (item['subtitulo'] ?? '').toString().trim();
              final lema = (item['lema'] ?? '').toString().trim();
              final entidad = (item['entidad'] ?? '').toString().trim();
              final descripcion = (item['descripcion'] ?? '').toString().trim();
              final previewText = subtitle.isNotEmpty
                  ? subtitle
                  : lema.isNotEmpty
                      ? lema
                      : entidad.isNotEmpty
                          ? entidad
                          : descripcion.isNotEmpty
                              ? descripcion
                              : 'Descripción no disponible';

              final imageName = (index < _imageNames.length)
                  ? _imageNames[index]
                  : 'Ferratelle.jpg';
              final assetPath = 'assets/images/home/$imageName';
              final imageUrl = (item['image_url'] ?? '').toString();
              final ImageProvider imageProvider = imageUrl.isNotEmpty
                  ? CachedNetworkImageProvider(
                      imageUrl,
                      maxWidth: 300,
                    ) as ImageProvider
                  : ResizeImage(
                      AssetImage(assetPath),
                      width: 300,
                    ) as ImageProvider;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GlassCard(
                  enableBlur: false,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SuccessStoriesScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: ResizeImage(imageProvider, height: 120),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item['titulo'] ?? 'Caso',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              previewText,
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.8),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
    );
  }
}
