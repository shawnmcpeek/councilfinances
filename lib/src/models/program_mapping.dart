

/// Represents a program category (Faith, Family, etc.)
enum ProgramCategory {
  faith,
  family,
  community,
  life,
  fraternal,
  miscellaneous,
}

/// Represents a program with its mapping information
class ProgramMapping {
  final String id;           // e.g., "CP001" for council, "AP001" for assembly
  final String name;         // e.g., "Refund Support Vocations Program"
  final ProgramCategory category;
  final int councilField;    // e.g., 2 for Text2
  final int assemblyField;   // e.g., 42 for Text42
  final bool isMiscellaneous;

  const ProgramMapping({
    required this.id,
    required this.name,
    required this.category,
    required this.councilField,
    required this.assemblyField,
    this.isMiscellaneous = false,
  });

  /// Get the field number based on whether it's council or assembly
  int getFieldNumber(bool isAssembly) => isAssembly ? assemblyField : councilField;

  /// Get the field key (e.g., "Text2" or "Text42")
  String getFieldKey(bool isAssembly) => 'Text${getFieldNumber(isAssembly)}';
}

/// Manages program mappings for both council and assembly
class ProgramMappingManager {
  static final ProgramMappingManager _instance = ProgramMappingManager._internal();
  factory ProgramMappingManager() => _instance;
  ProgramMappingManager._internal();

  // Faith Activities
  static const _refundSupportVocations = ProgramMapping(
    id: 'CP001',
    name: 'Refund Support Vocations Program',
    category: ProgramCategory.faith,
    councilField: 2,
    assemblyField: 42,
  );

  static const _churchFacilities = ProgramMapping(
    id: 'CP002',
    name: 'Church Facilities',
    category: ProgramCategory.faith,
    councilField: 3,
    assemblyField: 43,
  );

  static const _catholicSchools = ProgramMapping(
    id: 'CP003',
    name: 'Catholic Schools/Seminaries',
    category: ProgramCategory.faith,
    councilField: 4,
    assemblyField: 44,
  );

  static const _religiousEducation = ProgramMapping(
    id: 'CP004',
    name: 'Religious/Vocations Education',
    category: ProgramCategory.faith,
    councilField: 5,
    assemblyField: 45,
  );

  static const _prayerStudy = ProgramMapping(
    id: 'CP005',
    name: 'Prayer & Study Programs',
    category: ProgramCategory.faith,
    councilField: 6,
    assemblyField: 46,
  );

  static const _sacramentalGifts = ProgramMapping(
    id: 'CP006',
    name: 'Sacramental Gifts',
    category: ProgramCategory.faith,
    councilField: 7,
    assemblyField: 47,
  );

  static const _miscFaith = ProgramMapping(
    id: 'CP007',
    name: 'Miscellaneous Faith Activities',
    category: ProgramCategory.faith,
    councilField: 8,
    assemblyField: 48,
    isMiscellaneous: true,
  );

  // Family Activities
  static const _foodForFamilies = ProgramMapping(
    id: 'CP008',
    name: 'Food for Families',
    category: ProgramCategory.family,
    councilField: 9,
    assemblyField: 49,
  );

  static const _familyFormation = ProgramMapping(
    id: 'CP009',
    name: 'Family Formation Programs',
    category: ProgramCategory.family,
    councilField: 11,
    assemblyField: 50,
  );

  static const _keepChristInChristmas = ProgramMapping(
    id: 'CP010',
    name: 'Keep Christ in Christmas',
    category: ProgramCategory.family,
    councilField: 12,
    assemblyField: 51,
  );

  static const _familyWeek = ProgramMapping(
    id: 'CP011',
    name: 'Family Week',
    category: ProgramCategory.family,
    councilField: 13,
    assemblyField: 52,
  );

  static const _familyPrayerNight = ProgramMapping(
    id: 'CP012',
    name: 'Family Prayer Night',
    category: ProgramCategory.family,
    councilField: 14,
    assemblyField: 53,
  );

