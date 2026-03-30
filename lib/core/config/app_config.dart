import 'package:shared_preferences/shared_preferences.dart';

/// Manages server URL configuration and auth token persistence.
class AppConfig {
  static const String _keyServerUrl = 'server_url';
  static const String _keyToken = 'auth_token';
  static const String _keyEmployeeId = 'employee_id';
  static const String _keyEmployeeName = 'employee_name';
  static const String _keyEmployeeCode = 'employee_code';
  static const String _keyDepartmentName = 'department_name';
  static const String _keyVehicleId = 'selected_vehicle_id';
  static const String _keyVehiclePlaca = 'selected_vehicle_placa';
  static const String _keyVehicleTipo = 'selected_vehicle_tipo';

  static const String defaultServerUrl = 'http://192.168.1.100:8000';

  // --- Server URL ---
  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl) ?? defaultServerUrl;
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url.trim());
  }

  // --- Auth Token ---
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  // --- Employee Data ---
  static Future<int?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyEmployeeId);
  }

  static Future<void> setEmployeeData({
    required int id,
    required String name,
    required String code,
    required String departmentName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyEmployeeId, id);
    await prefs.setString(_keyEmployeeName, name);
    await prefs.setString(_keyEmployeeCode, code);
    await prefs.setString(_keyDepartmentName, departmentName);
  }

  static Future<String> getEmployeeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmployeeName) ?? 'Usuario';
  }

  static Future<String> getEmployeeCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmployeeCode) ?? '';
  }

  static Future<String> getDepartmentName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDepartmentName) ?? '';
  }

  // --- Vehicle Selection ---
  static Future<int?> getSelectedVehicleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyVehicleId);
  }

  static Future<void> setSelectedVehicle({
    required int id,
    required String placa,
    required String tipo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyVehicleId, id);
    await prefs.setString(_keyVehiclePlaca, placa);
    await prefs.setString(_keyVehicleTipo, tipo);
  }

  static Future<void> clearSelectedVehicle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyVehicleId);
    await prefs.remove(_keyVehiclePlaca);
    await prefs.remove(_keyVehicleTipo);
  }

  static Future<String?> getSelectedVehiclePlaca() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyVehiclePlaca);
  }

  static Future<String?> getSelectedVehicleTipo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyVehicleTipo);
  }

  // --- Logout ---
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyEmployeeId);
    await prefs.remove(_keyEmployeeName);
    await prefs.remove(_keyEmployeeCode);
    await prefs.remove(_keyDepartmentName);
    await prefs.remove(_keyVehicleId);
    await prefs.remove(_keyVehiclePlaca);
    await prefs.remove(_keyVehicleTipo);
  }
}
