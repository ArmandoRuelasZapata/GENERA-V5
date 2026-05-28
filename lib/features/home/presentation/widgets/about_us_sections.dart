import 'package:flutter/material.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/utils/url_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// --- VISUAL WIDGETS ---

class AboutUsMissionVision extends StatelessWidget {
  final Map<String, dynamic> data;
  const AboutUsMissionVision({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCard(
                context, 'Misión', data['mision'], Icons.emoji_objects_outlined)
            .animate()
            .fade(duration: 500.ms)
            .slideY(begin: 0.1, duration: 500.ms, curve: Curves.easeOutQuad),
        const SizedBox(height: AppSpacing.mediumGap),
        _buildCard(context, 'Visión', data['vision'], Icons.visibility_outlined)
            .animate()
            .fade(duration: 500.ms, delay: 200.ms)
            .slideY(
                begin: 0.1,
                duration: 500.ms,
                curve: Curves.easeOutQuad,
                delay: 200.ms),
      ],
    );
  }

  Widget _buildCard(
      BuildContext context, String title, String? text, IconData icon) {
    if (text == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : AppColors.primaryNavy.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decorative Top Line
          Container(
            height: 4,
            width: 45,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.accentCyan,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.accentCyan, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      text,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class AboutUsValues extends StatelessWidget {
  final List<dynamic> values;
  const AboutUsValues({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: values.map((val) {
        return _ValueChip(
          title: val['nombre'],
          description: val['descripcion'],
        );
      }).toList(),
    );
  }
}

class _ValueChip extends StatefulWidget {
  final String title;
  final String description;

  const _ValueChip({required this.title, required this.description});

  @override
  State<_ValueChip> createState() => _ValueChipState();
}

class _ValueChipState extends State<_ValueChip> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isExpanded
              ? AppColors.primaryNavy
              : (isDark ? Colors.white10 : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isExpanded
                ? Colors.transparent
                : Colors.grey.withValues(alpha: 0.2),
          ),
          boxShadow: _isExpanded
              ? [
                  BoxShadow(
                      color: AppColors.primaryNavy.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isExpanded
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.close, size: 14, color: Colors.white70),
                ]
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: 200, // Constraint width for expanded text
                child: Text(
                  widget.description,
                  style: AppTypography.caption.copyWith(color: Colors.white70),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class AboutUsTimeline extends StatelessWidget {
  final List<dynamic> steps;
  const AboutUsTimeline({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accentCyan, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.accentCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['titulo'] ?? '',
                        style: AppTypography.titleSmall
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['descripcion'] ?? '',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class AboutUsStats extends StatelessWidget {
  final List<dynamic> stats;
  const AboutUsStats({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Helper to extract number
    String extractNumber(String text) {
      final RegExp regExp = RegExp(r'(\d+)%?');
      return regExp.stringMatch(text) ?? '';
    }

    // Helper to extract label
    String extractLabel(String text) {
      return text.replaceAll(RegExp(r'(\d+)%?'), '').trim();
    }

    return SizedBox(
      height: 140, // Fixed height for horizontal scroll
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final text = stats[index].toString();
          final number = extractNumber(text);
          final label = extractLabel(text);

          return Container(
            width: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDarkElevated : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  number,
                  style: AppTypography.headlineLarge.copyWith(
                    color: isDark ? Colors.white : AppColors.primaryNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AboutUsContact extends StatelessWidget {
  final Map<String, dynamic> contactData;
  const AboutUsContact({super.key, required this.contactData});

  void _openUrl(BuildContext context, String url) {
    UrlHelper.openUrl(context, url);
  }

  void _makeCall(BuildContext context, String phone) {
    UrlHelper.openUrl(context, 'tel:$phone');
  }

  @override
  Widget build(BuildContext context) {
    final phones = List<String>.from(contactData['telefonos'] ?? []);
    final socials =
        contactData['redes_sociales'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone Buttons
        ...phones.map((phone) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: OutlinedButton.icon(
                onPressed: () => _makeCall(context, phone),
                icon: const Icon(Icons.phone),
                label: Text('Llamar a $phone'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )),

        const SizedBox(height: 16),
        const Text('Síguenos',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Social Icons Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (socials['facebook'] != null)
              _SocialBtn(
                  icon: Icons.facebook,
                  color: Colors.blue[800]!,
                  onTap: () => _openUrl(context, socials['facebook'])),
            if (socials['instagram'] != null)
              _SocialBtn(
                  icon: FontAwesomeIcons.instagram,
                  color: Colors.pink,
                  onTap: () => _openUrl(context, socials['instagram'])),
            if (socials['tiktok'] != null)
              _SocialBtn(
                  icon: FontAwesomeIcons.tiktok,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  onTap: () => _openUrl(context, socials['tiktok'])),
          ],
        ),
      ],
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

class AboutUsProjects extends StatelessWidget {
  final List<dynamic> projects;
  const AboutUsProjects({super.key, required this.projects});

  String _getImageForProject(String name) {
    final normalized = name
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('&', '')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');

    if (normalized.contains('agsoporte')) {
      return 'assets/images/casosexito/AGsoporte.jpg';
    }
    if (normalized.contains('aulaiem')) {
      return 'assets/images/casosexito/aulaiem.jpg';
    }
    if (normalized.contains('ferratelle')) {
      return 'assets/images/casosexito/ferratelle.jpg';
    }
    if (normalized.contains('heelcro')) {
      return 'assets/images/casosexito/heelcro.png';
    }
    if (normalized.contains('insignia')) {
      return 'assets/images/casosexito/insignia.png';
    }
    if (normalized.contains('karla') || normalized.contains('postreria')) {
      return 'assets/images/casosexito/karlapostreria.jpg';
    }
    if (normalized.contains('logistica') || normalized.contains('rodval')) {
      return 'assets/images/casosexito/logisticrodval.jpg';
    }
    if (normalized.contains('pastorsocial') || normalized.contains('pastor')) {
      return 'assets/images/casosexito/pastorsocial.png';
    }
    if (normalized.contains('valle')) {
      return 'assets/images/casosexito/valledelamor.png';
    }

    return '';
  }

  void _showProjectDetail(BuildContext context, dynamic project) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final name = project['nombre'] ?? 'Proyecto';
    final description = project['descripcion'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDarkElevated : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lightbulb_outline,
                      color: AppColors.primaryNavy, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    name,
                    style: AppTypography.headlineSmall
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cerrar'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        final name = project['nombre'] ?? '';

        final imagePath = _getImageForProject(name);

        return InkWell(
          onTap: () => _showProjectDetail(context, project),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark
                      ? Colors.transparent
                      : Colors.grey.withValues(alpha: 0.1)),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imagePath.isNotEmpty)
                  Image(
                    image: ResizeImage(
                      AssetImage(imagePath),
                      height: 400, // Optimize memory for grid views
                    ),
                    fit: BoxFit.cover,
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_center_outlined,
                        size: 32,
                        color: isDark
                            ? Colors.white70
                            : AppColors.primaryNavy.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.9),
                      ],
                      stops: const [0.3, 0.7, 1.0],
                    ),
                  ),
                ),
                // Text at bottom
                Positioned(
                  bottom: 12,
                  left: 8,
                  right: 8,
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
