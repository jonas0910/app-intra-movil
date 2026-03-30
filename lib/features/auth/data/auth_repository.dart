import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import 'models/user_model.dart';

class AuthRepository {
  /// Login using email and password.
  /// Uses the public /api/auth/login endpoint.
  Future<UserModel> login(String email, String password) async {
    final serverUrl = await AppConfig.getServerUrl();

    // Login is a public route, build URL from server base
    final dio = Dio(BaseOptions(
      baseUrl: serverUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    final response = await dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });

    final user = UserModel.fromJson(response.data);

    // Persist authentication
    await AppConfig.setToken(user.token);
    await AppConfig.setEmployeeData(
      id: user.employee.id,
      name: user.employee.fullName,
      code: user.employee.code,
      departmentName: user.employee.department?.name ?? '',
    );

    // Recreate Dio instance with the new token
    await DioClient.recreateInstance();

    return user;
  }

  /// Clear session data
  Future<void> logout() async {
    await AppConfig.clearSession();
    await AppConfig.clearSelectedVehicle();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await AppConfig.getToken();
    final employeeId = await AppConfig.getEmployeeId();
    return token != null && employeeId != null;
  }
}
