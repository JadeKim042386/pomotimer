import 'dart:convert';
import 'package:pomotimer/apis/models/custom_time_model.dart';
import 'package:pomotimer/apis/variable_interface.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageVariableApi extends VariableApi {
  final SharedPreferences _plugin;

  LocalStorageVariableApi({required SharedPreferences plugin})
      : _plugin = plugin {
    _init();
  }

  final _streamController =
      BehaviorSubject<List<CustomTimeModel>>.seeded(const []);
  static const customDataKey = '__custom_collection_key__';

  Future<void> _init() async {
    if (!_plugin.containsKey('totalRound')) {
      await setInt('totalRound', 4);
    }
    // seconds
    if (!_plugin.containsKey('breakTime')) {
      await setInt('breakTime', 5 * 60 + 3);
    }
    if (!_plugin.containsKey('selectedIndex')) {
      await setInt('selectedIndex', 0);
    }
    if (!_plugin.containsKey('settingType')) {
      await setInt('settingType', 0);
    }
    // minutes
    if (!_plugin.containsKey('totalWorkingTime')) {
      await setInt('totalWorkingTime', 20);
    }
    // custom data
    if (!_plugin.containsKey(customDataKey)) {
      await _plugin.setString(customDataKey, json.encode([]));
    } else {
      _streamController.add(getCustomTimeModels());
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

  @override
  String getString(String key) => _plugin.getString(key)!;

  @override
  Future<void> setString(String key, String value) async =>
      await _plugin.setString(key, value);

  @override
  Future<void> deleteCustomTimeModel(String id) {
    final customTimeModels = [..._streamController.value];
    final customTimeModelIndex =
        customTimeModels.indexWhere((element) => element.id == id);
    if (customTimeModelIndex == -1) {
      return setString(customDataKey, json.encode(customTimeModels));
    } else {
      customTimeModels.removeAt(customTimeModelIndex);
      _streamController.add(customTimeModels);
      return setString(customDataKey, json.encode(customTimeModels));
    }
  }

  @override
  List<CustomTimeModel> getCustomTimeModels() {
    final customTimeModelsJson = getString(customDataKey);
    final List<CustomTimeModel> customTimeModels =
        List<Map<dynamic, dynamic>>.from(
                json.decode(customTimeModelsJson) as List)
            .map((jsonMap) =>
                CustomTimeModel.fromJson(Map<String, dynamic>.from(jsonMap)))
            .toList();
    return customTimeModels;
  }

  @override
  Future<void> setCustomTimeModels(CustomTimeModel customTimeModel) {
    final customTimeModels = [..._streamController.value];
    final customTimeModelIndex = customTimeModels
        .indexWhere((element) => element.id == customTimeModel.id);
    if (customTimeModelIndex >= 0) {
      customTimeModels[customTimeModelIndex] = customTimeModel;
    } else {
      customTimeModels.add(customTimeModel);
    }

    _streamController.add(customTimeModels);

    return setString(customDataKey, json.encode(customTimeModels));
  }
}
