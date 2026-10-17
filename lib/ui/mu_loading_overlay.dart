import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_spinner.dart';

/// LoadingOverlay (components/LoadingOverlay.md): the blocking card shown only while a payment
/// is processed — « Paiement en cours… », the amount, « Ne ferme pas cette page » — that turns
/// into « Paiement confirmé ». Never dismissible: the flow closes it.
class MuLoadingOverlay {
  MuLoadingOverlay._(this._context, this._state);

  final BuildContext _context;
  final ValueNotifier<_OverlayStatus> _state;
  bool _closed = false;

  /// Opens the overlay; [detail] says what the payment is for.
  static MuLoadingOverlay show(BuildContext context, {required String amount, String? detail}) {
    final state = ValueNotifier(_OverlayStatus(amount: amount, detail: detail));
    final c = context.mu;
    final reduce = MediaQuery.disableAnimationsOf(context);
    showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: c.scrim,
      barrierLabel: 'Paiement en cours',
      transitionDuration: reduce ? Duration.zero : MuMotion.slow,
      pageBuilder: (context, _, _) => PopScope(
        canPop: false,
        child: _OverlayCard(state: state),
      ),
      transitionBuilder: (context, animation, _, child) {
        final t = CurvedAnimation(parent: animation, curve: MuMotion.enter);
        return FadeTransition(
          opacity: t,
          child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(t), child: child),
        );
      },
    );
    return MuLoadingOverlay._(context, state);
  }

  /// Turns the card into « Paiement confirmé »; close it after [MuMotion.success].
  void success({String? detail}) {
    _state.value = _state.value.copyWith(success: true, detail: detail);
  }

  void close() {
    if (_closed) return;
    _closed = true;
    if (_context.mounted) Navigator.of(_context, rootNavigator: true).pop();
  }
}

@immutable
class _OverlayStatus {
  const _OverlayStatus({required this.amount, this.detail, this.success = false});

  final String amount;
  final String? detail;
  final bool success;

  _OverlayStatus copyWith({bool? success, String? detail}) =>
      _OverlayStatus(amount: amount, detail: detail ?? this.detail, success: success ?? this.success);
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard({required this.state});

  final ValueNotifier<_OverlayStatus> state;

  // LoadingOverlay.md: card up to modal-s, padding s8 s6 s6, a 56 icon circle, spinner 32,
  // check 40.
  static const double _icon = 56;
  static const double _spinner = 32;
  static const double _check = 40;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MuSpace.s6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: MuSize.modalS),
          child: Material(
            color: c.surfaceElevated,
            borderRadius: MuRadius.lgAll,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: MuRadius.lgAll,
                boxShadow: MuElevation.of(context).level3,
              ),
              padding: const EdgeInsets.fromLTRB(MuSpace.s6, MuSpace.s8, MuSpace.s6, MuSpace.s6),
              child: ValueListenableBuilder<_OverlayStatus>(
                valueListenable: state,
                builder: (context, s, _) => Semantics(
                  liveRegion: true,
                  label: s.success ? 'Paiement confirmé' : 'Paiement en cours, ${s.amount}',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: MuMotion.durationOf(context, MuMotion.base),
                        switchInCurve: MuMotion.pop,
                        child: Container(
                          key: ValueKey(s.success),
                          width: _icon,
                          height: _icon,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: s.success ? c.successSoft : c.bg,
                            border: s.success ? null : Border.all(color: c.border),
                          ),
                          child: Center(
                            child: s.success
                                ? Icon(
                                    PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                                    size: _check,
                                    color: c.successText,
                                  )
                                : MuSpinner(size: _spinner, color: c.text),
                          ),
                        ),
                      ),
                      const SizedBox(height: MuSpace.s4),
                      Text(
                        s.success ? 'Paiement confirmé' : 'Paiement en cours…',
                        style: MuType.labelL.copyWith(color: c.text),
                      ),
                      const SizedBox(height: MuSpace.s1),
                      Text(s.amount, style: MuType.numXl.copyWith(color: c.text)),
                      if (s.detail != null) ...[
                        const SizedBox(height: MuSpace.s1),
                        Text(
                          s.detail!,
                          textAlign: TextAlign.center,
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                      ],
                      if (!s.success) ...[
                        const SizedBox(height: MuSpace.s4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MuSpace.s3,
                            vertical: MuSpace.s1,
                          ),
                          decoration: BoxDecoration(
                            color: c.bg,
                            borderRadius: MuRadius.fullAll,
                            border: Border.all(color: c.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIcons.lockSimple(), size: MuSize.iconXs, color: c.textSecondary),
                              const SizedBox(width: MuSpace.s1),
                              Text(
                                'Ne ferme pas cette page',
                                style: MuType.labelS.copyWith(color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
