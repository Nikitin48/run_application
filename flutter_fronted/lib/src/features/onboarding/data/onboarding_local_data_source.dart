import 'package:shared_preferences/shared_preferences.dart';

class OnboardingLocalDataSource {
  const OnboardingLocalDataSource();

  static const _seenKey = 'onboarding_seen_v1';

  Future<bool> isSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }
}
