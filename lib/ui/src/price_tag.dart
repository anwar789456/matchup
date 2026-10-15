import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../theme/theme.dart';

/// Price per person: value in `num-m`, « DT » smaller, then the unit (« /joueur ») under it.
class MuPriceTag extends StatelessWidget {
  const MuPriceTag({super.key, required this.amount, required this.unit});

  final num amount;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: formatAmount(amount), style: MuType.numM),
              TextSpan(text: ' DT', style: MuType.numXs),
            ]),
            style: TextStyle(color: c.text),
          ),
        ),
        Text(unit, style: MuType.caption.copyWith(color: c.textSecondary)),
      ],
    );
  }
}
