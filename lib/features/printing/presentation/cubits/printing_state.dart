import 'dart:typed_data';

import 'package:equatable/equatable.dart';

abstract class PrintingState extends Equatable {
  const PrintingState();

  @override
  List<Object?> get props => [];
}

class PrintingInitial extends PrintingState {
  const PrintingInitial();
}

class PrintingGenerating extends PrintingState {
  const PrintingGenerating();
}

class PrintingReady extends PrintingState {
  final Uint8List pdfData;

  const PrintingReady(this.pdfData);

  @override
  List<Object?> get props => [pdfData];
}

class PrintingError extends PrintingState {
  final String message;

  const PrintingError(this.message);

  @override
  List<Object?> get props => [message];
}

class PrintingComplete extends PrintingState {
  const PrintingComplete();
}
