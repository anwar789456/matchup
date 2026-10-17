import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../data/owner_drafts.dart';
import '../widgets/block_form.dart';
import '../widgets/owner_labels.dart';
import '../../../l10n/l10n.dart';

/// OWN-13 as a page (from Terrains or Aujourd’hui); the planning opens the same form in a sheet.
class BlockSlotScreen extends StatefulWidget {
  const BlockSlotScreen({super.key, this.prefill});

  final BlockPrefill? prefill;

  @override
  State<BlockSlotScreen> createState() => _BlockSlotScreenState();
}

class _BlockSlotScreenState extends State<BlockSlotScreen> {
  final _form = GlobalKey<BlockFormState>();

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
              title: l10n.bloquerUnCreneau,
              onBack: () => goBack(context, Routes.ownerPlanning),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s8),
                children: [
                  BlockForm(
                    key: _form,
                    prefill: widget.prefill,
                    onSaved: (block) {
                      MuToast.show(
                        context,
                        tone: MuToastTone.success,
                        title: l10n.creneauBloque,
                        description:
                            '${courtName(block.court)} · ${formatDay(block.start)} · ${hourLong(block.start.hour)} – ${hourLong(block.end.hour)}',
                      );
                      goBack(context, Routes.ownerPlanning);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          BlockFormFooter(formKey: _form, onCancel: () => goBack(context, Routes.ownerPlanning)),
        ],
      ),
    );
  }
}
