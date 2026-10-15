# Flutter

The Flutter package is the Flutter version of the MatchUp design system: colours for the two themes (« Light » and « Night match »), type styles, spacing, radii, sizes, motion, shadows and gradients, plus a ready-made Material 3 `ThemeData` and the six custom sport icons.

Every `.dart` file in `lib/theme/` is generated from the design system's `tokens.json` by `tool/flutter_gen.py`. Do not edit them by hand: change the tokens, run the generator again, and copy the folder again (see « When the tokens change » at the end).

In this design system the package is spread over three places: the Dart files in `flutter/lib/theme/`, the generator in `flutter/tool/flutter_gen.py` (it reads this system's `tokens.json`), and the six sport icons in the Icons asset group. Downloaded together they form the `matchup_flutter_theme` package:

```
matchup_flutter_theme/
  lib/theme/            the five Dart files to copy into your app
  assets/icons/sport/   football, padel, basketball, whistle, trophy, court (SVG)
  tool/                 flutter_gen.py + tokens.json, to regenerate the Dart files
```

Each component card ends with a `## Flutter` note: the `Mu…` widget to build for it, its parameters and the Flutter primitive underneath. Those widgets are built in the app on top of this theme; the theme itself already makes stock Material widgets look like MatchUp.

## What is in the folder

| File | What it gives you |
|---|---|
| `lib/theme/theme.dart` | The one file you import. It exports the four files below. |
| `lib/theme/mu_theme.dart` | `MuTheme.light()` and `MuTheme.dark()` (the full `ThemeData`), `context.mu`, and the `MuSport`, `MuTone`, `MuChartColor` enums. |
| `lib/theme/mu_colors.dart` | `MuColors`: one colour per token (`surfaceMuted`, `textSecondary`, `footballText`, `toastBg`…), with a Light and a Night match value. |
| `lib/theme/mu_type.dart` | `MuType`: one text style per type style (`body`, `label`, `h2`, `numM`, `score`, `arBody`…). |
| `lib/theme/mu_tokens.dart` | `MuPalette`, `MuSpace`, `MuRadius`, `MuSize`, `MuLayout`, `MuMotion`, `MuOpacity`, `MuGradients`, `MuElevation`. |

## Before you start

1. Open a terminal and run `flutter --version`. You need Flutter **3.27 or newer** (Dart 3.6 or newer). If it is older, run `flutter upgrade`.
2. You need a Flutter app. If you do not have one yet, create it: `flutter create matchup_app`, then `cd matchup_app`. In the steps below, « your app » means that folder (the one that contains `pubspec.yaml`).

## Step 1 — Copy the theme folder into your app

1. In the package (`flutter/` here), open the folder `lib/theme/`. It contains 5 files: `theme.dart`, `mu_theme.dart`, `mu_colors.dart`, `mu_type.dart`, `mu_tokens.dart`.
2. In your app, open the `lib/` folder (it already contains `main.dart`).
3. Copy the whole `theme` folder into `lib/`. You should now have:

```
your_app/
  pubspec.yaml
  lib/
    main.dart
    theme/
      theme.dart
      mu_theme.dart
      mu_colors.dart
      mu_type.dart
      mu_tokens.dart
```

Keep the five files together in the same folder: they import each other by file name.

## Step 2 — Add the three packages

1. Open `pubspec.yaml` (in the root of your app) in your editor.
2. Find the line `dependencies:`. Below it there is already `flutter:` and `sdk: flutter`.
3. Add the three lines marked « add » so the block looks like this. The indentation is **two spaces** — YAML breaks with tabs:

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.2.1        # add — Plus Jakarta Sans, Barlow Condensed, IBM Plex Sans Arabic
  phosphor_flutter: ^2.1.0    # add — the icon set (Regular by default, Fill for selected tabs)
  flutter_svg: ^2.0.17        # add — the custom sport icons
```

4. Save the file, then run in the terminal (in your app folder):

```
flutter pub get
```

5. If `flutter pub get` complains about versions, remove the three lines you added and run this instead; it picks the newest versions that work with your Flutter:

```
flutter pub add google_fonts phosphor_flutter flutter_svg
```

## Step 3 — Turn the theme on

1. Open `lib/main.dart`.
2. At the top, next to `import 'package:flutter/material.dart';`, add the theme import:

```dart
import 'theme/theme.dart';
```

3. Find your `MaterialApp(...)` and give it the three lines `theme`, `darkTheme` and `themeMode`. A complete `main.dart` looks like this:

```dart
import 'package:flutter/material.dart';

import 'theme/theme.dart';

void main() {
  runApp(const MatchUpApp());
}

class MatchUpApp extends StatelessWidget {
  const MatchUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MatchUp',
      theme: MuTheme.light(), // « Light »
      darkTheme: MuTheme.dark(), // « Night match »
      themeMode: ThemeMode.system, // follows the phone setting
      home: const Scaffold(
        body: Center(child: Text('Joue. Réserve. Progresse.')),
      ),
    );
  }
}
```

4. Run the app (`flutter run`). Switch the phone between light and dark mode: the app follows.

From now on, stock Material widgets already look like MatchUp: `FilledButton` is the primary button (ink in Light, Volt in Night match), `OutlinedButton` the secondary, `TextButton` the tertiary, `TextField` is 48 tall with an 8 radius, `FilterChip` turns Volt when selected, `NavigationBar` has the Volt pill, `SnackBar` is dark in both themes, and so on.

In files other than `main.dart`, import the theme with the right relative path, for example `import '../theme/theme.dart';` from `lib/screens/home_screen.dart`, or with the package path `import 'package:your_app/theme/theme.dart';` (replace `your_app` with the `name:` written at the top of `pubspec.yaml`).

## Step 4 — Use the tokens in a widget

Never type a hex colour, a font size or a random number of pixels. Read them from the theme:

| You need | Write | Notes |
|---|---|---|
| A colour | `context.mu.surfaceMuted` | Changes with the theme. Same names as tokens.json in camelCase: `text-secondary` → `textSecondary`. |
| A space | `MuSpace.s4` | 16. The scale is `s1` 4, `s2` 8, `s3` 12, `s4` 16, `s5` 20, `s6` 24, `s8` 32, `s10` 40, `s12` 48, `s16` 64. |
| A corner radius | `MuRadius.md` (a number) or `MuRadius.mdAll` (a `BorderRadius`) | `xs` 4, `sm` 8, `md` 12, `lg` 16, `full`. `MuRadius.lgTop` for sheets. |
| A text style | `MuType.body`, `MuType.label`, `MuType.h2`… | Prices, scores, times, levels: `MuType.numM`, `MuType.numS`… (tabular digits). |
| A size | `MuSize.controlL`, `MuSize.iconM`, `MuSize.avatarM`, `MuSize.touchTarget` | Sheet heights are fractions: `MuSize.sheetHalf` is 0.55. |
| A duration or curve | `MuMotion.base`, `MuMotion.enter` | See step 8 for reduced motion. |
| A shadow | `MuElevation.of(context).level1` | A list of `BoxShadow`. Night match gives hairline rings, as the tokens say. |
| A gradient | `MuGradients.ai`, `MuGradients.photoScrim` | The AI gradient is for AI features only. |

Example — a price tile. Create `lib/widgets/price_tile.dart` and paste:

```dart
import 'package:flutter/material.dart';

