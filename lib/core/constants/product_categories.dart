import 'package:flutter/material.dart';

class ProductCategory {
  final String id;
  final String nameAr;
  final List<String> keywords;
  final IconData icon;

  const ProductCategory({
    required this.id,
    required this.nameAr,
    required this.keywords,
    required this.icon,
  });

  bool matchesProduct(String productName) {
    final lowerName = productName.toLowerCase();
    return keywords.any((kw) => lowerName.contains(kw.toLowerCase()));
  }
}

class ProductCategories {
  ProductCategories._();

  static const all = ProductCategory(
    id: 'all',
    nameAr: 'الكل',
    keywords: [],
    icon: Icons.apps_rounded,
  );

  static const shoeStorage = ProductCategory(
    id: 'shoe_storage',
    nameAr: 'الجزامات',
    keywords: ['Shoe'],
    icon: Icons.storage_rounded,
  );

  static const mirrors = ProductCategory(
    id: 'mirrors',
    nameAr: 'المرايات',
    keywords: ['Mirror'],
    icon: Icons.filter_frames,
  );

  static const desks = ProductCategory(
    id: 'desks',
    nameAr: 'المكاتب',
    keywords: ['Desk', 'AKILA'],
    icon: Icons.desk_rounded,
  );

  static const beds = ProductCategory(
    id: 'beds',
    nameAr: 'السرير',
    keywords: ['BED'],
    icon: Icons.bed_rounded,
  );

  static const List<ProductCategory> values = [
    all,
    shoeStorage,
    mirrors,
    desks,
    beds,
  ];
}
