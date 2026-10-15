import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/onboarding_controller.dart';

/// « Ajouter une zone : quartier, ville… » — searches the zone directory and adds the pick.
class ZoneSearchField extends ConsumerWidget {
  const ZoneSearchField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final directory = ref.read(zoneDirectoryProvider);
    return MuSearchField<String>(
      label: 'Ajouter une zone',
      placeholder: 'Ajouter une zone : quartier, ville…',
      emptyMessage: (q) => 'Aucune zone trouvée pour « $q ». Essaie un quartier ou une ville.',
      search: (q) async => [
        for (final zone in await directory.search(q))
          MuSearchSuggestion(
            value: zone,
            title: zone,
            leading: Icon(PhosphorIcons.mapPin(), size: MuSize.iconS, color: c.textSecondary),
          ),
      ],
      onSelected: ref.onboarding.addZone,
    );
  }
}
