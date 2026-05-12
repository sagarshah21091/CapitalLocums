import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Display names for the six locum document slots (PDF / Word / image).
class RegisterDocumentNames extends Notifier<List<String?>> {
  static const slotCount = 6;

  @override
  List<String?> build() => List<String?>.filled(slotCount, null);

  void setName(int index, String? name) {
    if (index < 0 || index >= state.length) return;
    state = [
      for (var i = 0; i < state.length; i++) i == index ? name : state[i],
    ];
  }

  void clearAll() {
    state = List<String?>.filled(slotCount, null);
  }
}

final registerDocumentNamesProvider =
    NotifierProvider<RegisterDocumentNames, List<String?>>(
  RegisterDocumentNames.new,
);
