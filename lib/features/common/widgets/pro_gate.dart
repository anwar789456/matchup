import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';

/// Shows a spinner until a pro draft has loaded, then [child]; screens below read the draft
/// synchronously.
class ProGate extends ConsumerWidget {
  const ProGate({super.key, required this.provider, required this.child, this.onRetry});

  final ProviderListenable<AsyncValue<Object?>> provider;
  final Widget child;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final value = ref.watch(provider);
    if (value.hasValue) return child;
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: value.hasError
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Impossible de charger ton brouillon.',
                    style: MuType.body.copyWith(color: c.text),
                  ),
                  const SizedBox(height: MuSpace.s3),
                  MuButton.secondary(label: 'Réessayer', onPressed: onRetry),
                ],
              )
            : MuSpinner(size: MuSize.iconM, color: c.text, semanticLabel: 'Chargement'),
      ),
    );
  }
}
