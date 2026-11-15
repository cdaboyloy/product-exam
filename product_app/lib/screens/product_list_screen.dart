import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/mart.dart';
import '../widgets/product_image.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

/// Screen 1 — store front (READ): stock banner, categories, product grid
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  List<Product>? _items;
  List<Category> _categories = [];
  int? _categoryId;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCategories();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.getProducts(
        search: _search.text.trim(),
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
      /* store front still works without categories */
    }
  }

  Future<void> _refresh() async {
    if (_categories.isEmpty) _loadCategories();
    await _load();
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
    setState(() {});
  }

  void _pick(int? id) {
    if (_categoryId == id) return;
    HapticFeedback.selectionClick();
    setState(() => _categoryId = id);
    _load();
  }

  Future<void> _openForm([Product? p]) async {
    final changed = await Navigator.push<bool>(
      context,
      slideIn(ProductFormScreen(product: p)),
    );
    if (changed == true) _load();
  }

  Future<void> _openDetail(Product p) async {
    final changed = await Navigator.push<bool>(
      context,
      slideIn(ProductDetailScreen(product: p)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items ?? const <Product>[];
    final units = items.fold<int>(0, (s, p) => s + p.qty);
    final value = items.fold<double>(0, (s, p) => s + p.qty * p.unitPriceOut);
    final low = items.where((p) => p.qty < 10).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          width: 200,
          child: CoralButton(
            label: 'Add product',
            icon: Icons.add_rounded,
            onTap: () => _openForm(),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: Mart.coral,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverList.list(
                    children: [
                      _header(),
                      const SizedBox(height: 18),
                      _searchField(),
                      const SizedBox(height: 20),
                      RiseIn(child: _banner(items.length, units, value, low)),
                      if (_categories.isNotEmpty) ...[
                        const SizedBox(height: 26),
                        const SectionTitle('Categories'),
                        const SizedBox(height: 12),
                        _categoryRow(),
                      ],
                      const SizedBox(height: 22),
                      SectionTitle(
                        'Products',
                        trailing: Text(
                          '${items.length} items',
                          style: const TextStyle(color: Mart.grey),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                ..._content(items),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: Mart.coralGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.storefront_rounded, color: Colors.white),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: TextStyle(color: Mart.grey, fontSize: 13),
            ),
            Text(
              'Pocket Mart',
              style: TextStyle(
                color: Mart.navy,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      RoundButton(
        icon: Icons.refresh_rounded,
        tooltip: 'Reload',
        onTap: _refresh,
      ),
    ],
  );

  Widget _searchField() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: Mart.shadow(),
    ),
    child: TextField(
      controller: _search,
      onChanged: _onSearch,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search products or barcode',
        prefixIcon: const Icon(Icons.search_rounded),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.cancel_rounded, color: Mart.grey),
                onPressed: () {
                  _search.clear();
                  setState(() {});
                  _load();
                },
              ),
      ),
    ),
  );

  Widget _banner(int count, int units, double value, int low) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: Mart.coralGradient,
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: Mart.coral.withValues(alpha: 0.3),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total stock value',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: Mart.reduceMotion(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Text(
                  '\$${v.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _bannerPill(Icons.category_rounded, '$count products'),
                  _bannerPill(Icons.inventory_2_rounded, '$units units'),
                  if (low > 0)
                    _bannerPill(Icons.warning_amber_rounded, '$low low'),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shopping_bag_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ],
    ),
  );

  Widget _bannerPill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _categoryRow() => SizedBox(
    height: 96,
    child: ListView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      children: [
        _categoryTile('All', Icons.apps_rounded, null),
        for (final c in _categories)
          _categoryTile(
            c.categoryName,
            Mart.categoryIcon(c.categoryName),
            c.categoryId,
          ),
      ],
    ),
  );

  Widget _categoryTile(String label, IconData icon, int? id) {
    final selected = _categoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Squeeze(
        onTap: () => _pick(id),
        semanticLabel: 'Show $label',
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: selected ? Mart.coralGradient : null,
                color: selected ? null : Mart.card,
                borderRadius: BorderRadius.circular(22),
                boxShadow: Mart.shadow(selected ? 2 : 1),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : Mart.coral,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Mart.coral : Mart.navy,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _grid = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    mainAxisExtent: 252,
  );

  List<Widget> _content(List<Product> items) {
    if (_loading && _items == null) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator(color: Mart.coral)),
          ),
        ),
      ];
    }
    if (_error != null) {
      final e = _error;
      final network = e is ApiException && e.isNetwork;
      return [
        SliverToBoxAdapter(
          child: _InfoCard(
            icon: Icons.wifi_off_rounded,
            title: network
                ? 'Can\'t reach the store server'
                : 'Something went wrong',
            message: network ? 'Start the Laravel API and try again:' : '$e',
            code: network
                ? 'php artisan serve --host=0.0.0.0 --port=8000'
                : null,
            action: 'Try again',
            onAction: _refresh,
          ),
        ),
      ];
    }
    if (items.isEmpty) {
      final filtered = _search.text.isNotEmpty || _categoryId != null;
      return [
        SliverToBoxAdapter(
          child: _InfoCard(
            icon: Icons.search_off_rounded,
            title: filtered ? 'No products found' : 'Your store is empty',
            message: filtered
                ? 'Try another search or category.'
                : 'Add your first product to start selling.',
            action: filtered ? null : 'Add product',
            onAction: filtered ? null : () => _openForm(),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        sliver: SliverGrid.builder(
          gridDelegate: _grid,
          itemCount: items.length,
          itemBuilder: (_, i) => RiseIn(
            key: ValueKey(items[i].productId),
            index: i,
            child: _ProductCard(
              product: items[i],
              onOpen: () => _openDetail(items[i]),
              onEdit: () => _openForm(items[i]),
            ),
          ),
        ),
      ),
    ];
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onOpen, onEdit;

  const _ProductCard({
    required this.product,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    final low = p.qty < 10;
    return Squeeze(
      onTap: onOpen,
      semanticLabel: 'Open ${p.productName}',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Mart.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: Mart.shadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'mart-${p.productId}',
                    child: ProductImage(url: p.imageUrl),
                  ),
                  if (low)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Mart.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Low',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Tooltip(
                      message: 'Edit ${p.productName}',
                      child: Squeeze(
                        onTap: onEdit,
                        semanticLabel: 'Edit ${p.productName}',
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Mart.card,
                            shape: BoxShape.circle,
                            boxShadow: Mart.shadow(),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: Mart.coral,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              p.productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Mart.navy,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(
                  Mart.categoryIcon(p.category?.categoryName),
                  size: 13,
                  color: Mart.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    p.category?.categoryName ?? '—',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Mart.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  '\$${p.unitPriceOut.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Mart.coral,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                Text(
                  'Qty ${p.qty}',
                  style: TextStyle(
                    color: low ? Mart.amber : Mart.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? code;
  final String? action;
  final VoidCallback? onAction;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
    this.code,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
    child: RiseIn(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Mart.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: Mart.shadow(),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Mart.coralTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Mart.coral, size: 34),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Mart.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Mart.grey, height: 1.4),
            ),
            if (code != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Mart.navy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  code!,
                  style: const TextStyle(color: Mart.peach, fontSize: 12.5),
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 18),
              CoralButton(label: action!, onTap: onAction),
            ],
          ],
        ),
      ),
    ),
  );
}
