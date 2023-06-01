import 'package:pomotimer/apis/models/custom_time_model.dart';

abstract class VariableApi {
  const VariableApi();

  // get&set Int (seconds)
  int getInt(String key);
  Future<void> setInt(String key, int value);

  bool checkKey(String key);

  Future<void> removeData(String key);

  // custom data
  String getString(String key);
  Future<void> setString(String key, String value);

  List<CustomTimeModel> getCustomTimeModels();
  Future<void> setCustomTimeModels(CustomTimeModel customTimeModel);
  Future<void> deleteCustomTimeModel(String id);
}
