import 'package:flutter_test/flutter_test.dart';
import 'package:swifty_companion/services/api_exception.dart';

/// Comprueba que se lanza una [ApiException] del tipo [error].
Matcher throwsApiError(ApiError error) =>
    throwsA(isA<ApiException>().having((e) => e.error, 'error', error));
