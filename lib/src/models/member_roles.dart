enum AccessLevel {
  basic('Basic Access'),
  read('Report Access'),
  full('Full Access');

  final String displayName;
  const AccessLevel(this.displayName);
}

enum CouncilRole {
  // Full Access (F)
  financialSecretary('Financial Secretary', AccessLevel.full),
  treasurer('Treasurer', AccessLevel.full),

  // Read Access (R)
  grandKnight('Grand Knight', AccessLevel.read),
  deputyGrandKnight('Deputy Grand Knight', AccessLevel.read),
  programDirector('Program Director', AccessLevel.read),
  membershipDirector('Membership Director', AccessLevel.read),

  // Basic Access (B)
  knight('Knight', AccessLevel.basic);

  final String displayName;
  final AccessLevel accessLevel;
  const CouncilRole(this.displayName, this.accessLevel);

  bool hasAccess(AccessLevel requiredLevel) {
    switch (requiredLevel) {
      case AccessLevel.basic:
        return true; // Everyone has basic access
      case AccessLevel.read:
        return accessLevel == AccessLevel.read || accessLevel == AccessLevel.full;
      case AccessLevel.full:
        return accessLevel == AccessLevel.full;
    }
  }
}

enum AssemblyRole {
  // Full Access (F)
  faithfulComptroller('Faithful Comptroller', AccessLevel.full),
  faithfulPurser('Faithful Purser', AccessLevel.full),

  // Read Access (R)
  faithfulNavigator('Faithful Navigator', AccessLevel.read),
  faithfulCaptain('Faithful Captain', AccessLevel.read),
  programDirector('Program Director', AccessLevel.read),
  membershipDirector('Membership Director', AccessLevel.read),

  // Basic Access (B)
  sirKnight('Sir Knight', AccessLevel.basic);

  final String displayName;
  final AccessLevel accessLevel;
  const AssemblyRole(this.displayName, this.accessLevel);

  bool hasAccess(AccessLevel requiredLevel) {
    switch (requiredLevel) {
      case AccessLevel.basic:
        return true; // Everyone has basic access
      case AccessLevel.read:
        return accessLevel == AccessLevel.read || accessLevel == AccessLevel.full;
      case AccessLevel.full:
        return accessLevel == AccessLevel.full;
    }
  }
} 