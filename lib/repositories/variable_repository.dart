import 'package:pomotimer/apis/variable_api.dart';

class VariableRepository {
  final VariableApi _variableApi;

  const VariableRepository({
    required VariableApi variableApi,
  }) : _variableApi = variableApi;

  int getInt(String key) => _variableApi.getInt(key);

  Future<void> setInt(String key, int value) => _variableApi.setInt(key, value);

  bool checkKey(String key) => _variableApi.checkKey(key);

  Future<void> removeData(String key) => _variableApi.removeData(key);
}