  static const _miscFamily = ProgramMapping(
    id: 'CP013',
    name: 'Miscellaneous Family Programs',
    category: ProgramCategory.family,
    councilField: 15,
    assemblyField: 54,
    isMiscellaneous: true,
  );

  // Community Activities
  static const _coatsForKids = ProgramMapping(
    id: 'CP014',
    name: 'Coats for Kids',
    category: ProgramCategory.community,
    councilField: 16,
    assemblyField: 55,
  );

  static const _wheelchairMission = ProgramMapping(
    id: 'CP015',
    name: 'Global Wheelchair Mission',
    category: ProgramCategory.community,
    councilField: 17,
    assemblyField: 56,
  );

  static const _habitatForHumanity = ProgramMapping(
    id: 'CP016',
    name: 'Habitat for Humanity',
    category: ProgramCategory.community,
    councilField: 18,
    assemblyField: 57,
  );

  static const _disasterRelief = ProgramMapping(
    id: 'CP017',
    name: 'Disaster Preparedness/Relief',
    category: ProgramCategory.community,
    councilField: 19,
    assemblyField: 58,
  );

  static const _disabledCare = ProgramMapping(
    id: 'CP018',
    name: 'Physically Disabled/Intellectual Disabilities',
    category: ProgramCategory.community,
    councilField: 20,
    assemblyField: 59,
  );

  static const _elderlyCare = ProgramMapping(
    id: 'CP019',
    name: 'Elderly/Widow Care',
    category: ProgramCategory.community,
    councilField: 21,
    assemblyField: 60,
  );

  static const _hospitals = ProgramMapping(
    id: 'CP020',
    name: 'Hospitals/Health Organizations',
    category: ProgramCategory.community,
    councilField: 22,
    assemblyField: 61,
  );

  static const _squires = ProgramMapping(
    id: 'CP021',
    name: 'Columbian Squires',
    category: ProgramCategory.community,
    councilField: 23,
    assemblyField: 62,
  );

  static const _scouting = ProgramMapping(
    id: 'CP022',
    name: 'Scouting/Youth Groups',
    category: ProgramCategory.community,
    councilField: 24,
    assemblyField: 63,
  );

  static const _athletics = ProgramMapping(
    id: 'CP023',
    name: 'Athletics',
    category: ProgramCategory.community,
    councilField: 25,
    assemblyField: 64,
  );

  static const _youthWelfare = ProgramMapping(
    id: 'CP024',
    name: 'Youth Welfare/Service',
    category: ProgramCategory.community,
    councilField: 26,
    assemblyField: 65,
  );

  static const _scholarships = ProgramMapping(
    id: 'CP025',
    name: 'Scholarships/Education',
    category: ProgramCategory.community,
    councilField: 27,
    assemblyField: 66,
  );

  static const _veterans = ProgramMapping(
    id: 'CP026',
    name: 'Veteran Military/VAVS',
    category: ProgramCategory.community,
    councilField: 28,
    assemblyField: 67,
  );

  static const _miscCommunity = ProgramMapping(
    id: 'CP027',
    name: 'Miscellaneous Community/Youth Activities',
    category: ProgramCategory.community,
    councilField: 29,
    assemblyField: 68,
    isMiscellaneous: true,
  );

  // Life Activities
  static const _specialOlympics = ProgramMapping(
    id: 'CP028',
    name: 'Special Olympics',
    category: ProgramCategory.life,
    councilField: 30,
    assemblyField: 69,
  );

  static const _marchesForLife = ProgramMapping(
    id: 'CP029',
    name: 'Marches for Life',
    category: ProgramCategory.life,
    councilField: 31,
    assemblyField: 70,
  );

  static const _ultrasound = ProgramMapping(
    id: 'CP030',
    name: 'Ultrasound Initiatives',
    category: ProgramCategory.life,
    councilField: 32,
    assemblyField: 71,
  );

  static const _pregnancySupport = ProgramMapping(
    id: 'CP031',
    name: 'Pregnancy Support',
    category: ProgramCategory.life,
    councilField: 33,
    assemblyField: 72,
  );

