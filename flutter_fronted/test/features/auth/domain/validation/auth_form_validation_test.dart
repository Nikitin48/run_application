import 'package:flutter_test/flutter_test.dart';
import 'package:run_application/src/features/auth/domain/validation/auth_form_validation.dart';

void main() {
  group('AuthFormValidation', () {
    test('accepts a valid email address', () {
      expect(AuthFormValidation.validateEmail('runner@example.com'), isNull);
    });

    test('rejects an invalid email address', () {
      expect(
        AuthFormValidation.validateEmail('runner'),
        AuthFormValidation.emailInvalid,
      );
    });

    test('requires a longer password during registration', () {
      expect(
        AuthFormValidation.validatePassword('short'),
        AuthFormValidation.passwordMinLengthError,
      );
    });

    test('allows login with non-empty password and valid email', () {
      expect(
        AuthFormValidation.isFormValid(
          email: 'runner@example.com',
          password: 'short',
          isRegister: false,
        ),
        isTrue,
      );
    });

    test('requires minimum password length during registration', () {
      expect(
        AuthFormValidation.isFormValid(
          email: 'runner@example.com',
          password: 'short',
          isRegister: true,
        ),
        isFalse,
      );
    });
  });
}
