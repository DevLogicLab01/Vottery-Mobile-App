/// Shared role constants for RBAC.
/// Keep in sync with Web: src/constants/roles.js

class AppRoles {
  AppRoles._();

  static const String voter = 'voter';
  static const String creator = 'creator';
  static const String admin = 'admin';
  static const String superAdmin = 'super_admin';
  static const String manager = 'manager';
  static const String moderator = 'moderator';
  static const String advertiser = 'advertiser';
  static const String developer = 'developer';

  static const List<String> adminRoles = [
    admin,
    superAdmin,
    manager,
    moderator,
  ];

  static const List<String> creatorRoles = [
    creator,
    ...adminRoles,
  ];

  static const List<String> advertiserRoles = [
    advertiser,
    ...adminRoles,
  ];

  /// Get effective roles for a user (admin-like roles get admin access)
  static List<String> getEffectiveRoles(String? role) {
    final r = role ?? voter;
    final roles = <String>[r];
    if (adminRoles.contains(r)) roles.add(admin);
    if (creatorRoles.contains(r)) roles.add(creator);
    if (advertiserRoles.contains(r)) roles.add(advertiser);
    return roles.toSet().toList();
  }

  /// Check if user has any of the required roles
  static bool hasAnyRole(String? userRole, List<String> requiredRoles) {
    if (requiredRoles.isEmpty) return true;
    final effective = getEffectiveRoles(userRole);
    return requiredRoles.any((r) => effective.contains(r));
  }

  /// Check if role has admin access
  static bool isAdminRole(String? role) => hasAnyRole(role, adminRoles);

  /// Check if role has creator access
  static bool isCreatorRole(String? role) => hasAnyRole(role, creatorRoles);

  /// Check if role has advertiser access
  static bool isAdvertiserRole(String? role) =>
      hasAnyRole(role, advertiserRoles);
}
