import 'package:flutter/material.dart';

import '../theme.dart';

/// Product photo on a warm tinted backdrop (contain, so packaging is never cut).
class ProductImage extends StatelessWidget {
  final String? url;
  final double radius;
  final EdgeInsets padding;
  final Color background;

  const ProductImage({
    super.key,
    this.url,
    this.radius = 18,
    this.padding = const EdgeInsets.all(12),
    this.background = Mart.coralTint,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Icon(
        Icons.shopping_basket_rounded,
        size: 36,
        color: Mart.coral.withValues(alpha: 0.5),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: background,
        padding: padding,
        child: url == null
            ? placeholder
            : Image.network(
                url!,
                fit: BoxFit.contain,
                // Chrome: Laravel's /storage files have no CORS header, so fall
                // back to a plain <img> element (ignored on Android/iOS)
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
