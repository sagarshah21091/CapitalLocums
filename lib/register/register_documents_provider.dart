import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Document slots on the registration form (indexed 0..5).
abstract final class RegisterDocSlot {
  RegisterDocSlot._();

  static const passport = 0;
  static const visaWorkPermit = 1;
  static const nationalInsurance = 2;
  static const qualificationCert = 3;
  static const professionalReference1 = 4;
  static const professionalReference2 = 5;

  static const count = 6;
}

/// Files chosen for locum uploads (multipart).
class RegisterDocuments extends Notifier<List<XFile?>> {
  @override
  List<XFile?> build() => List<XFile?>.filled(RegisterDocSlot.count, null);

  void setFile(int index, XFile? file) {
    if (index < 0 || index >= state.length) return;
    state = [
      for (var i = 0; i < state.length; i++) i == index ? file : state[i],
    ];
  }

  void clearAll() {
    state = List<XFile?>.filled(RegisterDocSlot.count, null);
  }
}

final registerDocumentsProvider =
    NotifierProvider<RegisterDocuments, List<XFile?>>(
  RegisterDocuments.new,
);
