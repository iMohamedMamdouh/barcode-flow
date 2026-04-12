# تغليف وسيلة - Wasila Packaging

تطبيق Flutter لجلب باركود المنتجات من نظام Odoo ERP وطباعة ملصقات الباركود.

## المتطلبات

- Flutter SDK >= 3.7.1
- Dart SDK >= 3.7.1
- نظام Odoo ERP متصل بالشبكة
- Android device / emulator

## التثبيت

```bash
# استنساخ المشروع
git clone <repo-url>
cd wasilaah_finishing

# تثبيت الحزم
flutter pub get

# تشغيل التطبيق
flutter run
```

## بناء APK

```bash
flutter build apk --release
```

## الهيكل المعماري

يتبع التطبيق نمط **Clean Architecture**:

```
lib/
├── config/routes/          # Named routes
├── core/
│   ├── constants/          # App & API constants
│   ├── errors/             # Failure & Exception classes
│   ├── network/            # Odoo JSON-RPC client
│   ├── theme/              # Colors & ThemeData
│   └── utils/              # Service locator (GetIt)
├── features/
│   ├── authentication/     # Odoo login
│   ├── products/           # Product listing, variants, details
│   ├── printing/           # PDF generation & printing
│   └── splash/             # Splash screen
└── main.dart
```

## إعداد اتصال Odoo

عند تسجيل الدخول، أدخل:

| الحقل | الوصف | مثال |
|-------|-------|------|
| عنوان الخادم | رابط خادم Odoo | `https://your-company.odoo.com` |
| قاعدة البيانات | اسم قاعدة البيانات | `mydb` |
| اسم المستخدم | البريد أو اسم المستخدم | `admin@company.com` |
| كلمة المرور | كلمة مرور Odoo | `****` |

## نموذج بيانات Odoo

### Product Template (`product.template`)

```json
{
  "id": 1,
  "name": "قميص قطني",
  "default_code": "SH-001",
  "barcode": "6281000000001",
  "list_price": 45.00,
  "image_1920": "<base64-encoded>",
  "product_variant_ids": [1, 2, 3],
  "product_variant_count": 3
}
```

### Product Variant (`product.product`)

```json
{
  "id": 1,
  "name": "قميص قطني - أحمر / L",
  "default_code": "SH-001-RL",
  "barcode": "6281000000002",
  "list_price": 45.00,
  "image_1920": "<base64-encoded>",
  "product_template_variant_value_ids": [5, 12]
}
```

### Variant Attribute Value (`product.template.attribute.value`)

```json
{
  "id": 5,
  "name": "أحمر",
  "display_name": "اللون: أحمر"
}
```

## الحزم المستخدمة

| الحزمة | الاستخدام |
|--------|-----------|
| `dio` | طلبات HTTP |
| `cookie_jar` + `dio_cookie_manager` | إدارة جلسة Odoo |
| `flutter_bloc` | إدارة الحالة (Cubit) |
| `equatable` | مقارنة الكائنات |
| `dartz` | نمط Either للأخطاء |
| `barcode` + `barcode_widget` | توليد الباركود |
| `pdf` + `printing` | إنشاء PDF والطباعة |
| `flutter_secure_storage` | تخزين بيانات الدخول بأمان |
| `get_it` | حقن التبعيات |
| `google_fonts` | خط Tajawal العربي |

## تدفق المستخدم

1. **شاشة البداية** - عرض شعار التطبيق
2. **تسجيل الدخول** - الاتصال بنظام Odoo
3. **قائمة المنتجات** - عرض وبحث المنتجات
4. **متغيرات المنتج** - اختيار اللون/الحجم/النوع
5. **تفاصيل المنتج** - عرض المعلومات واختيار الكمية
6. **معاينة الملصق** - معاينة الباركود واختيار حجم الملصق
7. **طباعة / تصدير PDF** - طباعة مباشرة أو حفظ كملف PDF

## أحجام الملصقات المدعومة

- **50 × 30 mm** - ملصقات صغيرة
- **70 × 40 mm** - ملصقات متوسطة

## أنواع الباركود المدعومة

- **Code 128** - الافتراضي لأي نص
- **EAN-13** - أرقام 13 خانة
- **EAN-8** - أرقام 8 خانات
