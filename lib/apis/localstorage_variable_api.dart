import 'package:pomotimer/apis/variable_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageVariableApi extends VariableApi {
  final SharedPreferences _plugin;

  LocalStorageVariableApi({required SharedPreferences plugin})
      : _plugin = plugin {
    _init();
  }

  Future<void> _init() async {
    if (!_plugin.containsKey('totalRound')) {
      await _plugin.setInt('totalRound', 4);
    }
    if (!_plugin.containsKey('breakTime')) {
      await _plugin.setInt('breakTime', 5);
    }
    if (!_plugin.containsKey('selectedIndex')) {
      await _plugin.setInt('selectedIndex', 0);
    }
  }

  @override
  int getInt(String key) => _plugin.getInt(key)!;

  @override
  Future<void> setInt(String key, int value) async =>
      await _plugin.setInt(key, value);

  @override
  bool checkKey(String key) => _plugin.containsKey(key);

  @override
  Future<void> removeData(String key) => _plugin.remove(key);
}
