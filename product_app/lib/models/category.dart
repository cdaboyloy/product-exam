class Category {
  final int categoryId;
  final String categoryName;
  final String? description;
  final String? imageUrl;

  Category({
    required this.categoryId,
    required this.categoryName,
    this.description,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    categoryId: json['category_id'] as int,
    categoryName: json['category_name'] as String,
    description: json['description'] as String?,
    imageUrl: json['image_url'] as String?,
  );
}
