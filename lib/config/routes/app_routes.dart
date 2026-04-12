import 'package:flutter/material.dart';

import '../../features/printing/presentation/views/barcode_preview_screen.dart';
import '../../features/products/domain/entities/product_entity.dart';
import '../../features/products/presentation/views/product_details_screen.dart';
import '../../features/products/presentation/views/product_variants_screen.dart';
import '../../features/products/presentation/views/products_screen.dart';
import '../../features/splash/presentation/views/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String products = '/products';
  static const String productVariants = '/product-variants';
  static const String productDetails = '/product-details';
  static const String barcodePreview = '/barcode-preview';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);

      case products:
        return _buildRoute(const ProductsScreen(), settings);

      case productVariants:
        final product = settings.arguments as ProductEntity;
        return _buildRoute(
          ProductVariantsScreen(product: product),
          settings,
        );

      case productDetails:
        final data = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          ProductDetailsScreen(productData: data),
          settings,
        );

      case barcodePreview:
        final data = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          BarcodePreviewScreen(data: data),
          settings,
        );

      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('الصفحة غير موجودة: ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
