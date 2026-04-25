import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/app_pattern_lock_service.dart';
import 'app_pattern_pad.dart';

/// Verify the stored app pattern; returns true if the user drew the correct pattern.
Future<bool> showAppPatternVerifyDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const _PatternVerifyDialog(),
      ) ??
      false;
}

/// Bottom sheet: prefer-pattern switch, set/change/clear pattern.
Future<void> showAppPatternLockSettingsSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _PatternLockSettingsBody(outerContext: context),
  );
}

class _PatternLockSettingsBody extends StatefulWidget {
  const _PatternLockSettingsBody({required this.outerContext});

  /// Context from the page that opened the sheet (still valid after the sheet closes).
  final BuildContext outerContext;

  @override
  State<_PatternLockSettingsBody> createState() => _PatternLockSettingsBodyState();
}

class _PatternLockSettingsBodyState extends State<_PatternLockSettingsBody> {
  final _service = AppPatternLockService();
  var _loading = true;
  var _hasPattern = false;
  var _prefer = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final has = await _service.hasPattern();
    final prefer = await _service.getPreferAppPattern();
    if (mounted) {
      setState(() {
        _hasPattern = has;
        _prefer = prefer;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'App unlock pattern',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Use this when your device has no fingerprint sensor, the system lock prompt fails, or you prefer an in-app pattern.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Prefer app pattern for locked notes'),
            subtitle: Text(
              _hasPattern
                  ? 'When on, tapping a locked note asks for your app pattern first.'
                  : 'Set an app pattern below to enable this option.',
            ),
            value: _prefer,
            onChanged: _hasPattern
                ? (v) async {
                    await _service.setPreferAppPattern(v);
                    if (mounted) setState(() => _prefer = v);
                  }
                : null,
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await runAppPatternSetupFlow(widget.outerContext);
            },
            icon: const Icon(Icons.gesture),
            label: Text(_hasPattern ? 'Change app pattern' : 'Set app pattern'),
          ),
          if (_hasPattern) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Remove app pattern?'),
                    content: const Text(
                      'Locked notes will rely on device authentication only until you set a new pattern.',
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await _service.clearPattern();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (widget.outerContext.mounted) {
                    ScaffoldMessenger.of(widget.outerContext).showSnackBar(
                      const SnackBar(content: Text('App pattern removed.')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              label: const Text('Remove app pattern', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Two-step pattern setup (draw twice).
Future<void> runAppPatternSetupFlow(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _PatternSetupDialog(),
  );
}

class _PatternVerifyDialog extends StatefulWidget {
  const _PatternVerifyDialog();

  @override
  State<_PatternVerifyDialog> createState() => _PatternVerifyDialogState();
}

class _PatternVerifyDialogState extends State<_PatternVerifyDialog> {
  final _service = AppPatternLockService();
  var _error = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Draw your pattern'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPatternPad(
            errorPulse: _error,
            onPatternComplete: (path) async {
              final ok = await _service.verify(path);
              if (!context.mounted) return;
              if (ok) {
                Navigator.pop(context, true);
              } else {
                setState(() => _error = true);
                await Future<void>.delayed(const Duration(milliseconds: 50));
                if (context.mounted) setState(() => _error = false);
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Connect at least 4 dots.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      ],
    );
  }
}

class _PatternSetupDialog extends StatefulWidget {
  const _PatternSetupDialog();

  @override
  State<_PatternSetupDialog> createState() => _PatternSetupDialogState();
}

class _PatternSetupDialogState extends State<_PatternSetupDialog> {
  final _service = AppPatternLockService();
  List<int>? _first;
  var _confirm = false;
  var _error = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_confirm ? 'Confirm pattern' : 'Choose a pattern'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPatternPad(
            errorPulse: _error,
            onPatternComplete: (path) async {
              if (!_confirm) {
                setState(() {
                  _first = path;
                  _confirm = true;
                });
                return;
              }
              if (_first == null) return;
              if (listEquals(_first!, path)) {
                await _service.savePattern(path);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'App pattern saved. Open lock settings to prefer it for locked notes.',
                    ),
                  ),
                );
              } else {
                setState(() => _error = true);
                await Future<void>.delayed(const Duration(milliseconds: 50));
                if (!context.mounted) return;
                setState(() {
                  _error = false;
                  _confirm = false;
                  _first = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Patterns did not match. Try again.')),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            _confirm ? 'Draw the same pattern again to confirm.' : 'Connect at least 4 dots.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_confirm) {
              setState(() {
                _confirm = false;
                _first = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
          child: Text(_confirm ? 'Back' : 'Cancel'),
        ),
      ],
    );
  }
}
