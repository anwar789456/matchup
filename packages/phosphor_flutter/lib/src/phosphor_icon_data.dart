library phosphor_flutter;

import 'package:flutter/widgets.dart';

// MatchUp patch: IconData is a final class since Flutter 3.3x, so the icons are plain const
// IconData. Duotone icons keep their primary glyph only (MatchUp uses Regular, Fill and Bold).
typedef PhosphorIconData = IconData;
typedef PhosphorFlatIconData = IconData;
