import 'package:flutter/material.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../widgets/booking_detail.dart';
import '../../../l10n/l10n.dart';

/// OWN-12 as a page, when a booking is opened from outside the planning (Aujourd’hui,
/// Réservations): the same detail as the planning's sheet.
class OwnerBookingScreen extends StatelessWidget {
  const OwnerBookingScreen({super.key, required this.bookingRef});

  final String bookingRef;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuTopAppBar.compact(
              title: l10n.reservation2,
              onBack: () => goBack(context, Routes.ownerBookings),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s8),
                children: [OwnerBookingDetail(bookingRef: bookingRef)],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StickyActionBar(children: [OwnerBookingFooter(bookingRef: bookingRef)]),
    );
  }
}
