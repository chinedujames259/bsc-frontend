class ProductImage {
  final int id;
  final String url;
  final String? alt;
  final bool isPrimary;

  ProductImage({
    required this.id,
    required this.url,
    this.alt,
    required this.isPrimary,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'],
      url: json['url'],
      alt: json['alt'],
      isPrimary: json['isPrimary'] == 1 || json['isPrimary'] == true,
    );
  }
}

class Product {
  final int id;
  final String slug;
  final int userId;
  final int? categoryId;
  final String sku;
  final String name;
  final String? description;
  final int stockCount;
  final String? price;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProductImage> images;

  Product({
    required this.id,
    required this.slug,
    required this.userId,
    this.categoryId,
    required this.sku,
    required this.name,
    this.description,
    required this.stockCount,
    this.price,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    print('Product JSON: $json');
    final images = (json['images'] as List?)
            ?.map((img) => ProductImage.fromJson(img))
            .toList() ??
        [];
    print('Product ${json['name']} has ${images.length} images');
    if (images.isNotEmpty) {
      print('First image URL: ${images.first.url}');
      print('First image isPrimary: ${images.first.isPrimary}');
    }
    
    return Product(
      id: json['id'],
      slug: json['slug'],
      userId: json['userId'],
      categoryId: json['categoryId'],
      sku: json['sku'],
      name: json['name'],
      description: json['description'],
      stockCount: json['stockCount'],
      price: json['price'],
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
      images: images,
    );
  }

  String? get primaryImageUrl {
    try {
      final primary = images.firstWhere((img) => img.isPrimary).url;
      print('Primary image URL: $primary');
      return primary;
    } catch (e) {
      final fallback = images.isNotEmpty ? images.first.url : null;
      print('No primary image found, using fallback: $fallback');
      return fallback;
    }
  }

  Product copyWith({
    int? id,
    String? slug,
    int? userId,
    int? categoryId,
    String? sku,
    String? name,
    String? description,
    int? stockCount,
    String? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ProductImage>? images,
  }) {
    return Product(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      stockCount: stockCount ?? this.stockCount,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
    );
  }
}

