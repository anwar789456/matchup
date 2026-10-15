# FileUpload

Adds photos and documents: a drop zone with progress rows, an image grid with square thumbnails, and a circular profile-photo variant.

## When to use
- **dropzone** — venue photos, coach certificates, documents: several files with names and progress.
- **grid** — galleries where the image matters more than the name (venue gallery, post photos); the first photo is the cover.
- **avatar** — the player's or coach's profile photo.

## Anatomy & specs
- **Drop zone**: full width, min 176 high, padding `space-6` `space-4`, `radius-sm`, `surface`, 1.5px dashed `border-strong`; centred icon (`upload-simple` 24 in a 48 `surface-muted` circle), title `label` « Glisse tes photos ici ou parcours tes fichiers » (the link part in `link`, underlined) and hint `caption` « JPG, PNG · 10 Mo max ».
- **File row**: `space-2` apart, padding `space-3`, 1px `border`, `radius-sm`, `surface`; 40 type tile (`file-image`, `file-pdf`, `file-video`, `file-text` on `surface-muted`), name `label` (ellipsis), meta `caption`, actions at the end (IconButton S, tertiary Button S).
- **Progress**: 4px bar, `radius-full`, track `border`, fill `primary`; « 1,5 Mo sur 2,4 Mo » and « 64 % » (`num-xs`).
- **Grid**: square tiles (min 104), `space-2` gaps, `radius-sm`; thumbnails stand in with CourtArt `pattern`; a 28 on-media ✕ (44 hit area); « Couverture » pill (`surface-inverse`, `label-s`) on the first; dashed « Ajouter » tile; counter « 5/8 ».
- **Avatar**: 96 circle (`avatar-xl`); empty = dashed `border-strong` + `camera-plus`; a camera IconButton S on the photo; title, hint and actions (« Choisir une photo » / « Changer », « Retirer ») beside it, `space-5` apart.

## States
- Zone: default, hover (`text-secondary` border), focus (`focus-ring`), error (`error` border + message), disabled (`disabled-fill`, explains why).
- **Drag-over**: Volt as a fill — `accent` ground, `on-accent` dashed border, text and icon, the icon circle turns `on-accent` with an `accent` arrow; title « Dépose tes photos ici ». Same on the « Ajouter » tile and the avatar.
- **Uploading**: progress bar and cancel ✕ (rows); faded thumbnail with a 56 progress ring on `surface` (grid); 108 ring around the faded avatar (avatar).
- **Done**: « Envoyé » with `check-circle` in `success-text`, then remove (`trash`).
- **Error**: `error` border, `warning-circle` tile on `error-soft`, message in `error-text` and the action that fixes it — « Fichier trop lourd (max 10 Mo) » → « Remplacer »; « Échec de l’envoi. Vérifie ta connexion. » → « Réessayer ». On a grid tile the whole tile retries.

## Content
- Say what helps: « Montre l’éclairage et les vestiaires : les joueurs réservent plus vite. »
- Hints list formats then size: « JPG, PNG · 10 Mo max »; sizes in Ko/Mo with a comma and a no-break space (« 2,4 Mo »).
- On mobile the zone reads « Ajouter des photos » and opens the camera / gallery sheet — there is nothing to drag.

## Accessibility
- The zone and the « Ajouter » tile are buttons named by the label and the title, described by the hint; the native file input is hidden from the tab order.
- Progress uses `role="progressbar"` with `aria-valuenow` and a name (« Envoi de vestiaires.jpg »).
- Every ✕ names its file: « Annuler l’envoi de vestiaires.jpg », « Retirer parking-de-nuit.png ».
- Status is colour + icon + words; drag-over also changes the text.

## Do / Don't
- Do validate type and size before uploading and keep rejected files in the list with the fix.
- Do keep uploads going while the player edits the rest of the form.
- Don't use « Réessayer » for a file that is too heavy — it will fail again.
- Don't crop the profile photo silently; show the circle before saving.

## Props (web preview)
`variant` · `label` · `optional` · `helper` · `error` · `title` · `hint` · `accept` · `maxSize` · `multiple` · `maxFiles` · `files` (`id`, `name`, `size`, `type`, `status`, `progress`, `error`, `action`) · `onAdd(accepted, rejected)` · `onRemove` · `onCancel` · `onRetry` · `onReplace` · `coverLabel` · `name` · `dragOver` · `disabled` · `state`. See `index.d.ts`.

## Flutter
`MuFileUpload(variant: MuUploadVariant.dropzone, files:, onAdd:, maxSize: 10 * 1024 * 1024, accept: ['jpg', 'png'])` — on mobile the zone is a button opening `image_picker` (camera or gallery) or `file_picker`; on desktop and web wrap it in a `DropTarget` (desktop_drop) to drive the drag-over state. Rows use `LinearProgressIndicator(value:, minHeight: 4)`; grid tiles a `GridView` with `SliverGridDelegateWithMaxCrossAxisExtent`; the avatar a `CircleAvatar` inside `CircularProgressIndicator(value:, strokeWidth: 3)`.
