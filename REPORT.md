# تقرير فحص مشروع Barcode Flow وخطة تحويله لمنتج SaaS متعدد الشركات

> **نطاق التقرير:** فحص وتخطيط فقط — لم يتم تعديل أي ملف كود.
> **الفرع:** `claude/awesome-feynman-4bp7u9` — آخر commit تم فحصه: `c0649f9 optimize barcode`.
> **حجم الكود:** 49 ملف Dart داخل `lib/` (~5,500 سطر). أكبر ملف: `lib/core/utils/tspl_label_builder.dart` (930 سطر).
> **ملاحظة:** Flutter SDK غير مثبّت في بيئة الفحص، فلم يتم تشغيل `flutter analyze` أو الاختبارات؛ كل ما يلي مبني على قراءة الكود مباشرة.

---

## ✅ القرارات المعتمدة

القرارات دي اتاخدت بعد مراجعة التقرير، والخطة المرحلية في القسم الثالث متعدّلة على أساسها.

| # | الموضوع | القرار | السبب الأساسي |
|---|---|---|---|
| D1 | **الاتصال بـ Odoo** | **كل الطلبات تمر عبر Supabase Edge Function (`odoo-proxy`)**. التطبيق لا يتصل بـ Odoo مباشرة، ولا يرى مفتاح Odoo أبدًا. المفتاح متخزّن في **Supabase Vault** (write-only بعد الحفظ). | أمان مفتاح ERP العميل، إيقاف الخدمة فورًا عند انتهاء الاشتراك، فرض حد المستخدمين وسجل الطباعة من السيرفر، وإصلاح تغييرات Odoo بدون تحديث التطبيق. |
| D2 | **إصدارات Odoo المدعومة** | **16 و17 و18 و19**، Community وEnterprise، على Odoo Online وOdoo.sh والسيرفرات الخاصة. الإصدار يُكتشف تلقائيًا عند "اختبار الاتصال". 15 وأقدم غير مدعومين في الإطلاق. | تغطية الغالبية العظمى من الشركات النشطة، مع مصفوفة اختبار محدودة. |
| D3 | **الحقل المطبوع كباركود** | **إعداد لكل شركة** بثلاث قيم: `barcode` فقط · `default_code` (SKU) فقط · **`barcode` ولو فاضي `default_code` (الافتراضي)**. المحرر يسمح بإظهار الـ SKU كنص بجانب الباركود. تحقق قبل الطباعة: EAN-13/EAN-8 بـ checksum صحيح، وغير ذلك Code128. | الماسح في تطبيقات Odoo (Barcode/المخزن/POS) يبحث في حقل `barcode` أساسًا. |
| D4 | **الدقة والمقاسات** | دعم **203 DPI (افتراضي) و300 DPI**. المحرك يعمل بالمليمتر. قوالب جاهزة: 40×30 · 50×25 · 50×30 · 58×40 · 60×40 · 100×50 · 100×150 (4×6) · 75×130 (وسيلة) · مقاس مخصّص. إعدادات لكل طابعة: الكثافة، السرعة، الـ gap، الـ offset. | 203 هو الأشيع في طابعات الليبل الاقتصادية؛ 300 للّيبلات الصغيرة والنص العربي الصغير. |
| D5 | **المنصات ووسيلة الاتصال بالطابعة** | **الإطلاق على Android**، بطريقتين اتصال: **Bluetooth Classic** (الحالي) + **WiFi/LAN (TCP منفذ 9100)**. iPhone في مرحلة لاحقة عبر WiFi و BLE مع قائمة "طابعات معتمدة" تم اختبارها. لوحة ويب للمدير (إعداد Odoo، الفريق، المحرر) كتوسعة مستقبلية. | مستخدمي المخازن غالبًا على Android؛ iOS لا يسمح بالبلوتوث الكلاسيكي إلا لأجهزة MFi؛ الطباعة بالشبكة تفتح iOS وتناسب المخازن ذات الطابعة المشتركة. |

**قرار معلّق:** إصدار Odoo الفعلي عند وسيلة — يُعرف من `https://erp.wasilaahteam.com/web/webclient/version_info` أو من الإعدادات بعد تفعيل وضع المطوّر. هو أول إصدار في مصفوفة الاختبار.

---

## أولًا: فحص الوضع الحالي

### 1. خريطة المشروع

```
lib/
├── main.dart                      ← نقطة البداية: SharedPreferences + GetIt + MaterialApp (عربي/RTL فقط)
├── config/routes/app_routes.dart  ← Router يدوي (onGenerateRoute) بـ 5 مسارات
├── core/
│   ├── constants/   app_constants (اسم الشركة + Odoo URL/DB) · api_constants (endpoints + fields)
│   │                product_categories (فئات مكتوبة يدويًا) · label_dimensions (75×130mm)
│   ├── network/     odoo_client.dart  ← عميل JSON-RPC فوق Dio + Cookie jar في الذاكرة
│   ├── services/    auth_local_storage_service (حفظ الدخول) · bluetooth_printer_service (Singleton)
│   ├── theme/       app_colors (ألوان وسيلة الخضراء) · app_theme (خط Tajawal)
│   ├── errors/      Exceptions + Failures
│   └── utils/       tspl_label_builder (توليد الليبل) · barcode_helper · attribute_translator
│                    service_locator (GetIt) · responsive_helper
└── features/
    ├── splash/      شاشة بداية + استعادة الجلسة تلقائيًا
    ├── auth/        data / domain / presentation — تسجيل الدخول على Odoo
    ├── products/    data / domain / presentation — قائمة المنتجات، المتغيرات، التفاصيل، ديالوج الطباعة
    └── printing/    data / domain / presentation — PDF للمشاركة + طباعة TSPL بالبلوتوث
```

**دور كل feature:**

| Feature | الدور |
|---|---|
| `splash` | ينتظر 1.5 ثانية ثم: لو فيه جلسة محفوظة يعيد تسجيل الدخول على Odoo بنفس الإيميل/الباسورد المحفوظين، وإلا يروح للـ login (`splash_screen.dart:43-62`). |
| `auth` | Login بإيميل وباسورد مستخدم Odoo على سيرفر وسيلة الثابت. |
| `products` | جلب `product.template` كلها مرة واحدة، فلترة محلية بالبحث والفئات، شاشة متغيرات (`product.product`)، وديالوج الطباعة `print_action_dialog_widget.dart`. |
| `printing` | (أ) `PrintingRepoImpl` يولد PDF للمشاركة، (ب) `BluetoothPrinterCubit` + `TsplLabelBuilder` يولّدوا أوامر TSPL ويبعتوها للطابعة. |

**نمط المعمارية:** Clean Architecture مبسّطة لكل feature (`data` → `domain` → `presentation`): Repo abstract في `domain/repos` وتنفيذه في `data/repos`، Entities + Models (`fromOdoo`)، ونتائج بـ `Either<Failure, T>` من `dartz`. حقن الاعتماديات عبر **GetIt** (`core/utils/service_locator.dart`) — كلها `LazySingleton`.

**إدارة الحالة:** **flutter_bloc (Cubit)** + `equatable`. الـ Cubits بتتعمل محليًا في كل شاشة بـ `BlocProvider` (مثلًا `products_screen.dart:25-26`, `print_action_dialog_widget.dart:70-77`). مفيش حالة عامة (global) للمستخدم أو الشركة.

**ملاحظات على الالتزام بالمعمارية:**
- لا يوجد طبقة `usecases` — الـ Cubit بينادي الـ Repo مباشرة (مقبول).
- طبقة الطباعة **مكسورة معماريًا**: `BluetoothPrinterCubit` (presentation) بينادي `TsplLabelBuilder` (static utility في core) و`BluetoothPrinterService` مباشرة بدون Repo (`bluetooth_printer_cubit.dart:98`).
- `BluetoothPrinterService` Singleton يدوي (`instance`) ومسجّل في GetIt كمان (`service_locator.dart:34-36`).
- تمرير بيانات المنتج لشاشة التفاصيل كـ `Map<String, dynamic>` (`app_routes.dart:37`) بدل Entity.

---

### 2. كل ما يخص Wasilaah (Hardcoded)

#### 2.1 اتصال Odoo وبيانات الاعتماد
| الملف:السطر | القيمة |
|---|---|
| `lib/core/constants/app_constants.dart:12` | `odooUrl = 'https://erp.wasilaahteam.com'` |
| `lib/core/constants/app_constants.dart:13` | `odooDatabase = 'erp'` |
| `lib/features/auth/data/repos/auth_repo_impl.dart:26-27` | استخدام القيمتين السابقتين مباشرة في الـ login |
| — | **لا يوجد API key أو باسورد مكتوب في الكود** ✅ (الاعتماد على إيميل/باسورد يدخله المستخدم). |

