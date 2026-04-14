import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_application/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/legal_documents_config.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../application/auth_controller.dart';
import '../domain/validation/auth_form_validation.dart';
import '../../../core/theme/app_colors.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _loginEmailFocus = FocusNode();
  final _loginPasswordFocus = FocusNode();
  String? _loginEmailValidationError;
  bool _loginPasswordVisible = false;
  String? _loginError;

  /// Значения полей на момент показа [_loginError]; сброс только если текст реально изменился.
  String _loginEmailWhenErrorShown = '';
  String _loginPasswordWhenErrorShown = '';

  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();
  final _registerDisplayName = TextEditingController();
  final _registerEmailFocus = FocusNode();
  final _registerDisplayNameFocus = FocusNode();
  final _registerPasswordFocus = FocusNode();
  String? _registerEmailValidationError;
  String? _registerPasswordValidationError;
  bool _registerPasswordVisible = false;
  String? _registerError;

  bool _isRegister = false;
  bool _loading = false;
  late final TapGestureRecognizer _privacyTapRecognizer;
  late final TapGestureRecognizer _termsTapRecognizer;

  void _onLoginControllersChanged() => _onLoginCredentialsTextChanged();

  void _onRegisterControllersChanged() => _refreshValidationForMode(true);

  @override
  void initState() {
    super.initState();
    _privacyTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _openLegalUrl(LegalDocumentsConfig.privacyPolicyUrl);
      };
    _termsTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _openLegalUrl(LegalDocumentsConfig.termsOfUseUrl);
      };
    _loginEmail.addListener(_onLoginControllersChanged);
    _loginPassword.addListener(_onLoginControllersChanged);
    _registerEmail.addListener(_onRegisterControllersChanged);
    _registerPassword.addListener(_onRegisterControllersChanged);
    _loginEmailFocus.addListener(_onLoginEmailFocusChange);
    _loginPasswordFocus.addListener(_onLoginPasswordFocusChange);
    _registerEmailFocus.addListener(_onRegisterEmailFocusChange);
    _registerPasswordFocus.addListener(_onRegisterPasswordFocusChange);
  }

  @override
  void dispose() {
    _loginEmail.removeListener(_onLoginControllersChanged);
    _loginPassword.removeListener(_onLoginControllersChanged);
    _registerEmail.removeListener(_onRegisterControllersChanged);
    _registerPassword.removeListener(_onRegisterControllersChanged);
    _loginEmailFocus.removeListener(_onLoginEmailFocusChange);
    _loginPasswordFocus.removeListener(_onLoginPasswordFocusChange);
    _registerEmailFocus.removeListener(_onRegisterEmailFocusChange);
    _registerPasswordFocus.removeListener(_onRegisterPasswordFocusChange);
    _loginEmail.dispose();
    _loginPassword.dispose();
    _registerEmail.dispose();
    _registerPassword.dispose();
    _registerDisplayName.dispose();
    _loginEmailFocus.dispose();
    _loginPasswordFocus.dispose();
    _registerEmailFocus.dispose();
    _registerDisplayNameFocus.dispose();
    _registerPasswordFocus.dispose();
    _privacyTapRecognizer.dispose();
    _termsTapRecognizer.dispose();
    super.dispose();
  }

  void _onLoginEmailFocusChange() {
    if (!_loginEmailFocus.hasFocus) _refreshValidation();
  }

  void _onLoginPasswordFocusChange() {
    if (!_loginPasswordFocus.hasFocus) _refreshValidation();
  }

  void _onRegisterEmailFocusChange() {
    if (!_registerEmailFocus.hasFocus) _refreshValidation();
  }

  void _onRegisterPasswordFocusChange() {
    if (!_registerPasswordFocus.hasFocus) _refreshValidation();
  }

  void _refreshValidation() {
    _refreshValidationForMode(_isRegister);
  }

  /// Слушатели контроллеров висят на обеих формах; обновляем только тот режим,
  /// чей контроллер изменился, иначе при вводе на входе пересчитывалась бы
  /// только «регистрация» и UI не синхронизировался с [_isRegister].
  void _refreshValidationForMode(bool register) {
    if (!mounted) return;
    if (register) {
      final emailKey = AuthFormValidation.validateEmail(_registerEmail.text);
      final passwordKey = AuthFormValidation.validatePassword(
        _registerPassword.text,
      );
      setState(() {
        _registerEmailValidationError = emailKey;
        _registerPasswordValidationError = passwordKey;
      });
    } else {
      final emailKey = AuthFormValidation.validateEmail(_loginEmail.text);
      setState(() {
        _loginEmailValidationError = emailKey;
      });
    }
  }

  /// Слушатель текста входа: [TextEditingController] может уведомлять и без правки символов
  /// (IME и т.п.), поэтому снимаем [_loginError] только при отличии от снимка при ошибке.
  void _onLoginCredentialsTextChanged() {
    if (!mounted) return;
    final emailKey = AuthFormValidation.validateEmail(_loginEmail.text);
    final shouldClearApiError =
        _loginError != null &&
        (_loginEmail.text != _loginEmailWhenErrorShown ||
            _loginPassword.text != _loginPasswordWhenErrorShown);
    setState(() {
      _loginEmailValidationError = emailKey;
      if (shouldClearApiError) _loginError = null;
    });
  }

  bool get _isFormValid {
    if (_isRegister) {
      return AuthFormValidation.isFormValid(
        email: _registerEmail.text,
        password: _registerPassword.text,
        isRegister: true,
      );
    }
    return AuthFormValidation.isFormValid(
      email: _loginEmail.text,
      password: _loginPassword.text,
      isRegister: false,
    );
  }

  String? get _currentError => _isRegister ? _registerError : _loginError;

  static bool _isInvalidCredentialsBackendMessage(String message) {
    return message.trim().toLowerCase() == 'invalid credentials';
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      if (_isRegister) {
        _registerError = null;
      } else {
        _loginError = null;
      }
    });
    try {
      if (_isRegister) {
        await ref
            .read(authControllerProvider.notifier)
            .register(
              email: _registerEmail.text.trim(),
              password: _registerPassword.text,
              displayName: _registerDisplayName.text.trim().isEmpty
                  ? _registerEmail.text.trim().split('@').first
                  : _registerDisplayName.text.trim(),
            );
      } else {
        await ref
            .read(authControllerProvider.notifier)
            .login(
              email: _loginEmail.text.trim(),
              password: _loginPassword.text,
            );
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      var msg = toUserFriendlyError(
        e,
        fallbackMessage: 'Не удалось выполнить вход. Попробуйте снова.',
      );
      if (!_isRegister && _isInvalidCredentialsBackendMessage(msg)) {
        msg = l10n.authInvalidCredentials;
      }
      setState(() {
        if (_isRegister) {
          _registerError = msg;
        } else {
          _loginError = msg;
          _loginEmailWhenErrorShown = _loginEmail.text;
          _loginPasswordWhenErrorShown = _loginPassword.text;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleRegisterMode() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isRegister = !_isRegister;
    });
    _refreshValidation();
  }

  Future<void> _openLegalUrl(Uri url) async {
    final openedInApp = await launchUrl(
      url,
      mode: LaunchMode.inAppBrowserView,
    );
    if (openedInApp || !mounted) return;
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final err = _currentError;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: AppColors.background),
            ),
          ),
          GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.deferToChild,
            child: SafeArea(
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
                        minHeight: (constraints.maxHeight - 32).clamp(
                          0.0,
                          double.infinity,
                        ),
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
                                        _isRegister
                                            ? l10n.registerTitle
                                            : l10n.loginTitle,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (_isRegister) ...[
                                  TextField(
                                    controller: _registerEmail,
                                    focusNode: _registerEmailFocus,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    textInputAction: TextInputAction.next,
                                    onTapOutside: (_) => FocusManager
                                        .instance
                                        .primaryFocus
                                        ?.unfocus(),
                                    decoration: InputDecoration(
                                      labelText: l10n.emailLabel,
                                      prefixIcon: const Icon(
                                        Icons.alternate_email,
                                      ),
                                      errorText:
                                          _registerEmailValidationError ==
                                              AuthFormValidation.emailInvalid
                                          ? l10n.authValidationEmailInvalid
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _registerDisplayName,
                                    focusNode: _registerDisplayNameFocus,
                                    textInputAction: TextInputAction.next,
                                    onTapOutside: (_) => FocusManager
                                        .instance
                                        .primaryFocus
                                        ?.unfocus(),
                                    decoration: InputDecoration(
                                      labelText: l10n.displayNameLabel,
                                      prefixIcon: const Icon(
                                        Icons.badge_outlined,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _registerPassword,
                                    focusNode: _registerPasswordFocus,
                                    obscureText: !_registerPasswordVisible,
                                    onTapOutside: (_) => FocusManager
                                        .instance
                                        .primaryFocus
                                        ?.unfocus(),
                                    decoration: InputDecoration(
                                      labelText: l10n.passwordLabel,
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      errorText:
                                          _registerPasswordValidationError ==
                                              AuthFormValidation
                                                  .passwordMinLengthError
                                          ? l10n.authValidationPasswordMinLength
                                          : null,
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _registerPasswordVisible =
                                              !_registerPasswordVisible,
                                        ),
                                        icon: Icon(
                                          _registerPasswordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                      ),
                                    ),
                                    onSubmitted: (_) => _submit(),
                                  ),
                                ] else ...[
                                  TextField(
                                    controller: _loginEmail,
                                    focusNode: _loginEmailFocus,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    textInputAction: TextInputAction.next,
                                    onTapOutside: (_) => FocusManager
                                        .instance
                                        .primaryFocus
                                        ?.unfocus(),
                                    decoration: InputDecoration(
                                      labelText: l10n.emailLabel,
                                      prefixIcon: const Icon(
                                        Icons.alternate_email,
                                      ),
                                      errorText:
                                          _loginEmailValidationError ==
                                              AuthFormValidation.emailInvalid
                                          ? l10n.authValidationEmailInvalid
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _loginPassword,
                                    focusNode: _loginPasswordFocus,
                                    obscureText: !_loginPasswordVisible,
                                    onTapOutside: (_) => FocusManager
                                        .instance
                                        .primaryFocus
                                        ?.unfocus(),
                                    decoration: InputDecoration(
                                      labelText: l10n.passwordLabel,
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _loginPasswordVisible =
                                              !_loginPasswordVisible,
                                        ),
                                        icon: Icon(
                                          _loginPasswordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                      ),
                                    ),
                                    onSubmitted: (_) => _submit(),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                if (err != null) ...[
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
                                      err,
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
                                      : _toggleRegisterMode,
                                  child: Text(
                                    _isRegister
                                        ? l10n.switchToLogin
                                        : l10n.switchToRegister,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      fontSize: 11.5,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    children: [
                                      TextSpan(text: '${l10n.authLegalNotice} '),
                                      TextSpan(
                                        text: l10n.authTermsOfUseAction,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        recognizer: _termsTapRecognizer,
                                      ),
                                      const TextSpan(text: ' и '),
                                      TextSpan(
                                        text: l10n.authPrivacyPolicyAction,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        recognizer: _privacyTapRecognizer,
                                      ),
                                    ],
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
          ),
        ],
      ),
    );
  }
}