import '../theme/theme.dart';

class PriceTile extends StatelessWidget {
  const PriceTile({super.key, required this.price});

  final String price; // for example '15 DT'

  @override
  Widget build(BuildContext context) {
    final colors = context.mu; // the colours of the current theme
    return Container(
      padding: const EdgeInsets.all(MuSpace.s4),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(MuRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Par personne'.toUpperCase(), // overline is always in capitals
            style: MuType.overline.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: MuSpace.s1),
          Text(price, style: MuType.numM),
        ],
      ),
    );
  }
}
```

Things to know:

- Text styles have no colour on purpose. They take `text` automatically; add a colour with `.copyWith(color: colors.textSecondary)`.
- Do not change `fontWeight` with `copyWith`: pick the style that has the weight you need (`body` 400, `label` 600…).
- `overline` is not uppercased by the style: call `.toUpperCase()` on the string, as above.
- Sport colours: `MuSport.football.color(colors)` for pins and accents, `.text(colors)` for text and icons, `.soft(colors)` for chip backgrounds, `.label` for the word (« Football », « Padel », « Basket »). Always show the sport icon and label with the colour.
- Status colours (`MuTone.success`, `MuTone.error`…) work the same way: `.color(colors)`, `.text(colors)`, `.soft(colors)`. Status is never colour alone: add an icon and a word.
- Chart series: `MuChartColor.chart1.color(colors)`, in order 1 to 8.

## Step 5 — Icons (Phosphor)

1. At the top of the file, add `import 'package:phosphor_flutter/phosphor_flutter.dart';`.
2. Use the **Regular** style everywhere: `Icon(PhosphorIcons.mapPin())`.
3. Use the **Fill** style only for the selected tab in the tab bar (and other « on » states): `Icon(PhosphorIcons.house(PhosphorIconsStyle.fill))`.
4. Sizes: `MuSize.iconM` (24) by default, `MuSize.iconS` (20) in buttons and chips, `MuSize.iconXs` (16) in badges.

The bottom tab bar, with the Volt pill and Fill icon on the selected tab, is a stock `NavigationBar`:

```dart
NavigationBar(
  selectedIndex: index,
  onDestinationSelected: (int i) => setState(() => index = i),
  destinations: [
    NavigationDestination(
      icon: Icon(PhosphorIcons.house()),
      selectedIcon: Icon(PhosphorIcons.house(PhosphorIconsStyle.fill)),
      label: 'Accueil',
    ),
    NavigationDestination(
      icon: Icon(PhosphorIcons.compass()),
      selectedIcon: Icon(PhosphorIcons.compass(PhosphorIconsStyle.fill)),
      label: 'Explorer',
    ),
    NavigationDestination(
      icon: Icon(PhosphorIcons.calendarCheck()),
      selectedIcon: Icon(PhosphorIcons.calendarCheck(PhosphorIconsStyle.fill)),
      label: 'Mes matchs',
    ),
    NavigationDestination(
      icon: Icon(PhosphorIcons.barbell()),
      selectedIcon: Icon(PhosphorIcons.barbell(PhosphorIconsStyle.fill)),
      label: 'Entraînement',
    ),
    NavigationDestination(
      icon: Icon(PhosphorIcons.usersThree()),
      selectedIcon: Icon(PhosphorIcons.usersThree(PhosphorIconsStyle.fill)),
      label: 'Communauté',
    ),
  ],
)
```

Icon-only buttons need a name for screen readers: `IconButton(tooltip: 'Notifications', icon: Icon(PhosphorIcons.bell()), onPressed: …)`.

## Step 6 — Sport icons (custom SVG)

Football, padel and basketball have custom icons drawn to sit next to Phosphor Regular.

1. In the package, the folder `assets/icons/sport/` holds `football.svg`, `padel.svg`, `basketball.svg`, `whistle.svg`, `trophy.svg` and `court.svg`.
2. Copy the whole `assets` folder to the root of your app, next to `lib/`, so you have `your_app/assets/icons/sport/football.svg`. If your app already has an `assets` folder, copy only `icons/` into it.
3. Declare the folder in `pubspec.yaml`. Find the section `flutter:` at the **left edge** (not the one under `dependencies:`) and add the `assets:` lines, two spaces then four spaces of indentation:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/icons/sport/
```

