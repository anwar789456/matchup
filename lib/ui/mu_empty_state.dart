import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/theme.dart';

enum MuEmptyIllustration { bookings, notifications, programs, results }

/// EmptyState (components/EmptyState.md): an illustration, a title, one helpful sentence and the
/// action that fills the space. [compact] for side panels.
///
/// The illustrations are the design system's SVG assets; theme-aware painted versions can replace
/// them later without changing this API.
class MuEmptyState extends StatelessWidget {
  const MuEmptyState({
    super.key,
    required this.title,
    this.description,
    this.illustration = MuEmptyIllustration.results,
    this.actions = const [],
    this.compact = false,
  });

  final String title;
  final String? description;

  /// Null drops the art.
  final MuEmptyIllustration? illustration;
  final List<Widget> actions;
  final bool compact;

  // EmptyState.md: art 200 × 160 (compact 140 × 112); texts capped at 320 wide.
  static const _art = Size(200, 160);
  static const _artCompact = Size(140, 112);
  static const double _textMax = 320;

  String get _asset => switch (illustration!) {
        MuEmptyIllustration.bookings => 'assets/illustrations/no-matches.svg',
        MuEmptyIllustration.notifications => 'assets/illustrations/no-notifications.svg',
        MuEmptyIllustration.programs => 'assets/illustrations/no-programs.svg',
        MuEmptyIllustration.results => 'assets/illustrations/no-results.svg',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final art = compact ? _artCompact : _art;
    return Padding(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s6)
          : const EdgeInsets.symmetric(horizontal: MuSpace.s6, vertical: MuSpace.s8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (illustration != null) ...[
            ExcludeSemantics(
              child: SvgPicture.asset(_asset, width: art.width, height: art.height),
            ),
            SizedBox(height: compact ? MuSpace.s2 : MuSpace.s4),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _textMax),
            child: Column(
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: (compact ? MuType.labelL : MuType.h3).copyWith(color: c.text),
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: MuSpace.s2),
                  Text(
                    description!,
                    textAlign: TextAlign.center,
                    style: MuType.body.copyWith(color: c.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: MuSpace.s4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: MuSpace.s3,
              runSpacing: MuSpace.s3,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}
