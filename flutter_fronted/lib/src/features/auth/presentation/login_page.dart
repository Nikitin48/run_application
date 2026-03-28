import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../application/auth_controller.dart';
import '../domain/validation/auth_form_validation.dart';
import '../../../core/theme/app_colors.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isRegister = false;
  bool _loading = false;
  String? _error;
  bool _passwordVisible = false;
  /// Ключи ошибок валидации (из [AuthFormValidation]) для отображения под полями.
  String? _emailValidationError;
  String? _passwordValidationError;

  @override
  void initState() {
    super.initState();
    _email.addListener(_validateEmailField);
    _password.addListener(_validatePasswordField);
    _emailFocus.addListener(_onEmailFocusChange);
    _passwordFocus.addListener(_onPasswordFocusChange);
  }

  @override
  void dispose() {
    _email.removeListener(_validateEmailField);
    _password.removeListener(_validatePasswordField);
    _emailFocus.removeListener(_onEmailFocusChange);
    _passwordFocus.removeListener(_onPasswordFocusChange);
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onEmailFocusChange() {
    if (!_emailFocus.hasFocus) _validateEmailField();
  }

  void _onPasswordFocusChange() {
    if (!_passwordFocus.hasFocus) _validatePasswordField();
  }

  void _validateEmailField() {
    final key = AuthFormValidation.validateEmail(_email.text);
    if (key != _emailValidationError) {
      setState(() => _emailValidationError = key);
    }
  }

  void _validatePasswordField() {
    // Длину пароля проверяем только при регистрации.
    final key = _isRegister
        ? AuthFormValidation.validatePassword(_password.text)
        : null;
    if (key != _passwordValidationError) {
      setState(() => _passwordValidationError = key);
    }
  }

  bool get _isFormValid => AuthFormValidation.isFormValid(
        email: _email.text,
        password: _password.text,
        isRegister: _isRegister,
      );

  String _prettyError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['detail'] is String)
        return data['detail'] as String;
      return e.message ?? 'Network error';
    }
    return e.toString();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isRegister) {
        await ref
            .read(authControllerProvider.notifier)
            .register(
              email: _email.text.trim(),
              password: _password.text,
              displayName: _displayName.text.trim().isEmpty
                  ? _email.text.trim().split('@').first
                  : _displayName.text.trim(),
            );
      } else {
        await ref
            .read(authControllerProvider.notifier)
            .login(email: _email.text.trim(), password: _password.text);
      }
    } catch (e) {
      setState(() => _error = _prettyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 32).clamp(0.0, double.infinity),
                      maxWidth: 420,
                    ),
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.directions_run,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      l10n.appTitle,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SegmentedButton<bool>(
                                segments: [
                                  ButtonSegment(
                                    value: false,
                                    label: Text(l10n.loginTitle),
                                  ),
                                  ButtonSegment(
                                    value: true,
                                    label: Text(l10n.registerTitle),
                                  ),
                                ],
                                selected: {_isRegister},
                                onSelectionChanged: _loading
                                    ? null
                                    : (s) => setState(() {
                                        _isRegister = s.first;
                                        _error = null;
                                        // При переключении на вход убираем ошибку пароля; при регистрации — перепроверяем.
                                        _passwordValidationError =
                                            _isRegister
                                                ? AuthFormValidation
                                                    .validatePassword(
                                                        _password.text)
                                                : null;
                                      }),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _email,
                                focusNode: _emailFocus,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) => _validateEmailField(),
                                decoration: InputDecoration(
                                  labelText: l10n.emailLabel,
                                  prefixIcon: const Icon(Icons.alternate_email),
                                  errorText: _emailValidationError ==
                                          AuthFormValidation.emailInvalid
                                      ? l10n.authValidationEmailInvalid
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_isRegister) ...[
                                TextField(
                                  controller: _displayName,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: l10n.displayNameLabel,
                                    prefixIcon: const Icon(
                                      Icons.badge_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextField(
                                controller: _password,
                                focusNode: _passwordFocus,
                                obscureText: !_passwordVisible,
                                onChanged: (_) => _validatePasswordField(),
                                decoration: InputDecoration(
                                  labelText: l10n.passwordLabel,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  errorText: _isRegister &&
                                          _passwordValidationError ==
                                              AuthFormValidation
                                                  .passwordMinLengthError
                                      ? l10n.authValidationPasswordMinLength
                                      : null,
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () =>
                                          _passwordVisible = !_passwordVisible,
                                    ),
                                    icon: Icon(
                                      _passwordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: 12),
                              if (_error != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              FilledButton(
                                onPressed: (_loading || !_isFormValid)
                                    ? null
                                    : _submit,
                                child: Text(
                                  _loading
                                      ? l10n.loading
                                      : (_isRegister
                                            ? l10n.registerAction
                                            : l10n.loginAction),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => setState(() {
                                        _isRegister = !_isRegister;
                                        _error = null;
                                      }),
                                child: Text(
                                  _isRegister
                                      ? l10n.switchToLogin
                                      : l10n.switchToRegister,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