#### 2.2 اسم الشركة والتطبيق
| الملف:السطر | القيمة |
|---|---|
| `lib/core/constants/app_constants.dart:4-6` | `'تغليف وسيلة'`, `'Wasilaah Packaging'`, `'وسيلة'` (الأخير غير مستخدم) |
| `lib/main.dart:17,20` | الكلاس `WasilaahApp` |
| `lib/features/auth/presentation/views/login_screen.dart:52,62` | عرض اسم التطبيق |
| `lib/features/splash/presentation/views/splash_screen.dart:113,123` | عرض اسم التطبيق |
| `pubspec.yaml:1-2` | `name: wasilaah_finishing`, `description: "Wasila Packaging..."` |
| `android/app/src/main/AndroidManifest.xml:9` | `android:label="تغليف وسيلة"` |
| `android/app/build.gradle.kts:9,24` | `com.example.wasilaah_finishing` (namespace + applicationId) |
| `ios/Runner/Info.plist:8,16` | `CFBundleDisplayName = تغليف وسيلة`, `CFBundleName = wasilaah_finishing` |
| `macos/Runner/Configs/AppInfo.xcconfig:8,11` · `linux/CMakeLists.txt:7,10` · `windows/runner/Runner.rc:93-98` · `web/manifest.json:2-3` | اسم المنتج / Bundle ID |
| `test/widget_test.dart:2,6,9` | الاختبار الوحيد بيدوّر على النص `'تغليف وسيلة'` |

#### 2.3 اللوجو والصور
| الملف:السطر | القيمة |
|---|---|
| `assets/images/logo.png` | لوجو وسيلة (نسبة 874/306) |
| `assets/images/made_in_egypt.jpeg` | "صُنع في مصر" **كصورة** وليس نص |
| `assets/images/app_icon.png` + كل `mipmap-*` و`AppIcon.appiconset` | أيقونة التطبيق |
| `lib/core/utils/tspl_label_builder.dart:12-14` | مسارات اللوجو و"صنع في مصر" |
| `lib/core/utils/tspl_label_builder.dart:17` | `_logoAspectRatio = 874.0 / 306.0` — مربوطة بأبعاد لوجو وسيلة بالذات |
| `lib/features/printing/data/repos/printing_repo_impl.dart:34,38-39` | نفس الصورتين في PDF |
| `lib/features/printing/presentation/widgets/barcode_label_widget.dart:42` | اللوجو (widget غير مستخدم) |
| `generate_icon.swift:3,6` | سكريبت أيقونة بمسار لوجو ولون وسيلة |

#### 2.4 الألوان والخطوط
| الملف:السطر | القيمة |
|---|---|
| `lib/core/theme/app_colors.dart:6-10` | `primary 0xFF1B5E20` (أخضر وسيلة) + درجاته + `secondary` |
| `lib/core/theme/app_colors.dart:14` | `surfaceVariant 0xFFE8F5E9` (أخضر فاتح) |
| `lib/features/auth/presentation/widgets/login_form_widget.dart:44,55,85,109` | ألوان مكتوبة inline (`0xFFF2F5F3`, `0xFFE3E8E5`) |
| `pubspec.yaml:48,51` · `android/app/src/main/res/values/colors.xml:3-4` | `#1B5E20` للأيقونة والـ splash |
| `lib/core/theme/app_theme.dart:19` | خط Tajawal |

#### 2.5 الفئات المكتوبة يدويًا
| الملف:السطر | القيمة |
|---|---|
| `lib/core/constants/product_categories.dart:43-151` | 13 فئة أثاث (جزامات، مرايات، مكاتب، سرير، نباتات صناعية، تسريحات، كونسول، مقاعد، أرفف، مراجيح، ترابيزات، ترولي، كراسي) |
| نفس الملف `:60` | كلمة `'AKILA'` (اسم موديل/خط إنتاج خاص بوسيلة) |
| نفس الملف `:61, :118, :132` | قوائم استبعاد (`Laptop`, `Drop`, `LAMP`, `Jewelry`...) وكلمات مثل `'Mesh Chair', 'Ergonomic'` |
| `assets/icons/*.png` | 13 أيقونة أثاث |
| `lib/features/products/presentation/cubits/products_cubit.dart:72` | الفلترة = **مطابقة نصية على اسم المنتج** وليس على فئة Odoo |

> ⚠️ **مهم:** الفئات الحالية **مش فئات Odoo**. التطبيق لا يقرأ `categ_id` نهائيًا — الفئة مستنتجة من وجود كلمة إنجليزية في اسم المنتج.

#### 2.6 تصميم الليبل والطباعة (قيم خاصة بمنتجات وسيلة)
| الملف:السطر | القيمة |
|---|---|
| `lib/core/constants/label_dimensions.dart:7-8` | مقاس الليبل `75mm × 130mm` |
| `lib/core/utils/tspl_label_builder.dart:158` | نص احتياطي `'Walnut shoe storage bench'` لو اسم المنتج فاضي (منتج حقيقي لوسيلة!) |
| `lib/core/utils/tspl_label_builder.dart:101,108,132,142,168-170,198,220,239-242` | كل أبعاد ومسافات العناصر بالـ dots |
| `lib/core/utils/tspl_label_builder.dart:271` | `SPEED 4` · default `density 8` · `gap 3mm` |
| `lib/features/products/presentation/widgets/print_action_dialog_widget.dart:404` | `density: 8` |
| `lib/features/printing/data/repos/printing_repo_impl.dart:103,135-136,142` | أبعاد PDF بالمليمتر |
| `lib/core/utils/attribute_translator.dart:4-53` | قاموس ترجمة إنجليزي→عربي لخامات وألوان أثاث (`wood`, `fabric`, `Hand rest`...) — **خاص بقطاع الأثاث** |

#### 2.7 افتراضات عامة مقفولة
- `lib/main.dart:29-30, 40` — اللغة العربية فقط و RTL إجباري.
- `lib/features/products/data/repos/products_repo_impl.dart:24,31` — فلتر `['image_1920', '!=', false]`: **أي منتج بدون صورة لا يظهر في التطبيق**.

---

### 3. طبقة Odoo

**الملف:** `lib/core/network/odoo_client.dart`

| البند | التفاصيل |
|---|---|
| البروتوكول | **JSON-RPC 2.0 عبر HTTP POST** باستخدام Dio. |
| المصادقة | `POST {url}/web/session/authenticate` بـ `{db, login, password}` (`odoo_client.dart:40-47`). النتيجة: `uid` + **session cookie** محفوظة في `CookieJar()` في الذاكرة فقط (`:19,27`). |
| جلب البيانات | `POST {url}/web/dataset/call_kw` بـ `method: search_read` أو `read` (`:107-120`, `:150-162`). |
| endpoint غير مستخدم | `sessionInfoEndpoint` (`api_constants.dart:6`). |

**الـ Models والحقول** (`lib/core/constants/api_constants.dart`):

| Model | الحقول | الاستخدام |
|---|---|---|
| `product.template` | `id, name, default_code, barcode, list_price, image_128, product_variant_ids, product_variant_count` | قائمة المنتجات (`products_repo_impl.dart:40-45`) — مرتبة `name asc`، **بدون limit** |
| `product.product` | `id, name, default_code, barcode, list_price, image_128, product_template_variant_value_ids` | المتغيرات بفلتر `product_tmpl_id = X` (`:67-73`) |
| `product.template.attribute.value` | `id, name, display_name` | أسماء قيم المتغيرات — **طلب `read` منفصل لكل متغير** (N+1) (`:84-88`) |

**الباركود/SKU:**
- الباركود المطبوع = حقل **`barcode`** فقط. لو فاضي، زر الطباعة يتقفل (`print_action_dialog_widget.dart:65-66`, `product_details_screen.dart:205`) حتى لو `default_code` (الـ SKU / Internal Reference) موجود.
- `default_code` بيتعرض كمعلومة وبيُستخدم في البحث فقط.
- نوع الباركود يُستنتج تلقائيًا: EAN-13 / EAN-8 لو أرقام بـ checksum صحيح، وإلا Code128 (`barcode_helper.dart`, `tspl_label_builder.dart:835-843`).

**الفئات:** لا يتم جلب `categ_id` ولا `product.category` إطلاقًا (انظر 2.5).

