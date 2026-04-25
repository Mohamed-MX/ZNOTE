import 'package:flutter/material.dart';

import '../widgets/note_app_lock_ui.dart';
import 'app_pattern_lock_service.dart';
import 'device_auth_unlock.dart';

/// Handles unlock for redacted notes: device auth, optional app pattern, and user preference.
Future<bool> ensureRedactedNoteUnlocked(BuildContext context) async {
  final svc = AppPatternLockService();
  final prefer = await svc.getPreferAppPattern();
  final hasPat = await svc.hasPattern();

  if (prefer && hasPat) {
    if (!context.mounted) return false;
    return showAppPatternVerifyDialog(context);
  }

  if (hasPat) {
    if (!context.mounted) return false;
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Unlock note'),
        content: const Text('Choose how to verify.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, 'cancel'), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, 'app'), child: const Text('App pattern')),
          FilledButton(onPressed: () => Navigator.pop(c, 'device'), child: const Text('Device lock')),
        ],
      ),
    );
    if (!context.mounted) return false;
    if (choice == null || choice == 'cancel') return false;
    if (choice == 'app') {
      return showAppPatternVerifyDialog(context);
    }
  }

  var ok = await tryUnlockWithDeviceAuth();
  if (!context.mounted) return false;
  if (ok) return true;

  if (hasPat) {
    if (!context.mounted) return false;
    final retry = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Device unlock failed'),
        content: const Text('Try your app pattern instead?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('App pattern')),
        ],
      ),
    );
    if (!context.mounted) return false;
    if (retry == true) {
      return showAppPatternVerifyDialog(context);
    }
    return false;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Device unlock failed. Set an app pattern from the lock icon in the toolbar for a reliable fallback.',
        ),
      ),
    );
  }
  return false;
}
