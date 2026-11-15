import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/mart.dart';
import '../widgets/product_image.dart';
import 'product_form_screen.dart';

/// Screen 2 — product page (READ by id): big photo, white panel slides up
class ProductDetailScreen extends StatefulWidget {
  final Product product; // shown instantly, then refreshed from the API
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _p = widget.product;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final p = await ApiService.getProduct(widget.product.productId!);
      if (mounted) setState(() => _p = p);
    } catch (e) {
      if (mounted) notify(context, '$e', error: true);
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      slideIn(ProductFormScreen(product: _p)),
    );
    if (changed == true) {
      _changed = true;
      _refresh();
    }
  }

  Future<void> _delete() async {
    final ok = await ask(
      context,
      title: 'Delete this product?',
      message: '"${_p.productName}" will be removed from your store.',
      yes: 'Delete',
    );
    if (!ok) return;
    try {
      await ApiService.deleteProduct(_p.productId!);
      if (!mounted) return;
      notify(context, 'Product deleted');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) notify(context, '$e', error: true);
    }
  }

  (String, Color)? _expiry(String? date) {
    final d = date == null ? null : DateTime.tryParse(date);
    if (d == null) return null;
    final days = d.difference(DateTime.now()).inDays;
    if (days < 0) return ('Expired', Mart.red);
    if (days <= 30) return ('$days days left', Mart.amber);
    return ('Fresh', Mart.mint);
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    final profit = p.unitPriceOut - p.unitPriceIn;
    final expiry = _expiry(p.expireDate);
    final top = MediaQuery.paddingOf(context).top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: Mart.coralTint,
          body: Stack(
            children: [
              ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: [
                  // photo area
                  Container(
                    height: 330 + top,
                    padding: EdgeInsets.fromLTRB(40, top + 64, 40, 40),
                    child: Hero(
                      tag: 'mart-${p.productId}',
                      child: ProductImage(
                        url: p.imageUrl,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  // white panel
                  RiseIn(
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight:
                            MediaQuery.sizeOf(context).height - 330 - top,
                      ),
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 120),
                      decoration: const BoxDecoration(
                        color: Mart.card,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.productName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Mart.navy,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Mart.categoryIcon(
                                            p.category?.categoryName,
                                          ),
                                          size: 16,
                                          color: Mart.coral,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          p.category?.categoryName ?? '—',
                                          style: const TextStyle(
                                            color: Mart.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${p.unitPriceOut.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Mart.coral,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _Stat(
                                icon: Icons.inventory_2_rounded,
                                label: 'In stock',
                                value: '${p.qty}',
                                color: p.qty < 10 ? Mart.amber : Mart.coral,
                              ),
                              const SizedBox(width: 10),
                              _Stat(
                                icon: Icons.event_rounded,
                                label: expiry?.$1 ?? 'Expiry',
                                value: p.expireDate ?? '—',
                                color: expiry?.$2 ?? Mart.grey,
                              ),
                              const SizedBox(width: 10),
                              _Stat(
                                icon: Icons.trending_up_rounded,
                                label: 'Profit',
                                value: '\$${profit.toStringAsFixed(2)}',
                                color: profit < 0 ? Mart.red : Mart.mint,
                              ),
                            ],
                          ),
                          if ((p.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 22),
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Mart.navy,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p.description!,
                              style: const TextStyle(
                                color: Mart.grey,
                                height: 1.5,
                                fontSize: 15,
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          const Text(
                            'Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Mart.navy,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _line(
                            Icons.qr_code_2_rounded,
                            'Barcode',
                            (p.barcode ?? '').isEmpty ? '—' : p.barcode!,
                          ),
                          _line(
                            Icons.south_west_rounded,
                            'Cost price',
                            '\$${p.unitPriceIn.toStringAsFixed(2)}',
                          ),
                          _line(
                            Icons.north_east_rounded,
                            'Selling price',
                            '\$${p.unitPriceOut.toStringAsFixed(2)}',
                          ),
                          _line(
                            Icons.tag_rounded,
                            'Product ID',
                            '#${p.productId}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // floating top buttons
              Positioned(
                top: top + 8,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    RoundButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onTap: () => Navigator.maybePop(context),
                    ),
                    const Spacer(),
                    RoundButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Delete',
                      iconColor: Mart.red,
                      onTap: _delete,
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            color: Mart.card,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: CoralButton(
                label: 'Edit product',
                icon: Icons.edit_rounded,
                onTap: _edit,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Mart.canvas,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: Mart.navy),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Mart.grey)),
        const SizedBox(width: 12),
        Expanded(
          child: SelectableText(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Mart.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Mart.navy,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
