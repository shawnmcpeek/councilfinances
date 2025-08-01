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
  final String jurisdiction;
  final String? councilCity;
  final String? assemblyCity;
  final String? assemblyJurisdiction;

  UserProfile({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.membershipNumber,
    required this.councilNumber,
    this.assemblyNumber,
    List<CouncilRole>? councilRoles,
    List<AssemblyRole>? assemblyRoles,
    String? jurisdiction,
    this.councilCity,
    this.assemblyCity,
    this.assemblyJurisdiction,
  }) : 
    councilRoles = councilRoles ?? [],
    assemblyRoles = assemblyRoles ?? [],
    jurisdiction = jurisdiction ?? 'TN';  // Default to TN if not provided

  // Convert membership number string to int, removing leading zeros
  static int parseMembershipNumber(String value) {
    return int.parse(value.replaceAll(RegExp(r'^0+'), ''));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'first_name': firstName,
      'last_name': lastName,
      'membership_number': membershipNumber,
      'council_number': councilNumber,
      'assembly_number': assemblyNumber,
      'council_roles': councilRoles.map((role) => role.name).toList(),
      'assembly_roles': assemblyRoles.map((role) => role.name).toList(),
      'jurisdiction': jurisdiction,
      'city': councilCity,
      'assembly_city': assemblyCity,
      'assembly_jurisdiction': assemblyJurisdiction,
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
      jurisdiction: (map['jurisdiction'] as String?) ?? 'TN',
      councilCity: map['city'] as String?,
      assemblyCity: map['assembly_city'] as String?,
      assemblyJurisdiction: map['assembly_jurisdiction'] as String?,
    );
  }

  String getOrganizationId(bool isAssembly) {
    if (isAssembly) {
      if (assemblyNumber == null) return '';
      return 'A${assemblyNumber.toString().padLeft(6, '0')}';
    }
    return 'C${councilNumber.toString().padLeft(6, '0')}';
  }

  bool get isAssembly => assemblyNumber != null;
} 