**إصدار Odoo المتوقع:** الكود لا يحدد إصدار. الحقول المستخدمة (`image_128`, `image_1920`, `product_template_variant_value_ids`) موجودة من **Odoo 13 فما فوق**، والـ endpoints (`/web/session/authenticate`, `/web/dataset/call_kw`) هي endpoints الـ web client الداخلية وتعمل في 13→18 وما زالت في 19. ⇒ المتوقع عمليًا **Odoo 13+ (غالبًا 16/17)**. ملاحظات:
- `/web/dataset/call_kw` endpoint داخلي للواجهة وليس API عام رسمي؛ الأنسب للـ SaaS هو `/jsonrpc` (`execute_kw`) أو **JSON-2 API** الجديد في Odoo 19 (`/json/2/...` بـ Bearer API key).
- **مفاتيح API في Odoo (14+) لا تعمل مع `/web/session/authenticate`** — تعمل مع `/jsonrpc`/`/xmlrpc` و JSON-2 فقط. يعني لو هندخل "API key" لكل شركة، لازم نغيّر طريقة الاتصال.

**مشاكل في الطبقة الحالية:**
1. **بدون pagination**: `getProducts` بيجيب كل المنتجات مع صورها (base64) في طلب واحد؛ `productsPageSize = 80` (`app_constants.dart:8`) معرّف ومش مستخدم. كتالوج 5,000 منتج = طلب ضخم وبطء/انهيار.
2. **انتهاء جلسة Odoo غير معالج**: الـ cookie في الذاكرة؛ لو انتهت الجلسة أثناء الاستخدام، Odoo يرجع `error` فيتحول لـ `ServerException` عادي (`odoo_client.dart:124-131`) ومفيش re-login تلقائي.
3. **لا يوجد multi-company context**: لا يتم تمرير `allowed_company_ids`؛ لو Odoo الشركة فيه أكتر من res.company، المنتجات الظاهرة تعتمد على إعدادات المستخدم.
4. **لا يوجد لغة في الـ context**: أسماء المنتجات بترجع بلغة المستخدم الافتراضية، والترجمة للعربي بتتم بقاموس يدوي بدل `context: {lang: 'ar_001'}`.
5. `searchFromServer` في `products_cubit.dart:87` غير مستخدم — البحث كله محلي.

---

### 4. طبقة الطباعة

#### 4.1 الاتصال بالـ Xprinter
- المكتبة: **`print_bluetooth_thermal: ^1.1.9`** (`pubspec.yaml:30`) — Bluetooth Classic (SPP) على Android.
- `lib/core/services/bluetooth_printer_service.dart`:
  - يعرض **الأجهزة المقترنة مسبقًا فقط** (`pairedBluetooths`, سطر 23-25) — لا يوجد scan لأجهزة جديدة.
  - يحفظ MAC واسم آخر طابعة في `SharedPreferences` ويعمل auto-connect (`:74-92`).
  - الإرسال: محاولة one-shot ثم chunks بحجم 500 بايت مع delay 20ms (`:48-72`).
- الصلاحيات في `AndroidManifest.xml:2-7` (BLUETOOTH, CONNECT, SCAN, LOCATION).

#### 4.2 لغة الطباعة: **TSPL فقط**
- لا يوجد أي دعم لـ ESC/POS. الأوامر: `SIZE`, `GAP`, `SPEED`, `DENSITY`, `DIRECTION`, `REFERENCE`, `CODEPAGE UTF-8`, `CLS`, `BITMAP`, `BLOCK`, `PRINT` (`tspl_label_builder.dart:265-322`).
- يعني: يعمل مع موديلات Xprinter الخاصة بالليبل (TSPL) مثل XP-365B/XP-420B/P323B، **ولن يعمل مع طابعات Xprinter الإيصالات (ESC/POS فقط)**.

#### 4.3 أين يتم توليد الليبل؟ (يوجد **3 تصاميم منفصلة** للّيبل!)

| المسار | الملف | الاستخدام | الحالة |
|---|---|---|---|
| **أ. طباعة بلوتوث (الأساسي)** | `lib/core/utils/tspl_label_builder.dart` → `buildBarcodeLabel()` (سطر 91-325) | زر "طباعة فورية" | مستخدم |
| **ب. PDF للمشاركة** | `lib/features/printing/data/repos/printing_repo_impl.dart` → `generatePdfLabel()` | زر "مشاركة" (`Printing.sharePdf`) | مستخدم — **تصميم مختلف عن (أ)** |
| ج. Widget معاينة | `lib/features/printing/presentation/widgets/barcode_label_widget.dart` | — | **غير مستخدم** (ونسبته 4:6 ≠ 75:130) |
| كود ميت | `buildFromPdf`, `buildThermalPreviewFromPdf`, `_renderHeaderAsBitmap`, `_buildTsplBytes` في `tspl_label_builder.dart` | — | **غير مستخدم** |

**كيف يعمل `buildBarcodeLabel` فعليًا:**
1. كل عنصر (لوجو، اسم المنتج، المتغير، الباركود، "صنع في مصر") يُرسم **لوحده** كصفحة PDF صغيرة بمكتبة `pdf`، ثم يتحول لصورة raster بـ `Printing.raster` عند 203 DPI، ثم `copyResize`، ثم threshold لأبيض/أسود، ثم يُرسل كأمر TSPL `BITMAP` (السطور 451-733). يعني 5 عمليات PDF→raster لكل ليبل.
2. **الباركود نفسه مطبوع كصورة BITMAP** (`:301-307`) وليس بأمر TSPL `BARCODE` الأصلي — رغم إن التعليق في `bluetooth_printer_cubit.dart:77` يقول "native TSPL barcode commands". الصورة بعرض ثابت 240 dot ثم `copyResize` بـ `Interpolation.average` (`:662-668`) ⇒ **عرض الخطوط (module width) غير صحيح كعدد صحيح من الـ dots** ⇒ حواف رمادية تتحول بالـ threshold لخطوط غير متساوية ⇒ **خطر فشل القراءة بالماسح**، خصوصًا مع Code128 طويل.
3. الأرقام المقروءة تحت الباركود فقط هي نص TSPL أصلي (`BLOCK ... "3"`, سطر 310-313).
4. الخطوط العربية تُحمّل بـ `PdfGoogleFonts` (`:77-80`) = **تحميل من الإنترنت وقت التشغيل** (لو مفيش نت أول مرة، الطباعة تفشل أو تطلع بخط Helvetica بدون عربي).
5. `imageBase64` (صورة المنتج) بتتمرر في كل السلسلة (`printLabel`, `generateLabel`) **لكن لا تُستخدم إطلاقًا** في الرسم.
6. السعر (`list_price`) يُجلب ولا يُطبع.

#### 4.4 هل التصميم ثابت أم قابل للتعديل؟ ⚠️ (نقطة حرجة)
**ثابت تمامًا ومكتوب في الكود.** لا يوجد أي نموذج بيانات (model) للّيبل:
- ترتيب العناصر مكتوب كتسلسل أوامر (لوجو ← اسم ← متغير ← باركود ← أرقام ← صنع في مصر).
- المواضع محسوبة بمعادلات مترابطة (كل عنصر Y تبعه محسوب من اللي قبله + ثوابت سحرية مثل `28`, `82`, `188`, `280`, `0.045`, `0.24`, `0.58`, `0.54`).
- لا يمكن إخفاء عنصر أو تحريكه أو إضافة عنصر جديد بدون تعديل الكود.
- لا توجد معاينة حقيقية للّيبل قبل الطباعة الحرارية؛ شاشة التفاصيل تعرض باركود فقط (`product_details_screen.dart:150-175`)، والـ PDF المشارك تصميمه مختلف.

---

### 5. نظام الـ Login الحالي
- **الواجهة:** `login_screen.dart` + `login_form_widget.dart` — إيميل + باسورد مع validation "غير فارغ" فقط.
- **التحقق:** `AuthRepoImpl.login` (`auth_repo_impl.dart:20-45`) يرسل الإيميل والباسورد إلى **Odoo نفسه** (`/web/session/authenticate`) على URL وDB الثابتين. يعني **كل مستخدم للتطبيق لازم يكون مستخدم Odoo** في سيرفر وسيلة. لا يوجد backend خاص بالتطبيق.
- **التخزين:** بعد النجاح يحفظ **الإيميل والباسورد كنص صريح (plaintext)** في `SharedPreferences` (`auth_local_storage_service.dart:12-19`, المفاتيح `auth_username`, `auth_password`, `auth_is_logged_in`).
- **استعادة الجلسة:** في كل فتح للتطبيق، الـ splash يعيد تسجيل الدخول بالباسورد المحفوظ (`auth_repo_impl.dart:48-60`).
- **الخروج:** يمسح الـ uid والكوكيز والقيم المحفوظة (`:63-66`).
- لا يوجد: أدوار/صلاحيات، تغيير باسورد، نسيت الباسورد، أو ربط بشركة.

