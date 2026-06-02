import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Qualification certificate uploads (1–4 files required on registration).
class RegisterQualificationCerts extends Notifier<List<XFile>> {
  static const maxCount = 4;

  @override
  List<XFile> build() => [];

  bool add(XFile file) {
    if (state.length >= maxCount) return false;
    state = [...state, file];
    return true;
  }

  void removeAt(int index) {
    if (index < 0 || index >= state.length) return;
    state = [
      for (var i = 0; i < state.length; i++)
        if (i != index) state[i],
    ];
  }

  void clearAll() {
    state = [];
  }
}

final registerQualificationCertsProvider =
    NotifierProvider<RegisterQualificationCerts, List<XFile>>(
  RegisterQualificationCerts.new,
);
