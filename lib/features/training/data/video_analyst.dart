import 'training_models.dart';

/// The AI video analysis, faked until the assistant exists (phase 18): the bandeja of
/// ven. 16 oct. at Smash Padel Club as designed (ENT-09), and the same three habits, worded for
/// the stroke, for the other moves.
abstract final class VideoAnalyst {
  /// Sent, detection, comparison, writing (labels: videoSteps in plan_labels.dart).
  static const stepCount = 4;

  /// The tips it writes.
  static const tipCount = 3;

  /// The clip as the analysis reads it: 0:42 filmed at Smash Padel Club.
  static const clip = Duration(seconds: 42);
  static const venue = 'Smash Padel Club';

  static VideoAnalysis analyse({
    required String id,
    required VideoMove move,
    required String fileName,
    required int sizeBytes,
    required DateTime now,
    bool share = false,
  }) {
    final bandeja = move == VideoMove.bandeja;
    return VideoAnalysis(
      id: id,
      move: move,
      fileName: fileName,
      sizeBytes: sizeBytes,
      duration: clip,
      filmedAt: now,
      venue: venue,
      analysedAt: now.add(const Duration(minutes: 6)),
      sharedWithCoach: share,
      summary: bandeja
          ? 'Bons appuis et épaule bien de profil : la base de ta bandeja est là.\n\n'
                'Ta balle part souvent longue, parce que le contact est trop en arrière et que ton '
                'geste s’arrête tôt. Commence par le conseil 1 : il corrige la moitié du problème.'
          : 'Bons appuis : la base de ton geste est là.\n\n'
                'Le contact se fait souvent trop en arrière et ton geste s’arrête tôt. Commence '
                'par le conseil 1 : il corrige la moitié du problème.',
      confidenceNote:
          'Confiance moyenne : la vidéo est filmée de trois quarts. Filme bien de côté pour un '
          'avis plus précis.',
      tips: [
        AnalysisTip(
          priority: 1,
          at: const Duration(seconds: 21),
          title: 'Frappe devant l’épaule',
          text: bandeja
              ? 'Le contact se fait derrière ta tête, la balle part longue et tape la vitre du '
                    'fond. Avance le point d’impact d’environ 30 cm.'
              : 'Le contact se fait derrière ta tête, la balle part longue. Avance le point '
                    'd’impact d’environ 30 cm.',
          link: 'Séance 2 · Le contact devant l’épaule',
          linkKind: TipLinkKind.exercise,
          programId: 'bandeja',
        ),
        const AnalysisTip(
          priority: 2,
          at: Duration(seconds: 8),
          title: 'Arme plus tôt',
          text:
              'Ta raquette monte après le rebond. Arme dès que le lob passe au-dessus de toi, '
              'épaule de profil.',
          link: 'Armé face au grillage · 3 × 10',
          linkKind: TipLinkKind.exercise,
          programId: 'bandeja',
        ),
        AnalysisTip(
          priority: 3,
          at: const Duration(seconds: 35),
          title: 'Finis vers la grille latérale',
          text: bandeja
              ? 'Ton geste s’arrête trop tôt. Accompagne la raquette vers le côté pour croiser '
                    'ta bandeja.'
              : 'Ton geste s’arrête trop tôt. Accompagne la raquette vers le côté.',
          link: 'Séance 6 · Bandeja sous pression',
          linkKind: TipLinkKind.nextSession,
          programId: 'bandeja',
        ),
      ],
    );
  }
}
