import 'package:pomotimer/apis/models/custom_time_model.dart';
import 'package:pomotimer/apis/variable_interface.dart';

class VariableRepository {
  final VariableApi _variableApi;

  const VariableRepository({
    required VariableApi variableApi,
  }) : _variableApi = variableApi;

  int getInt(String key) => _variableApi.getInt(key);

  Future<void> setInt(String key, int value) => _variableApi.setInt(key, value);

  bool checkKey(String key) => _variableApi.checkKey(key);

  Future<void> removeData(String key) => _variableApi.removeData(key);

  String getString(String key) => _variableApi.getString(key);
  Future<void> setString(String key, String value) =>
      _variableApi.setString(key, value);

  List<CustomTimeModel> getCustomTimeModels() =>
      _variableApi.getCustomTimeModels();
  Future<void> setCustomTimeModels(CustomTimeModel customTimeModel) =>
      _variableApi.setCustomTimeModels(customTimeModel);
  Future<void> deleteCustomTimeModel(String id) =>
      _variableApi.deleteCustomTimeModel(id);
}