4. Run `flutter pub get`, then stop and restart the app (a hot reload does not pick up new assets).
5. Show an icon in the sport colour. `MuSport.padel.asset` already holds the path `assets/icons/sport/padel.svg`:

```dart
import 'package:flutter_svg/flutter_svg.dart';

// …inside build():
final colors = context.mu;
const sport = MuSport.padel;

Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    SvgPicture.asset(
      sport.asset,
      width: MuSize.iconS,
      height: MuSize.iconS,
      colorFilter: ColorFilter.mode(sport.text(colors), BlendMode.srcIn),
      excludeFromSemantics: true, // the label next to it is read instead
    ),
    const SizedBox(width: MuSpace.s1),
    Text(sport.label, style: MuType.label.copyWith(color: sport.text(colors))),
  ],
)
```

The files are drawn in ink; `colorFilter` repaints them in any colour.

## Step 7 — Arabic and right-to-left (RTL)

Flutter flips the whole layout to right-to-left by itself when the locale is Arabic. You only need to declare the languages and switch the fonts.

1. In `pubspec.yaml`, under `dependencies:`, add these two lines (two spaces, then four):

```yaml
  flutter_localizations:
    sdk: flutter
```

2. Run `flutter pub get`.
3. In `lib/main.dart`, add `import 'package:flutter_localizations/flutter_localizations.dart';` at the top and give `MaterialApp` the locale settings. `arabic: true` makes the theme use the Arabic type styles (IBM Plex Sans Arabic, taller lines):

