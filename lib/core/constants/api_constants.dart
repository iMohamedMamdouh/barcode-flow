class ApiConstants {
  ApiConstants._();

  static const String authEndpoint = '/web/session/authenticate';
  static const String callKwEndpoint = '/web/dataset/call_kw';
  static const String sessionInfoEndpoint = '/web/session/get_session_info';

  static const String productTemplateModel = 'product.template';
  static const String productProductModel = 'product.product';

  static const List<String> productTemplateFields = [
    'id',
    'name',
    'default_code',
    'barcode',
    'list_price',
    'image_128',
    'product_variant_ids',
    'product_variant_count',
  ];

  static const List<String> productVariantFields = [
    'id',
    'name',
    'default_code',
    'barcode',
    'list_price',
    'image_128',
    'product_template_variant_value_ids',
  ];

  static const List<String> variantValueFields = [
    'id',
    'name',
    'display_name',
  ];
}
