import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart' show XFile;

import '../config.dart';
import '../models/category.dart';
import '../models/product.dart';

class ApiException implements Exception {
  final String message;
  final bool isNetwork; // true = cannot reach the Laravel server
  ApiException(this.message, {this.isNetwork = false});
  @override
  String toString() => message;
}

/// Calls the Laravel REST API for products CRUD
class ApiService {
  static const _headers = {'Accept': 'application/json'};
  static const _timeout = Duration(seconds: 12);

  // ---------- Categories (for dropdown / filter chips) ----------
  static Future<List<Category>> getCategories() async {
    final res = await _send(
      () => http.get(
        Uri.parse('${AppConfig.baseUrl}/categories'),
        headers: _headers,
      ),
    );
    final body = _decode(res);
    return (body['data'] as List).map((e) => Category.fromJson(e)).toList();
  }

  // ---------- READ: all products ----------
  static Future<List<Product>> getProducts({
    String? search,
    int? categoryId,
  }) async {
    final query = <String, String>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': '$categoryId',
    };
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/products',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final res = await _send(() => http.get(uri, headers: _headers));
    final body = _decode(res);
    return (body['data'] as List).map((e) => Product.fromJson(e)).toList();
  }

  // ---------- READ: one product ----------
  static Future<Product> getProduct(int id) async {
    final res = await _send(
      () => http.get(
        Uri.parse('${AppConfig.baseUrl}/products/$id'),
        headers: _headers,
      ),
    );
    return Product.fromJson(_decode(res)['data']);
  }

  // ---------- CREATE ----------
  static Future<Product> createProduct(Product p, {XFile? image}) async {
    final res = await _send(() async {
      final req =
          http.MultipartRequest(
              'POST',
              Uri.parse('${AppConfig.baseUrl}/products'),
            )
            ..headers.addAll(_headers)
            ..fields.addAll(p.toFields());
      if (image != null) {
        req.files.add(await _imagePart(image));
      }
      return http.Response.fromStream(await req.send());
    });
    return Product.fromJson(_decode(res)['data']);
  }

  // ---------- UPDATE ----------
  // PHP cannot read multipart bodies on PUT, so send POST + _method=PUT
  static Future<Product> updateProduct(
    int id,
    Product p, {
    XFile? image,
  }) async {
    final res = await _send(() async {
      final req =
          http.MultipartRequest(
              'POST',
              Uri.parse('${AppConfig.baseUrl}/products/$id'),
            )
            ..headers.addAll(_headers)
            ..fields.addAll({...p.toFields(), '_method': 'PUT'});
      if (image != null) {
        req.files.add(await _imagePart(image));
      }
      return http.Response.fromStream(await req.send());
    });
    return Product.fromJson(_decode(res)['data']);
  }

  // ---------- DELETE ----------
  static Future<void> deleteProduct(int id) async {
    final res = await _send(
      () => http.delete(
        Uri.parse('${AppConfig.baseUrl}/products/$id'),
        headers: _headers,
      ),
    );
    _decode(res);
  }

  /// Multipart file from bytes — works on Android, iOS and web (Chrome)
  static Future<http.MultipartFile> _imagePart(XFile image) async =>
      http.MultipartFile.fromBytes(
        'ProductImage',
        await image.readAsBytes(),
        filename: image.name.isEmpty ? 'image.jpg' : image.name,
      );

  /// Turns low-level socket errors into one friendly message
  static Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_timeout);
    } on http.ClientException {
      throw ApiException('Cannot connect to the server', isNetwork: true);
    } on TimeoutException {
      throw ApiException(
        'The server took too long to respond',
        isNetwork: true,
      );
    }
  }

  static Map<String, dynamic> _decode(http.Response res) {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Server error (${res.statusCode})');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    // Laravel validation error (422)
    if (body['errors'] is Map) {
      final errors = (body['errors'] as Map).values
          .expand((e) => e as List)
          .join('\n');
      throw ApiException(errors);
    }
    throw ApiException(
      body['message']?.toString() ?? 'Error ${res.statusCode}',
    );
  }
}