```dart
const Locale locale = Locale('ar'); // Locale('fr') for French
final bool isArabic = locale.languageCode == 'ar';

return MaterialApp(
  locale: locale,
  supportedLocales: const [Locale('fr'), Locale('ar')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: MuTheme.light(arabic: isArabic),
  darkTheme: MuTheme.dark(arabic: isArabic),
  themeMode: ThemeMode.system,
  home: const HomeScreen(),
);
```

4. In your widgets, think « start » and « end », never « left » and « right »: use `EdgeInsetsDirectional.only(start: MuSpace.s4)`, `AlignmentDirectional.centerStart`, `PositionedDirectional(end: …)`, `CrossAxisAlignment.start`. These flip automatically.
5. **Do not mirror** numbers, scores, prices, times, phone numbers, maps and media controls (play, seek). Wrap them in a left-to-right `Directionality`:

```dart
Directionality(
  textDirection: TextDirection.ltr,
  child: Text('3 – 2', style: MuType.score),
)
```

6. Digits stay Western (0–9) in every language: the numeral styles (`MuType.numM`…) are Barlow Condensed in Arabic too. Format numbers with the French rules (« 1 250 DT ») even when the app is in Arabic.
7. Directional icons (arrows, carets, « next ») must point the other way in RTL. Material's back button already does it; for Phosphor icons flip them yourself:

```dart
Transform.flip(
  flipX: Directionality.of(context) == TextDirection.rtl,
  child: Icon(PhosphorIcons.caretRight()),
)
```

## Step 8 — Motion and reduced motion

- Use the motion tokens instead of your own numbers: `AnimatedContainer(duration: MuMotion.base, curve: MuMotion.enter, …)`. `fast` 150 ms for presses and toggles, `base` 200 ms for popovers and tabs, `slow` 250 ms for sheets and dialogs. `MuMotion.enter` for things appearing, `MuMotion.exit` for things leaving, `MuMotion.move` for things moving.
- Pressed buttons, cards and chips shrink slightly: `AnimatedScale(scale: pressed ? MuMotion.pressScale : 1.0, duration: MuMotion.fast, child: …)`.
- **Reduced motion is mandatory.** Some people turn animations off in the phone settings. Flutter tells you with `MediaQuery.of(context).disableAnimations`. When it is `true`, animate with a zero duration and do not start repeating animations (the live-dot pulse, skeleton and AI shimmers):

```dart
final bool reduceMotion = MediaQuery.of(context).disableAnimations;

AnimatedOpacity(
  opacity: visible ? 1.0 : 0.0,
  duration: reduceMotion ? Duration.zero : MuMotion.base,
  curve: MuMotion.enter,
  child: child,
)
```

The shortcut `MuMotion.durationOf(context, MuMotion.base)` does the same thing in one call. Never use motion alone to say something important: the information must also be in text or an icon.

## Step 9 — Shadows, gradients and the focus ring

