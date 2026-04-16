class LegalDocumentsConfig {
  LegalDocumentsConfig._();

  static final Uri privacyPolicyUrl = Uri.parse(
    const String.fromEnvironment(
      'PRIVACY_POLICY_URL',
      defaultValue: 'https://api.georunapp.ru/legal/privacy-policy.pdf',
    ),
  );

  static final Uri termsOfUseUrl = Uri.parse(
    const String.fromEnvironment(
      'TERMS_OF_USE_URL',
      defaultValue: 'https://api.georunapp.ru/legal/terms-of-use.pdf',
    ),
  );
}
