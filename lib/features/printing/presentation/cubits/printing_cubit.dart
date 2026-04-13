import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repos/printing_repo.dart';
import 'printing_state.dart';

class PrintingCubit extends Cubit<PrintingState> {
  final PrintingRepo _printingRepo;

  PrintingCubit(this._printingRepo) : super(const PrintingInitial());

  Future<void> generateLabel({
    required String productName,
    required String barcode,
    String? variantName,
    String? imageBase64,
    required int quantity,
  }) async {
    emit(const PrintingGenerating());

    try {
      final pdfData = await _printingRepo.generatePdfLabel(
        productName: productName,
        barcode: barcode,
        variantName: variantName,
        imageBase64: imageBase64,
        quantity: quantity,
      );
      if (isClosed) return;
      emit(PrintingReady(pdfData));
    } catch (e) {
      if (isClosed) return;
      emit(PrintingError('خطأ في إنشاء الملصق: $e'));
    }
  }

  void reset() {
    emit(const PrintingInitial());
  }
}
