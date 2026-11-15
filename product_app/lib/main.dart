import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/product_list_screen.dart';
import 'theme.dart';
import 'widgets/iphone_frame.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const ProductApp());
}

class ProductApp extends StatelessWidget {
  const ProductApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Mart',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // On a wide laptop/Chrome window, show the app inside an iPhone frame
      builder: (context, child) => IPhoneFrame(child: child!),
      home: const ProductListScreen(),
    );
  }
}