### 6. التخزين المحلي
| ماذا | الوسيلة | المكان |
|---|---|---|
| إيميل + **باسورد Odoo (نص صريح)** + علم "مسجّل" | `SharedPreferences` | `auth_local_storage_service.dart:6-8` |
| MAC واسم آخر طابعة | `SharedPreferences` | `bluetooth_printer_service.dart:13-14` |
| Session cookie لـ Odoo | `CookieJar()` **في الذاكرة فقط** (يضيع عند غلق التطبيق) | `odoo_client.dart:19` |
| خطوط PDF واللوجو | Cache static في الذاكرة | `tspl_label_builder.dart:23-28`, `printing_repo_impl.dart:12-17` |
| المنتجات | **لا يوجد cache** — كل فتح = تحميل كامل من Odoo | — |

لا يُستخدم `flutter_secure_storage` ولا قاعدة بيانات محلية.

---

## ثانيًا: التقييم

### 7. جاهزية الكود للتحويل Multi-Tenant

**نقاط قوة تساعدنا:**
- فصل `data/domain/presentation` وواجهات Repo موجود ⇒ سهل نستبدل التنفيذات.
- `OdooClient.authenticate` أصلًا بياخد `url` و`db` كبارامترات (`odoo_client.dart:30-35`) — الثابت فقط في `AuthRepoImpl`.
- Cubit + GetIt نمط معروف وقابل للتوسع.
- منطق تحويل الصورة لـ mono bitmap ومحاذاة 8-dot وبناء أوامر TSPL سليم ويمكن إعادة استخدامه.

**أكبر العوائق المعمارية:**
1. **لا يوجد مفهوم "شركة/Tenant" في الكود إطلاقًا** — كل شيء (URL، الفئات، اللوجو، الألوان، الليبل) `static const`. لازم كيان `TenantConfig` يُحمّل وقت التشغيل ويُمرر لكل الطبقات.
2. **الهوية = مستخدم Odoo.** في الهدف الجديد الهوية = مستخدم Supabase، وOdoo مجرد مصدر بيانات. هذا تغيير جذري في `auth` feature بالكامل.
3. **الفئات بالكلمات المفتاحية** لا تصلح لأي شركة أخرى ⇒ لازم نتحول لـ `product.category` (`categ_id`) من Odoo.
4. **طبقة الليبل hardcoded بالكامل** (انظر 8).
5. **Static/Singletons** (`TsplLabelBuilder` static caches، `BluetoothPrinterService.instance`، `AppColors` const) ⇒ صعب تغييرها حسب الشركة وصعب اختبارها.
6. **الثيم const** (`AppColors`, `AppTheme.lightTheme` getter) ⇒ لا يمكن تغيير ألوان الشركة ديناميكيًا بدون refactor.

**ديون تقنية ستعطّلنا:**
| # | الدين | الأثر |
|---|---|---|
| 1 | باسورد بنص صريح في SharedPreferences | ثغرة أمنية لا تُقبل في SaaS |
| 2 | جلب كل المنتجات بدون pagination + صور base64 | بطء/انهيار مع كتالوجات كبيرة للعملاء |
| 3 | N+1 requests للمتغيرات | بطء في المنتجات كثيرة المتغيرات |
| 4 | 3 تصاميم ليبل متباينة + كود ميت ~400 سطر | ارتباك وصيانة مضاعفة |
| 5 | الباركود كصورة مع resize | خطر فشل المسح — مشكلة سمعة للمنتج |
| 6 | خطوط من الإنترنت وقت التشغيل | فشل الطباعة offline |
| 7 | لا يوجد اختبارات فعلية (اختبار واحد يبحث عن نص "تغليف وسيلة" بدون إعداد GetIt) | لا شبكة أمان للـ refactor |
| 8 | فلتر "منتجات بصور فقط" | عملاء جدد هيلاقوا منتجات مختفية |
| 9 | قاموس ترجمة خاص بالأثاث | لن يصلح للملابس/الأغذية |
| 10 | لا معالجة لانتهاء جلسة Odoo | أخطاء مبهمة للمستخدم |

### 8. تقييم محرر الليبل

**الخلاصة: لا يمكن بناء محرر مرن فوق `buildBarcodeLabel` الحالي — طبقة "تخطيط الليبل" محتاجة إعادة كتابة من الصفر، مع الاحتفاظ بالأجزاء منخفضة المستوى.**

**ما يُعاد استخدامه:**
- `BluetoothPrinterService` (مع تحسينات).
- `_imageToMonoBitmap`, `_compositeOnWhite`, `_centerBitmapX` (منطق المحاذاة 8-dot)، `_addCommand/_addRaw`، اكتشاف نوع الباركود والتحقق من checksum.

**ما يُستبدل:** كل منطق الـ layout والـ 5 دوال `_render*AsBitmap` و`PrintingRepoImpl` و`BarcodeLabelWidget`.

**المقاربة التقنية المقترحة:**

1. **نموذج بيانات للّيبل (Template JSON)** — يُحفظ في Supabase:
   ```json
   {
     "version": 1,
     "size": {"widthMm": 75, "heightMm": 130, "gapMm": 3},
     "printer": {"dpi": 203, "density": 8, "speed": 4, "language": "TSPL"},
     "elements": [
       {"id":"e1","type":"image","source":"company_logo","x":10,"y":5,"w":55,"h":18},
       {"id":"e2","type":"text","binding":"product.name","x":3,"y":28,"w":69,"h":12,"fontSize":11,"bold":true,"align":"center","maxLines":3,"dir":"auto"},
       {"id":"e3","type":"text","binding":"variant.attributes","x":3,"y":42,"w":69,"h":20},
       {"id":"e4","type":"barcode","binding":"product.barcode","symbology":"auto","x":7,"y":66,"w":60,"h":20,"humanReadable":true,"moduleDots":2},
       {"id":"e5","type":"text","binding":"product.price","format":"{value} ج.م"},
       {"id":"e6","type":"image","source":"product_image","x":20,"y":95,"w":35,"h":25,"dither":true},
       {"id":"e7","type":"text","static":"صُنع في مصر"}
     ]
   }
   ```
   المواضع بالمليمتر (مستقلة عن الـ DPI)؛ `binding` يربط بحقل من Odoo؛ `static` لنص ثابت.

2. **محرك رسم واحد (Renderer) لكل من المعاينة والطباعة** — مبدأ "ما تراه هو ما يُطبع":
   - رسم الليبل كامل على **Flutter `Canvas` (`dart:ui` `PictureRecorder`)** عند دقة الطابعة الفعلية (203/300 DPI). Flutter يدعم تشكيل العربي (shaping) وRTL أصلًا بدون حيلة PDF، وأسرع بكثير من 5 عمليات PDF→raster.
   - المعاينة = نفس الصورة بعد threshold/dithering (أبيض/أسود) ⇒ المستخدم يشوف بالظبط ما سيخرج من الطابعة.
   - صورة المنتج: تُحمّل `image_512` من Odoo وتُحوّل بـ **dithering (Floyd–Steinberg)** بدل threshold عشان تطلع مقبولة على طابعة حرارية.

3. **الباركود: أمر طابعة أصلي (Native) وليس صورة** — هذا أهم قرار للجودة:
   - TSPL: `BARCODE x,y,"128",height,human,0,narrow,wide,"DATA"` و `"EAN13"`. الطابعة ترسم الخطوط بعرض dots صحيح ⇒ قراءة مضمونة.
   - في المعاينة يُرسم الباركود بمكتبة `barcode` بنفس عرض الـ module (عدد صحيح من الـ dots) لمحاكاة الناتج.
   - بديل لو احتجنا raster (مثلًا ESC/POS): نرسم الباركود يدويًا بعرض module = عدد صحيح من الـ dots **بدون أي resize**.
   - المحرر يتحقق أن عرض الباركود يكفي (`modules × moduleDots`) ويحذّر لو صغير.