  static const _refugeeRelief = ProgramMapping(
    id: 'CP032',
    name: 'Christian Refugee Relief',
    category: ProgramCategory.life,
    councilField: 34,
    assemblyField: 73,
  );

  static const _unbornMemorials = ProgramMapping(
    id: 'CP033',
    name: 'Memorials to Unborn Children',
    category: ProgramCategory.life,
    councilField: 35,
    assemblyField: 74,
  );

  static const _miscLife = ProgramMapping(
    id: 'CP034',
    name: 'Miscellaneous Life Activities',
    category: ProgramCategory.life,
    councilField: 36,
    assemblyField: 75,
    isMiscellaneous: true,
  );

  // Fraternal Activities
  static const _sickVisits = ProgramMapping(
    id: 'CP035',
    name: 'Visits to the Sick',
    category: ProgramCategory.fraternal,
    councilField: 37,
    assemblyField: 76,
  );

  static const _bereavedVisits = ProgramMapping(
    id: 'CP036',
    name: 'Visits to the Bereaved',
    category: ProgramCategory.fraternal,
    councilField: 38,
    assemblyField: 77,
  );

  static const _bloodDonations = ProgramMapping(
    id: 'CP037',
    name: 'Number of Blood Donations',
    category: ProgramCategory.fraternal,
    councilField: 39,
    assemblyField: 78,
  );

  static const _fraternalService = ProgramMapping(
    id: 'CP038',
    name: 'Hours of Fraternal Service to Sick/Disabled',
    category: ProgramCategory.fraternal,
    councilField: 41,
    assemblyField: 79,
  );

  // List of all program mappings
  static final List<ProgramMapping> _allPrograms = [
    _refundSupportVocations,
    _churchFacilities,
    _catholicSchools,
    _religiousEducation,
    _prayerStudy,
    _sacramentalGifts,
    _miscFaith,
    _foodForFamilies,
    _familyFormation,
    _keepChristInChristmas,
    _familyWeek,
    _familyPrayerNight,
    _miscFamily,
    _coatsForKids,
    _wheelchairMission,
    _habitatForHumanity,
    _disasterRelief,
    _disabledCare,
    _elderlyCare,
    _hospitals,
    _squires,
    _scouting,
    _athletics,
    _youthWelfare,
    _scholarships,
    _veterans,
    _miscCommunity,
    _specialOlympics,
    _marchesForLife,
    _ultrasound,
    _pregnancySupport,
    _refugeeRelief,
    _unbornMemorials,
    _miscLife,
    _sickVisits,
    _bereavedVisits,
    _bloodDonations,
    _fraternalService,
  ];

  /// Get all programs for a specific category
  List<ProgramMapping> getProgramsByCategory(ProgramCategory category) {
    return _allPrograms.where((p) => p.category == category).toList();
  }

  /// Get all programs for council or assembly
  List<ProgramMapping> getPrograms(bool isAssembly) {
    return _allPrograms.map((p) => ProgramMapping(
      id: isAssembly ? p.id.replaceFirst('CP', 'AP') : p.id,
      name: p.name,
      category: p.category,
      councilField: p.councilField,
      assemblyField: p.assemblyField,
      isMiscellaneous: p.isMiscellaneous,
    )).toList();
  }

  /// Get a program by its ID
  ProgramMapping? getProgramById(String id) {
    final isAssembly = id.startsWith('AP');
    final baseId = isAssembly ? id.replaceFirst('AP', 'CP') : id;
    return _allPrograms.firstWhere((p) => p.id == baseId);
  }

  /// Get a program by its field number
  ProgramMapping? getProgramByField(int fieldNumber, bool isAssembly) {
    return _allPrograms.firstWhere(
      (p) => isAssembly ? p.assemblyField == fieldNumber : p.councilField == fieldNumber,
      orElse: () => throw Exception('No program found for field $fieldNumber'),
    );
  }
} 