- Cards: `Card(child: …)` already uses `surface`, radius 12 and the Night match hairline. For a custom box use `BoxDecoration(color: colors.surface, borderRadius: MuRadius.mdAll, boxShadow: MuElevation.of(context).level1)`.
- Levels: `level1` cards at rest, `level2` popovers, menus and the FAB, `level2Up` the sticky bottom bar and tab bar, `level3` sheets and dialogs. In Night match these are hairline rings plus a dark shadow; elevation is mainly shown by `colors.surfaceElevated`.
- Keyboard focus ring (2 px gap + 2 px `focus`): add `MuElevation.of(context).focusRing` to the `boxShadow` of a focused custom control.
- AI features only: `BoxDecoration(gradient: MuGradients.ai)`, or `ShaderMask(shaderCallback: MuGradients.ai.createShader, child: …)` for a gradient icon.
- Text on top of a photo: put `DecoratedBox(decoration: BoxDecoration(gradient: MuGradients.photoScrim))` between the photo and the text.
- Dialogs: pass `barrierColor: context.mu.scrim` to `showDialog` (bottom sheets get the scrim from the theme).

## Step 10 — Check that it works

Run `flutter run` and check on a phone or emulator:

1. The page background is a very light grey-blue and cards are white in Light; both are dark blue in Night match.
2. A `FilledButton` is dark ink with white text in Light, and Volt (yellow-green) with ink text in Night match.
3. Text is in Plus Jakarta Sans (rounded, geometric), prices in `MuType.num*` are tall and narrow (Barlow Condensed).
4. A `FilterChip` turns Volt with ink text and a check when selected.
5. With animations turned off in the phone settings (Android: Accessibility, « Remove animations »; iOS: Accessibility, Motion, « Reduce Motion »), nothing slides or pulses.

## When the tokens change

1. Download the new `tokens.json` from the MatchUp design system and put it in the package's `tool/` folder (replace the old one).
2. In a terminal, go into `tool/` and run `python3 flutter_gen.py tokens.json ../lib/theme`. It rewrites the five Dart files and stops with an error if a token the Flutter theme relies on was renamed or removed.
3. Copy `lib/theme/` into your app again (replace the old files), then restart the app.

## Good to know

- **Fonts.** `google_fonts` downloads the fonts the first time the app runs, so the first launch needs internet (before that you see the system font). For a release build, bundle the fonts instead: download Plus Jakarta Sans, Barlow Condensed and IBM Plex Sans Arabic from fonts.google.com, copy the `.ttf` files (for Plus Jakarta Sans, the ones in the `static` subfolder, such as `PlusJakartaSans-SemiBold.ttf`) into `assets/google_fonts/` without renaming them, add `- assets/google_fonts/` under `assets:` in `pubspec.yaml`, and add `GoogleFonts.config.allowRuntimeFetching = false;` as the first line of `main()` (with `import 'package:google_fonts/google_fonts.dart';`). The design system's `.woff2` font files are for the web and do not work in Flutter.
- **What the theme cannot do alone.** Some parts of the design need the MatchUp widgets (built on top of this theme) rather than stock Material: the S, L and XL button sizes (stock buttons are M, 40 tall), the focus ring with its 2 px gap, the AI assistant FAB with the gradient (`FloatingActionButton` is themed as a plain primary FAB), the white bordered slider thumb of LevelSlider and RangeSlider, and the 48 × 28 switch of the web (Material's switch is 52 × 32, themed with the same colours).
- **Newer Flutter versions.** On recent Flutter releases the analyzer may suggest `AppBarThemeData` or `InputDecorationThemeData` instead of `AppBarTheme` and `InputDecorationTheme`. Those are hints, not errors: the app still builds.

## Troubleshooting

| Message | Fix |
|---|---|
| `Target of URI doesn't exist: 'package:google_fonts/google_fonts.dart'` | Step 2 is not done: add the packages and run `flutter pub get`. |
| `The getter 'mu' isn't defined for the type 'BuildContext'` | Add `import '../theme/theme.dart';` (with the right path) at the top of the file. |
| `Null check operator used on a null value` on a line with `context.mu` | `MaterialApp` is not using the MatchUp theme: do step 3. |
| `Unable to load asset: assets/icons/sport/…svg` | Step 6: check the folder is at `your_app/assets/icons/sport/`, the `assets:` lines in `pubspec.yaml`, then stop and restart the app. |
| Text shows in the default font | The fonts could not be downloaded (no internet on first launch), or see « Fonts » above. |
