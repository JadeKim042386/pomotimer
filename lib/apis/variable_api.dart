abstract class VariableApi {
  const VariableApi();

  // get&set Int (seconds)
  int getInt(String key);
  Future<void> setInt(String key, int value);

  bool checkKey(String key);

  Future<void> removeData(String key);
}
