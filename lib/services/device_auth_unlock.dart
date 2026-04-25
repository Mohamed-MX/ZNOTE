import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Tries device biometrics / PIN / pattern via the system [LocalAuthentication] prompt.
/// Returns false on cancel or any failure (including plugin channel errors).
Future<bool> tryUnlockWithDeviceAuth() async {
  if (kIsWeb) return false;
  final auth = LocalAuthentication();
  try {
    return await auth.authenticate(
      localizedReason: 'Authenticate to view this locked note.',
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );
  } on LocalAuthException catch (e) {
    if (e.code == LocalAuthExceptionCode.userCanceled) {
      return false;
    }
    return false;
  } on PlatformException {
    return false;
  } catch (_) {
    return false;
  }
}