4. **طبقة Driver قابلة للتبديل:** `abstract class PrinterDriver { List<int> encode(RenderedLabel, PrintOptions); }` مع `TsplDriver` (الآن) و`EscPosRasterDriver` (`GS v 0`) لاحقًا، وربما `ZplDriver`. الـ RenderedLabel = bitmap للخلفية + قائمة عناصر native (باركود/نص).

5. **واجهة المحرر:** canvas بمقياس الليبل، سحب/تكبير العناصر (أو كبداية أبسط: قائمة عناصر بترتيب + تشغيل/إخفاء + خصائص)، قوالب جاهزة حسب التخصص (أثاث/ملابس/أغذية)، ومعاينة حية بمنتج حقيقي من Odoo.

**توصية التنفيذ على مرحلتين:** (أ) محرك + قالب افتراضي يطابق ليبل وسيلة الحالي (لضمان عدم الكسر)، ثم (ب) المحرر المرئي.

---

## ثالثًا: خطة التنفيذ المرحلية

> **قاعدة عامة لكل المراحل:** تطبيق وسيلة يجب أن يبقى شغالًا في نهاية كل مرحلة. وسيلة = **Tenant رقم 1** وكل اختبار يدوي يتم على حسابها.

### المرحلة 0 — شبكة الأمان والتنظيف (صغيرة)
- **الهدف:** نقدر نغيّر بثقة.
- **الملفات:** `test/`, `analysis_options.yaml`, `.github/workflows/` (جديد), `lib/core/utils/tspl_label_builder.dart`, `barcode_label_widget.dart`.
- **التعديلات:**
  - CI: `flutter analyze` + `flutter test` على كل PR.
  - إصلاح `widget_test.dart` (إعداد GetIt بـ mocks).
  - **Snapshot test** لمخرجات `TsplLabelBuilder.buildBarcodeLabel` لمنتج ثابت (حفظ البايتات أو الصورة الناتجة) — المرجع اللي هنقارن بيه بعد إعادة الكتابة.
  - Unit tests لـ `ProductModel.fromOdoo`, `BarcodeHelper`, `ProductCategory.matchesProduct`.
  - حذف الكود الميت (`buildFromPdf`, `buildThermalPreviewFromPdf`, `_renderHeaderAsBitmap`, `_buildTsplBytes`, `BarcodeLabelWidget`, `searchFromServer` أو تفعيله).
  - **تضمين الخطوط العربية كـ assets** بدل `PdfGoogleFonts`.
- **Supabase/Odoo:** لا دور.
- **التحقق:** طباعة يدوية لـ 3 منتجات (بدون متغير، بمتغير، EAN13) ومقارنتها بطباعة قبل التعديل + مسحها بالماسح.

### المرحلة 1 — فصل قيم Wasilaah لطبقة إعدادات ديناميكية (متوسطة)
- **الهدف:** لا يوجد أي قيمة خاصة بوسيلة في الكود؛ كلها تُقرأ وقت التشغيل من `TenantConfig`.
- **الملفات:** `core/constants/app_constants.dart`, `product_categories.dart`, `label_dimensions.dart`, `core/theme/*`, `main.dart`, `auth_repo_impl.dart`, `login_screen.dart`, `splash_screen.dart`, `products_cubit.dart`, `category_filter_widget.dart`, `attribute_translator.dart`, `tspl_label_builder.dart`, `service_locator.dart` + جديد `lib/core/tenant/`.
- **التعديلات:**
  - كيان `TenantConfig { companyName, appDisplayName, odooUrl, odooDb, branding{logo, primaryColor, secondaryColor}, categories[], labelSettings{size, gap, density, madeInText/Image}, translationOverrides }`.
  - `TenantConfigRepository` بمصدرين: `LocalTenantConfigSource` (ملف JSON في assets بقيم وسيلة الحالية بالظبط — مؤقت) ثم `SupabaseTenantConfigSource` في المرحلة 3.
  - `TenantCubit` عام فوق `MaterialApp` — الثيم يُبنى من الألوان (`AppTheme.build(TenantBranding)`).
  - الفئات تصبح قائمة بيانات (`List<CategoryDef>`) بدل `static const` — نبقي آلية الكلمات المفتاحية كوضع "legacy" لوسيلة فقط.
  - `TsplLabelBuilder` يأخذ اللوجو والمقاس من الـ config بدل الثوابت؛ حذف `'Walnut shoe storage bench'`.
  - إعادة تسمية `WasilaahApp` → `BarcodeFlowApp`. (تغيير Bundle ID مؤجل لقرار — انظر الأسئلة).
- **Supabase/Odoo:** لا يوجد بعد؛ Odoo كما هو.
- **التحقق:** Snapshot test من المرحلة 0 لازم يطلع نفس النتيجة؛ grep على `wasila|1B5E20|erp.wasilaahteam` في `lib/` يرجع صفر نتائج (ما عدا ملف الإعدادات الافتراضي).

### المرحلة 2 — إعادة بناء طبقة Odoo (متوسطة)
- **الهدف:** عميل Odoo عام يعمل مع أي سيرفر/إصدار، بكفاءة.
- **الملفات:** `core/network/odoo_client.dart`, `core/constants/api_constants.dart`, `features/products/data/*`, `features/products/domain/*`, `products_cubit.dart` + جديد `features/categories/`.
- **التعديلات:**
  - واجهة `OdooGateway` في التطبيق بتنفيذين: `DirectOdooGateway` (**مؤقت للانتقال فقط** — لوسيلة لحد ما المرحلة 3 تخلص، ثم يُحذف) و`ProxyOdooGateway` (عبر Supabase Edge Function — **المسار الوحيد في المنتج النهائي، قرار D1**).
  - منطق الاتصال الفعلي بـ Odoo يُكتب بحيث ينتقل للـ Edge Function: **adapter حسب الإصدار** — `/jsonrpc` (`execute_kw`) بـ API key لـ 16–18، و**JSON-2** (Bearer API key) لـ 19+ (قرار D2).
  - `testConnection()`: يقرأ `/web/webclient/version_info` (إصدار Odoo) ويرفض الإصدارات الأقدم من 16 برسالة واضحة + يتحقق من DB والمستخدم والصلاحية على `product.template`.
  - جلب الفئات من `product.category` (`id, name, complete_name, parent_id`)، والفلترة بـ `categ_id child_of [ids]` على السيرفر.
  - **Pagination** (`limit/offset` + infinite scroll) والبحث على السيرفر (`name/barcode/default_code ilike`).
  - الصور: `image_128` في القائمة فقط، و`image_512` عند الطباعة بطلب منفصل.
  - دمج قراءة قيم المتغيرات في طلب واحد (كل الـ ids مرة واحدة) بدل N+1.
  - تمرير `context: {lang, allowed_company_ids}`.
  - معالجة `Session expired` (كود الخطأ 100) بإعادة مصادقة تلقائية.
  - جعل فلتر "منتجات بصور فقط" إعدادًا اختياريًا.
  - حقل الباركود المطبوع إعداد لكل شركة (قرار D3): `barcode` · `default_code` · **`barcode` ثم `default_code` (افتراضي)**. زر الطباعة يتقفل فقط لو الحقلين فاضيين.
  - تحقق من صلاحية الباركود قبل الطباعة: EAN-13/EAN-8 بـ checksum غلط ⇒ تحذير، وأي قيمة فيها حروف ⇒ Code128.
- **Supabase:** لا شيء بعد. **Odoo:** مصدر المنتجات/الفئات.
- **التحقق:** **مصفوفة اختبار آلية على Odoo تجريبي (Docker) للإصدارات 16 و17 و18 و19** (Community على الأقل) + إصدار وسيلة الفعلي؛ مقارنة عدد منتجات وسيلة قبل/بعد.

### المرحلة 3 — Supabase Auth + تسجيل شركة + ربط Odoo + التخصص والفئات (كبيرة)
- **الهدف:** أي شركة تسجل وتربط Odoo الخاص بيها وتبدأ تطبع.
- **الملفات:** `features/auth/*` (إعادة كتابة)، جديد `features/onboarding/`, `features/company/`, `core/supabase/`, `supabase/migrations/`, `supabase/functions/odoo-proxy/`, `splash_screen.dart`, `app_routes.dart`, `service_locator.dart`, `pubspec.yaml` (`supabase_flutter`, `flutter_secure_storage`).
- **مخطط قاعدة البيانات (مبدئي):**
  - `companies (id, name, industry, logo_path, branding jsonb, created_by, created_at)`
  - `company_members (company_id, user_id, role: owner|admin|member, status, created_at)` — PK مركّب.
  - `odoo_connections (company_id PK, base_url, database, login, auth_type, secret_id → Vault, odoo_version, last_tested_at, status)`
  - `company_settings (company_id, selected_category_ids int[], barcode_field, show_only_with_image, default_template_id)`
  - `industries` (جدول مرجعي: أثاث/ملابس/أغذية...) مع قوالب ليبل افتراضية لكل تخصص.
  - **RLS** على كل جدول بدالة `is_member(company_id)` / `has_role(company_id, 'admin')` (security definer)، والسر نفسه **لا يُقرأ من العميل أبدًا**.
