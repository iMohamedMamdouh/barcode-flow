import 'package:get_it/get_it.dart';

import '../../features/products/data/repos/products_repo_impl.dart';
import '../../features/products/domain/repos/products_repo.dart';
import '../../features/printing/data/repos/printing_repo_impl.dart';
import '../../features/printing/domain/repos/printing_repo.dart';
import '../network/odoo_client.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<OdooClient>(() => OdooClient());

  sl.registerLazySingleton<ProductsRepo>(
    () => ProductsRepoImpl(odooClient: sl<OdooClient>()),
  );
  sl.registerLazySingleton<PrintingRepo>(() => PrintingRepoImpl());
}
