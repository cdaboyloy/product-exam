import 'package:flutter/material.dart';

import '../theme.dart';

class ProductImage extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;

  const ProductImage({super.key, this.url, this.size = 56, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEDE9FF), Color(0xFFFCE7F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        size: size * 0.42,
        color: AppColors.primaryLight,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null
          ? placeholder
          : Image.network(
              url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // Chrome: Laravel's /storage files have no CORS header, so fall
              // back to a plain <img> element (ignored on Android/iOS)
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (_, _, _) => placeholder,
              frameBuilder: (context, child, frame, wasSync) => wasSync
                  ? child
                  : AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: AppMotion.normal,
                      child: frame == null ? placeholder : child,
                    ),
            ),
    );
  }
}