- **التعديلات:**
  - تسجيل/دخول بالإيميل (+ تأكيد الإيميل + نسيت الباسورد) عبر Supabase Auth.
  - Onboarding wizard: (1) بيانات الشركة → (2) URL + DB + login + API key → زر **"اختبار الاتصال"** (عبر Edge Function) → (3) اختيار التخصص → (4) شجرة فئات Odoo مع checkboxes → (5) رفع اللوجو (Supabase Storage).
  - **Edge Function `odoo-proxy`** (قرار D1 — المسار الوحيد للوصول لـ Odoo): يتحقق من JWT والعضوية **وحالة الاشتراك**، يقرأ السر من Vault، يختار الـ adapter حسب `odoo_version` المحفوظ، ينفذ **قائمة بيضاء من العمليات** (`search_read`/`read` على `product.template`, `product.product`, `product.category`, `product.template.attribute.value` فقط)، يحمي من SSRF، ويطبّق rate limiting لكل شركة.
  - الصور: قائمة المنتجات تطلب `image_128` فقط، والتطبيق يعمل cache للصور على الجهاز لتقليل الزمن الإضافي للـ proxy (المتوقع ~100–300ms لكل طلب).
  - دليل داخل الـ onboarding لإنشاء **مستخدم Odoo مخصص بصلاحية قراءة المنتجات فقط** وتوليد API key له.
  - إزالة تخزين باسورد Odoo من الجهاز نهائيًا؛ جلسة Supabase في `flutter_secure_storage`.
  - **ترحيل وسيلة:** إنشاء شركة وسيلة في Supabase بنفس الإعدادات + فئات Odoo المقابلة لفئات الكلمات المفتاحية الحالية.
- **Supabase:** Auth + DB + Vault + Storage + Edge Functions. **Odoo:** يُستدعى عبر الـ proxy فقط.
- **التحقق:** اختبارات RLS آلية (pgTAP أو سكريبت): مستخدم شركة A لا يرى أي صف من شركة B، ولا يستطيع استدعاء الـ proxy لشركة B. Feature flag للتبديل بين المسار القديم والجديد لوسيلة لحد ما يتأكد.

### المرحلة 4 — إدارة الفريق (حتى 5 مستخدمين) + الصلاحيات (متوسطة)
- **الهدف:** المالك يدعو حتى 5 إيميلات لنفس الشركة.
- **الملفات:** جديد `features/team/`, `supabase/migrations/`, `supabase/functions/invite-member/`.
- **التعديلات:**
  - جدول `invitations (id, company_id, email, role, token_hash, expires_at, accepted_at)`.
  - Edge Function للدعوة (`auth.admin.inviteUserByEmail` أو magic link) + قبول الدعوة يربط المستخدم بالشركة.
  - **فرض الحد على السيرفر**: trigger على `company_members` يرفض الإدراج لو العدد ≥ `plan.max_seats` (5) — مش في التطبيق فقط.
  - الأدوار: `owner` (كل شيء + الاشتراك)، `admin` (Odoo + القوالب + الفريق)، `member` (طباعة فقط).
  - شاشة الفريق: قائمة الأعضاء، دعوة، إلغاء دعوة، إزالة عضو، تغيير دور.
  - مستخدم = شركة واحدة في البداية (تبسيط) — انظر الأسئلة.
- **التحقق:** اختبار محاولة إضافة العضو السادس (يجب أن يفشل من السيرفر)، وعضو `member` لا يستطيع تعديل إعدادات Odoo (RLS).

### المرحلة 5 — محرك الليبل الجديد + المحرر + المعاينة (كبيرة — الأكبر)
- **الهدف:** ليبل قابل للتخصيص بالكامل، معاينة مطابقة للطباعة، باركود مضمون القراءة.
- **الملفات:** جديد `features/label_designer/` (`domain/label_template.dart`, `domain/label_element.dart`, `data/label_templates_repo.dart`, `presentation/editor/*`)، جديد `core/printing/` (`label_renderer.dart`, `drivers/tspl_driver.dart`, `drivers/escpos_driver.dart`)، حذف/استبدال `tspl_label_builder.dart`, `printing_repo_impl.dart`, `print_action_dialog_widget.dart` (تعديل).
- **التعديلات:**
  - 5أ: نموذج `LabelTemplate` (JSON versioned) + `LabelRenderer` على Flutter Canvas + `TsplDriver` بباركود native + قالب "Wasilaah Classic" يطابق الحالي. **شاشة معاينة قبل كل طباعة.**
  - الـ renderer يعمل بالمليمتر ويحوّل لـ dots حسب دقة الطابعة: **203 DPI (افتراضي) و300 DPI** (قرار D4). عرض الـ module في الباركود يُحسب كعدد صحيح من الـ dots لكل دقة.
  - 5ب: المحرر: إضافة/حذف/ترتيب/تحريك العناصر (اسم، متغير، باركود، SKU، سعر، نص ثابت، لوجو الشركة، صورة المنتج، خط فاصل)، خصائص (حجم خط، محاذاة، bold، أسطر قصوى)، معاينة حية بمنتج حقيقي.
  - **مقاسات جاهزة** (قرار D4): 40×30 · 50×25 · 50×30 (ملابس/إكسسوارات) · 58×40 · 60×40 (منتجات عامة/أغذية) · 100×50 · 100×150 = 4×6 (كراتين/شحن) · 75×130 (وسيلة) · **مقاس مخصّص**. المحرر يحذّر لو العناصر خرجت عن حدود الليبل أو لو الباركود أصغر من الحد الأدنى للقراءة على الدقة المختارة.
  - مشاركة PDF تُولّد من **نفس الـ renderer** (إلغاء التصميم الثاني).
  - جدول `label_templates (id, company_id, name, schema_version, definition jsonb, is_default, updated_by)` + RLS.
  - قوالب افتراضية لكل تخصص.
- **Supabase:** حفظ القوالب + الأصول (لوجو/صور ثابتة) في Storage. **Odoo:** بيانات المنتج + `image_512` لصورة المنتج + السعر.
- **التحقق:** golden tests لصور الـ renderer؛ مقارنة مع snapshot المرحلة 0؛ **اختبار مسح فعلي** لعينة باركودات (Code128 قصير/طويل، EAN13، EAN8) على 203 و300 DPI بماسح يدوي وكاميرا موبايل.

### المرحلة 6 — تحسينات الطباعة: كمية، طابور، سجل، **طباعة WiFi/LAN** (متوسطة–كبيرة)
- **الهدف:** طباعة موثوقة على دفعات مع تتبع، وطريقة اتصال ثانية بالشبكة (قرار D5).
- **الملفات:** `core/services/bluetooth_printer_service.dart`, جديد `core/printing/transports/` (`printer_transport.dart`, `bluetooth_transport.dart`, `network_transport.dart`), جديد `features/printing/domain/print_queue.dart`, `features/print_history/`, `bluetooth_printer_cubit.dart` (يتحول لـ `PrinterCubit` عام).
- **التعديلات:**
  - **طبقة Transport منفصلة عن الـ Driver**: `abstract class PrinterTransport { connect(); write(bytes); disconnect(); status; }` بتنفيذين:
    - `BluetoothClassicTransport` (المكتبة الحالية).
    - **`NetworkTransport`**: اتصال TCP خام على **منفذ 9100** لطابعات الليبل اللي فيها كارت شبكة/WiFi — إدخال IP يدويًا + محاولة اكتشاف تلقائي على الشبكة المحلية + اختبار اتصال. نفس أوامر TSPL بالظبط، فمفيش تغيير في المحرك.
  - **ملف الطابعة (Printer Profile)** لكل طابعة محفوظة: الاسم، طريقة الاتصال (BT/WiFi) والعنوان، اللغة (TSPL)، **الدقة 203/300**، الكثافة، السرعة، الـ gap، معايرة الـ offset (قرار D4). طابعة مشتركة بالشبكة ممكن تتحفظ على مستوى الشركة في Supabase عشان كل الفريق يلاقيها.
  - طابور طباعة (Queue) محلي: عدة منتجات بكميات مختلفة، إيقاف/استئناف/إلغاء، إعادة المحاولة عند انقطاع الاتصال.
  - الكمية عبر `PRINT n` (أسرع من تكرار الإرسال) مع حد معقول.
  - أمر `SELFTEST`/طباعة ليبل اختبار من شاشة الطابعة.
  - scan لأجهزة بلوتوث غير مقترنة.
  - جدول `print_jobs (id, company_id, user_id, product_ref, barcode, template_id, quantity, status, printer_name, created_at)` — يُرفع على دفعات (يعمل offline ويُزامن لاحقًا).
  - شاشة سجل الطباعة + إعادة طباعة.
