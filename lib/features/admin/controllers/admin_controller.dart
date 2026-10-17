import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/search.dart';
import '../../states/data/account_status.dart';
import '../data/admin_repository.dart';

/// ADM-02 sort sheet.
enum AdminUserSort { toHandle, activity, joined, reliability, name }

/// ADM-02 list state: search, filter chips and sort.
@immutable
class AdminUserQuery {
  const AdminUserQuery({
    this.text = '',
    this.role,
    this.status,
    this.flagged = false,
    this.toVerify = false,
    this.newOnly = false,
    this.sort = AdminUserSort.toHandle,
  });

  final String text;
  final AdminRole? role;
  final AdminUserStatus? status;
  final bool flagged;
  final bool toVerify;

  /// « Nouveaux · 7 jours ».
  final bool newOnly;
  final AdminUserSort sort;

  bool get filtered =>
      text.trim().isNotEmpty || role != null || status != null || flagged || toVerify || newOnly;

  AdminUserQuery copyWith({
    String? text,
    AdminRole? Function()? role,
    AdminUserStatus? Function()? status,
    bool? flagged,
    bool? toVerify,
    bool? newOnly,
    AdminUserSort? sort,
  }) => AdminUserQuery(
    text: text ?? this.text,
    role: role == null ? this.role : role(),
    status: status == null ? this.status : status(),
    flagged: flagged ?? this.flagged,
    toVerify: toVerify ?? this.toVerify,
    newOnly: newOnly ?? this.newOnly,
    sort: sort ?? this.sort,
  );
}

/// Filters and sorts ADM-02's list. AI scores never decide: « À traiter d’abord » puts the
/// flagged accounts, then the verifications, then the rest in their order.
List<AdminUser> applyUserQuery(List<AdminUser> users, AdminUserQuery q, DateTime now) {
  final text = foldAccents(q.text.trim());
  final digits = q.text.replaceAll(RegExp(r'\D'), '');
  final out = [
    for (final u in users)
      if ((text.isEmpty ||
              foldAccents(u.name).contains(text) ||
              foldAccents(u.email).contains(text) ||
              (digits.length >= 3 && u.phone.contains(digits))) &&
          (q.role == null || u.roles.contains(q.role)) &&
          (q.status == null || u.status == q.status) &&
          (!q.flagged || u.status == AdminUserStatus.flagged) &&
          (!q.toVerify || u.status == AdminUserStatus.toVerify) &&
          (!q.newOnly || now.difference(u.joined).inDays < 7))
        u,
  ];
  int rank(AdminUser u) => switch (u.status) {
    AdminUserStatus.flagged => 0,
    AdminUserStatus.toVerify => 1,
    _ => 2,
  };
  final order = {for (final (i, u) in users.indexed) u.id: i};
  int stable(AdminUser a, AdminUser b) => order[a.id]!.compareTo(order[b.id]!);
  out.sort(
    (a, b) => switch (q.sort) {
      AdminUserSort.toHandle => rank(a) != rank(b) ? rank(a) - rank(b) : stable(a, b),
      AdminUserSort.activity => b.lastActive.compareTo(a.lastActive),
      AdminUserSort.joined => b.joined.compareTo(a.joined),
      AdminUserSort.reliability => (a.reliability ?? 101).compareTo(b.reliability ?? 101),
      AdminUserSort.name => foldAccents(a.name).compareTo(foldAccents(b.name)),
    },
  );
  return out;
}

/// ADM-09 sort sheet.
enum ModerationSort { score, recent }

/// The admin's decisions: each one updates the repository, refreshes the lists and, for a
/// suspension, reaches the player's Home (STA-07). Nothing here runs without the admin's tap.
class AdminActions {
  AdminActions(this.ref);

  final Ref ref;

  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  /// ADM-04: suspends [user] until now + [length] (a ban has no end). A suspended player sees
  /// STA-07 with [plan]'s reason, the freed games and the refund.
  Future<void> suspend(
    AdminUser user, {
    required AdminSuspensionLength length,
    required AdminSanctionPlan plan,
    required DateTime now,
  }) async {
    final until = length.duration == null ? null : now.add(length.duration!);
    await _repo.suspend(user.id, until: until);
    if (until != null) {
      ref
          .read(suspensionsProvider.notifier)
          .suspend(
            user.name,
            Suspension(
              until: until,
              reason: plan.playerReason,
              refunded: plan.refund,
              freedGames: plan.freedGames,
            ),
          );
    }
    ref
      ..invalidate(adminUsersProvider)
      ..invalidate(adminUserDetailProvider(user.id));
  }

  Future<void> approve(String id, String doneLine) async {
    await _repo.approve(id, doneLine);
    ref
      ..invalidate(adminVerificationsProvider)
      ..invalidate(adminUsersProvider);
  }

  Future<void> validatePayouts(Set<String> ids) async {
    await _repo.validatePayouts(ids);
    ref.invalidate(adminPayoutsProvider);
  }

  Future<void> refund(String id) async {
    await _repo.refund(id);
    ref.invalidate(adminRefundsProvider);
  }

  Future<void> ignoreChurn(String id, {required bool ignored}) async {
    await _repo.ignoreChurn(id, ignored: ignored);
    ref.invalidate(adminChurnProvider);
  }

  Future<void> decide(String id, ModerationDecision decision) async {
    await _repo.decide(id, decision);
    ref.invalidate(adminModerationProvider);
  }
}

final adminActionsProvider = Provider<AdminActions>(AdminActions.new);
