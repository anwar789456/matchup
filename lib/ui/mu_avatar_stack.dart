import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'mu_avatar.dart';

/// A person shown in an [MuAvatarStack].
@immutable
class MuPerson {
  const MuPerson(this.name, {this.imageUrl});

  final String name;
  final String? imageUrl;
}

/// AvatarStack (components/AvatarStack.md): overlapping avatars, then « +N ». Pair it with a count
/// in text; [semanticLabel] names the group (« 8 inscrits »).
class MuAvatarStack extends StatelessWidget {
  const MuAvatarStack({
    super.key,
    required this.people,
    this.max = 4,
    this.size = MuAvatarSize.s,
    this.semanticLabel,
  }) : assert(size == MuAvatarSize.xs || size == MuAvatarSize.s || size == MuAvatarSize.m);

  final List<MuPerson> people;
  final int max;
  final MuAvatarSize size;
  final String? semanticLabel;

  // AvatarStack.md: overlap −6 / −8 / −10 for XS / S / M; 2 px surface ring.
  static const double _ring = 2;

  double get _diameter => switch (size) {
        MuAvatarSize.xs => MuSize.avatarXs,
        MuAvatarSize.m => MuSize.avatarM,
        _ => MuSize.avatarS,
      };

  double get _overlap => switch (size) {
        MuAvatarSize.xs => 6,
        MuAvatarSize.m => 10,
        _ => 8,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final shown = people.take(max).toList();
    final rest = people.length - shown.length;
    final outer = _diameter + _ring * 2;

    final children = <Widget>[
      for (final p in shown)
        MuAvatar(name: p.name, imageUrl: p.imageUrl, size: size, ring: true, short: true),
      if (rest > 0)
        ExcludeSemantics(
          child: Container(
            width: outer,
            height: outer,
            padding: const EdgeInsets.all(_ring),
            decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                shape: BoxShape.circle,
                border: Border.all(color: c.border),
              ),
              child: Text('+$rest', style: MuType.labelS.copyWith(color: c.text)),
            ),
          ),
        ),
    ];

    return Semantics(
      container: true,
      label: semanticLabel ?? '${people.length} joueurs',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++)
            i == children.length - 1
                ? children[i]
                : Align(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: (outer - _overlap) / outer,
                    child: children[i],
                  ),
        ],
      ),
    );
  }
}
