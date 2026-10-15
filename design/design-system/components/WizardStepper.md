# WizardStepper

Shows where you are in a multi-step flow — creating a tournament: Infos · Format · Règles · Lieu & terrains · Dates · Frais & prix · Aperçu.

## When to use
- **Horizontal** above the form of a desktop wizard with 3–7 steps (create a tournament, a program, onboard a venue).
- **Vertical** in a side panel, when each step’s summary is worth seeing.
- **Compact** on mobile, under the app bar: « Étape 3 sur 7 · Règles » + segmented progress.

## Anatomy & specs
| Part | Spec |
|---|---|
| Marker | 32 (`control-s`) circle; numbers in `num-s` |
| Done | `primary` fill, check 18 in `on-primary`; label `body` in `text` |
| Current | `accent` fill, number in `on-accent`, 4px `accent` halo at 28%; label `label` in `text` |
| Upcoming | 1.5px `border-strong` ring; number and `body` label in `text-secondary` |
| Error | `error-soft` fill, 1.5px `error` ring, warning-circle (Fill) in `error-text`; `label` + `caption` reason in `error-text` |
| Connector | 2px, `radius-full`, `space-2` from the markers; `primary` up to the current step, `border` after |
| Horizontal | equal columns; label `space-2` under the marker, centred, one line |
| Vertical | marker + text, gap `space-3`, steps `space-6` apart, `caption` summary |
| Compact | `caption` « Étape 3 sur 7 » · `label` title; `caption` « Suivant : … » or the error in `error-text`; 4px segments, gap `space-1`: `primary` up to the current step, `error` for steps to fix, `border` after |

## Variants
`horizontal` · `vertical` · `compact`. Step status is derived from `current` (done before, upcoming after) unless a step sets `status` or `error`.

## States
- Done and error steps are buttons: hover underlines the label and lifts the marker (`primary-hover`, 1.06, `ease-pop`); focus draws `focus-ring` around marker and label.
- Current and upcoming steps are not clickable — validate before moving forward.

## Content
- Step names are nouns, one to three words, the same ones as the page titles.
- Error captions say what to do: « Ajoute au moins un prix ». Vertical summaries recap choices: « Poules puis élimination directe ».

## Accessibility
- An `ol` with `aria-label`; the current step has `aria-current="step"`; each step adds hidden text « — étape 3, en cours / terminée / à corriger / à venir ».
- Compact is a `progressbar` with `aria-valuetext` « Étape 3 sur 7 : Règles ».
- Never colour alone: check, number, warning icon and words carry the state.

## Do / Don't
- Do let people go back to done steps and keep what they entered.
- Do save a draft at every step (« Brouillon enregistré · il y a 2 min »).
- Don’t go beyond 7 steps — group them. Don’t use it as tabs.

## Props (web preview)
`steps` (`label`, `description`, `status`, `error`) · `current` · `onStepClick` · `variant` · `label` · `states`. See `index.d.ts`.

## Flutter
`MuWizardStepper(steps: [MuStep('Infos'), …], current: 2, onStepTap:, variant: MuStepperVariant.horizontal)` — a `Row` of `Expanded` columns with a `CustomPainter` connector (Flutter’s `Stepper` is too opinionated); vertical is a `Column` with `IntrinsicHeight` rows; compact is a `Row` of `Expanded` 4px `DecoratedBox` segments inside `Semantics(value: 'Étape 3 sur 7 : Règles')`.
