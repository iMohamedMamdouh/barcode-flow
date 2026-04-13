import 'package:flutter/material.dart';

class ProductCategory {
  final String id;
  final String nameAr;
  final List<String> keywords;
  final List<String> excludeKeywords;
  final String? iconPath;
  final IconData? icon;

  const ProductCategory({
    required this.id,
    required this.nameAr,
    required this.keywords,
    this.excludeKeywords = const [],
    this.iconPath,
    this.icon,
  });

  bool matchesProduct(String productName) {
    final lowerName = productName.toLowerCase();
    final matchesKeyword = keywords.any(
      (kw) => lowerName.contains(kw.toLowerCase()),
    );
    if (!matchesKeyword) return false;
    final matchesExclude = excludeKeywords.any(
      (kw) => lowerName.contains(kw.toLowerCase()),
    );
    return !matchesExclude;
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
    iconPath: 'assets/icons/shoe-rack.png',
  );

  static const mirrors = ProductCategory(
    id: 'mirrors',
    nameAr: 'المرايات',
    keywords: ['Mirror'],
    iconPath: 'assets/icons/mirror.png',
  );

  static const desks = ProductCategory(
    id: 'desks',
    nameAr: 'المكاتب',
    keywords: ['Desk', 'AKILA'],
    excludeKeywords: ['Laptop', 'Drop'],
    iconPath: 'assets/icons/desk-chair.png',
  );

  static const beds = ProductCategory(
    id: 'beds',
    nameAr: 'السرير',
    keywords: ['BED'],
    iconPath: 'assets/icons/double-bed.png',
  );

  static const artificialPlants = ProductCategory(
    id: 'artificial_plants',
    nameAr: 'النباتات الصناعية',
    keywords: ['Tree', 'Plant'],
    iconPath: 'assets/icons/plants.png',
  );

  static const dresser = ProductCategory(
    id: 'dresser',
    nameAr: 'التسريحات',
    keywords: ['DRESSER'],
    iconPath: 'assets/icons/dresser.png',
  );

  static const console = ProductCategory(
    id: 'console',
    nameAr: 'الكونسول',
    keywords: ['CONSOLE'],
    iconPath: 'assets/icons/console.png',
  );

  static const poufs = ProductCategory(
    id: 'POUFS',
    nameAr: 'المقاعد',
    keywords: ['POUF'],
    iconPath: 'assets/icons/pouf.png',
  );

  static const shelves = ProductCategory(
    id: 'SHELVES',
    nameAr: 'الأرفف',
    keywords: ['Shelf'],
    iconPath: 'assets/icons/shelf.png',
  );

  static const swing = ProductCategory(
    id: 'SWING',
    nameAr: 'المراجيح',
    keywords: ['SWING'],
    iconPath: 'assets/icons/swing.png',
  );

  static const table = ProductCategory(
    id: 'TABLE',
    nameAr: 'الترابيزات',
    keywords: ['TABLE'],
    excludeKeywords: ['LAMP', 'Jewelry', 'Laptop'],
    iconPath: 'assets/icons/round-table.png',
  );

  static const trolley = ProductCategory(
    id: 'Trolley',
    nameAr: 'الترولي',
    keywords: ['Trolley'],
    iconPath: 'assets/icons/trolley.png',
  );

  static const chairs = ProductCategory(
    id: 'Chairs',
    nameAr: 'الكراسي',
    keywords: ['Mesh Chair', 'Ergonomic'],
    iconPath: 'assets/icons/chair.png',
  );

  static const List<ProductCategory> values = [
    all,
    shoeStorage,
    table,
    mirrors,
    desks,
    chairs,
    artificialPlants,
    beds,
    dresser,
    console,
    poufs,
    shelves,
    swing,
    trolley,
  ];
}
