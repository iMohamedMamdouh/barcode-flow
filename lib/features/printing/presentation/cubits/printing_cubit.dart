import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/repos/printing_repo.dart';
import 'printing_state.dart';

class PrintingCubit extends Cubit<PrintingState> {
  final PrintingRepo _printingRepo;

  PrintingCubit(this._printingRepo) : super(const PrintingInitial());

  Future<void> generateLabel({
    required String productName,
    required String barcode,
    String? sku,
    required int quantity,
    required LabelSize labelSize,
  }) async {
    emit(const PrintingGenerating());

    try {
      final pdfData = await _printingRepo.generatePdfLabel(
        companyName: AppConstants.appName,
        productName: productName,
        barcode: barcode,
        sku: sku,
        quantity: quantity,
        labelSize: labelSize,
      );
      emit(PrintingReady(pdfData));
    } catch (e) {
      emit(PrintingError('خطأ في إنشاء الملصق: $e'));
    }
  }

  void reset() {
    emit(const PrintingInitial());
  }
}
