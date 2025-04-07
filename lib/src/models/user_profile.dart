import 'member_roles.dart';

class UserProfile {
  final String uid; // Firebase user ID
  final String firstName;
  final String lastName;
  final int membershipNumber;
  final int councilNumber;  // Now required
  final int? assemblyNumber;
  final List<CouncilRole> councilRoles;
  final List<AssemblyRole> assemblyRoles;

  UserProfile({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.membershipNumber,
    required this.councilNumber,
    this.assemblyNumber,
    List<CouncilRole>? councilRoles,
    List<AssemblyRole>? assemblyRoles,
  }) : 
    councilRoles = councilRoles ?? [],
    assemblyRoles = assemblyRoles ?? [];

  // Convert membership number string to int, removing leading zeros
  static int parseMembershipNumber(String value) {
    return int.parse(value.replaceAll(RegExp(r'^0+'), ''));
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'membershipNumber': membershipNumber,
      'councilNumber': councilNumber,
      'assemblyNumber': assemblyNumber,
      'councilRoles': councilRoles.map((role) => role.name).toList(),
      'assemblyRoles': assemblyRoles.map((role) => role.name).toList(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      membershipNumber: map['membershipNumber'] as int,
      councilNumber: map['councilNumber'] as int,
      assemblyNumber: map['assemblyNumber'] as int?,
      councilRoles: (map['councilRoles'] as List<dynamic>?)
          ?.map((role) => CouncilRole.values.firstWhere((e) => e.name == role))
          .toList() ?? [],
      assemblyRoles: (map['assemblyRoles'] as List<dynamic>?)
          ?.map((role) => AssemblyRole.values.firstWhere((e) => e.name == role))
          .toList() ?? [],
    );
  }

  String getOrganizationId(bool isAssembly) {
    return isAssembly 
      ? (assemblyNumber ?? '').toString()
      : (councilNumber ?? '').toString();
  }

  bool get isAssembly => assemblyNumber != null;
} 