/// Modelo del usuario autenticado con su información de empleado
class UserModel {
  final int userId;
  final String userName;
  final EmployeeModel employee;
  final String token;

  UserModel({
    required this.userId,
    required this.userName,
    required this.employee,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final user = data['user'];
    final employee = user['employee'];

    return UserModel(
      userId: user['id'],
      userName: user['name'] ?? '',
      employee: EmployeeModel.fromJson(employee),
      token: data['token'],
    );
  }
}

class EmployeeModel {
  final int id;
  final String code;
  final String fullName;
  final DepartmentModel? department;

  EmployeeModel({
    required this.id,
    required this.code,
    required this.fullName,
    this.department,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'],
      code: json['code'] ?? '',
      fullName: json['full_name'] ?? '',
      department: json['department'] != null
          ? DepartmentModel.fromJson(json['department'])
          : null,
    );
  }
}

class DepartmentModel {
  final int id;
  final String name;

  DepartmentModel({required this.id, required this.name});

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}