- **التحقق:** طباعة 50 ليبل متتالي بدون فقد **على البلوتوث وعلى WiFi**؛ فصل الاتصال في المنتصف والتأكد من الاستئناف؛ نفس الليبل يطلع متطابق بالطريقتين وعلى 203 و300 DPI.

### المرحلة 7 — بنية نظام الاشتراك (بدون دفع) (صغيرة–متوسطة)
- **الهدف:** تجهيز البنية بحيث إضافة بوابة الدفع لاحقًا لا تغير المعمارية.
- **الملفات:** `supabase/migrations/`, جديد `features/subscription/`, `core/entitlements/`.
- **التعديلات:**
  - `plans (id, name, max_seats, max_templates, max_prints_per_month, features jsonb)`
  - `subscriptions (company_id, plan_id, status: trialing|active|past_due|canceled, trial_ends_at, current_period_end, provider, provider_ref)`
  - دالة `company_entitlements(company_id)` تُستخدم في RLS والـ triggers (مثل حد المقاعد) وفي الـ Edge Function (رفض الـ proxy لو الاشتراك منتهي).
  - `EntitlementsCubit` في التطبيق لإخفاء/قفل المزايا + شاشة "خطتك".
  - فترة تجريبية تلقائية عند تسجيل الشركة. التفعيل يدويًا من لوحة Supabase حاليًا.
- **التحقق:** شركة بحالة `canceled` لا تستطيع جلب المنتجات (من السيرفر وليس الواجهة فقط).

### المرحلة 8 — التقوية والإطلاق على Android (متوسطة)
- اسم التطبيق النهائي وBundle ID وأيقونة محايدة، دعم الإنجليزية (`intl`/ARB)، Crash reporting (Sentry/Crashlytics)، مراقبة أخطاء وزمن الـ proxy، cache محلي للمنتجات (اختياري)، سياسة خصوصية، اختبار على أجهزة Android متعددة (بما فيها أجهزة اقتصادية) وطابعات Xprinter متعددة بالبلوتوث والـ WiFi.
- **قائمة "طابعات معتمدة"** منشورة للعملاء (موديلات اتجربت فعلًا مع الدقة وطريقة الاتصال).
- **الإطلاق على Google Play فقط** (قرار D5).

### المرحلة 9 — iPhone ولوحة الويب (بعد الإطلاق) (متوسطة)
- **iOS:** الطباعة عبر `NetworkTransport` (WiFi) تعمل مباشرة لأنها مش محتاجة بلوتوث. إضافة `BleTransport` لموديلات طابعات تدعم BLE بعد اختبارها وإضافتها لقائمة الطابعات المعتمدة. البلوتوث الكلاسيكي غير مدعوم على iOS (يتطلب MFi).
- **لوحة ويب للمدير (Flutter Web):** إعداد اتصال Odoo، إدارة الفريق، محرر الليبل على شاشة كبيرة، سجل الطباعة. الطباعة نفسها تفضل من الموبايل.
- لا يحتاج تغيير في Supabase أو الـ proxy — كل المنطق موجود على السيرفر من المرحلة 3.

**ملخص الترتيب والحجم:**

| # | المرحلة | الحجم | يعتمد على |
|---|---|---|---|
| 0 | شبكة الأمان والتنظيف | صغيرة | — |
| 1 | فصل إعدادات وسيلة | متوسطة | 0 |
| 2 | طبقة Odoo عامة | متوسطة | 1 |
| 3 | Supabase + Onboarding + Proxy | كبيرة | 2 |
| 4 | الفريق والصلاحيات | متوسطة | 3 |
| 5 | محرك + محرر الليبل | كبيرة | 1 (المحرك) · 3 (حفظ القوالب) |
| 6 | تحسينات الطباعة + WiFi/LAN | متوسطة–كبيرة | 5 |
| 7 | بنية الاشتراك | صغيرة–متوسطة | 4 |
| 8 | التقوية والإطلاق على Android | متوسطة | 0–7 |
| 9 | iPhone + لوحة الويب | متوسطة | 8 |

> ملاحظة: **5أ (المحرك + الباركود native)** يمكن البدء فيه بالتوازي مع المرحلة 2–3 لأنه مستقل، وهو يحل مشكلة جودة قائمة اليوم عند وسيلة.

---

## رابعًا

### 10. أسئلة محتاجة توضيح

**تم حسمها (انظر جدول القرارات أعلى التقرير):**
- ~~الاتصال المباشر بـ Odoo مقابل الـ Proxy~~ ⇒ **D1: عبر Supabase Edge Function.**
- ~~إصدارات Odoo المستهدفة والمنصات (Online/Odoo.sh/self-hosted، Community/Enterprise)~~ ⇒ **D2: 16–19، كل المنصات والنسختين.** (المتبقي: إصدار وسيلة الفعلي — انظر السؤال 2.)
- ~~الباركود أم الـ SKU~~ ⇒ **D3: إعداد لكل شركة، الافتراضي barcode ثم SKU.**
- ~~مقاس الليبل ودقة الطابعات~~ ⇒ **D4: 203 و300 DPI + قوالب مقاسات جاهزة + مخصّص.** (المتبقي: المقاسات اللي وسيلة بتستخدمها فعلًا غير 75×130، لعمل قوالبها.)
- ~~دعم iOS~~ ⇒ **D5: Android في الإطلاق + WiFi/LAN؛ iOS في المرحلة 9.**

**ما زالت مفتوحة:**

1. ~~(تم حسمه — D1)~~
2. **إصدار Odoo عند وسيلة:** مطلوب لبدء مصفوفة الاختبار (يُعرف من `/web/webclient/version_info`).
3. **الفئات:** هل منتجات وسيلة في Odoo مصنفة فعلًا بـ `categ_id` بشكل يطابق الفئات الحالية (جزامات، مكاتب...)؟ الكود الحالي يعتمد على كلمات في الاسم، وهذا يوحي إن التصنيف في Odoo غير مرتب. وأي حقل فئة نعتمد: `categ_id` (المخزون) أم `public_categ_ids` (المتجر) أم `pos_categ_ids`؟
4. ~~(تم حسمه — D3)~~
5. **فلتر "المنتجات اللي ليها صورة فقط"** (`products_repo_impl.dart:24`): مقصود؟ (منتجات بدون صورة مخفية تمامًا حاليًا.)
6. **مقاسات وسيلة الفعلية:** الحالي 75×130mm، لكن تاريخ الـ commits يذكر 40×30 و 4×6. هل وسيلة بتستخدم أكتر من مقاس؟ (الدقة والمقاسات العامة اتحسمت في D4.)
7. **موديلات الطابعات:** هل كل العملاء المستهدفين عندهم طابعات ليبل تدعم TSPL، أم نحتاج ESC/POS (طابعات إيصالات) من البداية؟ وأي موديلات Xprinter عندكم (وهل فيها WiFi/LAN) عشان نبدأ بيها قائمة الطابعات المعتمدة؟
8. ~~(تم حسمه — D5)~~
9. **"صُنع في مصر":** حاليًا صورة (`made_in_egypt.jpeg`) وليس نص. نحوله لعنصر نص ثابت في المحرر، أم نسمح برفع صور ثابتة (شارات/أيقونات) كعنصر مستقل؟
10. **السعر:** أي سعر يُطبع؟ `list_price` للقالب أم `lst_price` للمتغير (يشمل extra price) أم سعر من Pricelist؟ شامل الضريبة؟ وبأي عملة؟
11. **أسماء المتغيرات بالعربي:** حاليًا تترجم بقاموس يدوي للأثاث. هل الترجمات العربية موجودة داخل Odoo (`ar_001`) عشان نعتمد عليها بدل القاموس؟
12. **الـ 5 مستخدمين:** هل يشملوا صاحب الحساب (المالك + 4) أم 5 بالإضافة للمالك؟ وهل ممكن مستخدم واحد ينتمي لأكثر من شركة؟
13. **الهوية والتسمية:** ما اسم المنتج الجديد؟ هل نغير Bundle ID الحالي (`com.example.wasilaah_finishing`) — ده يعني تطبيق جديد في المتجر ومستخدمي وسيلة يعيدوا التثبيت — أم نطلق تطبيقًا جديدًا ونترك تطبيق وسيلة القديم؟
14. **العمل بدون إنترنت:** هل مطلوب الطباعة offline (cache للمنتجات على الجهاز)؟
15. **زر "مشاركة PDF":** هل يُستخدم فعلًا؟ تصميمه الحالي مختلف عن المطبوع.
16. **الكمية القصوى:** حاليًا 999 (`quantity_selector_widget.dart:16`) — مناسب؟
17. **Odoo متعدد الشركات (multi-company):** لو Odoo العميل فيه أكتر من `res.company`، هل نسمح باختيار شركة Odoo محددة؟
18. ~~المنصات~~ ⇒ تم حسمه في D5 (Android أولًا، ثم iOS ولوحة ويب في المرحلة 9). مجلدات desktop (windows/linux/macos) يمكن حذفها من المشروع لتقليل الصيانة — محتاج تأكيد.

