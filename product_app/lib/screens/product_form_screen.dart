import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/product_image.dart';
import '../widgets/ui.dart';

/// Screen 3: form to CREATE and UPDATE a product
/// - product == null → create
/// - product != null → edit
class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name,
      _desc,
      _barcode,
      _qty,
      _priceIn,
      _priceOut,
      _expire;

  List<Category> _categories = [];
  int? _categoryId;
  XFile? _image;
  Uint8List? _imageBytes; // preview (works on web too)
  bool _loadingCategories = true;
  bool _saving = false;
  bool _saved = false;
  bool _dirty = false;
  bool _imageError = false; // new product must have an image

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.productName ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _qty = TextEditingController(text: p?.qty.toString() ?? '0');
    _priceIn = TextEditingController(
      text: p?.unitPriceIn.toStringAsFixed(2) ?? '0.00',
    );
    _priceOut = TextEditingController(
      text: p?.unitPriceOut.toStringAsFixed(2) ?? '0.00',
    );
    _expire = TextEditingController(text: p?.expireDate ?? '');
    _categoryId = p?.categoryId;
    for (final c in _controllers) {
      c.addListener(_markDirty);
    }
    _loadCategories();
  }

  List<TextEditingController> get _controllers => [
    _name,
    _desc,
    _barcode,
    _qty,
    _priceIn,
    _priceOut,
    _expire,
  ];

  void _markDirty() {
    if (!_dirty) _dirty = true;
    setState(() {}); // live profit preview
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await ApiService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
      showToast(context, 'Cannot load categories: $e', error: true);
    }
  }

  /// Bottom sheet: choose where the image comes from
  Future<void> _chooseImageSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImageSourceSheet(
        hasImage: _imageBytes != null,
        onRemove: () {
          Navigator.pop(ctx);
          setState(() {
            _image = null;
            _imageBytes = null;
          });
        },
      ),
    );
    if (source != null) await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes(); // works on Android, iOS and Chrome
      if (!mounted) return;
      setState(() {
        _image = x;
        _imageBytes = bytes;
        _imageError = false;
        _dirty = true;
      });
    } catch (e) {
      if (mounted) showToast(context, 'Cannot open image: $e', error: true);
    }
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_expire.text) ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      _expire.text =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }

  void _stepQty(int delta) {
    HapticFeedback.selectionClick();
    final v = math.max(0, (int.tryParse(_qty.text) ?? 0) + delta);
    _qty.text = '$v';
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final needsImage = !_isEdit && _imageBytes == null;
    setState(() => _imageError = needsImage);
    final formOk = _formKey.currentState!.validate();
    if (!formOk || needsImage) {
      if (needsImage)
        showToast(context, 'Please add a product image', error: true);
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _saving = true);

    final product = Product(
      productName: _name.text.trim(),
      description: _desc.text.trim(),
      categoryId: _categoryId!,
      barcode: _barcode.text.trim(),
      expireDate: _expire.text.trim(),
      qty: int.tryParse(_qty.text) ?? 0,
      unitPriceIn: double.tryParse(_priceIn.text) ?? 0,
      unitPriceOut: double.tryParse(_priceOut.text) ?? 0,
    );

    try {
      if (_isEdit) {
        await ApiService.updateProduct(
          widget.product!.productId!,
          product,
          image: _image,
        );
      } else {
        await ApiService.createProduct(product, image: _image);
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true; // button morphs into a green check
      });
      showToast(context, _isEdit ? 'Product updated' : 'Product created');
      await Future.delayed(const Duration(milliseconds: 650));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showToast(context, '$e', error: true);
    }
  }

  Future<bool> _confirmDiscard() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: const Text('Discard changes?'),
        content: const Text('Your edits will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Please enter a product name' : null;

  String? _number(String? v) {
    if (v == null || v.isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null) return 'Enter a number, e.g. 1.50';
    if (n < 0) return 'Cannot be negative';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final priceIn = double.tryParse(_priceIn.text) ?? 0;
    final priceOut = double.tryParse(_priceOut.text) ?? 0;
    final profit = priceOut - priceIn;

    return PopScope(
      canPop: !_dirty || _saved,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          _dirty = false;
          Navigator.pop(context);
        }
      },
      child: SoftBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: AppColors.bg.withValues(alpha: 0.85),
            scrolledUnderElevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: ClayIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  size: 44,
                  color: AppColors.text,
                  onTap: () => Navigator.maybePop(context),
                ),
              ),
            ),
            leadingWidth: 68,
            title: Text(_isEdit ? 'Edit Product' : 'New Product'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                StaggerIn(
                  index: 0,
                  child: Column(
                    children: [
                      Center(child: _imagePicker()),
                      AnimatedSwitcher(
                        duration: AppMotion.normal,
                        child: _imageError
                            ? const Padding(
                                key: ValueKey('img-err'),
                                padding: EdgeInsets.only(top: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      size: 16,
                                      color: AppColors.danger,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Product image is required — tap to add one',
                                      style: TextStyle(
                                        color: AppColors.danger,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : !_isEdit && _imageBytes == null
                            ? const Padding(
                                key: ValueKey('img-hint'),
                                padding: EdgeInsets.only(top: 14),
                                child: Text(
                                  'Tap to add a product image *',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('img-ok')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                StaggerIn(
                  index: 1,
                  child: _Section(
                    icon: Icons.info_rounded,
                    title: 'Basic info',
                    children: [
                      TextFormField(
                        controller: _name,
                        maxLength: 100,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Product name *',
                          prefixIcon: Icon(Icons.label_rounded),
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 6),
                      _loadingCategories
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: LinearProgressIndicator(),
                            )
                          : DropdownButtonFormField<int>(
                              initialValue:
                                  _categories.any(
                                    (c) => c.categoryId == _categoryId,
                                  )
                                  ? _categoryId
                                  : null,
                              borderRadius: BorderRadius.circular(
                                AppRadius.field,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Category *',
                                prefixIcon: Icon(Icons.sell_rounded),
                              ),
                              items: _categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.categoryId,
                                      child: Text(c.categoryName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() {
                                _categoryId = v;
                                _dirty = true;
                              }),
                              validator: (v) =>
                                  v == null ? 'Please choose a category' : null,
                            ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _desc,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.notes_rounded),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StaggerIn(
                  index: 2,
                  child: _Section(
                    icon: Icons.inventory_rounded,
                    title: 'Stock',
                    children: [
                      TextFormField(
                        controller: _barcode,
                        decoration: const InputDecoration(
                          labelText: 'Barcode',
                          prefixIcon: Icon(Icons.qr_code_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _expire,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: InputDecoration(
                          labelText: 'Expire date',
                          prefixIcon: const Icon(Icons.event_rounded),
                          suffixIcon: _expire.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear date',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => _expire.clear(),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          ClayIconButton(
                            icon: Icons.remove_rounded,
                            tooltip: 'Decrease qty',
                            onTap: () => _stepQty(-1),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _qty,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ClayIconButton(
                            icon: Icons.add_rounded,
                            tooltip: 'Increase qty',
                            onTap: () => _stepQty(1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StaggerIn(
                  index: 3,
                  child: _Section(
                    icon: Icons.payments_rounded,
                    title: 'Pricing',
                    trailing: AnimatedSwitcher(
                      duration: AppMotion.normal,
                      transitionBuilder: (c, a) =>
                          ScaleTransition(scale: a, child: c),
                      child: Pill(
                        key: ValueKey(profit >= 0),
                        text: 'Profit \$${profit.toStringAsFixed(2)}',
                        icon: profit >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: profit >= 0
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceIn,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Price in',
                                prefixText: '\$ ',
                              ),
                              validator: _number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _priceOut,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Price out',
                                prefixText: '\$ ',
                              ),
                              validator: _number,
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
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: GradientButton(
              label: _isEdit ? 'Update Product' : 'Save Product',
              icon: Icons.save_rounded,
              loading: _saving,
              success: _saved,
              onPressed: _save,
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePicker() {
    final Widget image = _imageBytes != null
        ? ClipRRect(
            key: ValueKey(_image!.name + _imageBytes!.length.toString()),
            borderRadius: BorderRadius.circular(32),
            child: Image.memory(
              _imageBytes!,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          )
        : ProductImage(
            key: const ValueKey('remote'),
            url: widget.product?.imageUrl,
            size: 150,
            radius: 32,
          );

    return Pressable3D(
      onTap: _chooseImageSource,
      semanticLabel: 'Choose product image',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: clayBox(radius: 38).copyWith(
              border: Border.all(
                color: _imageError ? AppColors.danger : AppColors.glassBorder,
                width: _imageError ? 2.5 : 1.5,
              ),
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.slow,
              transitionBuilder: _flip3D,
              child: image,
            ),
          ),
          Positioned(
            right: -6,
            bottom: -6,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.photo_camera_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// New image flips in around the Y axis like a card.
  Widget _flip3D(Widget child, Animation<double> anim) {
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (context, child) {
        final v = anim.value;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY((1 - v) * math.pi / 2),
          child: Opacity(opacity: v < 0.5 ? 0 : 1, child: child),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: clayBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.text,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Glassy bottom sheet with image source options
class _ImageSourceSheet extends StatelessWidget {
  final bool hasImage;
  final VoidCallback onRemove;
  const _ImageSourceSheet({required this.hasImage, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    Widget option(
      IconData icon,
      String title,
      String sub,
      Color color,
      VoidCallback onTap,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable3D(
        onTap: onTap,
        maxTilt: 0.06,
        semanticLabel: title,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: clayShadow(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Text(
                  'Product image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
            option(
              kIsWeb ? Icons.folder_open_rounded : Icons.photo_library_rounded,
              kIsWeb ? 'Choose a photo' : 'Choose from gallery',
              kIsWeb
                  ? 'Photos, camera (iPhone) or files (laptop)'
                  : 'Photos + images dragged from your laptop',
              AppColors.primary,
              () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (!kIsWeb)
              option(
                Icons.photo_camera_rounded,
                'Take a photo',
                'Use the camera',
                const Color(0xFF0E8FD6),
                () => Navigator.pop(context, ImageSource.camera),
              ),
            if (hasImage)
              option(
                Icons.delete_outline_rounded,
                'Remove selected image',
                'Keep the current image instead',
                AppColors.danger,
                onRemove,
              ),
          ],
        ),
      ),
    );
  }
}
