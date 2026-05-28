import 'package:flutter/material.dart';

/// Modelo para items con animación Hero
class HeroItem {
  final String title;
  final IconData icon;
  final Color color;
  final String? description;
  final String? imageUrl;

  HeroItem({
    required this.title,
    required this.icon,
    required this.color,
    this.description,
    this.imageUrl,
  });
}

/// Lista genérica con animaciones Hero
/// Para usar en productos, servicios, etc.
class HeroListView extends StatelessWidget {
  final List<HeroItem> items;
  final String title;
  final Function(int)? onItemTap;

  const HeroListView({
    super.key,
    required this.items,
    this.title = 'Lista',
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => ListTile(
          minTileHeight: 80,
          title: Text(items[index].title),
          subtitle: items[index].description != null
              ? Text(items[index].description!)
              : null,
          leading: Hero(
            tag: 'hero_item_$index',
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: items[index].color.withValues(alpha: 0.1),
              ),
              child: Icon(items[index].icon, color: items[index].color),
            ),
          ),
          onTap: () {
            if (onItemTap != null) {
              onItemTap!(index);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HeroDetailPage(
                    item: items[index],
                    heroTag: 'hero_item_$index',
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

/// Página de detalle con animación Hero
class HeroDetailPage extends StatelessWidget {
  final HeroItem item;
  final String heroTag;

  const HeroDetailPage({super.key, required this.item, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero animated container
            Hero(
              tag: heroTag,
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: item.color.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Icon(item.icon, color: item.color, size: 100),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              item.title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Description
            if (item.description != null)
              Text(
                item.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Agregar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
