import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/product_image.dart';
import '../widgets/ui.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

/// Screen 1: product list (READ) + search + category filter + delete
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  List<Product>? _items;
  List<Category> _categories = [];
  int? _categoryId;
  Object? _error;
  bool _loading = true;
  bool _fabVisible = true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCategories();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final dir = _scroll.position.userScrollDirection;
    if (dir == ScrollDirection.reverse && _fabVisible) {
      setState(() => _fabVisible = false);
    } else if (dir == ScrollDirection.forward && !_fabVisible) {
      setState(() => _fabVisible = true);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.getProducts(
        search: _searchCtrl.text.trim(),
        categoryId: _categoryId,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final c = await ApiService.getCategories();
      if (mounted) setState(() => _categories = c);
    } catch (_) {
      /* list screen still works without filter chips */
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
    setState(() {}); // toggle clear button
  }

  void _selectCategory(int? id) {
    if (_categoryId == id) return;
    setState(() => _categoryId = id);
    _load();
  }

  Future<void> _retry() async {
    if (_categories.isEmpty) _loadCategories();
    await _load();
  }

  Future<void> _openForm([Product? product]) async {
    final changed = await Navigator.push<bool>(
      context,
      route3D(ProductFormScreen(product: product)),
    );
    if (changed == true) _load();
  }

  Future<void> _openDetail(Product product) async {
    final changed = await Navigator.push<bool>(
      context,
      route3D(ProductDetailScreen(product: product)),
    );
    if (changed == true) _load();
  }

  /// Returns true when deleted (used by swipe-to-delete too)
  Future<bool> _delete(Product p) async {
    if (!await confirmDelete(context, p.productName)) return false;
    try {
      await ApiService.deleteProduct(p.productId!);
      if (!mounted) return true;
      showToast(context, '"${p.productName}" deleted');
      return true;
    } catch (e) {
      if (mounted) showToast(context, '$e', error: true);
      return false;
    }
  }

  void _removeLocal(Product p) {
    setState(() => _items?.removeWhere((x) => x.productId == p.productId));
  }

  @override
  Widget build(BuildContext context) {
    final items = _items ?? const <Product>[];
    final totalQty = items.fold<int>(0, (s, p) => s + p.qty);
    final stockValue = items.fold<double>(
      0,
      (s, p) => s + p.qty * p.unitPriceOut,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SoftBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: AnimatedSlide(
            offset: _fabVisible ? Offset.zero : const Offset(0, 2),
            duration: AppMotion.normal,
            curve: Curves.easeOutCubic,
            child: AnimatedScale(
              scale: _fabVisible ? 1 : 0.6,
              duration: AppMotion.normal,
              curve: AppMotion.springOut,
              child: SizedBox(
                width: 178,
                child: GradientButton(
                  label: 'Add Product',
                  icon: Icons.add_rounded,
                  onPressed: () => _openForm(),
                ),
              ),
            ),
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            edgeOffset: 120,
            onRefresh: _retry,
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    count: items.length,
                    totalQty: totalQty,
                    stockValue: stockValue,
                  ),
                ),
                SliverToBoxAdapter(child: _buildSearchAndFilters()),
                ..._buildContent(items),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Container(
            decoration: clayBox(radius: AppRadius.button),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                fillColor: AppColors.surface,
                hintText: 'Search name or barcode',
                hintStyle: const TextStyle(color: AppColors.muted),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                          _load();
                        },
                      ),
              ),
            ),
          ),
        ),
        if (_categories.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _categoryId == null,
                  onTap: () => _selectCategory(null),
                ),
                for (final c in _categories)
                  _CategoryChip(
                    label: c.categoryName,
                    selected: _categoryId == c.categoryId,
                    onTap: () => _selectCategory(c.categoryId),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildContent(List<Product> items) {
    if (_loading && _items == null) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          sliver: SliverList.builder(
            itemCount: 4,
            itemBuilder: (_, _) => const _SkeletonCard(),
          ),
        ),
      ];
    }
    if (_error != null) {
      final err = _error;
      final network = err is ApiException && err.isNetwork;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _StateView(
            icon: Icons.cloud_off_rounded,
            title: network ? "Can't reach the server" : 'Something went wrong',
            message: network ? 'Make sure the Laravel API is running:' : '$err',
            code: network
                ? 'php artisan serve --host=0.0.0.0 --port=8000'
                : null,
            actionLabel: 'Try again',
            actionIcon: Icons.refresh_rounded,
            onAction: _retry,
          ),
        ),
      ];
    }
    if (items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _StateView(
            icon: Icons.inventory_2_rounded,
            title: _searchCtrl.text.isNotEmpty || _categoryId != null
                ? 'No matching products'
                : 'No products yet',
            message: 'Tap "Add Product" to create your first one.',
            actionLabel: 'Add Product',
            actionIcon: Icons.add_rounded,
            onAction: () => _openForm(),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final p = items[i];
            return Padding(
              key: ValueKey(p.productId),
              padding: const EdgeInsets.only(bottom: 16),
              child: StaggerIn(
                index: i,
                child: Dismissible(
                  key: ValueKey('dismiss-${p.productId}'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _delete(p),
                  onDismissed: (_) => _removeLocal(p),
                  background: const _SwipeDeleteBackground(),
                  child: _ProductCard(
                    product: p,
                    onTap: () => _openDetail(p),
                    onEdit: () => _openForm(p),
                    onDelete: () async {
                      if (await _delete(p)) _removeLocal(p);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}

// ───────────────────────────── Header ─────────────────────────────

class _Header extends StatelessWidget {
  final int count;
  final int totalQty;
  final double stockValue;

  const _Header({
    required this.count,
    required this.totalQty,
    required this.stockValue,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingBlobs()),
            Padding(
              padding: EdgeInsets.fromLTRB(24, top + 18, 24, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventory',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Products',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spin3DIcon(icon: Icons.view_in_ar_rounded),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'Products',
                          icon: Icons.category_rounded,
                          value: count.toDouble(),
                          format: (v) => v.round().toString(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: 'In stock',
                          icon: Icons.inventory_rounded,
                          value: totalQty.toDouble(),
                          format: (v) => v.round().toString(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: 'Value',
                          icon: Icons.payments_rounded,
                          value: stockValue,
                          format: (v) => '\$${v.toStringAsFixed(0)}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final String Function(double) format;

  const _StatTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CountUp(
              value: value,
              format: format,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text(label, style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

// ───────────────────────────── Chips ─────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10, bottom: 4),
      child: Pressable3D(
        onTap: onTap,
        pressedScale: 0.9,
        semanticLabel: 'Filter: $label',
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.gradient : null,
            color: selected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                      spreadRadius: -4,
                    ),
                  ]
                : clayShadow(depth: 0.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: AppMotion.fast,
                child: selected
                    ? const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Product card ─────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap, onEdit, onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final low = product.qty < 10;
    return Pressable3D(
      onTap: onTap,
      semanticLabel: 'Open ${product.productName}',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: clayBox(),
        child: Row(
          children: [
            Hero(
              tag: 'product-img-${product.productId}',
              child: ProductImage(url: product.imageUrl, size: 76, radius: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Pill(text: product.category?.categoryName ?? '-'),
                      Pill(
                        text: low
                            ? 'Low · ${product.qty}'
                            : 'Qty ${product.qty}',
                        icon: low
                            ? Icons.warning_amber_rounded
                            : Icons.inventory_2_outlined,
                        color: low ? AppColors.warning : AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${product.unitPriceOut.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                ClayIconButton(
                  icon: Icons.edit_rounded,
                  tooltip: 'Edit',
                  onTap: onEdit,
                ),
                const SizedBox(height: 10),
                ClayIconButton(
                  icon: Icons.delete_rounded,
                  tooltip: 'Delete',
                  color: AppColors.danger,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground();

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 28),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFDA4AF), AppColors.danger],
      ),
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.delete_forever_rounded, color: Colors.white, size: 30),
        SizedBox(height: 4),
        Text(
          'Delete',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFECE8F6),
        borderRadius: BorderRadius.circular(8),
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: clayBox(),
      child: Shimmer(
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFECE8F6),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(140, 16),
                const SizedBox(height: 10),
                bar(90, 14),
                const SizedBox(height: 10),
                bar(60, 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Empty / error ─────────────────────────────

class _StateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? code;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  const _StateView({
    required this.icon,
    required this.title,
    required this.message,
    this.code,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Bob(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEDE9FF), Color(0xFFFCE7F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: clayShadow(),
              ),
              child: Icon(icon, size: 56, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
          if (code != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.text,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                code!,
                style: const TextStyle(
                  color: Color(0xFFC4B5FD),
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: 200,
            child: GradientButton(
              label: actionLabel,
              icon: actionIcon,
              onPressed: onAction,
            ),
          ),
        ],
      ),
    );
  }
}
