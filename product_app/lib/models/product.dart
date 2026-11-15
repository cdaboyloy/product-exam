import 'category.dart';

class Product {
  final int? productId;
  final String productName;
  final String? description;
  final int categoryId;
  final String? barcode;
  final String? expireDate; // yyyy-MM-dd
  final int qty;
  final double unitPriceIn;
  final double unitPriceOut;
  final String? imageUrl;
  final Category? category;

  Product({
    this.productId,
    required this.productName,
    this.description,
    required this.categoryId,
    this.barcode,
    this.expireDate,
    this.qty = 0,
    this.unitPriceIn = 0,
    this.unitPriceOut = 0,
    this.imageUrl,
    this.category,
  });

  static double _toDouble(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    productId: json['ProductID'] as int?,
    productName: json['ProductName'] as String,
    description: json['Description'] as String?,
    categoryId: int.parse(json['CategoryID'].toString()),
    barcode: json['Barcode'] as String?,
    expireDate: json['Expiredate'] as String?,
    qty: int.tryParse(json['Qty']?.toString() ?? '0') ?? 0,
    unitPriceIn: _toDouble(json['UnitPriceIn']),
    unitPriceOut: _toDouble(json['UnitPriceOut']),
    imageUrl: json['image_url'] as String?,
    category: json['category'] != null
        ? Category.fromJson(json['category'])
        : null,
  );

  /// ទិន្នន័យសម្រាប់ផ្ញើទៅ API (multipart fields ត្រូវតែជា String)
  Map<String, String> toFields() => {
    'ProductName': productName,
    'Description': description ?? '',
    'CategoryID': categoryId.toString(),
    'Barcode': barcode ?? '',
    if (expireDate != null && expireDate!.isNotEmpty) 'Expiredate': expireDate!,
    'Qty': qty.toString(),
    'UnitPriceIn': unitPriceIn.toString(),
    'UnitPriceOut': unitPriceOut.toString(),
  };
}