### 11. مخاطر وتحذيرات

**أمان بيانات اعتماد Odoo:**
1. **الوضع الحالي فيه ثغرة قائمة:** باسورد Odoo محفوظ نص صريح في `SharedPreferences` (`auth_local_storage_service.dart:17`). على جهاز rooted أو عبر backup يمكن قراءته. يجب إصلاحها حتى قبل الـ SaaS (`flutter_secure_storage` كحد أدنى).
2. **مفتاح API لكل شركة = مفتاح كامل لنظام ERP العميل.** لو اتسرّب، المهاجم يقدر يقرأ/يعدّل مبيعات ومحاسبة وعملاء. لذلك:
   - تخزين المفتاح مشفرًا في **Supabase Vault**، وعدم إرجاعه للتطبيق أبدًا بعد الحفظ (write-only).
   - استخدامه **فقط داخل Edge Function** بقائمة بيضاء لعمليات القراءة على موديلات المنتجات.
   - **إلزام العميل (أو نصحه بقوة) بإنشاء مستخدم Odoo مخصص بصلاحية قراءة المنتجات فقط** — نوفر دليلًا خطوة بخطوة.
   - تسجيل كل استدعاء للـ proxy (audit log) ودعم تدوير/إلغاء المفتاح.
3. **`service_role` key لـ Supabase لا يوضع في التطبيق أبدًا** — فقط `anon key` + RLS.
4. **SSRF:** الـ Edge Function ستتصل بـ URL يدخله العميل ⇒ يجب منع العناوين الداخلية/الخاصة (localhost, 10.x, 169.254.x...)، وفرض HTTPS، ومهلة زمنية وحد لحجم الرد.
5. بقرار D1 (الـ proxy) اتشال خطر وجود المفتاح على الأجهزة. **الخطر الجديد:** الـ Edge Function أصبحت نقطة مركزية — لو وقعت، كل العملاء يقفوا عن الطباعة، ولو فيها ثغرة، كل المفاتيح في خطر. التخفيف: مراقبة وتنبيهات على الأخطاء والزمن، code review إلزامي لأي تعديل فيها، أقل صلاحيات ممكنة للدالة على Vault، واختبارات آلية للقائمة البيضاء.
5ب. **مسار `DirectOdooGateway` المؤقت** (المرحلة 2) لازم يُحذف فعلًا بعد ترحيل وسيلة للـ proxy، وإلا يفضل باب خلفي يتجاوز الاشتراك والـ RLS.

**عزل بيانات الشركات:**
6. **RLS هو خط الدفاع الوحيد** بين الشركات — أي جدول بدون RLS أو بسياسة خاطئة = تسريب بين العملاء. يجب: تفعيل RLS افتراضيًا على كل جدول، اختبارات آلية للعزل في CI، ومراجعة كل migration.
7. فرض القيود (حد 5 مستخدمين، حالة الاشتراك، الأدوار) **على السيرفر** (triggers/RLS/Edge Functions) وليس في التطبيق فقط — التطبيق يمكن التلاعب به.
8. **تسريب عبر الكاش المحلي:** عند تسجيل الخروج أو تبديل الشركة يجب مسح كل الكاش (المنتجات، الصور، القوالب، الكوكيز، `TsplLabelBuilder` static caches حاليًا) — وإلا يظهر لوجو/منتجات شركة لمستخدم شركة أخرى على نفس الجهاز.
9. ملفات Storage (اللوجوهات/الصور) يجب أن تكون في buckets خاصة بمسارات `company_id/...` وسياسات Storage RLS، وليس public.

**مخاطر تقنية وتشغيلية:**
10. **جودة الباركود:** الطريقة الحالية (باركود كصورة + resize) قد تنتج ليبلات لا تُقرأ — مع عملاء متعددين هذا يتحول لمشكلة دعم فني وسمعة. أولوية عالية في المرحلة 5.
11. **أداء Odoo العملاء:** كتالوجات كبيرة + جلب بدون pagination قد يبطّئ سيرفر Odoo العميل نفسه ⇒ pagination + rate limiting إلزامي.
12. **تباين إصدارات Odoo:** أسماء الحقول والـ endpoints تختلف بين الإصدارات (مثلًا JSON-2 في 19، وإعلان Odoo عن إيقاف `/jsonrpc` و`/xmlrpc` مستقبلًا) ⇒ طبقة adapter حسب الإصدار + مصفوفة اختبار.
13. **تعدد موديلات الطابعات:** TSPL فقط حاليًا؛ عميل بطابعة ESC/POS لن يطبع ⇒ قائمة "طابعات معتمدة" منشورة قبل البيع (المرحلة 8).
13ب. **الطباعة بالشبكة (WiFi/LAN):** الطابعة لازم تكون على نفس الشبكة مع الموبايل، وعنوان الـ IP ممكن يتغير (DHCP) ⇒ ننصح العميل بـ IP ثابت للطابعة، ونوفر اكتشاف تلقائي ورسائل خطأ واضحة. المنفذ 9100 مافيهوش تشفير ولا مصادقة، فهو مناسب للشبكة الداخلية فقط.
14. **الخطوط من الإنترنت:** فشل الطباعة offline أو في شبكات مقيدة — حلها في المرحلة 0.
15. **كسر تطبيق وسيلة الحالي أثناء التحويل:** التخفيف عبر feature flags، snapshot tests، والإبقاء على وسيلة كـ tenant أول يُختبر عليه كل إصدار.

---

## الخلاصة

الكود الحالي **قاعدة صحية متوسطة** — مش محتاج إعادة كتابة كاملة، لكن محتاج إعادة هيكلة موجّهة في 3 مناطق.
**الجيد:** هيكل Clean Architecture لكل feature، Cubit + GetIt، عميل Odoo بسيط وقابل للتعميم، ومنطق TSPL/bitmap منخفض المستوى سليم وقابل لإعادة الاستخدام.
**يحتاج refactor متوسط:** كل قيم وسيلة `static const` (URL، الاسم، الألوان، اللوجو، الفئات بالكلمات المفتاحية) ← طبقة `TenantConfig`؛ وطبقة Odoo (pagination، فئات حقيقية، API key، proxy).
**يحتاج إعادة كتابة:** (1) نظام الدخول — الهوية تنتقل من Odoo إلى Supabase، مع إزالة الباسورد المخزن نص صريح؛ (2) طبقة توليد الليبل — مكتوبة hardcoded بالكامل، وفيها 3 تصاميم متباينة، والباركود مطبوع كصورة معدلة الحجم ⇒ تُستبدل بنموذج قالب JSON + renderer واحد للمعاينة والطباعة + باركود TSPL أصلي.
بعد القرارات D1–D5، الاتجاه: **Supabase كوسيط وحيد لـ Odoo (16–19)، والباركود مع الـ SKU كبديل حسب إعداد الشركة، و203/300 DPI بقوالب جاهزة، والإطلاق على Android بالبلوتوث والـ WiFi، وiPhone ولوحة الويب بعد الإطلاق.**
التقدير الإجمالي: حوالي **40% من الكود يبقى كما هو أو بتعديل بسيط**، و**35% refactor**، و**25% إعادة كتابة** (auth + الليبل)، بالإضافة لبناء كامل لطبقة Supabase (الشركات، الفريق، RLS، الـ proxy، الاشتراك).
