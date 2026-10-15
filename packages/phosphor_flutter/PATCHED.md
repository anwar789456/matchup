# phosphor_flutter 2.1.0 — patched copy

The published `phosphor_flutter` 2.1.0 (latest, May 2024) does not compile on Flutter 3.3x+
because `IconData` became a `final` class and the package extends it.

This copy is the official package with one mechanical change:

- `PhosphorIconData` / `PhosphorFlatIconData` are typedefs of `IconData`; every generated icon is
  now `IconData(codePoint, fontFamily: 'Phosphor<Style>', fontPackage: 'phosphor_flutter')`.
- Duotone icons keep only their primary glyph and `PhosphorIcon` no longer draws the duotone layer
  (MatchUp only uses Regular, Fill and Bold).
- Icons no longer set `matchTextDirection`; directional icons are flipped explicitly in RTL
  (`MuDirectionalIcon`), as the design system's Flutter README says.

The public API (`PhosphorIcons.house()`, `PhosphorIconsStyle.fill`, …) is unchanged.
It is wired through `dependency_overrides` in the app's `pubspec.yaml`: delete the override and
this folder once an official release supports current Flutter.
- SDK floor raised to Dart 3.0 so the typedefs are allowed.
