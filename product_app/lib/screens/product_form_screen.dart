import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/mart.dart';
import '../widgets/product_image.dart';

/// Screen 3 — CREATE / UPDATE a product (product == null → create)
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
      _cost,
      _price,
      _expire;

  List<Category> _categories = [];
  int? _categoryId;
  XFile? _image;
  Uint8List? _imageBytes;
  bool _loadingCategories = true;
  bool _saving = false;
  bool _dirty = false;
  bool _photoMissing = false;
  bool _categoryMissing = false;

  bool get _isEdit => widget.product != null;
  List<TextEditingController> get _fields => [
    _name,
    _desc,
    _barcode,
    _qty,
    _cost,
    _price,
    _expire,
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.productName ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _qty = TextEditingController(text: '${p?.qty ?? 1}');
    _cost = TextEditingController(
      text: p?.unitPriceIn.toStringAsFixed(2) ?? '',
    );
    _price = TextEditingController(
      text: p?.unitPriceOut.toStringAsFixed(2) ?? '',
    );
    _expire = TextEditingController(text: p?.expireDate ?? '');
    _categoryId = p?.categoryId;
    for (final c in _fields) {
      c.addListener(() => setState(() => _dirty = true));
    }
    _loadCategories();
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await ApiService.getCategories();
      if (mounted) setState(() => _categories = list);
    } catch (e) {
      if (mounted)
        notify(context, 'Could not load categories: $e', error: true);
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _choosePhoto() async {
    final source = kIsWeb
        ? ImageSource
              .gallery // browser: one file chooser (photos/camera on phones, files on laptops)
        : await showModalBottomSheet<ImageSource>(
            context: context,
            backgroundColor: Mart.card,
            showDragHandle: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            builder: (ctx) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    _sourceTile(
                      ctx,
                      Icons.photo_library_rounded,
                      'Gallery',
                      ImageSource.gallery,
                    ),
                    const SizedBox(width: 12),
                    _sourceTile(
                      ctx,
                      Icons.photo_camera_rounded,
                      'Camera',
                      ImageSource.camera,
                    ),
                  ],
                ),
              ),
            ),
          );
    if (source == null) return;
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
        _photoMissing = false;
        _dirty = true;
      });
    } catch (e) {
      if (mounted) notify(context, 'Could not open image: $e', error: true);
    }
  }

  Widget _sourceTile(
    BuildContext ctx,
    IconData icon,
    String label,
    ImageSource s,
  ) => Expanded(
    child: Squeeze(
      onTap: () => Navigator.pop(ctx, s),
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Mart.coralTint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: Mart.coral, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Mart.navy,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_expire.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      _expire.text =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }

  void _step(int delta) {
    HapticFeedback.selectionClick();
    _qty.text = '${math.max(0, (int.tryParse(_qty.text) ?? 0) + delta)}';
  }

  String? _money(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null) return 'Numbers only';
    if (n < 0) return 'Must be 0 or more';
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final needPhoto = !_isEdit && _imageBytes == null;
    final needCategory = _categoryId == null;
    setState(() {
      _photoMissing = needPhoto;
      _categoryMissing = needCategory;
    });
    if (!_formKey.currentState!.validate() || needPhoto || needCategory) {
      HapticFeedback.mediumImpact();
      notify(
        context,
        needPhoto
            ? 'Please add a product photo'
            : 'Please complete the required fields',
        error: true,
      );
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
      unitPriceIn: double.tryParse(_cost.text) ?? 0,
      unitPriceOut: double.tryParse(_price.text) ?? 0,
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
      _dirty = false;
      notify(
        context,
        _isEdit ? 'Product updated' : 'Product added to your store',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      notify(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profit =
        (double.tryParse(_price.text) ?? 0) -
        (double.tryParse(_cost.text) ?? 0);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await ask(
          context,
          title: 'Discard changes?',
          message: 'What you entered will not be saved.',
          yes: 'Discard',
          icon: Icons.undo_rounded,
        );
        if (leave && context.mounted) {
          setState(() => _dirty = false);
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 72,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(
              child: RoundButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onTap: () => Navigator.maybePop(context),
              ),
            ),
          ),
          title: Text(_isEdit ? 'Edit product' : 'Add product'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              RiseIn(child: _photoCard()),
              const SizedBox(height: 16),
              RiseIn(
                index: 1,
                child: _card('Product info', [
                  TextFormField(
                    controller: _name,
                    maxLength: 100,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Product name',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                      counterText: '',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Product name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Category',
                    style: TextStyle(
                      color: Mart.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_loadingCategories)
                    const LinearProgressIndicator(color: Mart.coral)
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in _categories) _categoryChoice(c),
                      ],
                    ),
                  if (_categoryMissing)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Choose a category',
                        style: TextStyle(color: Mart.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _desc,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              RiseIn(
                index: 2,
                child: _card('Inventory', [
                  TextFormField(
                    controller: _barcode,
                    decoration: const InputDecoration(
                      labelText: 'Barcode',
                      prefixIcon: Icon(Icons.qr_code_scanner_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _expire,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(
                      labelText: 'Expire date',
                      prefixIcon: Icon(Icons.event_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Quantity',
                          style: TextStyle(
                            color: Mart.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      RoundButton(
                        icon: Icons.remove_rounded,
                        tooltip: 'Decrease',
                        onTap: () => _step(-1),
                        background: Mart.canvas,
                      ),
                      SizedBox(
                        width: 72,
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
                            color: Mart.navy,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                      RoundButton(
                        icon: Icons.add_rounded,
                        tooltip: 'Increase',
                        onTap: () => _step(1),
                        background: Mart.coral,
                        iconColor: Colors.white,
                      ),
                    ],
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              RiseIn(
                index: 3,
                child: _card('Pricing', [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cost,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Cost',
                            prefixText: '\$ ',
                          ),
                          validator: _money,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _price,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Selling price',
                            prefixText: '\$ ',
                          ),
                          validator: _money,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: (profit < 0 ? Mart.red : Mart.mint).withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          profit < 0
                              ? Icons.trending_down_rounded
                              : Icons.trending_up_rounded,
                          color: profit < 0 ? Mart.red : Mart.mint,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          profit < 0 ? 'Loss per unit' : 'Profit per unit',
                          style: const TextStyle(
                            color: Mart.navy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$${profit.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: profit < 0 ? Mart.red : Mart.mint,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: CoralButton(
            label: _isEdit ? 'Save changes' : 'Add product',
            icon: Icons.check_rounded,
            busy: _saving,
            onTap: _save,
          ),
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Mart.card,
      borderRadius: BorderRadius.circular(24),
      boxShadow: Mart.shadow(),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Mart.navy,
          ),
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );

  Widget _categoryChoice(Category c) {
    final selected = _categoryId == c.categoryId;
    return Squeeze(
      onTap: () => setState(() {
        _categoryId = c.categoryId;
        _categoryMissing = false;
        _dirty = true;
      }),
      semanticLabel: 'Category ${c.categoryName}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? Mart.coralGradient : null,
          color: selected ? null : Mart.canvas,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Mart.categoryIcon(c.categoryName),
              size: 18,
              color: selected ? Colors.white : Mart.coral,
            ),
            const SizedBox(width: 6),
            Text(
              c.categoryName,
              style: TextStyle(
                color: selected ? Colors.white : Mart.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoCard() {
    final hasNew = _imageBytes != null;
    final oldUrl = widget.product?.imageUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Squeeze(
          onTap: _choosePhoto,
          semanticLabel: 'Choose product photo',
          child: Container(
            height: 210,
            decoration: BoxDecoration(
              color: Mart.coralTint,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _photoMissing ? Mart.red : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasNew)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                  )
                else if (oldUrl != null)
                  ProductImage(
                    url: oldUrl,
                    radius: 24,
                    padding: const EdgeInsets.all(20),
                  )
                else
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 44,
                          color: Mart.coral,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add a product photo',
                          style: TextStyle(
                            color: Mart.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Required',
                          style: TextStyle(color: Mart.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: Mart.coralGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Mart.coral.withValues(alpha: 0.4),
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
          ),
        ),
        if (_photoMissing)
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'A product photo is required',
              style: TextStyle(color: Mart.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
