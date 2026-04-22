import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/repos/auth_repo_impl.dart';
import '../../features/auth/domain/repos/auth_repo.dart';
import '../../features/products/data/repos/products_repo_impl.dart';
import '../../features/products/domain/repos/products_repo.dart';
import '../../features/printing/data/repos/printing_repo_impl.dart';
import '../../features/printing/domain/repos/printing_repo.dart';
import '../network/odoo_client.dart';
import '../services/auth_local_storage_service.dart';
import '../services/bluetooth_printer_service.dart';

final sl = GetIt.instance;

void setupServiceLocator({required SharedPreferences prefs}) {
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<OdooClient>(() => OdooClient());
  sl.registerLazySingleton<AuthLocalStorageService>(
    () => AuthLocalStorageService(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<AuthRepo>(
    () => AuthRepoImpl(
      odooClient: sl<OdooClient>(),
      localStorage: sl<AuthLocalStorageService>(),
    ),
  );

  sl.registerLazySingleton<ProductsRepo>(
    () => ProductsRepoImpl(odooClient: sl<OdooClient>()),
  );
  sl.registerLazySingleton<PrintingRepo>(() => PrintingRepoImpl());

  sl.registerLazySingleton<BluetoothPrinterService>(
    () => BluetoothPrinterService.instance,
  );
}
