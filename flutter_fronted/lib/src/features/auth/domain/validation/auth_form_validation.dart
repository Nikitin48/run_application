/// Валидация полей формы логина/регистрации.
/// Проверки: формат email, минимальная длина пароля (8 символов).
/// Возвращает ключ ошибки для локализации или null, если поле валидно.
class AuthFormValidation {
  AuthFormValidation._();

  /// Минимальная длина пароля (символов).
  static const int passwordMinLength = 8;

  /// Ключи ошибок для маппинга в l10n.
  static const String emailInvalid = 'emailInvalid';
  static const String passwordMinLengthError = 'passwordMinLength';

  /// Регулярка для формата email (базовая, покрывает большинство случаев).
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Проверяет формат email. Возвращает ключ ошибки или null, если валидно.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_emailRegex.hasMatch(value.trim())) return emailInvalid;
    return null;
  }

  /// Проверяет длину пароля. Возвращает ключ ошибки или null, если валидно.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < passwordMinLength) return passwordMinLengthError;
    return null;
  }

  /// Форма валидна для отправки.
  /// При регистрации проверяются email и длина пароля (≥8); при входе — только email и непустой пароль.
  static bool isFormValid({
    required String? email,
    required String? password,
    required bool isRegister,
  }) {
    if ((email?.trim().isNotEmpty ?? false) && (password?.isNotEmpty ?? false) &&
        validateEmail(email) == null) {
      if (isRegister) return validatePassword(password) == null;
      return true;
    }
    return false;
  }
}
