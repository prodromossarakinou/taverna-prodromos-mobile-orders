import 'package:shared_preferences/shared_preferences.dart';

class LocalSettingsStore {
  static const String _defaultWaiterNameKey = 'default_waiter_name';

  Future<String?> getDefaultWaiterName() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_defaultWaiterNameKey)?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    return value;
  }

  Future<void> setDefaultWaiterName(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      await prefs.remove(_defaultWaiterNameKey);
      return;
    }
    await prefs.setString(_defaultWaiterNameKey, normalized);
  }
}
