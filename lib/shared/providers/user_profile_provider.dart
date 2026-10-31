import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import 'core_providers.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;

  String get roleLabel => switch (role) {
        UserRole.owner => 'Owner',
        UserRole.admin => 'Admin',
        UserRole.manager => 'Manager',
        UserRole.kasir => 'Kasir',
        UserRole.staffGudang => 'Staff Gudang',
      };

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
  }) =>
      UserProfile(
        id: id ?? this.id,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
      );
}

final userProfileProvider = StreamProvider.autoDispose<UserProfile>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthSignedIn) {
    return const Stream.empty();
  }

  final db = ref.watch(databaseProvider);
  return (db.select(db.profiles)
        ..where((p) => p.id.equals(authState.userId)))
      .watchSingleOrNull()
      .map((profile) {
    if (profile == null) {
      return UserProfile(
        id: authState.userId,
        email: 'offline@local',
        fullName: 'Owner',
        role: authState.role,
      );
    }
    return UserProfile(
      id: profile.id,
      email: profile.email,
      fullName: profile.fullName,
      role: roleFromName(profile.role),
    );
  });
});
