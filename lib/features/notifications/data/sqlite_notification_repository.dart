import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart' show IconData;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/clock.dart';
import '../../../core/db/app_database.dart';
import '../../../theme/theme.dart';
import 'notification_models.dart';
import 'notification_repository.dart';

/// [NotificationRepository] on the phone's database (`notifications`): read state, deletions and
/// the notifications pushed while the app runs survive a restart.
class SqliteNotificationRepository implements NotificationRepository {
  SqliteNotificationRepository(this._database);

  final AppDatabase _database;
  final _changes = StreamController<List<AppNotification>>.broadcast();

  Future<Database> get _db => _database.db;

  static Future<void> seed(DatabaseExecutor db) async {
    for (final n in storyNotifications(storyNow)) {
      await db.insert('notifications', NotificationRows.row(n));
    }
  }

  Future<List<AppNotification>> _all() async => [
        for (final r in await (await _db).query('notifications', orderBy: 'recue_le DESC'))
          NotificationRows.read(r),
      ];

  Future<void> _emit() async => _changes.add(await _all());

  @override
  Stream<List<AppNotification>> watch() async* {
    yield await _all();
    yield* _changes.stream;
  }

  @override
  Future<void> markRead(String id) async {
    await (await _db).update('notifications', {'non_lue': 0}, where: 'id = ?', whereArgs: [id]);
    await _emit();
  }

  @override
  Future<void> markAllRead() async {
    await (await _db).update('notifications', {'non_lue': 0});
    await _emit();
  }

  @override
  Future<void> delete(String id) async {
    await (await _db).delete('notifications', where: 'id = ?', whereArgs: [id]);
    await _emit();
  }

  @override
  Future<void> push(AppNotification n) async {
    await (await _db).insert('notifications', NotificationRows.row(n),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await _emit();
  }
}

/// [AppNotification] ⇄ a `notifications` row. Icons are stored by name (the [icons] registry),
/// so release builds can still tree-shake the icon font; people and actions as JSON.
abstract final class NotificationRows {
  /// Every icon a notification of the catalog or the story can carry.
  static final Map<String, IconData> icons = {
    'at': PhosphorIcons.at(),
    'bank': PhosphorIcons.bank(),
    'barbell': PhosphorIcons.barbell(),
    'calendarCheck': PhosphorIcons.calendarCheck(),
    'calendarX': PhosphorIcons.calendarX(),
    'chatsCircle': PhosphorIcons.chatsCircle(),
    'checkCircle': PhosphorIcons.checkCircle(),
    'clock': PhosphorIcons.clock(),
    'creditCard': PhosphorIcons.creditCard(),
    'crownSimple': PhosphorIcons.crownSimple(),
    'flagCheckered': PhosphorIcons.flagCheckered(),
    'hourglass': PhosphorIcons.hourglass(),
    'magnifyingGlass': PhosphorIcons.magnifyingGlass(),
    'megaphone': PhosphorIcons.megaphone(),
    'navigationArrow': PhosphorIcons.navigationArrow(),
    'playCircle': PhosphorIcons.playCircle(),
    'plusCircle': PhosphorIcons.plusCircle(),
    'qrCode': PhosphorIcons.qrCode(),
    'receipt': PhosphorIcons.receipt(),
    'sealCheck': PhosphorIcons.sealCheck(),
    'signIn': PhosphorIcons.signIn(),
    'sparkle': PhosphorIcons.sparkle(),
    'star': PhosphorIcons.star(),
    'trophy': PhosphorIcons.trophy(),
    'userPlus': PhosphorIcons.userPlus(),
    'usersThree': PhosphorIcons.usersThree(),
    'wallet': PhosphorIcons.wallet(),
  };

  /// The registry name of [icon]; null for an icon outside it (the category icon shows instead).
  static String? iconName(IconData? icon) {
    if (icon == null) return null;
    for (final e in icons.entries) {
      if (e.value == icon) return e.key;
    }
    return null;
  }

  static T? _enum<T extends Enum>(List<T> values, Object? name) =>
      name == null ? null : values.byName(name as String);

  static Map<String, Object?> _action(NotificationAction a) => {
        'label': a.label,
        'target': a.target?.name,
        'secondary': a.secondary,
        'price': a.price,
        'icon': iconName(a.icon),
        'countdown': a.countdown,
        'accept': a.accept,
      };

  static NotificationAction _readAction(Map<String, Object?> a) => NotificationAction(
        a['label']! as String,
        target: _enum(NotificationTarget.values, a['target']),
        secondary: a['secondary']! as bool,
        price: a['price'] as String?,
        icon: icons[a['icon']],
        countdown: a['countdown']! as bool,
        accept: a['accept'] as bool?,
      );

  static Map<String, Object?> row(AppNotification n) => {
        'id': n.id,
        'type': n.type.name,
        'titre': n.title,
        'corps': n.body,
        'recue_le': n.at.toIso8601String(),
        'priorite': n.priority.name,
        'sport': n.sport?.name,
        'icone': iconName(n.icon),
        'statut': n.status?.name,
        'avatar': n.avatar,
        'personnes': jsonEncode(n.people),
        'vignette': n.thumbnail?.name,
        'ia': n.ai ? 1 : 0,
        'actions': jsonEncode([for (final a in n.actions) _action(a)]),
        'cible': n.target?.name,
        'cible_id': n.targetId,
        'expire_le': n.expiresAt?.toIso8601String(),
        'non_lue': n.unread ? 1 : 0,
      };

  static AppNotification read(Map<String, Object?> r) => AppNotification(
        id: r['id']! as String,
        type: NotificationType.values.byName(r['type']! as String),
        title: r['titre']! as String,
        body: r['corps']! as String,
        at: DateTime.parse(r['recue_le']! as String),
        priority: NotificationPriority.values.byName(r['priorite']! as String),
        sport: _enum(MuSport.values, r['sport']),
        icon: icons[r['icone']],
        status: _enum(MuTone.values, r['statut']),
        avatar: r['avatar'] as String?,
        people: [for (final p in jsonDecode(r['personnes']! as String) as List) p as String],
        thumbnail: _enum(MuSport.values, r['vignette']),
        ai: r['ia'] == 1,
        actions: [
          for (final a in jsonDecode(r['actions']! as String) as List)
            _readAction(a as Map<String, Object?>),
        ],
        target: _enum(NotificationTarget.values, r['cible']),
        targetId: r['cible_id'] as String?,
        expiresAt: DateTime.tryParse('${r['expire_le']}'),
        unread: r['non_lue'] == 1,
      );
}
