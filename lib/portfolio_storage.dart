import 'package:shared_preferences/shared_preferences.dart';

/// Prosty adapter pozwalający podmienić pamięć urządzenia w testach.
abstract class PortfolioStorage {
  Future<String?> read();
  Future<void> write(String json);
}

/// SharedPreferencesAsync działa w Chrome i na Androidzie.
/// Klucz i format JSON są wersjonowane, aby kolejne etapy mogły je migrować.
class PreferencesPortfolioStorage implements PortfolioStorage {
  PreferencesPortfolioStorage({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const String storageKey = 'system_metali_mobile_portfolio_v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(storageKey);

  @override
  Future<void> write(String json) => _preferences.setString(storageKey, json);
}
