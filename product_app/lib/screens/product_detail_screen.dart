import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/product_image.dart';
import '../widgets/ui.dart';
import 'product_form_screen.dart';

/// Screen 2: product detail (READ by id)
class ProductDetailScreen extends StatefulWidget {
  final Product product; // shown instantly (hero), then refreshed from API
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
      if (mounted) showToast(context, '$e', error: true);
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      route3D(ProductFormScreen(product: _p)),
    );
    if (changed == true) {
      _changed = true;
      _refresh();
    }
  }

  Future<void> _delete() async {
    if (!await confirmDelete(context, _p.productName)) return;
    try {
      await ApiService.deleteProduct(_p.productId!);
      if (!mounted) return;
      showToast(context, '"${_p.productName}" deleted');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showToast(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    final margin = p.unitPriceOut - p.unitPriceIn;
    final marginPct = p.unitPriceOut > 0
        ? (margin / p.unitPriceOut).clamp(0.0, 1.0)
        : 0.0;
    final expiry = _expiryStatus(p.expireDate);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: SoftBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 360,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.bg.withValues(alpha: 0.9),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Center(
                    child: ClayIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      size: 44,
                      color: AppColors.text,
                      onTap: () => Navigator.maybePop(context),
                    ),
                  ),
                ),
                leadingWidth: 68,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFE4DEFF),
                          Color(0xFFFBE4F1),
                          Color(0x00F8F7FF),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: Opacity(opacity: 0.6, child: FloatingBlobs()),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: _TiltImage(product: p),
                          ),
                        ),
                        Positioned(
                          bottom: 18,
                          left: 0,
                          right: 0,
                          child: Text(
                            'Drag the image to rotate',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.muted.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                sliver: SliverList.list(
                  children: [
                    StaggerIn(
                      index: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Pill(
                                text: p.category?.categoryName ?? '-',
                                icon: Icons.sell_rounded,
                              ),
                              if (expiry != null)
                                Pill(
                                  text: expiry.$1,
                                  icon: expiry.$2,
                                  color: expiry.$3,
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            p.productName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                            ),
                          ),
                          if ((p.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              p.description!,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.32,
                      children: [
                        StaggerIn(
                          index: 1,
                          child: _InfoTile(
                            icon: Icons.inventory_2_rounded,
                            label: 'Quantity',
                            value: '${p.qty}',
                            color: p.qty < 10
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                        StaggerIn(
                          index: 2,
                          child: _InfoTile(
                            icon: Icons.event_rounded,
                            label: 'Expire date',
                            value: p.expireDate ?? '—',
                            color: expiry?.$3 ?? AppColors.primary,
                          ),
                        ),
                        StaggerIn(
                          index: 3,
                          child: _InfoTile(
                            icon: Icons.south_west_rounded,
                            label: 'Price in',
                            value: '\$${p.unitPriceIn.toStringAsFixed(2)}',
                            color: const Color(0xFF0EA5E9),
                          ),
                        ),
                        StaggerIn(
                          index: 4,
                          child: _InfoTile(
                            icon: Icons.north_east_rounded,
                            label: 'Price out',
                            value: '\$${p.unitPriceOut.toStringAsFixed(2)}',
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    StaggerIn(
                      index: 5,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: clayBox(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.trending_up_rounded,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Profit per unit',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ),
                                Text(
                                  '\$${margin.toStringAsFixed(2)} · ${(marginPct * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: margin >= 0
                                        ? AppColors.success
                                        : AppColors.danger,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: marginPct.toDouble()),
                              duration: AppMotion.reduced(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 1100),
                              curve: Curves.easeOutCubic,
                              builder: (_, v, _) => ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: v,
                                  minHeight: 12,
                                  backgroundColor: AppColors.field,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    StaggerIn(
                      index: 6,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: clayBox(),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.qr_code_2_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Barcode',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  SelectableText(
                                    (p.barcode ?? '').isEmpty
                                        ? '—'
                                        : p.barcode!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      letterSpacing: 1.5,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '#${p.productId}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                ClayIconButton(
                  icon: Icons.delete_rounded,
                  tooltip: 'Delete',
                  color: AppColors.danger,
                  size: 56,
                  onTap: _delete,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GradientButton(
                    label: 'Edit Product',
                    icon: Icons.edit_rounded,
                    onPressed: _edit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// (label, icon, color) for expiry state — never color alone
  (String, IconData, Color)? _expiryStatus(String? date) {
    final d = date == null ? null : DateTime.tryParse(date);
    if (d == null) return null;
    final days = d.difference(DateTime.now()).inDays;
    if (days < 0) return ('Expired', Icons.error_rounded, AppColors.danger);
    if (days <= 30)
      return ('Expires in $days d', Icons.schedule_rounded, AppColors.warning);
    return ('Fresh', Icons.verified_rounded, AppColors.success);
  }
}

/// Product image that floats gently and rotates in 3D when dragged,
/// springing back on release.
class _TiltImage extends StatefulWidget {
  final Product product;
  const _TiltImage({required this.product});

  @override
  State<_TiltImage> createState() => _TiltImageState();
}

class _TiltImageState extends State<_TiltImage> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  late final AnimationController _spring = AnimationController(vsync: this);
  Offset _drag = Offset.zero;
  Offset _releaseFrom = Offset.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _idle.stop();
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _spring.dispose();
    super.dispose();
  }

  void _onPan(DragUpdateDetails d) {
    if (AppMotion.reduced(context)) return;
    _spring.stop();
    setState(() {
      _drag = Offset(
        (_drag.dx + d.delta.dx / 160).clamp(-0.7, 0.7),
        (_drag.dy + d.delta.dy / 160).clamp(-0.7, 0.7),
      );
    });
  }

  void _onPanEnd(DragEndDetails _) {
    _releaseFrom = _drag;
    _spring
      ..value = 0
      ..animateTo(
        1,
        duration: const Duration(milliseconds: 900),
        curve: Curves.elasticOut,
      );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPan,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _spring]),
        builder: (context, child) {
          if (_spring.isAnimating || _spring.value == 1) {
            _drag = Offset.lerp(_releaseFrom, Offset.zero, _spring.value)!;
          }
          final a = _idle.value * 2 * math.pi;
          final floatY = 8 * math.sin(a);
          final rx = -_drag.dy + 0.06 * math.sin(a);
          final ry = _drag.dx + 0.10 * math.cos(a);
          // shadow shifts opposite to tilt for depth
          final shadowOffset = Offset(-ry * 30, 26 - floatY);
          return Transform.translate(
            offset: Offset(0, floatY),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0018)
                ..rotateX(rx)
                ..rotateY(ry),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      offset: shadowOffset,
                      blurRadius: 40,
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
        child: Hero(
          tag: 'product-img-${widget.product.productId}',
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(44),
            ),
            child: ProductImage(
              url: widget.product.imageUrl,
              size: 200,
              radius: 36,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: clayBox(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
