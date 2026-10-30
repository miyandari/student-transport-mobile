class UserProfile {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String role;
  final int? universityId;
  final int? transportCompanyId;
  final int? studentId;
  final int? driverId;
  final bool isActive;

  const UserProfile({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.phone,
    required this.role,
    this.universityId,
    this.transportCompanyId,
    this.studentId,
    this.driverId,
    required this.isActive,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: _toInt(json['id']) ?? 0,
      username: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? '',
      universityId: _toInt(json['university_id']),
      transportCompanyId: _toInt(json['transport_company_id']),
      studentId: _toInt(json['student_id']),
      driverId: _toInt(json['driver_id']),
      isActive: json['is_active'] == true,
    );
  }

  String get fullName {
    final name = [
      if (firstName != null && firstName!.trim().isNotEmpty) firstName!,
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!,
    ].join(' ');

    return name.isEmpty ? 'دانشجو' : name;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }
}