class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String category;
  final String productUrl;
  final String imageUrl;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.category,
    required this.productUrl,
    this.imageUrl = '',
  });
}
