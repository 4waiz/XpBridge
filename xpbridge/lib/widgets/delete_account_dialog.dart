import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'xp_button.dart';

const String _confirmWord = 'DELETE';

/// Shows the provider-aware account deletion modal.
///
/// Branches:
///   - email/password only -> password field + typed-DELETE confirmation
///   - Google only         -> typed-DELETE + "Continue with Google to delete"
///                            (launches Google OAuth; `main()` finishes the
///                            deletion after the callback)
///   - linked              -> user picks Password or Google
///
/// Returns `true` if the account was deleted in-dialog (email path), `false`
/// otherwise. For Google-reauth, the dialog returns `false` once the browser
/// has been launched — the deletion itself completes on the next cold boot.
Future<bool> showDeleteAccountDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DeleteAccountDialog(),
  );
  return result ?? false;
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirmController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _processing = false;
  String? _error;

  /// Which path the linked-provider user picked. Ignored for single-provider
  /// accounts (they're always forced onto the matching path).
  _LinkedChoice _linkedChoice = _LinkedChoice.password;

  late final AuthProviderKind _provider;

  @override
  void initState() {
    super.initState();
    _provider = SupabaseService.currentAuthProvider();
    _confirmController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _confirmed =>
      _confirmController.text.trim().toUpperCase() == _confirmWord;

  bool get _showPasswordField {
    switch (_provider) {
      case AuthProviderKind.emailPassword:
      case AuthProviderKind.unknown:
        return true;
      case AuthProviderKind.google:
        return false;
      case AuthProviderKind.linked:
        return _linkedChoice == _LinkedChoice.password;
    }
  }

  bool get _showGoogleButton {
    switch (_provider) {
      case AuthProviderKind.google:
        return true;
      case AuthProviderKind.linked:
        return _linkedChoice == _LinkedChoice.google;
      case AuthProviderKind.emailPassword:
      case AuthProviderKind.unknown:
        return false;
    }
  }

  bool get _passwordButtonEnabled =>
      !_processing &&
      _confirmed &&
      _passwordController.text.trim().isNotEmpty;

  bool get _googleButtonEnabled => !_processing && _confirmed;

  Future<void> _deleteWithPassword() async {
    final appState = AppStateScope.of(context);
    final password = _passwordController.text;

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      await appState.deleteAccountWithPassword(password);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      // Router auto-redirects to /login because isLoggedIn flipped to false.
      // Push an explicit go() too so we don't rely on the refresh listener.
      // The login screen picks up the one-shot "Your account has been
      // deleted" message via SupabaseService.consumeDeletionStatusMessage.
      context.goNamed('login');
    } on XpServiceException catch (error) {
      if (!mounted) return;
      if (error.message.toLowerCase().contains('session has expired')) {
        Navigator.of(context).pop(false);
        context.goNamed('login');
        return;
      }
      setState(() {
        _processing = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _deleteWithGoogleReauth() async {
    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      await SupabaseService.beginGoogleReauthForAccountDeletion();
      // On web we navigate away before this future resolves with a result; on
      // mobile, control returns once Chrome Custom Tabs has been handed a URL.
      // Either way, close the dialog so the user isn't staring at a stale
      // sheet when the app comes back. The actual deletion runs from
      // SupabaseService.executePendingAccountDeletion() during bootstrap.
      if (!mounted) return;
      Navigator.of(context).pop(false);
    } on XpServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = 'Could not start Google reauthentication.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.sheetBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      title: const Text(
        'Delete account',
        style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently erases your profile, XP, missions, applications, '
              'uploaded files, and every other record tied to your account. '
              'This cannot be undone.',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_provider == AuthProviderKind.linked) _buildLinkedPicker(),
            Text(
              'Type $_confirmWord to confirm:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _confirmController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                LengthLimitingTextInputFormatter(10),
                UpperCaseTextFormatter(),
              ],
              decoration: const InputDecoration(
                hintText: _confirmWord,
                filled: true,
                fillColor: AppTheme.background,
              ),
              enabled: !_processing,
            ),
            if (_showPasswordField) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Enter your current password:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                enabled: !_processing,
                decoration: InputDecoration(
                  hintText: 'Your password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  filled: true,
                  fillColor: AppTheme.background,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: _processing
                        ? null
                        : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                  ),
                ),
              ),
            ],
            if (_showGoogleButton) ...[
              const SizedBox(height: AppSpacing.md),
              const Text(
                'For your safety, confirm again with the Google account linked '
                'to XPBridge. You\'ll be sent to Google, then bounced back here '
                'to finish deletion.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (_showPasswordField)
              XPButton(
                label: 'Delete forever',
                icon: Icons.delete_forever_rounded,
                backgroundColor: AppTheme.error,
                loading: _processing,
                onPressed:
                    _passwordButtonEnabled ? _deleteWithPassword : null,
              ),
            if (_showGoogleButton)
              XPButton(
                label: 'Continue with Google to delete',
                icon: Icons.open_in_new_rounded,
                backgroundColor: AppTheme.error,
                loading: _processing,
                onPressed:
                    _googleButtonEnabled ? _deleteWithGoogleReauth : null,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _processing ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildLinkedPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose how to confirm:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<_LinkedChoice>(
            segments: const [
              ButtonSegment(
                value: _LinkedChoice.password,
                label: Text('Password'),
                icon: Icon(Icons.lock_outline_rounded),
              ),
              ButtonSegment(
                value: _LinkedChoice.google,
                label: Text('Google'),
                icon: Icon(Icons.account_circle_outlined),
              ),
            ],
            selected: {_linkedChoice},
            onSelectionChanged: _processing
                ? null
                : (selection) => setState(() {
                      _linkedChoice = selection.first;
                      _error = null;
                    }),
          ),
        ],
      ),
    );
  }

}

enum _LinkedChoice { password, google }

/// Forces the typed DELETE confirmation into upper-case so the user can type
/// "delete" or "Delete" and still satisfy the check.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
