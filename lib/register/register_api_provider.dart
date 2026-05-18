import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/register_api.dart';

final registerApiProvider = Provider<RegisterApi>((ref) => RegisterApi());
