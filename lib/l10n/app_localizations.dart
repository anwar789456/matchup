import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @compteBloquePendantMin.
  ///
  /// In fr, this message translates to:
  /// **'Compte bloqué pendant 15 min'**
  String get compteBloquePendantMin;

  /// No description provided for @apresTentativesIncorrectesOnBloque.
  ///
  /// In fr, this message translates to:
  /// **'Après 5 tentatives incorrectes, on bloque la connexion pour protéger ton compte.'**
  String get apresTentativesIncorrectesOnBloque;

  /// No description provided for @tuPourrasReessayerDans.
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras réessayer dans'**
  String get tuPourrasReessayerDans;

  /// No description provided for @tuPeuxTeReconnecter.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux te reconnecter'**
  String get tuPeuxTeReconnecter;

  /// No description provided for @ceNEtaitPasToi.
  ///
  /// In fr, this message translates to:
  /// **'Ce n’était pas toi ?'**
  String get ceNEtaitPasToi;

  /// No description provided for @reinitialiseTonMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialise ton mot de passe maintenant : toutes tes sessions seront fermées. On t’a aussi prévenu par email.'**
  String get reinitialiseTonMotDePasse;

  /// No description provided for @reinitialiserMonMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser mon mot de passe'**
  String get reinitialiserMonMotDePasse;

  /// No description provided for @contacterLeSupport.
  ///
  /// In fr, this message translates to:
  /// **'Contacter le support'**
  String get contacterLeSupport;

  /// No description provided for @appelleNousAu.
  ///
  /// In fr, this message translates to:
  /// **'Appelle-nous au +216 71 234 567'**
  String get appelleNousAu;

  /// No description provided for @duLundiAuSamediDe.
  ///
  /// In fr, this message translates to:
  /// **'Du lundi au samedi, de 9h00 à 18h00.'**
  String get duLundiAuSamediDe;

  /// No description provided for @tonEmail.
  ///
  /// In fr, this message translates to:
  /// **'Ton email'**
  String get tonEmail;

  /// No description provided for @motDePasseOublie.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get motDePasseOublie;

  /// No description provided for @entreLEmailDeTon.
  ///
  /// In fr, this message translates to:
  /// **'Entre l’email de ton compte. On t’envoie un code à 6 chiffres pour choisir un nouveau mot de passe.'**
  String get entreLEmailDeTon;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @yassineBEmailTn.
  ///
  /// In fr, this message translates to:
  /// **'yassine.b@email.tn'**
  String get yassineBEmailTn;

  /// No description provided for @envoyerLeCode.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le code'**
  String get envoyerLeCode;

  /// No description provided for @contentDeTeRevoir.
  ///
  /// In fr, this message translates to:
  /// **'Content de te revoir'**
  String get contentDeTeRevoir;

  /// No description provided for @connecteToiPourRetrouverTes.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi pour retrouver tes parties et tes réservations.'**
  String get connecteToiPourRetrouverTes;

  /// No description provided for @seConnecter.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get seConnecter;

  /// No description provided for @pasEncoreDeCompte.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? '**
  String get pasEncoreDeCompte;

  /// No description provided for @creerUnCompte.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get creerUnCompte;

  /// No description provided for @nouveauMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get nouveauMotDePasse;

  /// No description provided for @choisisUnNouveauMotDe.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un nouveau mot de passe'**
  String get choisisUnNouveauMotDe;

  /// No description provided for @ilDoitEtreDifferentDe.
  ///
  /// In fr, this message translates to:
  /// **'Il doit être différent de l’ancien.'**
  String get ilDoitEtreDifferentDe;

  /// No description provided for @confirmeLeMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Confirme le mot de passe'**
  String get confirmeLeMotDePasse;

  /// No description provided for @enregistrer.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get enregistrer;

  /// No description provided for @motDePasseModifie.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié'**
  String get motDePasseModifie;

  /// No description provided for @tuPeuxMaintenantTeConnecter.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux maintenant te connecter avec ton nouveau mot de passe.'**
  String get tuPeuxMaintenantTeConnecter;

  /// No description provided for @tesAutresSessionsOntEte.
  ///
  /// In fr, this message translates to:
  /// **'Tes autres sessions ont été fermées'**
  String get tesAutresSessionsOntEte;

  /// No description provided for @parSecuriteOnTA.
  ///
  /// In fr, this message translates to:
  /// **'Par sécurité, on t’a déconnecté de tes autres appareils. Reconnecte-toi avec ton nouveau mot de passe.'**
  String get parSecuriteOnTA;

  /// No description provided for @leNumeroDoitContenirChiffres.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro doit contenir 8 chiffres.'**
  String get leNumeroDoitContenirChiffres;

  /// No description provided for @ajouteTonNumero.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ton numéro'**
  String get ajouteTonNumero;

  /// No description provided for @pourConfirmerLesPartiesEt.
  ///
  /// In fr, this message translates to:
  /// **'Pour confirmer les parties et sécuriser les paiements.'**
  String get pourConfirmerLesPartiesEt;

  /// No description provided for @onTEnvoieUnCode.
  ///
  /// In fr, this message translates to:
  /// **'On t’envoie un code à 6 chiffres par SMS.'**
  String get onTEnvoieUnCode;

  /// No description provided for @desPartiesConfirmees.
  ///
  /// In fr, this message translates to:
  /// **'Des parties confirmées.'**
  String get desPartiesConfirmees;

  /// No description provided for @unNumeroVerifieParJoueur.
  ///
  /// In fr, this message translates to:
  /// **' Un numéro vérifié par joueur, c’est moins d’absents le jour J.'**
  String get unNumeroVerifieParJoueur;

  /// No description provided for @desPaiementsProteges.
  ///
  /// In fr, this message translates to:
  /// **'Des paiements protégés.'**
  String get desPaiementsProteges;

  /// No description provided for @onSAssureQueC.
  ///
  /// In fr, this message translates to:
  /// **' On s’assure que c’est bien toi avant de débiter ta part.'**
  String get onSAssureQueC;

  /// No description provided for @tonNumeroRestePrive.
  ///
  /// In fr, this message translates to:
  /// **'Ton numéro reste privé.'**
  String get tonNumeroRestePrive;

  /// No description provided for @seulsLesOrganisateursDeTes.
  ///
  /// In fr, this message translates to:
  /// **' Seuls les organisateurs de tes parties le voient.'**
  String get seulsLesOrganisateursDeTes;

  /// No description provided for @recevoirLeCode.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le code'**
  String get recevoirLeCode;

  /// No description provided for @code.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @codeEnvoyeA.
  ///
  /// In fr, this message translates to:
  /// **'Code envoyé à '**
  String get codeEnvoyeA;

  /// No description provided for @modifier.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get modifier;

  /// No description provided for @codeRecuParEmail.
  ///
  /// In fr, this message translates to:
  /// **'Code reçu par email'**
  String get codeRecuParEmail;

  /// No description provided for @expireDansMinutesRegardeAussi.
  ///
  /// In fr, this message translates to:
  /// **'Expire dans 10 minutes. Regarde aussi dans tes spams.'**
  String get expireDansMinutesRegardeAussi;

  /// No description provided for @verifierLeCode.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier le code'**
  String get verifierLeCode;

  /// No description provided for @joueur.
  ///
  /// In fr, this message translates to:
  /// **'Joueur'**
  String get joueur;

  /// No description provided for @trouveDesPartiesReserveDes.
  ///
  /// In fr, this message translates to:
  /// **'Trouve des parties, réserve des terrains et paie ta part.'**
  String get trouveDesPartiesReserveDes;

  /// No description provided for @proprietaireDeTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire de terrain'**
  String get proprietaireDeTerrain;

  /// No description provided for @proprietaire.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get proprietaire;

  /// No description provided for @gereTesTerrainsTonPlanning.
  ///
  /// In fr, this message translates to:
  /// **'Gère tes terrains, ton planning et tes réservations.'**
  String get gereTesTerrainsTonPlanning;

  /// No description provided for @coach.
  ///
  /// In fr, this message translates to:
  /// **'Coach'**
  String get coach;

  /// No description provided for @publieTesProgrammesEtSuis.
  ///
  /// In fr, this message translates to:
  /// **'Publie tes programmes et suis la progression de tes élèves.'**
  String get publieTesProgrammesEtSuis;

  /// No description provided for @organisateur.
  ///
  /// In fr, this message translates to:
  /// **'Organisateur'**
  String get organisateur;

  /// No description provided for @creeEtGereTesTournois.
  ///
  /// In fr, this message translates to:
  /// **'Crée et gère tes tournois et tes événements.'**
  String get creeEtGereTesTournois;

  /// No description provided for @choisisAuMoinsUnRole.
  ///
  /// In fr, this message translates to:
  /// **'Choisis au moins un rôle'**
  String get choisisAuMoinsUnRole;

  /// No description provided for @continuerDAbord.
  ///
  /// In fr, this message translates to:
  /// **'Continuer · {p0} d’abord'**
  String continuerDAbord(Object p0);

  /// No description provided for @continuer.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continuer;

  /// No description provided for @commentVasTuUtiliserMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Comment vas-tu utiliser MatchUp ?'**
  String get commentVasTuUtiliserMatchup;

  /// No description provided for @choisisUnOuPlusieursRoles.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un ou plusieurs rôles.'**
  String get choisisUnOuPlusieursRoles;

  /// No description provided for @tesRolesSurMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Tes rôles sur MatchUp'**
  String get tesRolesSurMatchup;

  /// No description provided for @tuPourrasEnAjouterD.
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras en ajouter d’autres plus tard depuis ton profil.'**
  String get tuPourrasEnAjouterD;

  /// No description provided for @creeTonCompte.
  ///
  /// In fr, this message translates to:
  /// **'Crée ton compte'**
  String get creeTonCompte;

  /// No description provided for @trouveDesPartiesATon.
  ///
  /// In fr, this message translates to:
  /// **'Trouve des parties à ton niveau près de chez toi. C’est gratuit.'**
  String get trouveDesPartiesATon;

  /// No description provided for @cEstLeTien.
  ///
  /// In fr, this message translates to:
  /// **'C’est le tien ? '**
  String get cEstLeTien;

  /// No description provided for @jAccepteLesConditionsD.
  ///
  /// In fr, this message translates to:
  /// **'J’accepte les conditions d’utilisation et la politique de confidentialité'**
  String get jAccepteLesConditionsD;

  /// No description provided for @recevoirLesPartiesPresDe.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir les parties près de chez moi par email (facultatif)'**
  String get recevoirLesPartiesPresDe;

  /// No description provided for @creerMonCompte.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get creerMonCompte;

  /// No description provided for @codeEnvoyeAu.
  ///
  /// In fr, this message translates to:
  /// **'Code envoyé au '**
  String get codeEnvoyeAu;

  /// No description provided for @codeRecuParSms.
  ///
  /// In fr, this message translates to:
  /// **'Code reçu par SMS'**
  String get codeRecuParSms;

  /// No description provided for @leCodeExpireDansMinutes.
  ///
  /// In fr, this message translates to:
  /// **'Le code expire dans 10 minutes.'**
  String get leCodeExpireDansMinutes;

  /// No description provided for @verifier.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get verifier;

  /// No description provided for @emailRenvoye.
  ///
  /// In fr, this message translates to:
  /// **'Email renvoyé'**
  String get emailRenvoye;

  /// No description provided for @lienEnvoyeA.
  ///
  /// In fr, this message translates to:
  /// **'Lien envoyé à {p0}'**
  String lienEnvoyeA(Object p0);

  /// No description provided for @verifieTaBoiteMail.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ta boîte mail'**
  String get verifieTaBoiteMail;

  /// No description provided for @onAEnvoyeUnLien.
  ///
  /// In fr, this message translates to:
  /// **'On a envoyé un lien de confirmation à '**
  String get onAEnvoyeUnLien;

  /// No description provided for @ouvrirMaMessagerie.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir ma messagerie'**
  String get ouvrirMaMessagerie;

  /// No description provided for @ouvreTaMessagerie.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre ta messagerie'**
  String get ouvreTaMessagerie;

  /// No description provided for @leLienDeConfirmationT.
  ///
  /// In fr, this message translates to:
  /// **'Le lien de confirmation t’attend dans ta boîte.'**
  String get leLienDeConfirmationT;

  /// No description provided for @modifierLAdresse.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l’adresse'**
  String get modifierLAdresse;

  /// No description provided for @rienRecuRegardeDansTes.
  ///
  /// In fr, this message translates to:
  /// **'Rien reçu ? Regarde dans tes spams ou l’onglet Promotions.'**
  String get rienRecuRegardeDansTes;

  /// No description provided for @tuPourrasVerifierPlusTard.
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras vérifier plus tard. En attendant, un rappel s’affichera en haut de l’app.'**
  String get tuPourrasVerifierPlusTard;

  /// No description provided for @renvoyerLEmail.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer l’email'**
  String get renvoyerLEmail;

  /// No description provided for @unCompteExisteDejaAvec.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cet email.'**
  String get unCompteExisteDejaAvec;

  /// No description provided for @entreTonEmail.
  ///
  /// In fr, this message translates to:
  /// **'Entre ton email.'**
  String get entreTonEmail;

  /// No description provided for @ajouteLaFinDeTon.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute la fin de ton adresse, par exemple @gmail.com.'**
  String get ajouteLaFinDeTon;

  /// No description provided for @tonMotDePasseDoit.
  ///
  /// In fr, this message translates to:
  /// **'Ton mot de passe doit respecter les 3 règles.'**
  String get tonMotDePasseDoit;

  /// No description provided for @entreTonMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Entre ton mot de passe.'**
  String get entreTonMotDePasse;

  /// No description provided for @accepteLesConditionsPourContinuer.
  ///
  /// In fr, this message translates to:
  /// **'Accepte les conditions pour continuer.'**
  String get accepteLesConditionsPourContinuer;

  /// No description provided for @emailOuMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect.'**
  String get emailOuMotDePasse;

  /// No description provided for @entreLesChiffresDuCode.
  ///
  /// In fr, this message translates to:
  /// **'Entre les 6 chiffres du code.'**
  String get entreLesChiffresDuCode;

  /// No description provided for @tropDEssaisReessaieDans.
  ///
  /// In fr, this message translates to:
  /// **'Trop d’essais. Réessaie dans 10 minutes.'**
  String get tropDEssaisReessaieDans;

  /// No description provided for @numeroVerifie.
  ///
  /// In fr, this message translates to:
  /// **'Numéro vérifié.'**
  String get numeroVerifie;

  /// No description provided for @lesMotsDePasseCorrespondent.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe correspondent.'**
  String get lesMotsDePasseCorrespondent;

  /// No description provided for @lesMotsDePasseNe.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas.'**
  String get lesMotsDePasseNe;

  /// No description provided for @laConnexionNAPas.
  ///
  /// In fr, this message translates to:
  /// **'La connexion n’a pas abouti. Réessaie ou continue avec ton email.'**
  String get laConnexionNAPas;

  /// No description provided for @ilTeReste.
  ///
  /// In fr, this message translates to:
  /// **'Il te reste {p0} {p1}'**
  String ilTeReste(Object p0, Object p1);

  /// No description provided for @codeIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect. {p0}.'**
  String codeIncorrect(Object p0);

  /// No description provided for @avantLeBlocageTemporaire.
  ///
  /// In fr, this message translates to:
  /// **'{p0} avant le blocage temporaire.'**
  String avantLeBlocageTemporaire(Object p0);

  /// No description provided for @ouAvecTonEmail.
  ///
  /// In fr, this message translates to:
  /// **'ou avec ton email'**
  String get ouAvecTonEmail;

  /// No description provided for @entreLeCode.
  ///
  /// In fr, this message translates to:
  /// **'Entre le code'**
  String get entreLeCode;

  /// No description provided for @codeRenvoye.
  ///
  /// In fr, this message translates to:
  /// **'Code renvoyé'**
  String get codeRenvoye;

  /// No description provided for @mixte.
  ///
  /// In fr, this message translates to:
  /// **'Mixte'**
  String get mixte;

  /// No description provided for @femmes.
  ///
  /// In fr, this message translates to:
  /// **'Femmes'**
  String get femmes;

  /// No description provided for @hommes.
  ///
  /// In fr, this message translates to:
  /// **'Hommes'**
  String get hommes;

  /// No description provided for @couvert.
  ///
  /// In fr, this message translates to:
  /// **'Couvert'**
  String get couvert;

  /// No description provided for @partText.
  ///
  /// In fr, this message translates to:
  /// **'Part · {p0}'**
  String partText(Object p0);

  /// No description provided for @terrain.
  ///
  /// In fr, this message translates to:
  /// **'Terrain · {p0}'**
  String terrain(Object p0);

  /// No description provided for @template.
  ///
  /// In fr, this message translates to:
  /// **'TEMPLATE'**
  String get template;

  /// No description provided for @africaTunis.
  ///
  /// In fr, this message translates to:
  /// **'Africa/Tunis'**
  String get africaTunis;

  /// No description provided for @reservationHttpsMatchupTnR.
  ///
  /// In fr, this message translates to:
  /// **'Réservation {p0} · https://matchup.tn/r/{p1}'**
  String reservationHttpsMatchupTnR(Object p0, Object p1);

  /// No description provided for @fermerEtRevenirAL.
  ///
  /// In fr, this message translates to:
  /// **'Fermer et revenir à l’accueil'**
  String get fermerEtRevenirAL;

  /// No description provided for @ref.
  ///
  /// In fr, this message translates to:
  /// **'Réf. {p0}'**
  String ref(Object p0);

  /// No description provided for @cEstReserve.
  ///
  /// In fr, this message translates to:
  /// **'C’est réservé !'**
  String get cEstReserve;

  /// No description provided for @leTerrainEstPayeConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Le terrain est payé : {p0}. Confirmation envoyée à {p1}.'**
  String leTerrainEstPayeConfirmation(Object p0, Object p1);

  /// No description provided for @taPartDeEstPayee.
  ///
  /// In fr, this message translates to:
  /// **'Ta part de {p0} est payée. Confirmation envoyée à {p1}.'**
  String taPartDeEstPayee(Object p0, Object p1);

  /// No description provided for @presenteCeCodeAL.
  ///
  /// In fr, this message translates to:
  /// **'Présente ce code à l’accueil {p0}. Il est aussi dans Mes matchs.'**
  String presenteCeCodeAL(Object p0);

  /// No description provided for @ajouterAuCalendrier.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au calendrier'**
  String get ajouterAuCalendrier;

  /// No description provided for @partagerLeLien.
  ///
  /// In fr, this message translates to:
  /// **'Partager le lien'**
  String get partagerLeLien;

  /// No description provided for @rejoinsMoi.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins-moi : {p0}, {p1}. {p2}'**
  String rejoinsMoi(Object p0, Object p1, Object p2);

  /// No description provided for @taPartiePublique.
  ///
  /// In fr, this message translates to:
  /// **'Ta partie publique'**
  String get taPartiePublique;

  /// No description provided for @taPartiePrivee.
  ///
  /// In fr, this message translates to:
  /// **'Ta partie privée'**
  String get taPartiePrivee;

  /// No description provided for @niveau.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · niveau {p1} – {p2} · {p3}'**
  String niveau(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @surInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Sur invitation · {p0} {p1}'**
  String surInvitation(Object p0, Object p1);

  /// No description provided for @paiements.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get paiements;

  /// No description provided for @moi.
  ///
  /// In fr, this message translates to:
  /// **'Moi'**
  String get moi;

  /// No description provided for @tesJusquAu.
  ///
  /// In fr, this message translates to:
  /// **'Tes {p0} {p1} jusqu’au '**
  String tesJusquAu(Object p0, Object p1);

  /// No description provided for @pourPayerLeurPartOn.
  ///
  /// In fr, this message translates to:
  /// **' pour payer leur part. On les relance pour toi.'**
  String get pourPayerLeurPartOn;

  /// No description provided for @inviterDesJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Inviter des joueurs'**
  String get inviterDesJoueurs;

  /// No description provided for @voirMaReservation.
  ///
  /// In fr, this message translates to:
  /// **'Voir ma réservation'**
  String get voirMaReservation;

  /// No description provided for @retourALAccueil.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l’accueil'**
  String get retourALAccueil;

  /// No description provided for @laMarsa.
  ///
  /// In fr, this message translates to:
  /// **'La Marsa'**
  String get laMarsa;

  /// No description provided for @tesInvites.
  ///
  /// In fr, this message translates to:
  /// **'Tes invités'**
  String get tesInvites;

  /// No description provided for @continuerSansInviter.
  ///
  /// In fr, this message translates to:
  /// **'Continuer sans inviter'**
  String get continuerSansInviter;

  /// No description provided for @inviterEtContinuer.
  ///
  /// In fr, this message translates to:
  /// **'Inviter {p0} {p1} et continuer'**
  String inviterEtContinuer(Object p0, Object p1);

  /// No description provided for @invitationsEnvoyees.
  ///
  /// In fr, this message translates to:
  /// **'Invitations envoyées'**
  String get invitationsEnvoyees;

  /// No description provided for @inviteTesAmis.
  ///
  /// In fr, this message translates to:
  /// **'Invite tes amis'**
  String get inviteTesAmis;

  /// No description provided for @partieChacunPaieEnAcceptant.
  ///
  /// In fr, this message translates to:
  /// **'Partie {p0} · {p1} · {p2} · {p3}. Chacun paie {p4} en acceptant.'**
  String partieChacunPaieEnAcceptant(
    Object p0,
    Object p1,
    Object p2,
    Object p3,
    Object p4,
  );

  /// No description provided for @rechercherUnAmi.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un ami'**
  String get rechercherUnAmi;

  /// No description provided for @nomPseudoOuNumero.
  ///
  /// In fr, this message translates to:
  /// **'Nom, pseudo ou numéro'**
  String get nomPseudoOuNumero;

  /// No description provided for @aucunAmiInvite.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ami invité'**
  String get aucunAmiInvite;

  /// No description provided for @amiInvite.
  ///
  /// In fr, this message translates to:
  /// **'ami invité'**
  String get amiInvite;

  /// No description provided for @amisInvites.
  ///
  /// In fr, this message translates to:
  /// **'amis invités'**
  String get amisInvites;

  /// No description provided for @ilResteSur.
  ///
  /// In fr, this message translates to:
  /// **'Il reste {p0} {p1} sur {p2}'**
  String ilResteSur(Object p0, Object p1, Object p2);

  /// No description provided for @retirer.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {p0}'**
  String retirer(Object p0);

  /// No description provided for @coequipiersSuggeres.
  ///
  /// In fr, this message translates to:
  /// **'Coéquipiers suggérés'**
  String get coequipiersSuggeres;

  /// No description provided for @ilsOntDejaJoueAvec.
  ///
  /// In fr, this message translates to:
  /// **'Ils ont déjà joué avec toi à {p0} ou près de {p1}.'**
  String ilsOntDejaJoueAvec(Object p0, Object p1);

  /// No description provided for @aucunCoequipierNeSAppelle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun coéquipier ne s’appelle « {p0} ». Partage le lien ci-dessous.'**
  String aucunCoequipierNeSAppelle(Object p0);

  /// No description provided for @inviter.
  ///
  /// In fr, this message translates to:
  /// **'Inviter {p0}'**
  String inviter(Object p0);

  /// No description provided for @rejoinsMoiAuHttps.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins-moi au {p0} : {p1}, {p2}. https://{p3}'**
  String rejoinsMoiAuHttps(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @ouPartageLeLien.
  ///
  /// In fr, this message translates to:
  /// **'Ou partage le lien'**
  String get ouPartageLeLien;

  /// No description provided for @seulesLesPersonnesQuiOnt.
  ///
  /// In fr, this message translates to:
  /// **'Seules les personnes qui ont le lien peuvent rejoindre.'**
  String get seulesLesPersonnesQuiOnt;

  /// No description provided for @copierLeLien.
  ///
  /// In fr, this message translates to:
  /// **'Copier le lien'**
  String get copierLeLien;

  /// No description provided for @lienCopie.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié'**
  String get lienCopie;

  /// No description provided for @whatsapp.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @debutant.
  ///
  /// In fr, this message translates to:
  /// **'Débutant'**
  String get debutant;

  /// No description provided for @intermediaire.
  ///
  /// In fr, this message translates to:
  /// **'Intermédiaire'**
  String get intermediaire;

  /// No description provided for @avance.
  ///
  /// In fr, this message translates to:
  /// **'Avancé'**
  String get avance;

  /// No description provided for @expert.
  ///
  /// In fr, this message translates to:
  /// **'Expert'**
  String get expert;

  /// No description provided for @partiePublique.
  ///
  /// In fr, this message translates to:
  /// **'Partie publique'**
  String get partiePublique;

  /// No description provided for @completeTonEquipe.
  ///
  /// In fr, this message translates to:
  /// **'Complète ton équipe'**
  String get completeTonEquipe;

  /// No description provided for @joueursDejaDansLEquipe.
  ///
  /// In fr, this message translates to:
  /// **'{p0} joueurs déjà dans l’équipe'**
  String joueursDejaDansLEquipe(Object p0);

  /// No description provided for @toiSeulPourLInstant.
  ///
  /// In fr, this message translates to:
  /// **'Toi seul pour l’instant'**
  String get toiSeulPourLInstant;

  /// No description provided for @dejaJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Déjà {p0} joueurs'**
  String dejaJoueurs(Object p0);

  /// No description provided for @inviteDesAmisOuLaisse.
  ///
  /// In fr, this message translates to:
  /// **'Invite des amis ou laisse les joueurs te rejoindre'**
  String get inviteDesAmisOuLaisse;

  /// No description provided for @toiEt.
  ///
  /// In fr, this message translates to:
  /// **'Toi et {p0} {p1}'**
  String toiEt(Object p0, Object p1);

  /// No description provided for @placesACompleter.
  ///
  /// In fr, this message translates to:
  /// **'Places à compléter'**
  String get placesACompleter;

  /// No description provided for @joueursChacun.
  ///
  /// In fr, this message translates to:
  /// **'{p0} joueurs · {p1} chacun'**
  String joueursChacun(Object p0, Object p1);

  /// No description provided for @retirerUnePlace.
  ///
  /// In fr, this message translates to:
  /// **'Retirer une place'**
  String get retirerUnePlace;

  /// No description provided for @ajouterUnePlace.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une place'**
  String get ajouterUnePlace;

  /// No description provided for @niveauDesJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Niveau des joueurs'**
  String get niveauDesJoueurs;

  /// No description provided for @niveauMinimum.
  ///
  /// In fr, this message translates to:
  /// **'Niveau minimum'**
  String get niveauMinimum;

  /// No description provided for @niveauMaximum.
  ///
  /// In fr, this message translates to:
  /// **'Niveau maximum'**
  String get niveauMaximum;

  /// No description provided for @tonNiveauSeulsLesJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Ton niveau {p0} : {p1} · {p2}. Seuls les joueurs dans cette fourchette peuvent rejoindre.'**
  String tonNiveauSeulsLesJoueurs(Object p0, Object p1, Object p2);

  /// No description provided for @typeDePartie.
  ///
  /// In fr, this message translates to:
  /// **'Type de partie'**
  String get typeDePartie;

  /// No description provided for @quiPeutLaVoir.
  ///
  /// In fr, this message translates to:
  /// **'Qui peut la voir ?'**
  String get quiPeutLaVoir;

  /// No description provided for @toutLeMonde.
  ///
  /// In fr, this message translates to:
  /// **'Tout le monde'**
  String get toutLeMonde;

  /// No description provided for @visibleDansExplorerParLes.
  ///
  /// In fr, this message translates to:
  /// **'Visible dans Explorer par les joueurs de ton niveau.'**
  String get visibleDansExplorerParLes;

  /// No description provided for @mesAbonnes.
  ///
  /// In fr, this message translates to:
  /// **'Mes abonnés'**
  String get mesAbonnes;

  /// No description provided for @seulsLesJoueursQuiTe.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les joueurs qui te suivent la voient.'**
  String get seulsLesJoueursQuiTe;

  /// No description provided for @unMotPourLesJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Un mot pour les joueurs'**
  String get unMotPourLesJoueurs;

  /// No description provided for @ambiancePosteAPrendreMateriel.
  ///
  /// In fr, this message translates to:
  /// **'Ambiance, poste à prendre, matériel fourni…'**
  String get ambiancePosteAPrendreMateriel;

  /// No description provided for @foot.
  ///
  /// In fr, this message translates to:
  /// **'Foot {p0}'**
  String foot(Object p0);

  /// No description provided for @reservation.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · réservation {p1}'**
  String reservation(Object p0, Object p1);

  /// No description provided for @taPartJoueurSur.
  ///
  /// In fr, this message translates to:
  /// **'Ta part · 1 joueur sur {p0}'**
  String taPartJoueurSur(Object p0);

  /// No description provided for @leTerrainJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Le terrain · {p0} joueurs'**
  String leTerrainJoueurs(Object p0);

  /// No description provided for @taPartSur.
  ///
  /// In fr, this message translates to:
  /// **'Ta part : {p0} sur {p1}'**
  String taPartSur(Object p0, Object p1);

  /// No description provided for @quoi.
  ///
  /// In fr, this message translates to:
  /// **'Quoi'**
  String get quoi;

  /// No description provided for @partDeReservation.
  ///
  /// In fr, this message translates to:
  /// **'Part de réservation'**
  String get partDeReservation;

  /// No description provided for @partiePublique2.
  ///
  /// In fr, this message translates to:
  /// **'Partie publique · {p0} · {p1} – {p2}'**
  String partiePublique2(Object p0, Object p1, Object p2);

  /// No description provided for @partiePrivee.
  ///
  /// In fr, this message translates to:
  /// **'Partie privée'**
  String get partiePrivee;

  /// No description provided for @ou.
  ///
  /// In fr, this message translates to:
  /// **'Où'**
  String get ou;

  /// No description provided for @terrain2.
  ///
  /// In fr, this message translates to:
  /// **'Terrain'**
  String get terrain2;

  /// No description provided for @quand.
  ///
  /// In fr, this message translates to:
  /// **'Quand'**
  String get quand;

  /// No description provided for @heureDePointe.
  ///
  /// In fr, this message translates to:
  /// **' · heure de pointe'**
  String get heureDePointe;

  /// No description provided for @joueurs.
  ///
  /// In fr, this message translates to:
  /// **'Joueurs'**
  String get joueurs;

  /// No description provided for @placesEncoreOuvertes.
  ///
  /// In fr, this message translates to:
  /// **'{p0} places encore ouvertes'**
  String placesEncoreOuvertes(Object p0);

  /// No description provided for @partieEntreAmis.
  ///
  /// In fr, this message translates to:
  /// **'Partie entre amis'**
  String get partieEntreAmis;

  /// No description provided for @payerMaPart.
  ///
  /// In fr, this message translates to:
  /// **'Payer ma part'**
  String get payerMaPart;

  /// No description provided for @payerLeTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Payer le terrain'**
  String get payerLeTerrain;

  /// No description provided for @recapitulatif.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get recapitulatif;

  /// No description provided for @tes.
  ///
  /// In fr, this message translates to:
  /// **'Tes {p0} {p1}'**
  String tes(Object p0, Object p1);

  /// No description provided for @verifieEtPaieTaPart.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie et paie ta part'**
  String get verifieEtPaieTaPart;

  /// No description provided for @partie.
  ///
  /// In fr, this message translates to:
  /// **'Partie'**
  String get partie;

  /// No description provided for @publique.
  ///
  /// In fr, this message translates to:
  /// **'Publique · {p0} · {p1} – {p2}'**
  String publique(Object p0, Object p1, Object p2);

  /// No description provided for @priveeSurInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Privée · sur invitation'**
  String get priveeSurInvitation;

  /// No description provided for @joueursInscrits.
  ///
  /// In fr, this message translates to:
  /// **'{p0} joueurs inscrits'**
  String joueursInscrits(Object p0);

  /// No description provided for @modifierLaPartie.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la partie'**
  String get modifierLaPartie;

  /// No description provided for @quiPaieQuoi.
  ///
  /// In fr, this message translates to:
  /// **'Qui paie quoi ?'**
  String get quiPaieQuoi;

  /// No description provided for @partageDuPaiement.
  ///
  /// In fr, this message translates to:
  /// **'Partage du paiement'**
  String get partageDuPaiement;

  /// No description provided for @chacunPaieSaPart.
  ///
  /// In fr, this message translates to:
  /// **'Chacun paie sa part · {p0}'**
  String chacunPaieSaPart(Object p0);

  /// No description provided for @tuPaiesTaPartMaintenant.
  ///
  /// In fr, this message translates to:
  /// **'Tu paies ta part maintenant. Les autres paient la leur en rejoignant.'**
  String get tuPaiesTaPartMaintenant;

  /// No description provided for @tuPaiesTaPartMaintenant2.
  ///
  /// In fr, this message translates to:
  /// **'Tu paies ta part maintenant. {p0} paient la leur en {p1}.'**
  String tuPaiesTaPartMaintenant2(Object p0, Object p1);

  /// No description provided for @recommande.
  ///
  /// In fr, this message translates to:
  /// **'Recommandé'**
  String get recommande;

  /// No description provided for @jePaieTout.
  ///
  /// In fr, this message translates to:
  /// **'Je paie tout · {p0}'**
  String jePaieTout(Object p0);

  /// No description provided for @tuAvancesLeTerrainChaque.
  ///
  /// In fr, this message translates to:
  /// **'Tu avances le terrain. Chaque part payée ensuite t’est remboursée sur ton solde.'**
  String get tuAvancesLeTerrainChaque;

  /// No description provided for @toutDoitEtrePayeAvant.
  ///
  /// In fr, this message translates to:
  /// **'Tout doit être payé avant {p0}'**
  String toutDoitEtrePayeAvant(Object p0);

  /// No description provided for @sinonLaReservationEstAnnulee.
  ///
  /// In fr, this message translates to:
  /// **'Sinon la réservation est annulée et chacun est remboursé. Tu pourras payer le reste toi-même.'**
  String get sinonLaReservationEstAnnulee;

  /// No description provided for @utiliserMonSoldeMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser mon solde MatchUp'**
  String get utiliserMonSoldeMatchup;

  /// No description provided for @tuAvancesLeTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Tu avances le terrain'**
  String get tuAvancesLeTerrain;

  /// No description provided for @fraisDeService.
  ///
  /// In fr, this message translates to:
  /// **'Frais de service'**
  String get fraisDeService;

  /// No description provided for @offerts.
  ///
  /// In fr, this message translates to:
  /// **'Offerts'**
  String get offerts;

  /// No description provided for @soldeMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Solde MatchUp'**
  String get soldeMatchup;

  /// No description provided for @aPayerMaintenant.
  ///
  /// In fr, this message translates to:
  /// **'À payer maintenant'**
  String get aPayerMaintenant;

  /// No description provided for @siTuAnnules.
  ///
  /// In fr, this message translates to:
  /// **'Si tu annules'**
  String get siTuAnnules;

  /// No description provided for @politiqueAppliqueeAChaqueJoueur.
  ///
  /// In fr, this message translates to:
  /// **'Politique {p0}, appliquée à chaque joueur.'**
  String politiqueAppliqueeAChaqueJoueur(Object p0);

  /// No description provided for @enPayantTuAcceptesLes.
  ///
  /// In fr, this message translates to:
  /// **'En payant, tu acceptes les '**
  String get enPayantTuAcceptesLes;

  /// No description provided for @conditionsDeReservation.
  ///
  /// In fr, this message translates to:
  /// **'conditions de réservation'**
  String get conditionsDeReservation;

  /// No description provided for @etLaPolitiqueDAnnulation.
  ///
  /// In fr, this message translates to:
  /// **' {p0} et la politique d’annulation ci-dessus.'**
  String etLaPolitiqueDAnnulation(Object p0);

  /// No description provided for @continuerInviterMesAmis.
  ///
  /// In fr, this message translates to:
  /// **'Continuer · inviter mes amis'**
  String get continuerInviterMesAmis;

  /// No description provided for @quiJoueAvecToi.
  ///
  /// In fr, this message translates to:
  /// **'Qui joue avec toi ?'**
  String get quiJoueAvecToi;

  /// No description provided for @choisisQuiPeutRejoindreTon.
  ///
  /// In fr, this message translates to:
  /// **'Choisis qui peut rejoindre ton terrain. Tu pourras inviter tes amis dans les deux cas.'**
  String get choisisQuiPeutRejoindreTon;

  /// No description provided for @typeDeReservation.
  ///
  /// In fr, this message translates to:
  /// **'Type de réservation'**
  String get typeDeReservation;

  /// No description provided for @privee.
  ///
  /// In fr, this message translates to:
  /// **'Privée'**
  String get privee;

  /// No description provided for @jInviteMesAmisPersonne.
  ///
  /// In fr, this message translates to:
  /// **'J’invite mes amis. Personne d’autre ne peut rejoindre.'**
  String get jInviteMesAmisPersonne;

  /// No description provided for @publique2.
  ///
  /// In fr, this message translates to:
  /// **'Publique'**
  String get publique2;

  /// No description provided for @jeCompleteAvecDesJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Je complète avec des joueurs. Tes places libres s’affichent dans Explorer pour des joueurs à ton niveau.'**
  String get jeCompleteAvecDesJoueurs;

  /// No description provided for @chacunPaieSaPart2.
  ///
  /// In fr, this message translates to:
  /// **'Chacun paie sa part'**
  String get chacunPaieSaPart2;

  /// No description provided for @parPersonneATuChoisis.
  ///
  /// In fr, this message translates to:
  /// **'{p0} par personne à {p1}. Tu choisis comment partager à l’étape suivante.'**
  String parPersonneATuChoisis(Object p0, Object p1);

  /// No description provided for @retour.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get retour;

  /// No description provided for @aucuneReservationEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réservation en cours'**
  String get aucuneReservationEnCours;

  /// No description provided for @choisisUnTerrainEtUn.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un terrain et un créneau pour commencer.'**
  String get choisisUnTerrainEtUn;

  /// No description provided for @voirLesTerrains.
  ///
  /// In fr, this message translates to:
  /// **'Voir les terrains'**
  String get voirLesTerrains;

  /// No description provided for @profil.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profil;

  /// No description provided for @certification.
  ///
  /// In fr, this message translates to:
  /// **'Certification'**
  String get certification;

  /// No description provided for @premierProgramme.
  ///
  /// In fr, this message translates to:
  /// **'Premier programme'**
  String get premierProgramme;

  /// No description provided for @diplomeEnvoye.
  ///
  /// In fr, this message translates to:
  /// **'Diplôme envoyé'**
  String get diplomeEnvoye;

  /// No description provided for @peseMaxMoChoisisUn.
  ///
  /// In fr, this message translates to:
  /// **'{p0} pèse {p1} (max 10 Mo). Choisis un fichier plus léger.'**
  String peseMaxMoChoisisUn(Object p0, Object p1);

  /// No description provided for @fichierTropLourd.
  ///
  /// In fr, this message translates to:
  /// **'Fichier trop lourd'**
  String get fichierTropLourd;

  /// No description provided for @ajouteTonDiplomePourLancer.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ton diplôme pour lancer la vérification.'**
  String get ajouteTonDiplomePourLancer;

  /// No description provided for @diplomeOuCertificat.
  ///
  /// In fr, this message translates to:
  /// **'Diplôme ou certificat'**
  String get diplomeOuCertificat;

  /// No description provided for @glisseOuChoisisUnFichier.
  ///
  /// In fr, this message translates to:
  /// **'Glisse ou choisis un fichier'**
  String get glisseOuChoisisUnFichier;

  /// No description provided for @pdfJpgPngMoMax.
  ///
  /// In fr, this message translates to:
  /// **'PDF, JPG, PNG · 10 Mo max'**
  String get pdfJpgPngMoMax;

  /// No description provided for @taCertification.
  ///
  /// In fr, this message translates to:
  /// **'Ta certification'**
  String get taCertification;

  /// No description provided for @unDiplomeVerifieAfficheLe.
  ///
  /// In fr, this message translates to:
  /// **'Un diplôme vérifié affiche le badge « Coach vérifié » : les élèves réservent en confiance.'**
  String get unDiplomeVerifieAfficheLe;

  /// No description provided for @verificationSousH.
  ///
  /// In fr, this message translates to:
  /// **'Vérification sous 48 h'**
  String get verificationSousH;

  /// No description provided for @envoieTonDiplomeOnLe.
  ///
  /// In fr, this message translates to:
  /// **'Envoie ton diplôme : on le vérifie auprès de la fédération et tu reçois un email dès que c’est validé.'**
  String get envoieTonDiplomeOnLe;

  /// No description provided for @verificationEnCoursH.
  ///
  /// In fr, this message translates to:
  /// **'Vérification en cours · 48 h'**
  String get verificationEnCoursH;

  /// No description provided for @onVerifieTonDiplomeAupres.
  ///
  /// In fr, this message translates to:
  /// **'On vérifie ton diplôme auprès de la fédération. Tu reçois un email dès que c’est validé, au plus tard le {p0}'**
  String onVerifieTonDiplomeAupres(Object p0);

  /// No description provided for @enAttendantTuPeuxDeja.
  ///
  /// In fr, this message translates to:
  /// **'En attendant, tu peux déjà'**
  String get enAttendantTuPeuxDeja;

  /// No description provided for @creerEtPreparerTesProgrammes.
  ///
  /// In fr, this message translates to:
  /// **'Créer et préparer tes programmes'**
  String get creerEtPreparerTesProgrammes;

  /// No description provided for @completerTonProfilEtTes.
  ///
  /// In fr, this message translates to:
  /// **'Compléter ton profil et tes tarifs'**
  String get completerTonProfilEtTes;

  /// No description provided for @inviterTesElevesActuels.
  ///
  /// In fr, this message translates to:
  /// **'Inviter tes élèves actuels'**
  String get inviterTesElevesActuels;

  /// No description provided for @apresLaValidation.
  ///
  /// In fr, this message translates to:
  /// **'Après la validation'**
  String get apresLaValidation;

  /// No description provided for @publierTesProgrammes.
  ///
  /// In fr, this message translates to:
  /// **'Publier tes programmes'**
  String get publierTesProgrammes;

  /// No description provided for @recevoirLesPaiementsDeTes.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir les paiements de tes élèves'**
  String get recevoirLesPaiementsDeTes;

  /// No description provided for @apparaitreDansLaRechercheDe.
  ///
  /// In fr, this message translates to:
  /// **'Apparaître dans la recherche de coachs'**
  String get apparaitreDansLaRechercheDe;

  /// No description provided for @diplomeAEnvoyer.
  ///
  /// In fr, this message translates to:
  /// **'Diplôme à envoyer'**
  String get diplomeAEnvoyer;

  /// No description provided for @pdfJpgOuPng.
  ///
  /// In fr, this message translates to:
  /// **'PDF, JPG ou PNG'**
  String get pdfJpgOuPng;

  /// No description provided for @enVerification.
  ///
  /// In fr, this message translates to:
  /// **'En vérification'**
  String get enVerification;

  /// No description provided for @reponseSousH.
  ///
  /// In fr, this message translates to:
  /// **'Réponse sous 48 h'**
  String get reponseSousH;

  /// No description provided for @coachVerifie.
  ///
  /// In fr, this message translates to:
  /// **'Coach vérifié'**
  String get coachVerifie;

  /// No description provided for @badgeSurTonProfil.
  ///
  /// In fr, this message translates to:
  /// **'Badge sur ton profil'**
  String get badgeSurTonProfil;

  /// No description provided for @tonDossier.
  ///
  /// In fr, this message translates to:
  /// **'Ton dossier'**
  String get tonDossier;

  /// No description provided for @enAttente.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get enAttente;

  /// No description provided for @aEnvoyer.
  ///
  /// In fr, this message translates to:
  /// **'À envoyer'**
  String get aEnvoyer;

  /// No description provided for @tableauDeBord.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get tableauDeBord;

  /// No description provided for @coaching.
  ///
  /// In fr, this message translates to:
  /// **'Coaching'**
  String get coaching;

  /// No description provided for @programmes.
  ///
  /// In fr, this message translates to:
  /// **'Programmes'**
  String get programmes;

  /// No description provided for @eleves.
  ///
  /// In fr, this message translates to:
  /// **'Élèves'**
  String get eleves;

  /// No description provided for @retours.
  ///
  /// In fr, this message translates to:
  /// **'Retours'**
  String get retours;

  /// No description provided for @gestion.
  ///
  /// In fr, this message translates to:
  /// **'Gestion'**
  String get gestion;

  /// No description provided for @revenus.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get revenus;

  /// No description provided for @abonnement.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get abonnement;

  /// No description provided for @ajouteTonDiplomePourDevenir.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ton diplôme pour devenir « Coach vérifié »'**
  String get ajouteTonDiplomePourDevenir;

  /// No description provided for @tesProgrammesSerontPubliesDes.
  ///
  /// In fr, this message translates to:
  /// **'Tes programmes seront publiés dès la validation.'**
  String get tesProgrammesSerontPubliesDes;

  /// No description provided for @ajouter.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get ajouter;

  /// No description provided for @diplomeEnVerificationReponseSous.
  ///
  /// In fr, this message translates to:
  /// **'Diplôme en vérification · réponse sous 48 h'**
  String get diplomeEnVerificationReponseSous;

  /// No description provided for @prepareTesProgrammesIlsSeront.
  ///
  /// In fr, this message translates to:
  /// **'Prépare tes programmes : ils seront publiés dès la validation.'**
  String get prepareTesProgrammesIlsSeront;

  /// No description provided for @creeTonPremierProgramme.
  ///
  /// In fr, this message translates to:
  /// **'Crée ton premier programme'**
  String get creeTonPremierProgramme;

  /// No description provided for @desSemainesDeSeancesQue.
  ///
  /// In fr, this message translates to:
  /// **'Des semaines de séances que tes élèves suivent à leur rythme, avec tes vidéos et tes conseils.'**
  String get desSemainesDeSeancesQue;

  /// No description provided for @creerMonPremierProgramme.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon premier programme'**
  String get creerMonPremierProgramme;

  /// No description provided for @voirUnExemple.
  ///
  /// In fr, this message translates to:
  /// **'Voir un exemple'**
  String get voirUnExemple;

  /// No description provided for @aSemaines.
  ///
  /// In fr, this message translates to:
  /// **'4 à 12 semaines'**
  String get aSemaines;

  /// No description provided for @videosEtExercices.
  ///
  /// In fr, this message translates to:
  /// **'Vidéos et exercices'**
  String get videosEtExercices;

  /// No description provided for @tonPrixOuInclusDans.
  ///
  /// In fr, this message translates to:
  /// **'Ton prix, ou inclus dans Premium'**
  String get tonPrixOuInclusDans;

  /// No description provided for @assistantProgramme.
  ///
  /// In fr, this message translates to:
  /// **'Assistant programme'**
  String get assistantProgramme;

  /// No description provided for @lIaPeutProposerUn.
  ///
  /// In fr, this message translates to:
  /// **'L’IA peut proposer un plan de 4 semaines à partir de ta bio'**
  String get lIaPeutProposerUn;

  /// No description provided for @rienNEstPublieSans.
  ///
  /// In fr, this message translates to:
  /// **'Rien n’est publié sans toi : tu relis et modifies chaque séance.'**
  String get rienNEstPublieSans;

  /// No description provided for @baseSur.
  ///
  /// In fr, this message translates to:
  /// **'Basé sur'**
  String get baseSur;

  /// No description provided for @taBio.
  ///
  /// In fr, this message translates to:
  /// **'ta bio.'**
  String get taBio;

  /// No description provided for @taBioEtTesSpecialites.
  ///
  /// In fr, this message translates to:
  /// **'ta bio et tes spécialités : {p0}.'**
  String taBioEtTesSpecialites(Object p0);

  /// No description provided for @proposerUnPlan.
  ///
  /// In fr, this message translates to:
  /// **'Proposer un plan'**
  String get proposerUnPlan;

  /// No description provided for @plusTard.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get plusTard;

  /// No description provided for @coach2.
  ///
  /// In fr, this message translates to:
  /// **'Coach{p0} · {p1}'**
  String coach2(Object p0, Object p1);

  /// No description provided for @modifierMonProfil.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon profil'**
  String get modifierMonProfil;

  /// No description provided for @bienvenue.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue, {p0}'**
  String bienvenue(Object p0);

  /// No description provided for @tonProfilCoachEstPret.
  ///
  /// In fr, this message translates to:
  /// **'Ton profil coach est prêt. Crée ton premier programme pour accueillir tes élèves.'**
  String get tonProfilCoachEstPret;

  /// No description provided for @tesElevesApparaitrontIci.
  ///
  /// In fr, this message translates to:
  /// **'Tes élèves apparaîtront ici'**
  String get tesElevesApparaitrontIci;

  /// No description provided for @inscriptionsActives.
  ///
  /// In fr, this message translates to:
  /// **'Inscriptions actives'**
  String get inscriptionsActives;

  /// No description provided for @desTonPremierProgrammePublie.
  ///
  /// In fr, this message translates to:
  /// **'Dès ton premier programme publié'**
  String get desTonPremierProgrammePublie;

  /// No description provided for @revenusDuMois.
  ///
  /// In fr, this message translates to:
  /// **'Revenus du mois'**
  String get revenusDuMois;

  /// No description provided for @versesChaqueLundi.
  ///
  /// In fr, this message translates to:
  /// **'Versés chaque lundi'**
  String get versesChaqueLundi;

  /// No description provided for @noteMoyenne.
  ///
  /// In fr, this message translates to:
  /// **'Note moyenne'**
  String get noteMoyenne;

  /// No description provided for @apresLesPremiersRetours.
  ///
  /// In fr, this message translates to:
  /// **'Après les premiers retours'**
  String get apresLesPremiersRetours;

  /// No description provided for @presenteToiEnQuelquesPhrases.
  ///
  /// In fr, this message translates to:
  /// **'Présente-toi en quelques phrases.'**
  String get presenteToiEnQuelquesPhrases;

  /// No description provided for @choisisAuMoinsUneSpecialite.
  ///
  /// In fr, this message translates to:
  /// **'Choisis au moins une spécialité.'**
  String get choisisAuMoinsUneSpecialite;

  /// No description provided for @choisisAuMoinsUnSport.
  ///
  /// In fr, this message translates to:
  /// **'Choisis au moins un sport.'**
  String get choisisAuMoinsUnSport;

  /// No description provided for @choisisAuMoinsUnNiveau.
  ///
  /// In fr, this message translates to:
  /// **'Choisis au moins un niveau.'**
  String get choisisAuMoinsUnNiveau;

  /// No description provided for @sports.
  ///
  /// In fr, this message translates to:
  /// **'Sports'**
  String get sports;

  /// No description provided for @niveauxQueTuEntraines.
  ///
  /// In fr, this message translates to:
  /// **'Niveaux que tu entraînes'**
  String get niveauxQueTuEntraines;

  /// No description provided for @presenteToiAuxJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Présente-toi aux joueurs'**
  String get presenteToiAuxJoueurs;

  /// No description provided for @lesElevesChoisissentDAbord.
  ///
  /// In fr, this message translates to:
  /// **'Les élèves choisissent d’abord un coach, puis un programme. Sois précis.'**
  String get lesElevesChoisissentDAbord;

  /// No description provided for @photoDeProfil.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil'**
  String get photoDeProfil;

  /// No description provided for @jpgPngVisageBienVisible.
  ///
  /// In fr, this message translates to:
  /// **'JPG, PNG · visage bien visible'**
  String get jpgPngVisageBienVisible;

  /// No description provided for @villeOuTuCoaches.
  ///
  /// In fr, this message translates to:
  /// **'Ville où tu coaches'**
  String get villeOuTuCoaches;

  /// No description provided for @lesElevesCherchentUnCoach.
  ///
  /// In fr, this message translates to:
  /// **'Les élèves cherchent un coach près de chez eux.'**
  String get lesElevesCherchentUnCoach;

  /// No description provided for @bio.
  ///
  /// In fr, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @specialites.
  ///
  /// In fr, this message translates to:
  /// **'Spécialités'**
  String get specialites;

  /// No description provided for @specialiteSurMax.
  ///
  /// In fr, this message translates to:
  /// **'{p0} spécialité{p1} sur {p2} max'**
  String specialiteSurMax(Object p0, Object p1, Object p2);

  /// No description provided for @deviensCoachSurMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Deviens coach sur MatchUp'**
  String get deviensCoachSurMatchup;

  /// No description provided for @etapesEnvironMin.
  ///
  /// In fr, this message translates to:
  /// **'{p0} étapes · environ 5 min'**
  String etapesEnvironMin(Object p0);

  /// No description provided for @bientotDisponible.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get bientotDisponible;

  /// No description provided for @cetEcranArriveDansUne.
  ///
  /// In fr, this message translates to:
  /// **'Cet écran arrive dans une prochaine version de MatchUp.'**
  String get cetEcranArriveDansUne;

  /// No description provided for @ouvrirLeMenu.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le menu'**
  String get ouvrirLeMenu;

  /// No description provided for @monProfil.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get monProfil;

  /// No description provided for @parametres.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get parametres;

  /// No description provided for @changerDeRole.
  ///
  /// In fr, this message translates to:
  /// **'Changer de rôle'**
  String get changerDeRole;

  /// No description provided for @seDeconnecter.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get seDeconnecter;

  /// No description provided for @impossibleDeChargerTonBrouillon.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ton brouillon.'**
  String get impossibleDeChargerTonBrouillon;

  /// No description provided for @reessayer.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get reessayer;

  /// No description provided for @chargement.
  ///
  /// In fr, this message translates to:
  /// **'Chargement'**
  String get chargement;

  /// No description provided for @espaceProprietaire.
  ///
  /// In fr, this message translates to:
  /// **'Espace propriétaire'**
  String get espaceProprietaire;

  /// No description provided for @espaceCoach.
  ///
  /// In fr, this message translates to:
  /// **'Espace coach'**
  String get espaceCoach;

  /// No description provided for @espaceOrganisateur.
  ///
  /// In fr, this message translates to:
  /// **'Espace organisateur'**
  String get espaceOrganisateur;

  /// No description provided for @etapes.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · étapes'**
  String etapes(Object p0);

  /// No description provided for @besoinDAide.
  ///
  /// In fr, this message translates to:
  /// **'Besoin d’aide ?'**
  String get besoinDAide;

  /// No description provided for @appelleNousAuDuLundi.
  ///
  /// In fr, this message translates to:
  /// **'Appelle-nous au +216 71 234 567, du lundi au samedi, de 9h00 à 18h00.'**
  String get appelleNousAuDuLundi;

  /// No description provided for @enregistrerEtQuitter.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer et quitter'**
  String get enregistrerEtQuitter;

  /// No description provided for @brouillonEnregistre.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon enregistré · {p0}'**
  String brouillonEnregistre(Object p0);

  /// No description provided for @matin.
  ///
  /// In fr, this message translates to:
  /// **'Matin'**
  String get matin;

  /// No description provided for @apresMidi.
  ///
  /// In fr, this message translates to:
  /// **'Après-midi'**
  String get apresMidi;

  /// No description provided for @soirApres18h.
  ///
  /// In fr, this message translates to:
  /// **'Soir · après 18h'**
  String get soirApres18h;

  /// No description provided for @toutes.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get toutes;

  /// No description provided for @recommandees.
  ///
  /// In fr, this message translates to:
  /// **'Recommandées'**
  String get recommandees;

  /// No description provided for @plusProches.
  ///
  /// In fr, this message translates to:
  /// **'Plus proches'**
  String get plusProches;

  /// No description provided for @plusTot.
  ///
  /// In fr, this message translates to:
  /// **'Plus tôt'**
  String get plusTot;

  /// No description provided for @moinsCheres.
  ///
  /// In fr, this message translates to:
  /// **'Moins chères'**
  String get moinsCheres;

  /// No description provided for @vestiairesEtDouches.
  ///
  /// In fr, this message translates to:
  /// **'Vestiaires et douches'**
  String get vestiairesEtDouches;

  /// No description provided for @parking.
  ///
  /// In fr, this message translates to:
  /// **'Parking'**
  String get parking;

  /// No description provided for @cafe.
  ///
  /// In fr, this message translates to:
  /// **'Café'**
  String get cafe;

  /// No description provided for @chasubles.
  ///
  /// In fr, this message translates to:
  /// **'Chasubles'**
  String get chasubles;

  /// No description provided for @horsLigne.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get horsLigne;

  /// No description provided for @reconnecteToiPourReserver.
  ///
  /// In fr, this message translates to:
  /// **'Reconnecte-toi pour réserver.'**
  String get reconnecteToiPourReserver;

  /// No description provided for @filtres.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filtres;

  /// No description provided for @filtresActifs.
  ///
  /// In fr, this message translates to:
  /// **'Filtres, {p0} actifs'**
  String filtresActifs(Object p0);

  /// No description provided for @monNiveau.
  ///
  /// In fr, this message translates to:
  /// **'Mon niveau'**
  String get monNiveau;

  /// No description provided for @ceSoir.
  ///
  /// In fr, this message translates to:
  /// **'Ce soir'**
  String get ceSoir;

  /// No description provided for @ceWeekEnd.
  ///
  /// In fr, this message translates to:
  /// **'Ce week-end'**
  String get ceWeekEnd;

  /// No description provided for @libreCeSoir.
  ///
  /// In fr, this message translates to:
  /// **'Libre ce soir'**
  String get libreCeSoir;

  /// No description provided for @eclaire.
  ///
  /// In fr, this message translates to:
  /// **'Éclairé'**
  String get eclaire;

  /// No description provided for @explorer.
  ///
  /// In fr, this message translates to:
  /// **'Explorer'**
  String get explorer;

  /// No description provided for @zoneKmChanger.
  ///
  /// In fr, this message translates to:
  /// **'Zone : {p0}, {p1} km. Changer'**
  String zoneKmChanger(Object p0, Object p1);

  /// No description provided for @km.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · {p1} km'**
  String km(Object p0, Object p1);

  /// No description provided for @rechercherUnTerrainUnePartie.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un terrain, une partie, un quartier'**
  String get rechercherUnTerrainUnePartie;

  /// No description provided for @rechercheIndisponibleHorsLigne.
  ///
  /// In fr, this message translates to:
  /// **'Recherche indisponible hors ligne'**
  String get rechercheIndisponibleHorsLigne;

  /// No description provided for @terrainPartieQuartier.
  ///
  /// In fr, this message translates to:
  /// **'Terrain, partie, quartier…'**
  String get terrainPartieQuartier;

  /// No description provided for @parties.
  ///
  /// In fr, this message translates to:
  /// **'Parties'**
  String get parties;

  /// No description provided for @terrains.
  ///
  /// In fr, this message translates to:
  /// **'Terrains'**
  String get terrains;

  /// No description provided for @tournois.
  ///
  /// In fr, this message translates to:
  /// **'Tournois'**
  String get tournois;

  /// No description provided for @filtresRapides.
  ///
  /// In fr, this message translates to:
  /// **'Filtres rapides'**
  String get filtresRapides;

  /// No description provided for @presDe.
  ///
  /// In fr, this message translates to:
  /// **'près de {p0}'**
  String presDe(Object p0);

  /// No description provided for @libresCeSoir.
  ///
  /// In fr, this message translates to:
  /// **'libres ce soir'**
  String get libresCeSoir;

  /// No description provided for @enregistreesA.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrées à '**
  String get enregistreesA;

  /// No description provided for @trierPar.
  ///
  /// In fr, this message translates to:
  /// **'Trier par : {p0}'**
  String trierPar(Object p0);

  /// No description provided for @affichage.
  ///
  /// In fr, this message translates to:
  /// **'Affichage'**
  String get affichage;

  /// No description provided for @carte.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get carte;

  /// No description provided for @liste.
  ///
  /// In fr, this message translates to:
  /// **'Liste'**
  String get liste;

  /// No description provided for @carteDesPartiesAutourDe.
  ///
  /// In fr, this message translates to:
  /// **'Carte des parties autour de {p0}'**
  String carteDesPartiesAutourDe(Object p0);

  /// No description provided for @carteDesTerrainsAutourDe.
  ///
  /// In fr, this message translates to:
  /// **'Carte des terrains autour de {p0}'**
  String carteDesTerrainsAutourDe(Object p0);

  /// No description provided for @chargementDesParties.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des parties'**
  String get chargementDesParties;

  /// No description provided for @chargementDesTerrains.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des terrains'**
  String get chargementDesTerrains;

  /// No description provided for @chargementDesTournois.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des tournois'**
  String get chargementDesTournois;

  /// No description provided for @pasDeConnexion.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion'**
  String get pasDeConnexion;

  /// No description provided for @impossibleDeCharger.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger'**
  String get impossibleDeCharger;

  /// No description provided for @reconnecteToiPourVoirLes.
  ///
  /// In fr, this message translates to:
  /// **'Reconnecte-toi pour voir les parties et les terrains près de toi.'**
  String get reconnecteToiPourVoirLes;

  /// No description provided for @unSouciDeNotreCote.
  ///
  /// In fr, this message translates to:
  /// **'Un souci de notre côté. Réessaie dans un instant.'**
  String get unSouciDeNotreCote;

  /// No description provided for @partieDe.
  ///
  /// In fr, this message translates to:
  /// **'partie de {p0}'**
  String partieDe(Object p0);

  /// No description provided for @terrainDe.
  ///
  /// In fr, this message translates to:
  /// **'terrain de {p0}'**
  String terrainDe(Object p0);

  /// No description provided for @tournoiDe.
  ///
  /// In fr, this message translates to:
  /// **'tournoi de {p0}'**
  String tournoiDe(Object p0);

  /// No description provided for @aucune.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get aucune;

  /// No description provided for @aucun.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get aucun;

  /// No description provided for @ceSoir2.
  ///
  /// In fr, this message translates to:
  /// **' ce soir'**
  String get ceSoir2;

  /// No description provided for @ceWeekEnd2.
  ///
  /// In fr, this message translates to:
  /// **' ce week-end'**
  String get ceWeekEnd2;

  /// No description provided for @laDate.
  ///
  /// In fr, this message translates to:
  /// **'la date'**
  String get laDate;

  /// No description provided for @partiesDe.
  ///
  /// In fr, this message translates to:
  /// **'parties de {p0}'**
  String partiesDe(Object p0);

  /// No description provided for @previensMoi.
  ///
  /// In fr, this message translates to:
  /// **'Préviens-moi'**
  String get previensMoi;

  /// No description provided for @desQuSOuvre.
  ///
  /// In fr, this message translates to:
  /// **'Dès qu’{p0} {p1} s’ouvre'**
  String desQuSOuvre(Object p0, Object p1);

  /// No description provided for @previensMoiDesQuS.
  ///
  /// In fr, this message translates to:
  /// **'Préviens-moi dès qu’{p0} {p1} s’ouvre près de {p2}'**
  String previensMoiDesQuS(Object p0, Object p1, Object p2);

  /// No description provided for @elargirAKm.
  ///
  /// In fr, this message translates to:
  /// **'Élargir à {p0} km'**
  String elargirAKm(Object p0);

  /// No description provided for @estAKm.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1}, est à {p2} km'**
  String estAKm(Object p0, Object p1, Object p2);

  /// No description provided for @elargirLaDistanceAKm.
  ///
  /// In fr, this message translates to:
  /// **'Élargir la distance à {p0} km'**
  String elargirLaDistanceAKm(Object p0);

  /// No description provided for @retirer2.
  ///
  /// In fr, this message translates to:
  /// **'Retirer « {p0} »'**
  String retirer2(Object p0);

  /// No description provided for @retirerLeFiltre.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le filtre {p0}'**
  String retirerLeFiltre(Object p0);

  /// No description provided for @creerUnePartie.
  ///
  /// In fr, this message translates to:
  /// **'Créer une partie'**
  String get creerUnePartie;

  /// No description provided for @creerUnePartieDe.
  ///
  /// In fr, this message translates to:
  /// **'Créer une partie de {p0}'**
  String creerUnePartieDe(Object p0);

  /// No description provided for @reserveUnTerrainOnComplete.
  ///
  /// In fr, this message translates to:
  /// **'Réserve un terrain, on complète l’équipe'**
  String get reserveUnTerrainOnComplete;

  /// No description provided for @rienAMoinsDeKm.
  ///
  /// In fr, this message translates to:
  /// **'Rien à moins de {p0} km de {p1} pour l’instant. Essaie une de ces pistes :'**
  String rienAMoinsDeKm(Object p0, Object p1);

  /// No description provided for @foot5v5.
  ///
  /// In fr, this message translates to:
  /// **'Foot 5v5'**
  String get foot5v5;

  /// No description provided for @padel.
  ///
  /// In fr, this message translates to:
  /// **'Padel'**
  String get padel;

  /// No description provided for @basket.
  ///
  /// In fr, this message translates to:
  /// **'Basket'**
  String get basket;

  /// No description provided for @zones.
  ///
  /// In fr, this message translates to:
  /// **'Zones'**
  String get zones;

  /// No description provided for @pers.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · {p1} · {p2}/pers.'**
  String pers(Object p0, Object p1, Object p2);

  /// No description provided for @rechercher.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get rechercher;

  /// No description provided for @voirLesTerrainsPresDe.
  ///
  /// In fr, this message translates to:
  /// **'Voir les terrains près de moi'**
  String get voirLesTerrainsPresDe;

  /// No description provided for @chercheUnQuartierCommeUn.
  ///
  /// In fr, this message translates to:
  /// **'Cherche un quartier comme {p0}, un terrain, une partie ou un joueur.'**
  String chercheUnQuartierCommeUn(Object p0);

  /// No description provided for @reinitialiser.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reinitialiser;

  /// No description provided for @afficher.
  ///
  /// In fr, this message translates to:
  /// **'Afficher {p0}'**
  String afficher(Object p0);

  /// No description provided for @sport.
  ///
  /// In fr, this message translates to:
  /// **'Sport'**
  String get sport;

  /// No description provided for @dateEtHeure.
  ///
  /// In fr, this message translates to:
  /// **'Date et heure'**
  String get dateEtHeure;

  /// No description provided for @date.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @choisir.
  ///
  /// In fr, this message translates to:
  /// **'Choisir'**
  String get choisir;

  /// No description provided for @autourDeTonNiveau.
  ///
  /// In fr, this message translates to:
  /// **'Autour de ton niveau : {p0}.'**
  String autourDeTonNiveau(Object p0);

  /// No description provided for @prixParPersonne.
  ///
  /// In fr, this message translates to:
  /// **'Prix par personne'**
  String get prixParPersonne;

  /// No description provided for @prixMinimum.
  ///
  /// In fr, this message translates to:
  /// **'Prix minimum'**
  String get prixMinimum;

  /// No description provided for @prixMaximum.
  ///
  /// In fr, this message translates to:
  /// **'Prix maximum'**
  String get prixMaximum;

  /// No description provided for @distance.
  ///
  /// In fr, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @jusquAKm.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu’à {p0} km'**
  String jusquAKm(Object p0);

  /// No description provided for @km2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} – {p1} km'**
  String km2(Object p0, Object p1);

  /// No description provided for @distanceMinimum.
  ///
  /// In fr, this message translates to:
  /// **'Distance minimum'**
  String get distanceMinimum;

  /// No description provided for @distanceMaximum.
  ///
  /// In fr, this message translates to:
  /// **'Distance maximum'**
  String get distanceMaximum;

  /// No description provided for @exterieur.
  ///
  /// In fr, this message translates to:
  /// **'Extérieur'**
  String get exterieur;

  /// No description provided for @interieur.
  ///
  /// In fr, this message translates to:
  /// **'Intérieur'**
  String get interieur;

  /// No description provided for @eclaireLeSoir.
  ///
  /// In fr, this message translates to:
  /// **'Éclairé le soir'**
  String get eclaireLeSoir;

  /// No description provided for @equipements.
  ///
  /// In fr, this message translates to:
  /// **'Équipements'**
  String get equipements;

  /// No description provided for @footVs.
  ///
  /// In fr, this message translates to:
  /// **'Foot 5 vs 5'**
  String get footVs;

  /// No description provided for @taPartPartie.
  ///
  /// In fr, this message translates to:
  /// **'Ta part · partie {p0}'**
  String taPartPartie(Object p0);

  /// No description provided for @placeDansUnePartieOuverte.
  ///
  /// In fr, this message translates to:
  /// **'Place dans une partie ouverte'**
  String get placeDansUnePartieOuverte;

  /// No description provided for @httpsMatchupTnG.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · {p1} · {p2} · https://matchup.tn/g/{p3}'**
  String httpsMatchupTnG(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @partieIntrouvable.
  ///
  /// In fr, this message translates to:
  /// **'Partie introuvable'**
  String get partieIntrouvable;

  /// No description provided for @elleAPeutEtreEte.
  ///
  /// In fr, this message translates to:
  /// **'Elle a peut-être été annulée.'**
  String get elleAPeutEtreEte;

  /// No description provided for @voirLesParties.
  ///
  /// In fr, this message translates to:
  /// **'Voir les parties'**
  String get voirLesParties;

  /// No description provided for @chargementDeLaPartie.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de la partie'**
  String get chargementDeLaPartie;

  /// No description provided for @tuJouesAnnulationGratuiteJusqu.
  ///
  /// In fr, this message translates to:
  /// **'Tu joues · annulation gratuite jusqu’à {p0}'**
  String tuJouesAnnulationGratuiteJusqu(Object p0);

  /// No description provided for @quitterLaPartie.
  ///
  /// In fr, this message translates to:
  /// **'Quitter la partie'**
  String get quitterLaPartie;

  /// No description provided for @discussion.
  ///
  /// In fr, this message translates to:
  /// **'Discussion'**
  String get discussion;

  /// No description provided for @tuEsESurLa.
  ///
  /// In fr, this message translates to:
  /// **'Tu es {p0}e sur la liste d’attente'**
  String tuEsESurLa(Object p0);

  /// No description provided for @voirLaListeDAttente.
  ///
  /// In fr, this message translates to:
  /// **'Voir la liste d’attente'**
  String get voirLaListeDAttente;

  /// No description provided for @gratuitTuNePaies.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit · tu ne paies '**
  String get gratuitTuNePaies;

  /// No description provided for @queSiTuReclamesUne.
  ///
  /// In fr, this message translates to:
  /// **' que si tu réclames une place'**
  String get queSiTuReclamesUne;

  /// No description provided for @rejoindreLaListeDAttente.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre la liste d’attente'**
  String get rejoindreLaListeDAttente;

  /// No description provided for @annulationGratuiteJusquA.
  ///
  /// In fr, this message translates to:
  /// **'Annulation gratuite jusqu’à {p0}'**
  String annulationGratuiteJusquA(Object p0);

  /// No description provided for @rejoindreEtPayer.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre et payer'**
  String get rejoindreEtPayer;

  /// No description provided for @vs.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · 5 vs 5'**
  String vs(Object p0);

  /// No description provided for @lOrganisateur.
  ///
  /// In fr, this message translates to:
  /// **'l’organisateur'**
  String get lOrganisateur;

  /// No description provided for @partagerLaPartie.
  ///
  /// In fr, this message translates to:
  /// **'Partager la partie'**
  String get partagerLaPartie;

  /// No description provided for @plusDActions.
  ///
  /// In fr, this message translates to:
  /// **'Plus d’actions'**
  String get plusDActions;

  /// No description provided for @complet.
  ///
  /// In fr, this message translates to:
  /// **'Complet'**
  String get complet;

  /// No description provided for @terrainReserve.
  ///
  /// In fr, this message translates to:
  /// **'Terrain réservé'**
  String get terrainReserve;

  /// No description provided for @niveau2.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {p0}'**
  String niveau2(Object p0);

  /// No description provided for @jusquA.
  ///
  /// In fr, this message translates to:
  /// **'jusqu’à {p0}'**
  String jusquA(Object p0);

  /// No description provided for @taPart.
  ///
  /// In fr, this message translates to:
  /// **'Ta part'**
  String get taPart;

  /// No description provided for @leTerrain.
  ///
  /// In fr, this message translates to:
  /// **'{p0} le terrain'**
  String leTerrain(Object p0);

  /// No description provided for @places.
  ///
  /// In fr, this message translates to:
  /// **'Places'**
  String get places;

  /// No description provided for @organiseeParVoirSonProfil.
  ///
  /// In fr, this message translates to:
  /// **'Organisée par {p0}, voir son profil'**
  String organiseeParVoirSonProfil(Object p0);

  /// No description provided for @organiseePar.
  ///
  /// In fr, this message translates to:
  /// **'Organisée par'**
  String get organiseePar;

  /// No description provided for @pourquoiPourToi.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi pour toi'**
  String get pourquoiPourToi;

  /// No description provided for @pasPourMoi.
  ///
  /// In fr, this message translates to:
  /// **'Pas pour moi'**
  String get pasPourMoi;

  /// No description provided for @merciOnEnTientCompte.
  ///
  /// In fr, this message translates to:
  /// **'Merci, on en tient compte'**
  String get merciOnEnTientCompte;

  /// No description provided for @lIaProposeraMoinsDe.
  ///
  /// In fr, this message translates to:
  /// **'L’IA proposera moins de parties comme celle-ci.'**
  String get lIaProposeraMoinsDe;

  /// No description provided for @composition.
  ///
  /// In fr, this message translates to:
  /// **'Composition'**
  String get composition;

  /// No description provided for @enListeDAttenteTu.
  ///
  /// In fr, this message translates to:
  /// **'{p0} en liste d’attente · tu serais {p1}e'**
  String enListeDAttenteTu(Object p0, Object p1);

  /// No description provided for @taPlaceEstPriseA.
  ///
  /// In fr, this message translates to:
  /// **'Ta place est prise, à {p0} sur le terrain'**
  String taPlaceEstPriseA(Object p0);

  /// No description provided for @toucheUnPourChoisirTon.
  ///
  /// In fr, this message translates to:
  /// **'Touche un « + » pour choisir ton poste'**
  String get toucheUnPourChoisirTon;

  /// No description provided for @moy.
  ///
  /// In fr, this message translates to:
  /// **'Moy. '**
  String get moy;

  /// No description provided for @ouvrirLaDiscussion.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la discussion'**
  String get ouvrirLaDiscussion;

  /// No description provided for @tuPourrasEcrireDesQue.
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras écrire dès que tu as une place.'**
  String get tuPourrasEcrireDesQue;

  /// No description provided for @rejoinsLaPartiePourEcrire.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins la partie pour écrire aux joueurs.'**
  String get rejoinsLaPartiePourEcrire;

  /// No description provided for @reglesEtAnnulation.
  ///
  /// In fr, this message translates to:
  /// **'Règles et annulation'**
  String get reglesEtAnnulation;

  /// No description provided for @arriveMinAvantLeCoup.
  ///
  /// In fr, this message translates to:
  /// **'Arrive 10 min avant le coup d’envoi'**
  String get arriveMinAvantLeCoup;

  /// No description provided for @rembourseSurTonSoldeMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé sur ton solde MatchUp, en entier si {p0} annule.'**
  String rembourseSurTonSoldeMatchup(Object p0);

  /// No description provided for @voirMesMatchs.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes matchs'**
  String get voirMesMatchs;

  /// No description provided for @lOrganisateur2.
  ///
  /// In fr, this message translates to:
  /// **'L’organisateur'**
  String get lOrganisateur2;

  /// No description provided for @inscriptionConfirmee.
  ///
  /// In fr, this message translates to:
  /// **'Inscription confirmée'**
  String get inscriptionConfirmee;

  /// No description provided for @tuEsDansLaPartie.
  ///
  /// In fr, this message translates to:
  /// **'Tu es dans la partie !'**
  String get tuEsDansLaPartie;

  /// No description provided for @etJoueursTAttendentA.
  ///
  /// In fr, this message translates to:
  /// **'{p0} et {p1} joueurs t’attendent {p2} à {p3}. Ta part est payée.'**
  String etJoueursTAttendentA(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @arriveMinAvant.
  ///
  /// In fr, this message translates to:
  /// **'Arrive 10 min avant'**
  String get arriveMinAvant;

  /// No description provided for @taPart2.
  ///
  /// In fr, this message translates to:
  /// **'Ta part · {p0}'**
  String taPart2(Object p0);

  /// No description provided for @paye.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get paye;

  /// No description provided for @calendrier.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get calendrier;

  /// No description provided for @plusQuUnePlace.
  ///
  /// In fr, this message translates to:
  /// **'Plus qu’une place'**
  String get plusQuUnePlace;

  /// No description provided for @encorePlaces.
  ///
  /// In fr, this message translates to:
  /// **'Encore {p0} places'**
  String encorePlaces(Object p0);

  /// No description provided for @inviteUnAmiPourCompleter.
  ///
  /// In fr, this message translates to:
  /// **'Invite un ami pour compléter la partie. Il paiera sa part de {p0}.'**
  String inviteUnAmiPourCompleter(Object p0);

  /// No description provided for @rejoinsMoi2.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins-moi : {p0} · {p1} · {p2} · {p3}'**
  String rejoinsMoi2(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @taPlace.
  ///
  /// In fr, this message translates to:
  /// **'Ta place'**
  String get taPlace;

  /// No description provided for @tuAsQuitteLaListe.
  ///
  /// In fr, this message translates to:
  /// **'Tu as quitté la liste d’attente'**
  String get tuAsQuitteLaListe;

  /// No description provided for @listeDAttente.
  ///
  /// In fr, this message translates to:
  /// **'Liste d’attente'**
  String get listeDAttente;

  /// No description provided for @quitterLaListe.
  ///
  /// In fr, this message translates to:
  /// **'Quitter la liste'**
  String get quitterLaListe;

  /// No description provided for @partiesSimilaires.
  ///
  /// In fr, this message translates to:
  /// **'Parties similaires'**
  String get partiesSimilaires;

  /// No description provided for @simulerUnePlaceLiberee.
  ///
  /// In fr, this message translates to:
  /// **'Simuler une place libérée'**
  String get simulerUnePlaceLiberee;

  /// No description provided for @cEstToiLeProchain.
  ///
  /// In fr, this message translates to:
  /// **'C’est toi le prochain.'**
  String get cEstToiLeProchain;

  /// No description provided for @plusQueJoueurAvantToi.
  ///
  /// In fr, this message translates to:
  /// **'Plus que {p0} joueur{p1} avant toi.'**
  String plusQueJoueurAvantToi(Object p0, Object p1);

  /// No description provided for @placeLibre.
  ///
  /// In fr, this message translates to:
  /// **'Place libre'**
  String get placeLibre;

  /// No description provided for @toi.
  ///
  /// In fr, this message translates to:
  /// **'Toi'**
  String get toi;

  /// No description provided for @completVoirLaPartie.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1}, complet, voir la partie'**
  String completVoirLaPartie(Object p0, Object p1);

  /// No description provided for @complet2.
  ///
  /// In fr, this message translates to:
  /// **' · complet'**
  String get complet2;

  /// No description provided for @commentCaMarche.
  ///
  /// In fr, this message translates to:
  /// **'Comment ça marche'**
  String get commentCaMarche;

  /// No description provided for @onTePrevientToutDe.
  ///
  /// In fr, this message translates to:
  /// **'On te prévient tout de suite'**
  String get onTePrevientToutDe;

  /// No description provided for @desQuUnJoueurSe.
  ///
  /// In fr, this message translates to:
  /// **'Dès qu’un joueur se désiste, c’est ton tour.'**
  String get desQuUnJoueurSe;

  /// No description provided for @minPourReclamerLaPlace.
  ///
  /// In fr, this message translates to:
  /// **'15 min pour réclamer la place'**
  String get minPourReclamerLaPlace;

  /// No description provided for @sansReponseEllePasseAu.
  ///
  /// In fr, this message translates to:
  /// **'Sans réponse, elle passe au suivant de la liste.'**
  String get sansReponseEllePasseAu;

  /// No description provided for @rienAPayerDIci.
  ///
  /// In fr, this message translates to:
  /// **'Rien à payer d’ici là'**
  String get rienAPayerDIci;

  /// No description provided for @tuPaies.
  ///
  /// In fr, this message translates to:
  /// **'Tu paies '**
  String get tuPaies;

  /// No description provided for @seulementSiTuReclamesLa.
  ///
  /// In fr, this message translates to:
  /// **' seulement si tu réclames la place.'**
  String get seulementSiTuReclamesLa;

  /// No description provided for @mePrevenirAussiParSms.
  ///
  /// In fr, this message translates to:
  /// **'Me prévenir aussi par SMS'**
  String get mePrevenirAussiParSms;

  /// No description provided for @partie2.
  ///
  /// In fr, this message translates to:
  /// **'Partie {p0} · {p1}'**
  String partie2(Object p0, Object p1);

  /// No description provided for @sansReponseLaPlacePasse.
  ///
  /// In fr, this message translates to:
  /// **'Sans réponse, la place passe au suivant de la liste. Annulation gratuite jusqu’à {p0}.'**
  String sansReponseLaPlacePasse(Object p0);

  /// No description provided for @jusquA2.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu’à {p0}'**
  String jusquA2(Object p0);

  /// No description provided for @annulationGratuite.
  ///
  /// In fr, this message translates to:
  /// **'Annulation gratuite'**
  String get annulationGratuite;

  /// No description provided for @rembourses.
  ///
  /// In fr, this message translates to:
  /// **'50 % remboursés'**
  String get rembourses;

  /// No description provided for @moinsDeHAvant.
  ///
  /// In fr, this message translates to:
  /// **'Moins de 6 h avant'**
  String get moinsDeHAvant;

  /// No description provided for @nonRemboursable.
  ///
  /// In fr, this message translates to:
  /// **'Non remboursable'**
  String get nonRemboursable;

  /// No description provided for @coupDEnvoi.
  ///
  /// In fr, this message translates to:
  /// **'Coup d’envoi'**
  String get coupDEnvoi;

  /// No description provided for @verifie.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get verifie;

  /// No description provided for @itineraire.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire'**
  String get itineraire;

  /// No description provided for @voirLeTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Voir le terrain'**
  String get voirLeTerrain;

  /// No description provided for @quitterLaPartie2.
  ///
  /// In fr, this message translates to:
  /// **'Quitter la partie ?'**
  String get quitterLaPartie2;

  /// No description provided for @seraPrevenuEtTaPlace.
  ///
  /// In fr, this message translates to:
  /// **'{p0} {p1} · {p2} · {p3}. {p4} sera prévenu et ta place ira à la liste d’attente.'**
  String seraPrevenuEtTaPlace(
    Object p0,
    Object p1,
    Object p2,
    Object p3,
    Object p4,
  );

  /// No description provided for @tesSerontRemboursesSurTon.
  ///
  /// In fr, this message translates to:
  /// **'Tes {p0} seront remboursés sur ton solde MatchUp. Annulation gratuite jusqu’à {p1}.'**
  String tesSerontRemboursesSurTon(Object p0, Object p1);

  /// No description provided for @resterDansLaPartie.
  ///
  /// In fr, this message translates to:
  /// **'Rester dans la partie'**
  String get resterDansLaPartie;

  /// No description provided for @partieQuittee.
  ///
  /// In fr, this message translates to:
  /// **'Partie quittée'**
  String get partieQuittee;

  /// No description provided for @annuler.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get annuler;

  /// No description provided for @matchup.
  ///
  /// In fr, this message translates to:
  /// **'MatchUp'**
  String get matchup;

  /// No description provided for @tunis.
  ///
  /// In fr, this message translates to:
  /// **'Tunis'**
  String get tunis;

  /// No description provided for @impossibleDeCharger2.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger {p0}'**
  String impossibleDeCharger2(Object p0);

  /// No description provided for @verifieTaConnexionPuisReessaie.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ta connexion puis réessaie.'**
  String get verifieTaConnexionPuisReessaie;

  /// No description provided for @partiesPourToi.
  ///
  /// In fr, this message translates to:
  /// **'Parties pour toi'**
  String get partiesPourToi;

  /// No description provided for @voirTout.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get voirTout;

  /// No description provided for @choisiesSelonTonNiveauTes.
  ///
  /// In fr, this message translates to:
  /// **'Choisies selon ton niveau, tes zones et tes soirs libres.'**
  String get choisiesSelonTonNiveauTes;

  /// No description provided for @onChercheLesPartiesA.
  ///
  /// In fr, this message translates to:
  /// **'On cherche les parties à ton niveau autour de {p0}…'**
  String onChercheLesPartiesA(Object p0);

  /// No description provided for @lesParties.
  ///
  /// In fr, this message translates to:
  /// **'les parties'**
  String get lesParties;

  /// No description provided for @actionsRapides.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get actionsRapides;

  /// No description provided for @reserverUnTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Réserver un terrain'**
  String get reserverUnTerrain;

  /// No description provided for @paieTaPartPasTout.
  ///
  /// In fr, this message translates to:
  /// **'Paie ta part, pas tout le terrain'**
  String get paieTaPartPasTout;

  /// No description provided for @onCompleteAvecDesJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'On complète avec des joueurs à ton niveau'**
  String get onCompleteAvecDesJoueurs;

  /// No description provided for @tesProchainsMatchs.
  ///
  /// In fr, this message translates to:
  /// **'Tes prochains matchs'**
  String get tesProchainsMatchs;

  /// No description provided for @mesMatchs.
  ///
  /// In fr, this message translates to:
  /// **'Mes matchs'**
  String get mesMatchs;

  /// No description provided for @tesMatchs.
  ///
  /// In fr, this message translates to:
  /// **'tes matchs'**
  String get tesMatchs;

  /// No description provided for @chargementDeTesMatchs.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de tes matchs'**
  String get chargementDeTesMatchs;

  /// No description provided for @terrainsPresDeToi.
  ///
  /// In fr, this message translates to:
  /// **'Terrains près de toi'**
  String get terrainsPresDeToi;

  /// No description provided for @lesTerrains.
  ///
  /// In fr, this message translates to:
  /// **'les terrains'**
  String get lesTerrains;

  /// No description provided for @tournoisPresDeChezToi.
  ///
  /// In fr, this message translates to:
  /// **'Tournois près de chez toi'**
  String get tournoisPresDeChezToi;

  /// No description provided for @inscrisTonEquipeAvantQu.
  ///
  /// In fr, this message translates to:
  /// **'Inscris ton équipe avant qu’il soit complet.'**
  String get inscrisTonEquipeAvantQu;

  /// No description provided for @lesTournois.
  ///
  /// In fr, this message translates to:
  /// **'les tournois'**
  String get lesTournois;

  /// No description provided for @salut.
  ///
  /// In fr, this message translates to:
  /// **'Salut !'**
  String get salut;

  /// No description provided for @salut2.
  ///
  /// In fr, this message translates to:
  /// **'Salut {p0}'**
  String salut2(Object p0);

  /// No description provided for @desPartiesChoisiesPourToi.
  ///
  /// In fr, this message translates to:
  /// **'Des parties choisies pour toi'**
  String get desPartiesChoisiesPourToi;

  /// No description provided for @recommandeCarTonNiveauTes.
  ///
  /// In fr, this message translates to:
  /// **'Recommandé car ton niveau, tes soirs libres et tes zones correspondent.'**
  String get recommandeCarTonNiveauTes;

  /// No description provided for @recommandeCarTonNiveauTes2.
  ///
  /// In fr, this message translates to:
  /// **'Recommandé car ton niveau ({p0}), tes soirs libres et tes zones correspondent.'**
  String recommandeCarTonNiveauTes2(Object p0);

  /// No description provided for @organiser.
  ///
  /// In fr, this message translates to:
  /// **'ORGANISER'**
  String get organiser;

  /// No description provided for @creeTaPartieEnMinute.
  ///
  /// In fr, this message translates to:
  /// **'Crée ta partie en 1 minute'**
  String get creeTaPartieEnMinute;

  /// No description provided for @choisisLeTerrainEtL.
  ///
  /// In fr, this message translates to:
  /// **'Choisis le terrain et l’heure : on invite des joueurs à ton niveau, et chacun paie sa part.'**
  String get choisisLeTerrainEtL;

  /// No description provided for @mesMatchs2.
  ///
  /// In fr, this message translates to:
  /// **'MES MATCHS'**
  String get mesMatchs2;

  /// No description provided for @tousTesMatchsAuMeme.
  ///
  /// In fr, this message translates to:
  /// **'Tous tes matchs au même endroit'**
  String get tousTesMatchsAuMeme;

  /// No description provided for @partiesAVenirInvitationsEt.
  ///
  /// In fr, this message translates to:
  /// **'Parties à venir, invitations et paiements en attente : tout se retrouve ici.'**
  String get partiesAVenirInvitationsEt;

  /// No description provided for @pers2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · {p1} · {p2} · {p3} /pers.'**
  String pers2(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @tInviteAuRepondre.
  ///
  /// In fr, this message translates to:
  /// **'{p0} t’invite au {p1}, {p2}. Répondre'**
  String tInviteAuRepondre(Object p0, Object p1, Object p2);

  /// No description provided for @tInviteAu.
  ///
  /// In fr, this message translates to:
  /// **'{p0} t’invite au {p1}'**
  String tInviteAu(Object p0, Object p1);

  /// No description provided for @repondre.
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get repondre;

  /// No description provided for @demandeAMatchupLAssistant.
  ///
  /// In fr, this message translates to:
  /// **'Demande à MatchUp, l’assistant IA'**
  String get demandeAMatchupLAssistant;

  /// No description provided for @demandeAMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Demande à MatchUp…'**
  String get demandeAMatchup;

  /// No description provided for @etapeSur.
  ///
  /// In fr, this message translates to:
  /// **'Étape {p0} sur {p1}'**
  String etapeSur(Object p0, Object p1);

  /// No description provided for @passerLaVisite.
  ///
  /// In fr, this message translates to:
  /// **'Passer la visite'**
  String get passerLaVisite;

  /// No description provided for @cEstParti.
  ///
  /// In fr, this message translates to:
  /// **'C’est parti'**
  String get cEstParti;

  /// No description provided for @suivant.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get suivant;

  /// No description provided for @tonBillet.
  ///
  /// In fr, this message translates to:
  /// **'Ton billet'**
  String get tonBillet;

  /// No description provided for @presenteCeCodeAL2.
  ///
  /// In fr, this message translates to:
  /// **'Présente ce code à l’accueil {p0}.'**
  String presenteCeCodeAL2(Object p0);

  /// No description provided for @annulerLaReservation.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la réservation ?'**
  String get annulerLaReservation;

  /// No description provided for @lesJoueursEtSerontPrevenus.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · {p1}. Les joueurs et {p2} seront prévenus.'**
  String lesJoueursEtSerontPrevenus(Object p0, Object p1, Object p2);

  /// No description provided for @lesJoueursSerontRemboursesChacun.
  ///
  /// In fr, this message translates to:
  /// **'Les {p0} joueurs seront remboursés : {p1} chacun sur leur solde MatchUp.'**
  String lesJoueursSerontRemboursesChacun(Object p0, Object p1);

  /// No description provided for @taPartRemboursee.
  ///
  /// In fr, this message translates to:
  /// **'Ta part remboursée'**
  String get taPartRemboursee;

  /// No description provided for @totalRembourseJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Total remboursé · {p0} joueurs'**
  String totalRembourseJoueurs(Object p0);

  /// No description provided for @annulationGratuiteAvant.
  ///
  /// In fr, this message translates to:
  /// **'Annulation gratuite · avant {p0}'**
  String annulationGratuiteAvant(Object p0);

  /// No description provided for @garderLaReservation.
  ///
  /// In fr, this message translates to:
  /// **'Garder la réservation'**
  String get garderLaReservation;

  /// No description provided for @annulerLaReservation2.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la réservation'**
  String get annulerLaReservation2;

  /// No description provided for @reservationAnnulee.
  ///
  /// In fr, this message translates to:
  /// **'Réservation annulée'**
  String get reservationAnnulee;

  /// No description provided for @remboursesSurLesSoldesMatchup.
  ///
  /// In fr, this message translates to:
  /// **'{p0} remboursés sur les soldes MatchUp, les joueurs sont prévenus.'**
  String remboursesSurLesSoldesMatchup(Object p0);

  /// No description provided for @reservationIntrouvable.
  ///
  /// In fr, this message translates to:
  /// **'Réservation introuvable'**
  String get reservationIntrouvable;

  /// No description provided for @chargementDeLaReservation.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de la réservation'**
  String get chargementDeLaReservation;

  /// No description provided for @inviterDesJoueursPlaces.
  ///
  /// In fr, this message translates to:
  /// **'Inviter des joueurs · {p0} places'**
  String inviterDesJoueursPlaces(Object p0);

  /// No description provided for @rejoinsMaPartie.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins ma partie : {p0} · {p1} · {p2} · {p3}'**
  String rejoinsMaPartie(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @lundi.
  ///
  /// In fr, this message translates to:
  /// **'Lundi'**
  String get lundi;

  /// No description provided for @mardi.
  ///
  /// In fr, this message translates to:
  /// **'Mardi'**
  String get mardi;

  /// No description provided for @mercredi.
  ///
  /// In fr, this message translates to:
  /// **'Mercredi'**
  String get mercredi;

  /// No description provided for @jeudi.
  ///
  /// In fr, this message translates to:
  /// **'Jeudi'**
  String get jeudi;

  /// No description provided for @vendredi.
  ///
  /// In fr, this message translates to:
  /// **'Vendredi'**
  String get vendredi;

  /// No description provided for @samedi.
  ///
  /// In fr, this message translates to:
  /// **'Samedi'**
  String get samedi;

  /// No description provided for @dimanche.
  ///
  /// In fr, this message translates to:
  /// **'Dimanche'**
  String get dimanche;

  /// No description provided for @sousLesProjecteurs.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1} sous les projecteurs'**
  String sousLesProjecteurs(Object p0, Object p1);

  /// No description provided for @retourAMesMatchs.
  ///
  /// In fr, this message translates to:
  /// **'Retour à Mes matchs'**
  String get retourAMesMatchs;

  /// No description provided for @partager.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get partager;

  /// No description provided for @confirmee.
  ///
  /// In fr, this message translates to:
  /// **'Confirmée'**
  String get confirmee;

  /// No description provided for @footballVs.
  ///
  /// In fr, this message translates to:
  /// **'Football 5 vs 5'**
  String get footballVs;

  /// No description provided for @ref2.
  ///
  /// In fr, this message translates to:
  /// **'Réf. '**
  String get ref2;

  /// No description provided for @niveau3.
  ///
  /// In fr, this message translates to:
  /// **' · niveau {p0} – {p1}'**
  String niveau3(Object p0, Object p1);

  /// No description provided for @tuOrganises.
  ///
  /// In fr, this message translates to:
  /// **' · tu organises'**
  String get tuOrganises;

  /// No description provided for @quandEtCombien.
  ///
  /// In fr, this message translates to:
  /// **'Quand et combien'**
  String get quandEtCombien;

  /// No description provided for @aujourdHui.
  ///
  /// In fr, this message translates to:
  /// **'aujourd’hui'**
  String get aujourdHui;

  /// No description provided for @dansJour.
  ///
  /// In fr, this message translates to:
  /// **'dans {p0} jour{p1}'**
  String dansJour(Object p0, Object p1);

  /// No description provided for @horaire.
  ///
  /// In fr, this message translates to:
  /// **'Horaire'**
  String get horaire;

  /// No description provided for @eclaire2.
  ///
  /// In fr, this message translates to:
  /// **' · éclairé'**
  String get eclaire2;

  /// No description provided for @afficherLeQrCode.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le QR code'**
  String get afficherLeQrCode;

  /// No description provided for @tonBilletPourLAccueil.
  ///
  /// In fr, this message translates to:
  /// **'Ton billet pour l’accueil {p0}, le jour du match.'**
  String tonBilletPourLAccueil(Object p0);

  /// No description provided for @lieu.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get lieu;

  /// No description provided for @km3.
  ///
  /// In fr, this message translates to:
  /// **' · {p0} km'**
  String km3(Object p0);

  /// No description provided for @niveauMoyen.
  ///
  /// In fr, this message translates to:
  /// **'NIVEAU MOYEN'**
  String get niveauMoyen;

  /// No description provided for @suivreLesPaiements.
  ///
  /// In fr, this message translates to:
  /// **'Suivre les paiements'**
  String get suivreLesPaiements;

  /// No description provided for @leTerrainParJoueur.
  ///
  /// In fr, this message translates to:
  /// **'{p0} le terrain · {p1} par joueur'**
  String leTerrainParJoueur(Object p0, Object p1);

  /// No description provided for @recus.
  ///
  /// In fr, this message translates to:
  /// **' reçus'**
  String get recus;

  /// No description provided for @toi2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · toi'**
  String toi2(Object p0);

  /// No description provided for @organisateurPayeLe.
  ///
  /// In fr, this message translates to:
  /// **'Organisateur · payé le {p0}'**
  String organisateurPayeLe(Object p0);

  /// No description provided for @placesPubliques.
  ///
  /// In fr, this message translates to:
  /// **'{p0} places publiques'**
  String placesPubliques(Object p0);

  /// No description provided for @payesParChaqueJoueurQui.
  ///
  /// In fr, this message translates to:
  /// **'{p0} payés par chaque joueur qui rejoint'**
  String payesParChaqueJoueurQui(Object p0);

  /// No description provided for @nouveauxMessages.
  ///
  /// In fr, this message translates to:
  /// **'{p0} nouveaux messages'**
  String nouveauxMessages(Object p0);

  /// No description provided for @pasEncoreDeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de message.'**
  String get pasEncoreDeMessage;

  /// No description provided for @annulation.
  ///
  /// In fr, this message translates to:
  /// **'Annulation'**
  String get annulation;

  /// No description provided for @annulationGratuiteJusquAH.
  ///
  /// In fr, this message translates to:
  /// **'Annulation gratuite jusqu’à 24 h avant, 50 % jusqu’à 6 h avant, puis rien'**
  String get annulationGratuiteJusquAH;

  /// No description provided for @gratuiteJusquAu.
  ///
  /// In fr, this message translates to:
  /// **'Gratuite jusqu’au {p0}'**
  String gratuiteJusquAu(Object p0);

  /// No description provided for @rembourseTuEsIci.
  ///
  /// In fr, this message translates to:
  /// **'100 % remboursé · tu es ici'**
  String get rembourseTuEsIci;

  /// No description provided for @entreHEtHAvant.
  ///
  /// In fr, this message translates to:
  /// **'Entre 24 h et 6 h avant'**
  String get entreHEtHAvant;

  /// No description provided for @rembourse.
  ///
  /// In fr, this message translates to:
  /// **'50 % remboursé'**
  String get rembourse;

  /// No description provided for @siTuAnnulesLesJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Si tu annules, les {p0} joueurs sont remboursés automatiquement sur leur solde MatchUp et prévenus par notification.'**
  String siTuAnnulesLesJoueurs(Object p0);

  /// No description provided for @aVenir.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get aVenir;

  /// No description provided for @passes.
  ///
  /// In fr, this message translates to:
  /// **'Passés'**
  String get passes;

  /// No description provided for @annules.
  ///
  /// In fr, this message translates to:
  /// **'Annulés'**
  String get annules;

  /// No description provided for @aRepondre.
  ///
  /// In fr, this message translates to:
  /// **'À répondre'**
  String get aRepondre;

  /// No description provided for @invitationAcceptee.
  ///
  /// In fr, this message translates to:
  /// **'Invitation acceptée'**
  String get invitationAcceptee;

  /// No description provided for @estPrevenue.
  ///
  /// In fr, this message translates to:
  /// **'{p0} est prévenue.'**
  String estPrevenue(Object p0);

  /// No description provided for @tuJoues.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · Tu joues'**
  String tuJoues(Object p0);

  /// No description provided for @quitter.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get quitter;

  /// No description provided for @tuOrganises2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · Tu organises'**
  String tuOrganises2(Object p0);

  /// No description provided for @enAttenteDeJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'En attente de {p0} joueurs'**
  String enAttenteDeJoueurs(Object p0);

  /// No description provided for @placesLibres.
  ///
  /// In fr, this message translates to:
  /// **'{p0} places libres'**
  String placesLibres(Object p0);

  /// No description provided for @inviter2.
  ///
  /// In fr, this message translates to:
  /// **'Inviter'**
  String get inviter2;

  /// No description provided for @tInviteAuTaPart.
  ///
  /// In fr, this message translates to:
  /// **'{p0} t’invite au {p1}, {p2}, {p3}, {p4} ta part'**
  String tInviteAuTaPart(Object p0, Object p1, Object p2, Object p3, Object p4);

  /// No description provided for @joueurs2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · {p1}/{p2} joueurs'**
  String joueurs2(Object p0, Object p1, Object p2);

  /// No description provided for @taPart3.
  ///
  /// In fr, this message translates to:
  /// **'ta part'**
  String get taPart3;

  /// No description provided for @refuser.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get refuser;

  /// No description provided for @accepter.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get accepter;

  /// No description provided for @aucunMatchAVenir.
  ///
  /// In fr, this message translates to:
  /// **'Aucun match à venir'**
  String get aucunMatchAVenir;

  /// No description provided for @rejoinsUnePartieATon.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins une partie à ton niveau, ou réserve un terrain et invite tes amis.'**
  String get rejoinsUnePartieATon;

  /// No description provided for @trouverUnePartie.
  ///
  /// In fr, this message translates to:
  /// **'Trouver une partie'**
  String get trouverUnePartie;

  /// No description provided for @partiesOuvertesCetteSemaineA.
  ///
  /// In fr, this message translates to:
  /// **'{p0} parties ouvertes cette semaine à moins de 5 km'**
  String partiesOuvertesCetteSemaineA(Object p0);

  /// No description provided for @aucunMatchJoue.
  ///
  /// In fr, this message translates to:
  /// **'Aucun match joué'**
  String get aucunMatchJoue;

  /// No description provided for @tesResultatsEtTesEvaluations.
  ///
  /// In fr, this message translates to:
  /// **'Tes résultats et tes évaluations apparaîtront ici.'**
  String get tesResultatsEtTesEvaluations;

  /// No description provided for @aEvaluer.
  ///
  /// In fr, this message translates to:
  /// **'À évaluer'**
  String get aEvaluer;

  /// No description provided for @evalueTesCoequipiers.
  ///
  /// In fr, this message translates to:
  /// **'Évalue tes coéquipiers'**
  String get evalueTesCoequipiers;

  /// No description provided for @min.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · 1 min'**
  String min(Object p0);

  /// No description provided for @evaluerLesJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Évaluer les joueurs'**
  String get evaluerLesJoueurs;

  /// No description provided for @evalues.
  ///
  /// In fr, this message translates to:
  /// **'Évalués'**
  String get evalues;

  /// No description provided for @matchsDepuisVictoire.
  ///
  /// In fr, this message translates to:
  /// **'{p0} matchs depuis {p1} · {p2} victoire{p3}'**
  String matchsDepuisVictoire(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @voirToutesMesStats.
  ///
  /// In fr, this message translates to:
  /// **'Voir toutes mes stats'**
  String get voirToutesMesStats;

  /// No description provided for @fevrier.
  ///
  /// In fr, this message translates to:
  /// **'février'**
  String get fevrier;

  /// No description provided for @aout.
  ///
  /// In fr, this message translates to:
  /// **'août'**
  String get aout;

  /// No description provided for @decembre.
  ///
  /// In fr, this message translates to:
  /// **'décembre'**
  String get decembre;

  /// No description provided for @aucuneAnnulation.
  ///
  /// In fr, this message translates to:
  /// **'Aucune annulation'**
  String get aucuneAnnulation;

  /// No description provided for @lesPartiesEtReservationsAnnulees.
  ///
  /// In fr, this message translates to:
  /// **'Les parties et réservations annulées, avec leur remboursement.'**
  String get lesPartiesEtReservationsAnnulees;

  /// No description provided for @remboursement.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement'**
  String get remboursement;

  /// No description provided for @rembourse2.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé'**
  String get rembourse2;

  /// No description provided for @annuleeParToiLeTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Annulée par toi, le terrain et les joueurs sont prévenus.'**
  String get annuleeParToiLeTerrain;

  /// No description provided for @annuleeParLOrganisateur.
  ///
  /// In fr, this message translates to:
  /// **'Annulée par l’organisateur, {p0}.'**
  String annuleeParLOrganisateur(Object p0);

  /// No description provided for @crediteLe.
  ///
  /// In fr, this message translates to:
  /// **'Crédité le {p0}'**
  String crediteLe(Object p0);

  /// No description provided for @tonSoldeMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Ton solde MatchUp'**
  String get tonSoldeMatchup;

  /// No description provided for @chaqueJoueurEstRembourseEn.
  ///
  /// In fr, this message translates to:
  /// **'Chaque joueur est remboursé en entier sur son solde MatchUp.'**
  String get chaqueJoueurEstRembourseEn;

  /// No description provided for @quandLOrganisateurOuLe.
  ///
  /// In fr, this message translates to:
  /// **'Quand l’organisateur ou le terrain annule, ta part est remboursée en entier, sans démarche.'**
  String get quandLOrganisateurOuLe;

  /// No description provided for @impossibleDeChargerTesMatchs.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger tes matchs'**
  String get impossibleDeChargerTesMatchs;

  /// No description provided for @scoreEnregistre.
  ///
  /// In fr, this message translates to:
  /// **'Score enregistré'**
  String get scoreEnregistre;

  /// No description provided for @ontHPourLeConfirmer.
  ///
  /// In fr, this message translates to:
  /// **'{p0} ont 48 h pour le confirmer.'**
  String ontHPourLeConfirmer(Object p0);

  /// No description provided for @matchIntrouvable.
  ///
  /// In fr, this message translates to:
  /// **'Match introuvable'**
  String get matchIntrouvable;

  /// No description provided for @passer.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get passer;

  /// No description provided for @leScoreDuMatch.
  ///
  /// In fr, this message translates to:
  /// **'Le score du match'**
  String get leScoreDuMatch;

  /// No description provided for @facultatifCaAideLIa.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif. Ça aide l’IA à affiner les niveaux de chacun.'**
  String get facultatifCaAideLIa;

  /// No description provided for @ajouterUnESet.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un {p0}e set'**
  String ajouterUnESet(Object p0);

  /// No description provided for @confirmerontLeScoreSansReponse.
  ///
  /// In fr, this message translates to:
  /// **'{p0} confirmeront le score. Sans réponse sous 48 h, il est validé.'**
  String confirmerontLeScoreSansReponse(Object p0);

  /// No description provided for @enregistrerLeScore.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le score'**
  String get enregistrerLeScore;

  /// No description provided for @sets.
  ///
  /// In fr, this message translates to:
  /// **'Sets'**
  String get sets;

  /// No description provided for @setText.
  ///
  /// In fr, this message translates to:
  /// **'Set {p0}'**
  String setText(Object p0);

  /// No description provided for @setText2.
  ///
  /// In fr, this message translates to:
  /// **'Set {p0}, {p1}'**
  String setText2(Object p0, Object p1);

  /// No description provided for @retirerUnJeuA.
  ///
  /// In fr, this message translates to:
  /// **'Retirer un jeu à {p0}'**
  String retirerUnJeuA(Object p0);

  /// No description provided for @ajouterUnJeuA.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un jeu à {p0}'**
  String ajouterUnJeuA(Object p0);

  /// No description provided for @evalueLesJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Évalue les joueurs'**
  String get evalueLesJoueurs;

  /// No description provided for @merciEvaluationsEnvoyees.
  ///
  /// In fr, this message translates to:
  /// **'Merci, évaluations envoyées'**
  String get merciEvaluationsEnvoyees;

  /// No description provided for @envoyer.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get envoyer;

  /// No description provided for @mauvaisEsprit.
  ///
  /// In fr, this message translates to:
  /// **'Mauvais esprit'**
  String get mauvaisEsprit;

  /// No description provided for @limite.
  ///
  /// In fr, this message translates to:
  /// **'Limite'**
  String get limite;

  /// No description provided for @correct.
  ///
  /// In fr, this message translates to:
  /// **'Correct'**
  String get correct;

  /// No description provided for @sympa.
  ///
  /// In fr, this message translates to:
  /// **'Sympa'**
  String get sympa;

  /// No description provided for @exemplaire.
  ///
  /// In fr, this message translates to:
  /// **'Exemplaire'**
  String get exemplaire;

  /// No description provided for @notesAnonymes.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · {p1} · {p2} · notes anonymes'**
  String notesAnonymes(Object p0, Object p1, Object p2);

  /// No description provided for @quelquUnNEstPas.
  ///
  /// In fr, this message translates to:
  /// **'Quelqu’un n’est pas venu ?'**
  String get quelquUnNEstPas;

  /// No description provided for @signalerUneAbsence.
  ///
  /// In fr, this message translates to:
  /// **'Signaler une absence'**
  String get signalerUneAbsence;

  /// No description provided for @annoncee.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · annoncée {p1}'**
  String annoncee(Object p0, Object p1);

  /// No description provided for @sonNiveauCeJourLa.
  ///
  /// In fr, this message translates to:
  /// **'Son niveau ce jour-là'**
  String get sonNiveauCeJourLa;

  /// No description provided for @niveauDe.
  ///
  /// In fr, this message translates to:
  /// **'Niveau de {p0}'**
  String niveauDe(Object p0);

  /// No description provided for @enDessous.
  ///
  /// In fr, this message translates to:
  /// **'En dessous'**
  String get enDessous;

  /// No description provided for @conforme.
  ///
  /// In fr, this message translates to:
  /// **'Conforme'**
  String get conforme;

  /// No description provided for @auDessus.
  ///
  /// In fr, this message translates to:
  /// **'Au-dessus'**
  String get auDessus;

  /// No description provided for @fairPlay.
  ///
  /// In fr, this message translates to:
  /// **'Fair-play'**
  String get fairPlay;

  /// No description provided for @gardien.
  ///
  /// In fr, this message translates to:
  /// **'Gardien'**
  String get gardien;

  /// No description provided for @defenseur.
  ///
  /// In fr, this message translates to:
  /// **'Défenseur'**
  String get defenseur;

  /// No description provided for @milieu.
  ///
  /// In fr, this message translates to:
  /// **'Milieu'**
  String get milieu;

  /// No description provided for @attaquant.
  ///
  /// In fr, this message translates to:
  /// **'Attaquant'**
  String get attaquant;

  /// No description provided for @chezLes.
  ///
  /// In fr, this message translates to:
  /// **'{p0} chez les {p1}'**
  String chezLes(Object p0, Object p1);

  /// No description provided for @plusQuPlace.
  ///
  /// In fr, this message translates to:
  /// **'plus qu’1 place'**
  String get plusQuPlace;

  /// No description provided for @encorePlaces2.
  ///
  /// In fr, this message translates to:
  /// **'encore {p0} places'**
  String encorePlaces2(Object p0);

  /// No description provided for @aRejointLaPartie.
  ///
  /// In fr, this message translates to:
  /// **'{p0} a rejoint la partie · {p1}/{p2}'**
  String aRejointLaPartie(Object p0, Object p1, Object p2);

  /// No description provided for @invitationRefusee.
  ///
  /// In fr, this message translates to:
  /// **'Invitation refusée'**
  String get invitationRefusee;

  /// No description provided for @taPartReservation.
  ///
  /// In fr, this message translates to:
  /// **'Ta part · réservation {p0}'**
  String taPartReservation(Object p0);

  /// No description provided for @arenaFiveTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Arena Five · Terrain 1'**
  String get arenaFiveTerrain;

  /// No description provided for @merOct21h0022h00Foot.
  ///
  /// In fr, this message translates to:
  /// **'mer. 21 oct. · 21h00 – 22h00 · Foot 5 vs 5'**
  String get merOct21h0022h00Foot;

  /// No description provided for @taPartJoueurSur2.
  ///
  /// In fr, this message translates to:
  /// **'Ta part · 1 joueur sur 10'**
  String get taPartJoueurSur2;

  /// No description provided for @arenaFive.
  ///
  /// In fr, this message translates to:
  /// **'Arena Five'**
  String get arenaFive;

  /// No description provided for @taPartDtSurDt.
  ///
  /// In fr, this message translates to:
  /// **'Ta part : 15 DT sur 150 DT'**
  String get taPartDtSurDt;

  /// No description provided for @partArenaFive.
  ///
  /// In fr, this message translates to:
  /// **'Part · Arena Five'**
  String get partArenaFive;

  /// No description provided for @invitationsPlacesLibereesRappels.
  ///
  /// In fr, this message translates to:
  /// **'Invitations, places libérées, rappels'**
  String get invitationsPlacesLibereesRappels;

  /// No description provided for @confirmationsAnnulationsCheckIn.
  ///
  /// In fr, this message translates to:
  /// **'Confirmations, annulations, check-in'**
  String get confirmationsAnnulationsCheckIn;

  /// No description provided for @partsAPayerRecusRemboursements.
  ///
  /// In fr, this message translates to:
  /// **'Parts à payer, reçus, remboursements'**
  String get partsAPayerRecusRemboursements;

  /// No description provided for @inscriptionsTableauxResultats.
  ///
  /// In fr, this message translates to:
  /// **'Inscriptions, tableaux, résultats'**
  String get inscriptionsTableauxResultats;

  /// No description provided for @plansIaRetoursDuCoach.
  ///
  /// In fr, this message translates to:
  /// **'Plans IA, retours du coach, séances'**
  String get plansIaRetoursDuCoach;

  /// No description provided for @reponsesMentionsModeration.
  ///
  /// In fr, this message translates to:
  /// **'Réponses, mentions, modération'**
  String get reponsesMentionsModeration;

  /// No description provided for @connexionsMotDePasseAppareils.
  ///
  /// In fr, this message translates to:
  /// **'Connexions, mot de passe, appareils'**
  String get connexionsMotDePasseAppareils;

  /// No description provided for @jusquA3.
  ///
  /// In fr, this message translates to:
  /// **'jusqu’à {p0} · {p1}'**
  String jusquA3(Object p0, Object p1);

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pause.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @toutMettreEnPause.
  ///
  /// In fr, this message translates to:
  /// **'Tout mettre en pause'**
  String get toutMettreEnPause;

  /// No description provided for @plusDePushNiD.
  ///
  /// In fr, this message translates to:
  /// **'Plus de push ni d’email pendant la pause. Les alertes de paiement et de sécurité restent dans l’app.'**
  String get plusDePushNiD;

  /// No description provided for @enPause.
  ///
  /// In fr, this message translates to:
  /// **'En pause {p0}'**
  String enPause(Object p0);

  /// No description provided for @reprendreMaintenant.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre maintenant'**
  String get reprendreMaintenant;

  /// No description provided for @parCategorie.
  ///
  /// In fr, this message translates to:
  /// **'Par catégorie'**
  String get parCategorie;

  /// No description provided for @tuChoisisOuChaqueCategorie.
  ///
  /// In fr, this message translates to:
  /// **'Tu choisis où chaque catégorie te prévient.'**
  String get tuChoisisOuChaqueCategorie;

  /// No description provided for @inApp.
  ///
  /// In fr, this message translates to:
  /// **'In-app'**
  String get inApp;

  /// No description provided for @push.
  ///
  /// In fr, this message translates to:
  /// **'Push'**
  String get push;

  /// No description provided for @toujoursDansLApp.
  ///
  /// In fr, this message translates to:
  /// **'Toujours dans l’app'**
  String get toujoursDansLApp;

  /// No description provided for @toujoursActive.
  ///
  /// In fr, this message translates to:
  /// **', toujours activé'**
  String get toujoursActive;

  /// No description provided for @toujoursActiveObligatoirePourTon.
  ///
  /// In fr, this message translates to:
  /// **'Toujours activé : obligatoire pour ton argent et ton compte. Tu peux quand même couper le push et l’email.'**
  String get toujoursActiveObligatoirePourTon;

  /// No description provided for @heuresCalmes.
  ///
  /// In fr, this message translates to:
  /// **'Heures calmes'**
  String get heuresCalmes;

  /// No description provided for @aucunPushLaNuitTout.
  ///
  /// In fr, this message translates to:
  /// **'Aucun push la nuit. Tout t’attend dans l’app au réveil.'**
  String get aucunPushLaNuitTout;

  /// No description provided for @debut.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get debut;

  /// No description provided for @fin.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get fin;

  /// No description provided for @tousLesJoursHeureDe.
  ///
  /// In fr, this message translates to:
  /// **'Tous les jours, heure de Tunis. Seul le push se tait : l’app et l’email ne changent pas.'**
  String get tousLesJoursHeureDe;

  /// No description provided for @recapParEmail.
  ///
  /// In fr, this message translates to:
  /// **'Récap par email'**
  String get recapParEmail;

  /// No description provided for @hebdoDimanche10h00.
  ///
  /// In fr, this message translates to:
  /// **'Hebdo · dimanche 10h00'**
  String get hebdoDimanche10h00;

  /// No description provided for @tesMatchsDeLaSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Tes matchs de la semaine et des parties près de chez toi.'**
  String get tesMatchsDeLaSemaine;

  /// No description provided for @jamais.
  ///
  /// In fr, this message translates to:
  /// **'Jamais'**
  String get jamais;

  /// No description provided for @lesRecusEtLesAlertes.
  ///
  /// In fr, this message translates to:
  /// **'Les reçus et les alertes de sécurité arrivent quand même.'**
  String get lesRecusEtLesAlertes;

  /// No description provided for @aujourdHui2.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get aujourdHui2;

  /// No description provided for @cetteSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get cetteSemaine;

  /// No description provided for @plusAncien.
  ///
  /// In fr, this message translates to:
  /// **'Plus ancien'**
  String get plusAncien;

  /// No description provided for @tout.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get tout;

  /// No description provided for @toutEstCalme.
  ///
  /// In fr, this message translates to:
  /// **'Tout est calme'**
  String get toutEstCalme;

  /// No description provided for @tuVerrasIciTesInvitations.
  ///
  /// In fr, this message translates to:
  /// **'Tu verras ici tes invitations, rappels de match et paiements dès qu’il se passe quelque chose.'**
  String get tuVerrasIciTesInvitations;

  /// No description provided for @gererMesNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mes notifications'**
  String get gererMesNotifications;

  /// No description provided for @nonLue.
  ///
  /// In fr, this message translates to:
  /// **' non lue'**
  String get nonLue;

  /// No description provided for @nonLues.
  ///
  /// In fr, this message translates to:
  /// **' non lues'**
  String get nonLues;

  /// No description provided for @toutMarquerCommeLu.
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer comme lu'**
  String get toutMarquerCommeLu;

  /// No description provided for @tuAsToutVuLes.
  ///
  /// In fr, this message translates to:
  /// **'Tu as tout vu. Les notifications de plus de 90 jours sont effacées.'**
  String get tuAsToutVuLes;

  /// No description provided for @preferencesDeNotification.
  ///
  /// In fr, this message translates to:
  /// **'Préférences de notification'**
  String get preferencesDeNotification;

  /// No description provided for @ouvrirMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir MatchUp'**
  String get ouvrirMatchup;

  /// No description provided for @joueReserveProgresse.
  ///
  /// In fr, this message translates to:
  /// **'Joue. Réserve. Progresse.'**
  String get joueReserveProgresse;

  /// No description provided for @trouveDesJoueursATon.
  ///
  /// In fr, this message translates to:
  /// **'Trouve des joueurs à ton niveau'**
  String get trouveDesJoueursATon;

  /// No description provided for @rejoinsDesPartiesPresDe.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins des parties près de chez toi, équilibrées selon le niveau de chacun.'**
  String get rejoinsDesPartiesPresDe;

  /// No description provided for @reserveEtPaieEnQuelques.
  ///
  /// In fr, this message translates to:
  /// **'Réserve et paie en quelques secondes'**
  String get reserveEtPaieEnQuelques;

  /// No description provided for @choisisTonCreneauEtPaie.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton créneau et paie seulement ta part. Chacun règle la sienne.'**
  String get choisisTonCreneauEtPaie;

  /// No description provided for @progresseEtAffronteLesMeilleurs.
  ///
  /// In fr, this message translates to:
  /// **'Progresse et affronte les meilleurs'**
  String get progresseEtAffronteLesMeilleurs;

  /// No description provided for @tonNiveauEvolueAChaque.
  ///
  /// In fr, this message translates to:
  /// **'Ton niveau évolue à chaque match. Quand tu es prêt, vise les tournois.'**
  String get tonNiveauEvolueAChaque;

  /// No description provided for @commencer.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get commencer;

  /// No description provided for @jAiDejaUnCompte.
  ///
  /// In fr, this message translates to:
  /// **'J’ai déjà un compte'**
  String get jAiDejaUnCompte;

  /// No description provided for @aTonNiveau.
  ///
  /// In fr, this message translates to:
  /// **'À TON NIVEAU'**
  String get aTonNiveau;

  /// No description provided for @taPart4.
  ///
  /// In fr, this message translates to:
  /// **'TA PART'**
  String get taPart4;

  /// No description provided for @terrain3.
  ///
  /// In fr, this message translates to:
  /// **'Terrain '**
  String get terrain3;

  /// No description provided for @joueurs3.
  ///
  /// In fr, this message translates to:
  /// **' ÷ {p0} joueurs'**
  String joueurs3(Object p0);

  /// No description provided for @ontPayeLeurPart.
  ///
  /// In fr, this message translates to:
  /// **' ont payé leur part'**
  String get ontPayeLeurPart;

  /// No description provided for @taPartEstPayee.
  ///
  /// In fr, this message translates to:
  /// **'Ta part est payée'**
  String get taPartEstPayee;

  /// No description provided for @niveauBasket.
  ///
  /// In fr, this message translates to:
  /// **'NIVEAU BASKET'**
  String get niveauBasket;

  /// No description provided for @surJours.
  ///
  /// In fr, this message translates to:
  /// **' sur 30 jours'**
  String get surJours;

  /// No description provided for @versAvance.
  ///
  /// In fr, this message translates to:
  /// **'Vers Avancé'**
  String get versAvance;

  /// No description provided for @estimeDApresTesDerniers.
  ///
  /// In fr, this message translates to:
  /// **'Estimé d’après tes 12 derniers matchs.'**
  String get estimeDApresTesDerniers;

  /// No description provided for @organisation.
  ///
  /// In fr, this message translates to:
  /// **'Organisation'**
  String get organisation;

  /// No description provided for @premierTournoi.
  ///
  /// In fr, this message translates to:
  /// **'Premier tournoi'**
  String get premierTournoi;

  /// No description provided for @peseMaxMo.
  ///
  /// In fr, this message translates to:
  /// **'{p0} pèse {p1} (max 5 Mo).'**
  String peseMaxMo(Object p0, Object p1);

  /// No description provided for @donneUnNomAL.
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom à l’événement.'**
  String get donneUnNomAL;

  /// No description provided for @retire.
  ///
  /// In fr, this message translates to:
  /// **'{p0} retiré'**
  String retire(Object p0);

  /// No description provided for @indiqueLeNomDeTon.
  ///
  /// In fr, this message translates to:
  /// **'Indique le nom de ton organisation.'**
  String get indiqueLeNomDeTon;

  /// No description provided for @organiseTesTournois.
  ///
  /// In fr, this message translates to:
  /// **'Organise tes tournois'**
  String get organiseTesTournois;

  /// No description provided for @etapesEnvironMin2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} étapes · environ 3 min'**
  String etapesEnvironMin2(Object p0);

  /// No description provided for @presenteTonOrganisation.
  ///
  /// In fr, this message translates to:
  /// **'Présente ton organisation'**
  String get presenteTonOrganisation;

  /// No description provided for @lesEquipesVoientCesInfos.
  ///
  /// In fr, this message translates to:
  /// **'Les équipes voient ces infos sur chaque tournoi que tu publies.'**
  String get lesEquipesVoientCesInfos;

  /// No description provided for @tonOrganisation.
  ///
  /// In fr, this message translates to:
  /// **'Ton organisation'**
  String get tonOrganisation;

  /// No description provided for @logo.
  ///
  /// In fr, this message translates to:
  /// **'Logo'**
  String get logo;

  /// No description provided for @pngOuSvgMoMax.
  ///
  /// In fr, this message translates to:
  /// **'PNG ou SVG · 5 Mo max'**
  String get pngOuSvgMoMax;

  /// No description provided for @nomDeLOrganisation.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’organisation'**
  String get nomDeLOrganisation;

  /// No description provided for @afficheSurTesTournoisEt.
  ///
  /// In fr, this message translates to:
  /// **'Affiché sur tes tournois et tes annonces.'**
  String get afficheSurTesTournoisEt;

  /// No description provided for @emailDeContact.
  ///
  /// In fr, this message translates to:
  /// **'Email de contact'**
  String get emailDeContact;

  /// No description provided for @telephone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get telephone;

  /// No description provided for @pourLesQuestionsDesEquipes.
  ///
  /// In fr, this message translates to:
  /// **'Pour les questions des équipes le jour du tournoi.'**
  String get pourLesQuestionsDesEquipes;

  /// No description provided for @evenementsPasses.
  ///
  /// In fr, this message translates to:
  /// **'Événements passés'**
  String get evenementsPasses;

  /// No description provided for @facultatif.
  ///
  /// In fr, this message translates to:
  /// **'(facultatif)'**
  String get facultatif;

  /// No description provided for @jusquALesEquipesS.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu’à 3 : les équipes s’inscrivent plus volontiers chez un organisateur qui a de l’expérience.'**
  String get jusquALesEquipesS;

  /// No description provided for @ajouterUnEvenement.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un événement'**
  String get ajouterUnEvenement;

  /// No description provided for @evenements.
  ///
  /// In fr, this message translates to:
  /// **' événements'**
  String get evenements;

  /// No description provided for @nouvelEvenement.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel événement'**
  String get nouvelEvenement;

  /// No description provided for @modificationEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Modification en cours'**
  String get modificationEnCours;

  /// No description provided for @nomDeLEvenement.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’événement'**
  String get nomDeLEvenement;

  /// No description provided for @mars.
  ///
  /// In fr, this message translates to:
  /// **'mars 2026'**
  String get mars;

  /// No description provided for @equipes.
  ///
  /// In fr, this message translates to:
  /// **'Équipes'**
  String get equipes;

  /// No description provided for @modifier2.
  ///
  /// In fr, this message translates to:
  /// **'Modifier {p0}'**
  String modifier2(Object p0);

  /// No description provided for @competitions.
  ///
  /// In fr, this message translates to:
  /// **'Compétitions'**
  String get competitions;

  /// No description provided for @tournoisEvenements.
  ///
  /// In fr, this message translates to:
  /// **'Tournois & événements'**
  String get tournoisEvenements;

  /// No description provided for @scoresEnDirect.
  ///
  /// In fr, this message translates to:
  /// **'Scores en direct'**
  String get scoresEnDirect;

  /// No description provided for @annonces.
  ///
  /// In fr, this message translates to:
  /// **'Annonces'**
  String get annonces;

  /// No description provided for @premierPas.
  ///
  /// In fr, this message translates to:
  /// **'PREMIER PAS'**
  String get premierPas;

  /// No description provided for @creeTonPremierTournoi.
  ///
  /// In fr, this message translates to:
  /// **'Crée ton premier tournoi'**
  String get creeTonPremierTournoi;

  /// No description provided for @formatTerrainsDatesFraisD.
  ///
  /// In fr, this message translates to:
  /// **'Format, terrains, dates, frais d’inscription : on te guide étape par étape. Ton brouillon est enregistré à chaque étape.'**
  String get formatTerrainsDatesFraisD;

  /// No description provided for @creerUnTournoi.
  ///
  /// In fr, this message translates to:
  /// **'Créer un tournoi'**
  String get creerUnTournoi;

  /// No description provided for @reprendre.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre {p0}'**
  String reprendre(Object p0);

  /// No description provided for @courtDePadelEclaireLe.
  ///
  /// In fr, this message translates to:
  /// **'Court de padel éclairé le soir'**
  String get courtDePadelEclaireLe;

  /// No description provided for @etape.
  ///
  /// In fr, this message translates to:
  /// **'Étape {p0}'**
  String etape(Object p0);

  /// No description provided for @estPreteLanceTonPremier.
  ///
  /// In fr, this message translates to:
  /// **'{p0} est prête. Lance ton premier tournoi en quelques minutes.'**
  String estPreteLanceTonPremier(Object p0);

  /// No description provided for @modifierLOrganisation.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l’organisation'**
  String get modifierLOrganisation;

  /// No description provided for @cree.
  ///
  /// In fr, this message translates to:
  /// **'Crée'**
  String get cree;

  /// No description provided for @choisisLeFormatLesTerrains.
  ///
  /// In fr, this message translates to:
  /// **'Choisis le format, les terrains, les dates et les frais d’inscription.'**
  String get choisisLeFormatLesTerrains;

  /// No description provided for @ouvreLesInscriptions.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre les inscriptions'**
  String get ouvreLesInscriptions;

  /// No description provided for @partageLeLienLesEquipes.
  ///
  /// In fr, this message translates to:
  /// **'Partage le lien : les équipes s’inscrivent et paient leur place en ligne.'**
  String get partageLeLienLesEquipes;

  /// No description provided for @publieLeTableau.
  ///
  /// In fr, this message translates to:
  /// **'Publie le tableau'**
  String get publieLeTableau;

  /// No description provided for @poulesEtTableauFinalPuis.
  ///
  /// In fr, this message translates to:
  /// **'Poules et tableau final, puis les scores en direct le jour J.'**
  String get poulesEtTableauFinalPuis;

  /// No description provided for @bientotLIaPrepareTon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt : l’IA prépare ton tableau et ton planning'**
  String get bientotLIaPrepareTon;

  /// No description provided for @aPartirDeTesTerrains.
  ///
  /// In fr, this message translates to:
  /// **'À partir de tes terrains, de tes créneaux et du repos entre deux matchs. Tu modifies et valides tout avant de publier.'**
  String get aPartirDeTesTerrains;

  /// No description provided for @entreprise.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise'**
  String get entreprise;

  /// No description provided for @adresse.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get adresse;

  /// No description provided for @horaires.
  ///
  /// In fr, this message translates to:
  /// **'Horaires'**
  String get horaires;

  /// No description provided for @tarifs.
  ///
  /// In fr, this message translates to:
  /// **'Tarifs'**
  String get tarifs;

  /// No description provided for @photos.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @versements.
  ///
  /// In fr, this message translates to:
  /// **'Versements'**
  String get versements;

  /// No description provided for @offre.
  ///
  /// In fr, this message translates to:
  /// **'Offre'**
  String get offre;

  /// No description provided for @pro.
  ///
  /// In fr, this message translates to:
  /// **'Pro'**
  String get pro;

  /// No description provided for @starter.
  ///
  /// In fr, this message translates to:
  /// **'Starter'**
  String get starter;

  /// No description provided for @ferme.
  ///
  /// In fr, this message translates to:
  /// **'fermé'**
  String get ferme;

  /// No description provided for @aDefinir.
  ///
  /// In fr, this message translates to:
  /// **'à définir'**
  String get aDefinir;

  /// No description provided for @dtH.
  ///
  /// In fr, this message translates to:
  /// **'{p0} DT /h'**
  String dtH(Object p0);

  /// No description provided for @aDtH.
  ///
  /// In fr, this message translates to:
  /// **'{p0} à {p1} DT /h'**
  String aDtH(Object p0, Object p1);

  /// No description provided for @indiqueLAdresseDuTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Indique l’adresse du terrain.'**
  String get indiqueLAdresseDuTerrain;

  /// No description provided for @leCodePostalCompteChiffres.
  ///
  /// In fr, this message translates to:
  /// **'Le code postal compte 4 chiffres.'**
  String get leCodePostalCompteChiffres;

  /// No description provided for @indiqueLaVille.
  ///
  /// In fr, this message translates to:
  /// **'Indique la ville.'**
  String get indiqueLaVille;

  /// No description provided for @tonTerrain.
  ///
  /// In fr, this message translates to:
  /// **'ton terrain'**
  String get tonTerrain;

  /// No description provided for @ouSeTrouve.
  ///
  /// In fr, this message translates to:
  /// **'Où se trouve {p0} ?'**
  String ouSeTrouve(Object p0);

  /// No description provided for @lesJoueursTeTrouventSur.
  ///
  /// In fr, this message translates to:
  /// **'Les joueurs te trouvent sur la carte et reçoivent l’itinéraire avant le match.'**
  String get lesJoueursTeTrouventSur;

  /// No description provided for @codePostal.
  ///
  /// In fr, this message translates to:
  /// **'Code postal'**
  String get codePostal;

  /// No description provided for @ville.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get ville;

  /// No description provided for @gouvernorat.
  ///
  /// In fr, this message translates to:
  /// **'Gouvernorat'**
  String get gouvernorat;

  /// No description provided for @indicationsDAcces.
  ///
  /// In fr, this message translates to:
  /// **'Indications d’accès'**
  String get indicationsDAcces;

  /// No description provided for @zoomer.
  ///
  /// In fr, this message translates to:
  /// **'Zoomer'**
  String get zoomer;

  /// No description provided for @dezoomer.
  ///
  /// In fr, this message translates to:
  /// **'Dézoomer'**
  String get dezoomer;

  /// No description provided for @centrerSurLEpingle.
  ///
  /// In fr, this message translates to:
  /// **'Centrer sur l’épingle'**
  String get centrerSurLEpingle;

  /// No description provided for @positionDe.
  ///
  /// In fr, this message translates to:
  /// **'Position de {p0}, {p1}'**
  String positionDe(Object p0, Object p1);

  /// No description provided for @positionSurLaCarte.
  ///
  /// In fr, this message translates to:
  /// **'Position sur la carte'**
  String get positionSurLaCarte;

  /// No description provided for @deplaceLEpingleSurL.
  ///
  /// In fr, this message translates to:
  /// **'Déplace l’épingle sur l’entrée'**
  String get deplaceLEpingleSurL;

  /// No description provided for @epingleDeplaceeDeM.
  ///
  /// In fr, this message translates to:
  /// **' · épingle déplacée de {p0} m'**
  String epingleDeplaceeDeM(Object p0);

  /// No description provided for @recentrerSurLAdresse.
  ///
  /// In fr, this message translates to:
  /// **'Recentrer sur l’adresse'**
  String get recentrerSurLAdresse;

  /// No description provided for @indiqueLeNomDuTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Indique le nom du terrain.'**
  String get indiqueLeNomDuTerrain;

  /// No description provided for @indiqueLaRaisonSociale.
  ///
  /// In fr, this message translates to:
  /// **'Indique la raison sociale.'**
  String get indiqueLaRaisonSociale;

  /// No description provided for @leMatriculeFiscalRessembleA.
  ///
  /// In fr, this message translates to:
  /// **'Le matricule fiscal ressemble à 1234567/A/M/000.'**
  String get leMatriculeFiscalRessembleA;

  /// No description provided for @parleNousDeTonEntreprise.
  ///
  /// In fr, this message translates to:
  /// **'Parle-nous de ton entreprise'**
  String get parleNousDeTonEntreprise;

  /// No description provided for @lesJoueursNeVerrontQue.
  ///
  /// In fr, this message translates to:
  /// **'Les joueurs ne verront que le nom du terrain et son téléphone.'**
  String get lesJoueursNeVerrontQue;

  /// No description provided for @tonEtablissement.
  ///
  /// In fr, this message translates to:
  /// **'Ton établissement'**
  String get tonEtablissement;

  /// No description provided for @cesInfosFigurentSurTes.
  ///
  /// In fr, this message translates to:
  /// **'Ces infos figurent sur tes factures. Tu pourras les modifier plus tard.'**
  String get cesInfosFigurentSurTes;

  /// No description provided for @nomDuTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Nom du terrain'**
  String get nomDuTerrain;

  /// No description provided for @leNomQueLesJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Le nom que les joueurs verront sur MatchUp.'**
  String get leNomQueLesJoueurs;

  /// No description provided for @raisonSociale.
  ///
  /// In fr, this message translates to:
  /// **'Raison sociale'**
  String get raisonSociale;

  /// No description provided for @commeSurTonRegistreDe.
  ///
  /// In fr, this message translates to:
  /// **'Comme sur ton registre de commerce.'**
  String get commeSurTonRegistreDe;

  /// No description provided for @matriculeFiscal.
  ///
  /// In fr, this message translates to:
  /// **'Matricule fiscal'**
  String get matriculeFiscal;

  /// No description provided for @ilFigureSurTaCarte.
  ///
  /// In fr, this message translates to:
  /// **'Il figure sur ta carte d’identification fiscale.'**
  String get ilFigureSurTaCarte;

  /// No description provided for @formeJuridique.
  ///
  /// In fr, this message translates to:
  /// **'Forme juridique'**
  String get formeJuridique;

  /// No description provided for @contact.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @responsableDuCompte.
  ///
  /// In fr, this message translates to:
  /// **'Responsable du compte : {p0}'**
  String responsableDuCompte(Object p0);

  /// No description provided for @telephoneDuTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone du terrain'**
  String get telephoneDuTerrain;

  /// No description provided for @lesJoueursTAppellentA.
  ///
  /// In fr, this message translates to:
  /// **'Les joueurs t’appellent à ce numéro le jour du match.'**
  String get lesJoueursTAppellentA;

  /// No description provided for @emailPro.
  ///
  /// In fr, this message translates to:
  /// **'Email pro'**
  String get emailPro;

  /// No description provided for @pourLesReservationsLesVersements.
  ///
  /// In fr, this message translates to:
  /// **'Pour les réservations, les versements et les factures.'**
  String get pourLesReservationsLesVersements;

  /// No description provided for @terrain4.
  ///
  /// In fr, this message translates to:
  /// **'Terrain {p0}'**
  String terrain4(Object p0);

  /// No description provided for @donneUnNomAuTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom au terrain.'**
  String get donneUnNomAuTerrain;

  /// No description provided for @copie.
  ///
  /// In fr, this message translates to:
  /// **'{p0} (copie)'**
  String copie(Object p0);

  /// No description provided for @supprime.
  ///
  /// In fr, this message translates to:
  /// **'{p0} supprimé'**
  String supprime(Object p0);

  /// No description provided for @ajouteAuMoinsUnTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute au moins un terrain.'**
  String get ajouteAuMoinsUnTerrain;

  /// No description provided for @tesTerrains.
  ///
  /// In fr, this message translates to:
  /// **'Tes terrains'**
  String get tesTerrains;

  /// No description provided for @ajouteChaqueTerrainReservableLes.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute chaque terrain réservable. Les joueurs filtrent par sport, surface et éclairage.'**
  String get ajouteChaqueTerrainReservableLes;

  /// No description provided for @chaqueTerrainASonPlanning.
  ///
  /// In fr, this message translates to:
  /// **'Chaque terrain a son planning et ses créneaux.'**
  String get chaqueTerrainASonPlanning;

  /// No description provided for @ajouterUnTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un terrain'**
  String get ajouterUnTerrain;

  /// No description provided for @nouveauTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau terrain'**
  String get nouveauTerrain;

  /// No description provided for @nom.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get nom;

  /// No description provided for @surface.
  ///
  /// In fr, this message translates to:
  /// **'Surface'**
  String get surface;

  /// No description provided for @type.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @eclairage.
  ///
  /// In fr, this message translates to:
  /// **'Éclairage'**
  String get eclairage;

  /// No description provided for @projecteursLedPourLesMatchs.
  ///
  /// In fr, this message translates to:
  /// **'Projecteurs LED pour les matchs du soir'**
  String get projecteursLedPourLesMatchs;

  /// No description provided for @dupliquer.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer'**
  String get dupliquer;

  /// No description provided for @supprimer.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get supprimer;

  /// No description provided for @plusDActionsPour.
  ///
  /// In fr, this message translates to:
  /// **'Plus d’actions pour {p0}'**
  String plusDActionsPour(Object p0);

  /// No description provided for @eclairage2.
  ///
  /// In fr, this message translates to:
  /// **'Éclairage, {p0}'**
  String eclairage2(Object p0);

  /// No description provided for @horairesDuAppliquesATous.
  ///
  /// In fr, this message translates to:
  /// **'Horaires du {p0} appliqués à tous les jours ouverts'**
  String horairesDuAppliquesATous(Object p0);

  /// No description provided for @ouvreAuMoinsUnJour.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre au moins un jour.'**
  String get ouvreAuMoinsUnJour;

  /// No description provided for @tesHorairesDOuverture.
  ///
  /// In fr, this message translates to:
  /// **'Tes horaires d’ouverture'**
  String get tesHorairesDOuverture;

  /// No description provided for @lesJoueursNePeuventReserver.
  ///
  /// In fr, this message translates to:
  /// **'Les joueurs ne peuvent réserver que pendant ces plages.'**
  String get lesJoueursNePeuventReserver;

  /// No description provided for @horairesDeLaSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Horaires de la semaine'**
  String get horairesDeLaSemaine;

  /// No description provided for @lesCreneauxSontGeneresToutes.
  ///
  /// In fr, this message translates to:
  /// **'Les créneaux sont générés toutes les heures dans ces plages.'**
  String get lesCreneauxSontGeneresToutes;

  /// No description provided for @appliquerATousLesJours.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer à tous les jours'**
  String get appliquerATousLesJours;

  /// No description provided for @jour.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get jour;

  /// No description provided for @ouverture.
  ///
  /// In fr, this message translates to:
  /// **'Ouverture'**
  String get ouverture;

  /// No description provided for @fermeture.
  ///
  /// In fr, this message translates to:
  /// **'Fermeture'**
  String get fermeture;

  /// No description provided for @duree.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get duree;

  /// No description provided for @fermeturesExceptionnelles.
  ///
  /// In fr, this message translates to:
  /// **'Fermetures exceptionnelles'**
  String get fermeturesExceptionnelles;

  /// No description provided for @aidJoursFeriesTravauxLes.
  ///
  /// In fr, this message translates to:
  /// **'Aïd, jours fériés, travaux : les créneaux de ces dates disparaissent.'**
  String get aidJoursFeriesTravauxLes;

  /// No description provided for @ajouterUneFermeture.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une fermeture'**
  String get ajouterUneFermeture;

  /// No description provided for @ouvertureLe.
  ///
  /// In fr, this message translates to:
  /// **'Ouverture le {p0}'**
  String ouvertureLe(Object p0);

  /// No description provided for @fermetureLe.
  ///
  /// In fr, this message translates to:
  /// **'Fermeture le {p0}'**
  String fermetureLe(Object p0);

  /// No description provided for @fermeTouteLaJournee.
  ///
  /// In fr, this message translates to:
  /// **'Fermé toute la journée'**
  String get fermeTouteLaJournee;

  /// No description provided for @laFermetureDoitVenirApres.
  ///
  /// In fr, this message translates to:
  /// **'La fermeture doit venir après l’ouverture.'**
  String get laFermetureDoitVenirApres;

  /// No description provided for @activite.
  ///
  /// In fr, this message translates to:
  /// **'Activité'**
  String get activite;

  /// No description provided for @planning.
  ///
  /// In fr, this message translates to:
  /// **'Planning'**
  String get planning;

  /// No description provided for @reservations.
  ///
  /// In fr, this message translates to:
  /// **'Réservations'**
  String get reservations;

  /// No description provided for @clientele.
  ///
  /// In fr, this message translates to:
  /// **'Clientèle'**
  String get clientele;

  /// No description provided for @clients.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @avis.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get avis;

  /// No description provided for @infosDeLEntreprise.
  ///
  /// In fr, this message translates to:
  /// **'Infos de l’entreprise'**
  String get infosDeLEntreprise;

  /// No description provided for @matriculeFiscal2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · matricule fiscal {p1}'**
  String matriculeFiscal2(Object p0, Object p1);

  /// No description provided for @raisonSocialeMatriculeFiscalEt.
  ///
  /// In fr, this message translates to:
  /// **'Raison sociale, matricule fiscal et contact.'**
  String get raisonSocialeMatriculeFiscalEt;

  /// No description provided for @reprendre2.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get reprendre2;

  /// No description provided for @modifierLesInfosDeL.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les infos de l’entreprise'**
  String get modifierLesInfosDeL;

  /// No description provided for @adresseEtTerrains.
  ///
  /// In fr, this message translates to:
  /// **'Adresse et terrains'**
  String get adresseEtTerrains;

  /// No description provided for @ouTeTrouverEtChaque.
  ///
  /// In fr, this message translates to:
  /// **'Où te trouver, et chaque terrain réservable.'**
  String get ouTeTrouverEtChaque;

  /// No description provided for @modifierLAdresseEtLes.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l’adresse et les terrains'**
  String get modifierLAdresseEtLes;

  /// No description provided for @horairesEtTarifs.
  ///
  /// In fr, this message translates to:
  /// **'Horaires et tarifs'**
  String get horairesEtTarifs;

  /// No description provided for @jDeADtH.
  ///
  /// In fr, this message translates to:
  /// **'{p0}j/7 · de {p1} à {p2} DT /h, soit {p3} à {p4} DT /pers.'**
  String jDeADtH(Object p0, Object p1, Object p2, Object p3, Object p4);

  /// No description provided for @quandOnPeutReserverEt.
  ///
  /// In fr, this message translates to:
  /// **'Quand on peut réserver, et à quel prix.'**
  String get quandOnPeutReserverEt;

  /// No description provided for @modifierLesHorairesEtLes.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les horaires et les tarifs'**
  String get modifierLesHorairesEtLes;

  /// No description provided for @photosEtVersements.
  ///
  /// In fr, this message translates to:
  /// **'Photos et versements'**
  String get photosEtVersements;

  /// No description provided for @photos2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} photos · {p1} {p2}'**
  String photos2(Object p0, Object p1, Object p2);

  /// No description provided for @tesPhotosEtLeCompte.
  ///
  /// In fr, this message translates to:
  /// **'Tes photos, et le compte où on verse tes revenus.'**
  String get tesPhotosEtLeCompte;

  /// No description provided for @ribEnVerification.
  ///
  /// In fr, this message translates to:
  /// **'RIB en vérification'**
  String get ribEnVerification;

  /// No description provided for @modifierLesPhotosEtLes.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les photos et les versements'**
  String get modifierLesPhotosEtLes;

  /// No description provided for @choisisTonOffre.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton offre'**
  String get choisisTonOffre;

  /// No description provided for @joursDEssaiGratuitSans.
  ///
  /// In fr, this message translates to:
  /// **'{p0} jours d’essai gratuit, sans paiement aujourd’hui.'**
  String joursDEssaiGratuitSans(Object p0);

  /// No description provided for @ajouteTaPolitiqueDAnnulation.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ta politique d’annulation'**
  String get ajouteTaPolitiqueDAnnulation;

  /// No description provided for @lesJoueursLaLisentAvant.
  ///
  /// In fr, this message translates to:
  /// **'Les joueurs la lisent avant de payer. Par exemple : remboursé jusqu’à 24 h avant.'**
  String get lesJoueursLaLisentAvant;

  /// No description provided for @publieTonPremierCreneau.
  ///
  /// In fr, this message translates to:
  /// **'Publie ton premier créneau'**
  String get publieTonPremierCreneau;

  /// No description provided for @tesTerrainsDeviennentReservablesEt.
  ///
  /// In fr, this message translates to:
  /// **'Tes terrains deviennent réservables et visibles à {p0}.'**
  String tesTerrainsDeviennentReservablesEt(Object p0);

  /// No description provided for @publier.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get publier;

  /// No description provided for @miseEnRoute.
  ///
  /// In fr, this message translates to:
  /// **'MISE EN ROUTE'**
  String get miseEnRoute;

  /// No description provided for @termineLaConfiguration.
  ///
  /// In fr, this message translates to:
  /// **'Termine la configuration {p0}'**
  String termineLaConfiguration(Object p0);

  /// No description provided for @toutEstPret.
  ///
  /// In fr, this message translates to:
  /// **'Tout est prêt.'**
  String get toutEstPret;

  /// No description provided for @encoreEtapeEtLesJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Encore {p0} étape{p1} et les joueurs pourront réserver.'**
  String encoreEtapeEtLesJoueurs(Object p0, Object p1);

  /// No description provided for @configuration.
  ///
  /// In fr, this message translates to:
  /// **'Configuration'**
  String get configuration;

  /// No description provided for @reservationsDuJour.
  ///
  /// In fr, this message translates to:
  /// **'Réservations du jour'**
  String get reservationsDuJour;

  /// No description provided for @aucuneReservationPourLInstant.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réservation pour l’instant'**
  String get aucuneReservationPourLInstant;

  /// No description provided for @publieTonPremierCreneauIl.
  ///
  /// In fr, this message translates to:
  /// **'Publie ton premier créneau : il apparaîtra aux joueurs {p0}.'**
  String publieTonPremierCreneauIl(Object p0);

  /// No description provided for @ouvrirLePlanning.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le planning'**
  String get ouvrirLePlanning;

  /// No description provided for @bonjour.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {p0}'**
  String bonjour(Object p0);

  /// No description provided for @voiciOuEnEst.
  ///
  /// In fr, this message translates to:
  /// **'{p0} Voici où en est {p1}.'**
  String voiciOuEnEst(Object p0, Object p1);

  /// No description provided for @termineLaConfigurationPourDemarrer.
  ///
  /// In fr, this message translates to:
  /// **'Termine la configuration pour démarrer ton essai gratuit. Voici où en est {p0}.'**
  String termineLaConfigurationPourDemarrer(Object p0);

  /// No description provided for @pasEncoreVisibleDesJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore visible des joueurs'**
  String get pasEncoreVisibleDesJoueurs;

  /// No description provided for @tauxDOccupation.
  ///
  /// In fr, this message translates to:
  /// **'Taux d’occupation'**
  String get tauxDOccupation;

  /// No description provided for @calculeDesTaPremiereReservation.
  ///
  /// In fr, this message translates to:
  /// **'Calculé dès ta première réservation'**
  String get calculeDesTaPremiereReservation;

  /// No description provided for @revenusDuJour.
  ///
  /// In fr, this message translates to:
  /// **'Revenus du jour'**
  String get revenusDuJour;

  /// No description provided for @aucunPaiementEncaisse.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement encaissé'**
  String get aucunPaiementEncaisse;

  /// No description provided for @pasEncoreDeComparaison.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de comparaison'**
  String get pasEncoreDeComparaison;

  /// No description provided for @apresLesPremiersAvisDes.
  ///
  /// In fr, this message translates to:
  /// **'Après les premiers avis des joueurs'**
  String get apresLesPremiersAvisDes;

  /// No description provided for @fait.
  ///
  /// In fr, this message translates to:
  /// **'Fait'**
  String get fait;

  /// No description provided for @aFaire.
  ///
  /// In fr, this message translates to:
  /// **'À faire'**
  String get aFaire;

  /// No description provided for @peseMaxMoChoisisUn2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} pèse {p1} (max 5 Mo). Choisis un fichier plus léger.'**
  String peseMaxMoChoisisUn2(Object p0, Object p1);

  /// No description provided for @chiffresCleRibValide.
  ///
  /// In fr, this message translates to:
  /// **'20 chiffres · clé RIB valide'**
  String get chiffresCleRibValide;

  /// No description provided for @indiqueLeTitulaireDuCompte.
  ///
  /// In fr, this message translates to:
  /// **'Indique le titulaire du compte.'**
  String get indiqueLeTitulaireDuCompte;

  /// No description provided for @choisisTaBanque.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ta banque.'**
  String get choisisTaBanque;

  /// No description provided for @leRibCompteChiffres.
  ///
  /// In fr, this message translates to:
  /// **'Le RIB compte 20 chiffres.'**
  String get leRibCompteChiffres;

  /// No description provided for @ajouteTonAttestationDeRib.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ton attestation de RIB.'**
  String get ajouteTonAttestationDeRib;

  /// No description provided for @titulaireDuCompte.
  ///
  /// In fr, this message translates to:
  /// **'Titulaire du compte'**
  String get titulaireDuCompte;

  /// No description provided for @commeSurTonReleveBancaire.
  ///
  /// In fr, this message translates to:
  /// **'Comme sur ton relevé bancaire.'**
  String get commeSurTonReleveBancaire;

  /// No description provided for @banque.
  ///
  /// In fr, this message translates to:
  /// **'Banque'**
  String get banque;

  /// No description provided for @choisisTaBanque2.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ta banque'**
  String get choisisTaBanque2;

  /// No description provided for @rib.
  ///
  /// In fr, this message translates to:
  /// **'RIB'**
  String get rib;

  /// No description provided for @verificationDuRib.
  ///
  /// In fr, this message translates to:
  /// **'Vérification du RIB…'**
  String get verificationDuRib;

  /// No description provided for @attestationDeRib.
  ///
  /// In fr, this message translates to:
  /// **'Attestation de RIB'**
  String get attestationDeRib;

  /// No description provided for @glisseOuChoisisTonAttestation.
  ///
  /// In fr, this message translates to:
  /// **'Glisse ou choisis ton attestation'**
  String get glisseOuChoisisTonAttestation;

  /// No description provided for @pdfJpgPngMoMax2.
  ///
  /// In fr, this message translates to:
  /// **'PDF, JPG, PNG · 5 Mo max'**
  String get pdfJpgPngMoMax2;

  /// No description provided for @ouVerserTesRevenus.
  ///
  /// In fr, this message translates to:
  /// **'Où verser tes revenus ?'**
  String get ouVerserTesRevenus;

  /// No description provided for @chaqueLundiMatchupVireSur.
  ///
  /// In fr, this message translates to:
  /// **'Chaque lundi, MatchUp vire sur ce compte les réservations payées en ligne la semaine passée.'**
  String get chaqueLundiMatchupVireSur;

  /// No description provided for @verifieSousH.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié sous 48 h'**
  String get verifieSousH;

  /// No description provided for @onVerifieQueLeCompte.
  ///
  /// In fr, this message translates to:
  /// **'On vérifie que le compte est bien au nom {p0}. Tes réservations s’ouvrent sans attendre, les versements partent dès la validation.'**
  String onVerifieQueLeCompte(Object p0);

  /// No description provided for @tesCoordonneesBancairesSontChiffrees.
  ///
  /// In fr, this message translates to:
  /// **'Tes coordonnées bancaires sont chiffrées'**
  String get tesCoordonneesBancairesSontChiffrees;

  /// No description provided for @apresLEnregistrementSeulsLes.
  ///
  /// In fr, this message translates to:
  /// **'Après l’enregistrement, seuls les 4 derniers chiffres restent visibles : '**
  String get apresLEnregistrementSeulsLes;

  /// No description provided for @peseMaxMoReduisSa.
  ///
  /// In fr, this message translates to:
  /// **'{p0} pèse {p1} (max 10 Mo). Réduis sa taille ou choisis une autre photo.'**
  String peseMaxMoReduisSa(Object p0, Object p1);

  /// No description provided for @photosMaximumLesSuivantesSont.
  ///
  /// In fr, this message translates to:
  /// **'{p0} photos maximum : les suivantes sont ignorées.'**
  String photosMaximumLesSuivantesSont(Object p0);

  /// No description provided for @ajouteAuMoinsUnePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute au moins une photo de ton terrain.'**
  String get ajouteAuMoinsUnePhoto;

  /// No description provided for @montreTonTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Montre ton terrain'**
  String get montreTonTerrain;

  /// No description provided for @montreLEclairageLesVestiaires.
  ///
  /// In fr, this message translates to:
  /// **'Montre l’éclairage, les vestiaires et le parking : les joueurs réservent plus vite.'**
  String get montreLEclairageLesVestiaires;

  /// No description provided for @ajouteTesPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute tes photos'**
  String get ajouteTesPhotos;

  /// No description provided for @jpgPngMoMaxJusqu.
  ///
  /// In fr, this message translates to:
  /// **'JPG, PNG · 10 Mo max · jusqu’à 20 photos'**
  String get jpgPngMoMaxJusqu;

  /// No description provided for @tesPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Tes photos'**
  String get tesPhotos;

  /// No description provided for @la1rePhotoSertDe.
  ///
  /// In fr, this message translates to:
  /// **'La 1re photo sert de couverture. Glisse une photo pour changer l’ordre.'**
  String get la1rePhotoSertDe;

  /// No description provided for @tonTerrainReservableEnLigne.
  ///
  /// In fr, this message translates to:
  /// **'Ton terrain réservable en ligne en 10 minutes.'**
  String get tonTerrainReservableEnLigne;

  /// No description provided for @jusquATerrains.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu’à 2 terrains'**
  String get jusquATerrains;

  /// No description provided for @calendrierEtReservationsEnLigne.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier et réservations en ligne'**
  String get calendrierEtReservationsEnLigne;

  /// No description provided for @paiementEnLigneCommission.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en ligne · commission 5 %'**
  String get paiementEnLigneCommission;

  /// No description provided for @statistiquesDOccupationEtDe.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques d’occupation et de revenus'**
  String get statistiquesDOccupationEtDe;

  /// No description provided for @tarifsHeuresCreusesPleines.
  ///
  /// In fr, this message translates to:
  /// **'Tarifs heures creuses / pleines'**
  String get tarifsHeuresCreusesPleines;

  /// No description provided for @comptesGerants.
  ///
  /// In fr, this message translates to:
  /// **'Comptes gérants'**
  String get comptesGerants;

  /// No description provided for @remplisTesCreneauxCreux.
  ///
  /// In fr, this message translates to:
  /// **'Remplis tes créneaux creux.'**
  String get remplisTesCreneauxCreux;

  /// No description provided for @terrainsIllimites.
  ///
  /// In fr, this message translates to:
  /// **'Terrains illimités'**
  String get terrainsIllimites;

  /// No description provided for @jusquAComptesGerants.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu’à 5 comptes gérants'**
  String get jusquAComptesGerants;

  /// No description provided for @paiementEnLigneCommission2.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en ligne · commission 3 %'**
  String get paiementEnLigneCommission2;

  /// No description provided for @supportPrioritaire7j.
  ///
  /// In fr, this message translates to:
  /// **'Support prioritaire 7j/7'**
  String get supportPrioritaire7j;

  /// No description provided for @tonTerrain2.
  ///
  /// In fr, this message translates to:
  /// **'Ton terrain'**
  String get tonTerrain2;

  /// No description provided for @moisOfferts.
  ///
  /// In fr, this message translates to:
  /// **'2 mois offerts'**
  String get moisOfferts;

  /// No description provided for @joursDEssaiGratuitSur.
  ///
  /// In fr, this message translates to:
  /// **'{p0} jours d’essai gratuit sur les deux offres. Aucun paiement aujourd’hui.'**
  String joursDEssaiGratuitSur(Object p0);

  /// No description provided for @demarrerLEssaiGratuit.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer l’essai gratuit'**
  String get demarrerLEssaiGratuit;

  /// No description provided for @periodeDeFacturation.
  ///
  /// In fr, this message translates to:
  /// **'Période de facturation'**
  String get periodeDeFacturation;

  /// No description provided for @mensuel.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel'**
  String get mensuel;

  /// No description provided for @annuel.
  ///
  /// In fr, this message translates to:
  /// **'Annuel'**
  String get annuel;

  /// No description provided for @aTerrainsAvecStarterSeuls.
  ///
  /// In fr, this message translates to:
  /// **'{p0} a {p1} terrains : avec Starter, seuls {p2} seraient réservables.'**
  String aTerrainsAvecStarterSeuls(Object p0, Object p1, Object p2);

  /// No description provided for @sansEngagementResiliableEnClics.
  ///
  /// In fr, this message translates to:
  /// **'Sans engagement · résiliable en 2 clics'**
  String get sansEngagementResiliableEnClics;

  /// No description provided for @dtAujourdHuiPuisA.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · 0 DT aujourd’hui, puis {p1} à partir du {p2}'**
  String dtAujourdHuiPuisA(Object p0, Object p1, Object p2);

  /// No description provided for @terrains2.
  ///
  /// In fr, this message translates to:
  /// **'Terrains {p0}'**
  String terrains2(Object p0);

  /// No description provided for @fixeTesTarifs.
  ///
  /// In fr, this message translates to:
  /// **'Fixe tes tarifs'**
  String get fixeTesTarifs;

  /// No description provided for @lesJoueursComparentLePrix.
  ///
  /// In fr, this message translates to:
  /// **'Les joueurs comparent le prix par personne : MatchUp l’affiche à côté du prix du terrain.'**
  String get lesJoueursComparentLePrix;

  /// No description provided for @prixDuTerrainAL.
  ///
  /// In fr, this message translates to:
  /// **'Prix du terrain à l’heure'**
  String get prixDuTerrainAL;

  /// No description provided for @lePrixParJoueurEst.
  ///
  /// In fr, this message translates to:
  /// **'Le prix par joueur est calculé pour 10 joueurs, comme sur MatchUp.'**
  String get lePrixParJoueurEst;

  /// No description provided for @modifierLesPlages.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les plages'**
  String get modifierLesPlages;

  /// No description provided for @weekEndEnHeuresDe.
  ///
  /// In fr, this message translates to:
  /// **'Week-end en heures de pointe'**
  String get weekEndEnHeuresDe;

  /// No description provided for @samediEtDimancheDeL.
  ///
  /// In fr, this message translates to:
  /// **'Samedi et dimanche, de l’ouverture à la fermeture.'**
  String get samediEtDimancheDeL;

  /// No description provided for @datesSpeciales.
  ///
  /// In fr, this message translates to:
  /// **'Dates spéciales'**
  String get datesSpeciales;

  /// No description provided for @ramadanAidSoirDeFinale.
  ///
  /// In fr, this message translates to:
  /// **'Ramadan, Aïd, soir de finale : un autre tarif pour un jour précis.'**
  String get ramadanAidSoirDeFinale;

  /// No description provided for @ajouterUneDate.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une date'**
  String get ajouterUneDate;

  /// No description provided for @typeDeTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Type de terrain'**
  String get typeDeTerrain;

  /// No description provided for @heuresCreuses.
  ///
  /// In fr, this message translates to:
  /// **'Heures creuses'**
  String get heuresCreuses;

  /// No description provided for @lunVen08h0017h00.
  ///
  /// In fr, this message translates to:
  /// **'Lun.–ven. · 08h00–17h00'**
  String get lunVen08h0017h00;

  /// No description provided for @heuresDePointe.
  ///
  /// In fr, this message translates to:
  /// **'Heures de pointe'**
  String get heuresDePointe;

  /// No description provided for @lunVen17h00Fermeture.
  ///
  /// In fr, this message translates to:
  /// **'Lun.–ven. · 17h00–fermeture'**
  String get lunVen17h00Fermeture;

  /// No description provided for @interieur2.
  ///
  /// In fr, this message translates to:
  /// **'intérieur'**
  String get interieur2;

  /// No description provided for @exterieur2.
  ///
  /// In fr, this message translates to:
  /// **'extérieur'**
  String get exterieur2;

  /// No description provided for @dtH2.
  ///
  /// In fr, this message translates to:
  /// **'DT /h'**
  String get dtH2;

  /// No description provided for @indiqueUnPrix.
  ///
  /// In fr, this message translates to:
  /// **'Indique un prix.'**
  String get indiqueUnPrix;

  /// No description provided for @soitPers.
  ///
  /// In fr, this message translates to:
  /// **'soit {p0} /pers.'**
  String soitPers(Object p0);

  /// No description provided for @heuresCreuses2.
  ///
  /// In fr, this message translates to:
  /// **'heures creuses'**
  String get heuresCreuses2;

  /// No description provided for @heuresDePointe2.
  ///
  /// In fr, this message translates to:
  /// **'heures de pointe'**
  String get heuresDePointe2;

  /// No description provided for @apercuJoueurHeureDePointe.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu joueur : {p0}, heure de pointe, {p1}'**
  String apercuJoueurHeureDePointe(Object p0, Object p1);

  /// No description provided for @apercuJoueurEnDirect.
  ///
  /// In fr, this message translates to:
  /// **'APERÇU JOUEUR · EN DIRECT'**
  String get apercuJoueurEnDirect;

  /// No description provided for @heureDePointeH.
  ///
  /// In fr, this message translates to:
  /// **'Heure de pointe · 1 h'**
  String get heureDePointeH;

  /// No description provided for @leTerrainSoitPersPour.
  ///
  /// In fr, this message translates to:
  /// **'{p0} le terrain · soit {p1} /pers. pour {p2} joueurs'**
  String leTerrainSoitPersPour(Object p0, Object p1, Object p2);

  /// No description provided for @metsEnLigne.
  ///
  /// In fr, this message translates to:
  /// **'Mets {p0} en ligne'**
  String metsEnLigne(Object p0);

  /// No description provided for @etapesEnvironMin3.
  ///
  /// In fr, this message translates to:
  /// **'{p0} étapes · environ 10 min'**
  String etapesEnvironMin3(Object p0);

  /// No description provided for @yassineBelhaj.
  ///
  /// In fr, this message translates to:
  /// **'YASSINE BELHAJ'**
  String get yassineBelhaj;

  /// No description provided for @numeroDeCarteInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de carte invalide'**
  String get numeroDeCarteInvalide;

  /// No description provided for @dateDExpirationInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Date d’expiration invalide'**
  String get dateDExpirationInvalide;

  /// No description provided for @carteExpiree.
  ///
  /// In fr, this message translates to:
  /// **'Carte expirée'**
  String get carteExpiree;

  /// No description provided for @cvcIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'CVC incorrect'**
  String get cvcIncorrect;

  /// No description provided for @codePromoExpire.
  ///
  /// In fr, this message translates to:
  /// **'Code promo expiré'**
  String get codePromoExpire;

  /// No description provided for @taCarte.
  ///
  /// In fr, this message translates to:
  /// **'ta carte'**
  String get taCarte;

  /// No description provided for @refuseeA.
  ///
  /// In fr, this message translates to:
  /// **'Refusée à {p0} · {p1}'**
  String refuseeA(Object p0, Object p1);

  /// No description provided for @paiementRefuse.
  ///
  /// In fr, this message translates to:
  /// **'Paiement refusé'**
  String get paiementRefuse;

  /// No description provided for @rienNAEteDebite.
  ///
  /// In fr, this message translates to:
  /// **'Rien n’a été débité. Choisis une autre solution.'**
  String get rienNAEteDebite;

  /// No description provided for @taPlaceEstConfirmeeRecu.
  ///
  /// In fr, this message translates to:
  /// **'Ta place est confirmée · reçu envoyé par e-mail'**
  String get taPlaceEstConfirmeeRecu;

  /// No description provided for @paiementConfirme.
  ///
  /// In fr, this message translates to:
  /// **'Paiement confirmé'**
  String get paiementConfirme;

  /// No description provided for @taPartNEstPas.
  ///
  /// In fr, this message translates to:
  /// **'Ta part n’est pas passée'**
  String get taPartNEstPas;

  /// No description provided for @rienNAEteDebite2.
  ///
  /// In fr, this message translates to:
  /// **'Rien n’a été débité. Tu peux réessayer.'**
  String get rienNAEteDebite2;

  /// No description provided for @rienAPayer.
  ///
  /// In fr, this message translates to:
  /// **'Rien à payer'**
  String get rienAPayer;

  /// No description provided for @reviensDepuisUneReservationOu.
  ///
  /// In fr, this message translates to:
  /// **'Reviens depuis une réservation ou une partie.'**
  String get reviensDepuisUneReservationOu;

  /// No description provided for @accueil.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get accueil;

  /// No description provided for @reductions.
  ///
  /// In fr, this message translates to:
  /// **'Réductions'**
  String get reductions;

  /// No description provided for @codePromo.
  ///
  /// In fr, this message translates to:
  /// **'Code promo'**
  String get codePromo;

  /// No description provided for @exBienvenue10.
  ///
  /// In fr, this message translates to:
  /// **'Ex. BIENVENUE10'**
  String get exBienvenue10;

  /// No description provided for @code2.
  ///
  /// In fr, this message translates to:
  /// **'Code {p0} · −{p1} %'**
  String code2(Object p0, Object p1);

  /// No description provided for @appliquer.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get appliquer;

  /// No description provided for @utiliserMonSolde.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser mon solde'**
  String get utiliserMonSolde;

  /// No description provided for @nouvelleCarte.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle carte'**
  String get nouvelleCarte;

  /// No description provided for @mesCartes.
  ///
  /// In fr, this message translates to:
  /// **'Mes cartes'**
  String get mesCartes;

  /// No description provided for @enregistrerCetteCarte.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer cette carte'**
  String get enregistrerCetteCarte;

  /// No description provided for @pourPayerEnUnGeste.
  ///
  /// In fr, this message translates to:
  /// **'Pour payer en un geste la prochaine fois. Elle est gardée par Stripe, jamais par MatchUp.'**
  String get pourPayerEnUnGeste;

  /// No description provided for @paieAutrement.
  ///
  /// In fr, this message translates to:
  /// **'Paie autrement'**
  String get paieAutrement;

  /// No description provided for @moyenDePaiement.
  ///
  /// In fr, this message translates to:
  /// **'Moyen de paiement'**
  String get moyenDePaiement;

  /// No description provided for @taPlaceTAttendChoisis.
  ///
  /// In fr, this message translates to:
  /// **'Ta place t’attend. Choisis une autre solution.'**
  String get taPlaceTAttendChoisis;

  /// No description provided for @tonSoldeCouvreToutTa.
  ///
  /// In fr, this message translates to:
  /// **'Ton solde couvre tout : ta carte ne sera pas débitée.'**
  String get tonSoldeCouvreToutTa;

  /// No description provided for @soldeMatchupCouvreTaPart.
  ///
  /// In fr, this message translates to:
  /// **'Solde MatchUp · {p0}, couvre ta part'**
  String soldeMatchupCouvreTaPart(Object p0);

  /// No description provided for @soldeMatchup2.
  ///
  /// In fr, this message translates to:
  /// **'Solde MatchUp · {p0}'**
  String soldeMatchup2(Object p0);

  /// No description provided for @couvreTaPartDe.
  ///
  /// In fr, this message translates to:
  /// **'Couvre ta part de {p0}'**
  String couvreTaPartDe(Object p0);

  /// No description provided for @ajouterUneCarte.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une carte'**
  String get ajouterUneCarte;

  /// No description provided for @ouEnUnGeste.
  ///
  /// In fr, this message translates to:
  /// **'ou en un geste'**
  String get ouEnUnGeste;

  /// No description provided for @payerAvecApplePay.
  ///
  /// In fr, this message translates to:
  /// **'Payer {p0} avec Apple Pay'**
  String payerAvecApplePay(Object p0);

  /// No description provided for @applePay.
  ///
  /// In fr, this message translates to:
  /// **'Apple Pay'**
  String get applePay;

  /// No description provided for @payerAvecGooglePay.
  ///
  /// In fr, this message translates to:
  /// **'Payer {p0} avec Google Pay'**
  String payerAvecGooglePay(Object p0);

  /// No description provided for @googlePay.
  ///
  /// In fr, this message translates to:
  /// **'Google Pay'**
  String get googlePay;

  /// No description provided for @taCarteEstApprovisionneeTa.
  ///
  /// In fr, this message translates to:
  /// **'Ta carte est approvisionnée ? Ta banque bloque peut-être le paiement en ligne : appelle-la.'**
  String get taCarteEstApprovisionneeTa;

  /// No description provided for @fraisDeRecharge.
  ///
  /// In fr, this message translates to:
  /// **'Frais de recharge'**
  String get fraisDeRecharge;

  /// No description provided for @debiteDeTonSoldeMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Débité de ton solde MatchUp · il te restera {p0}'**
  String debiteDeTonSoldeMatchup(Object p0);

  /// No description provided for @pointACorrigerAvantDe.
  ///
  /// In fr, this message translates to:
  /// **'{p0} point{p1} à corriger avant de payer'**
  String pointACorrigerAvantDe(Object p0, Object p1);

  /// No description provided for @taBanqueARefuseLe.
  ///
  /// In fr, this message translates to:
  /// **'Ta banque a refusé le paiement ({p0}). Rien n’a été débité.'**
  String taBanqueARefuseLe(Object p0);

  /// No description provided for @bonASavoir.
  ///
  /// In fr, this message translates to:
  /// **'Bon à savoir'**
  String get bonASavoir;

  /// No description provided for @jAccepteLes.
  ///
  /// In fr, this message translates to:
  /// **'J’accepte les '**
  String get jAccepteLes;

  /// No description provided for @etLaPolitiqueDAnnulation2.
  ///
  /// In fr, this message translates to:
  /// **' et la politique d’annulation {p0}.'**
  String etLaPolitiqueDAnnulation2(Object p0);

  /// No description provided for @paiement.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get paiement;

  /// No description provided for @retourAuRecapitulatif.
  ///
  /// In fr, this message translates to:
  /// **'Retour au récapitulatif'**
  String get retourAuRecapitulatif;

  /// No description provided for @securise.
  ///
  /// In fr, this message translates to:
  /// **'Sécurisé'**
  String get securise;

  /// No description provided for @payer.
  ///
  /// In fr, this message translates to:
  /// **'Payer'**
  String get payer;

  /// No description provided for @taCommande.
  ///
  /// In fr, this message translates to:
  /// **'Ta commande'**
  String get taCommande;

  /// No description provided for @masquerLeDetailDeLa.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le détail de la commande'**
  String get masquerLeDetailDeLa;

  /// No description provided for @voirLeDetailDeLa.
  ///
  /// In fr, this message translates to:
  /// **'Voir le détail de la commande'**
  String get voirLeDetailDeLa;

  /// No description provided for @masquerLeDetail.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le détail'**
  String get masquerLeDetail;

  /// No description provided for @voirLeDetail.
  ///
  /// In fr, this message translates to:
  /// **'Voir le détail'**
  String get voirLeDetail;

  /// No description provided for @retirer3.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get retirer3;

  /// No description provided for @taBanqueMetTropDe.
  ///
  /// In fr, this message translates to:
  /// **'Ta banque met trop de temps à répondre'**
  String get taBanqueMetTropDe;

  /// No description provided for @connexionPerduePendantLePaiement.
  ///
  /// In fr, this message translates to:
  /// **'Connexion perdue pendant le paiement'**
  String get connexionPerduePendantLePaiement;

  /// No description provided for @rienNAEteDebite3.
  ///
  /// In fr, this message translates to:
  /// **'Rien n’a été débité deux fois. Vérifie le statut avant de réessayer : on te dit tout de suite si ta part est passée.'**
  String get rienNAEteDebite3;

  /// No description provided for @taTentativeDePaiement.
  ///
  /// In fr, this message translates to:
  /// **'Ta tentative de paiement'**
  String get taTentativeDePaiement;

  /// No description provided for @montant.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get montant;

  /// No description provided for @tentative.
  ///
  /// In fr, this message translates to:
  /// **'Tentative'**
  String get tentative;

  /// No description provided for @statut.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get statut;

  /// No description provided for @aVerifier.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier'**
  String get aVerifier;

  /// No description provided for @ceQuiSePasseMaintenant.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui se passe maintenant'**
  String get ceQuiSePasseMaintenant;

  /// No description provided for @verifieLeStatut.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie le statut.'**
  String get verifieLeStatut;

  /// No description provided for @onDemandeAStripeSi.
  ///
  /// In fr, this message translates to:
  /// **'On demande à Stripe si ta part de {p0} est passée.'**
  String onDemandeAStripeSi(Object p0);

  /// No description provided for @siElleEstPassee.
  ///
  /// In fr, this message translates to:
  /// **'Si elle est passée,'**
  String get siElleEstPassee;

  /// No description provided for @tuRecoisTaConfirmationEt.
  ///
  /// In fr, this message translates to:
  /// **'tu reçois ta confirmation et ton QR code.'**
  String get tuRecoisTaConfirmationEt;

  /// No description provided for @sinonReessaie.
  ///
  /// In fr, this message translates to:
  /// **'Sinon, réessaie.'**
  String get sinonReessaie;

  /// No description provided for @unSeulPaiementSeraDebite.
  ///
  /// In fr, this message translates to:
  /// **'Un seul paiement sera débité, jamais deux.'**
  String get unSeulPaiementSeraDebite;

  /// No description provided for @taPlaceEstGardeeJusqu.
  ///
  /// In fr, this message translates to:
  /// **'Ta place est gardée jusqu’à '**
  String get taPlaceEstGardeeJusqu;

  /// No description provided for @verifierLeStatut.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier le statut'**
  String get verifierLeStatut;

  /// No description provided for @fermerEtVoirMaReservation.
  ///
  /// In fr, this message translates to:
  /// **'Fermer et voir ma réservation'**
  String get fermerEtVoirMaReservation;

  /// No description provided for @paiementReussi.
  ///
  /// In fr, this message translates to:
  /// **'Paiement réussi'**
  String get paiementReussi;

  /// No description provided for @taPartDeEstPayee2.
  ///
  /// In fr, this message translates to:
  /// **'Ta part de {p0} est payée. Reçu envoyé à {p1}.'**
  String taPartDeEstPayee2(Object p0, Object p1);

  /// No description provided for @recu.
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get recu;

  /// No description provided for @payeLe.
  ///
  /// In fr, this message translates to:
  /// **'Payé le'**
  String get payeLe;

  /// No description provided for @avec.
  ///
  /// In fr, this message translates to:
  /// **'Avec'**
  String get avec;

  /// No description provided for @pour.
  ///
  /// In fr, this message translates to:
  /// **'Pour'**
  String get pour;

  /// No description provided for @totalPaye.
  ///
  /// In fr, this message translates to:
  /// **'Total payé'**
  String get totalPaye;

  /// No description provided for @voirLeRecu.
  ///
  /// In fr, this message translates to:
  /// **'Voir le reçu'**
  String get voirLeRecu;

  /// No description provided for @taPartiePubliqueEstVisible.
  ///
  /// In fr, this message translates to:
  /// **'Ta partie publique est visible dans Explorer.'**
  String get taPartiePubliqueEstVisible;

  /// No description provided for @inviteTesAmisPourCompleter.
  ///
  /// In fr, this message translates to:
  /// **'Invite tes amis pour compléter l’équipe.'**
  String get inviteTesAmisPourCompleter;

  /// No description provided for @termine.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get termine;

  /// No description provided for @taReservationEstDansMes.
  ///
  /// In fr, this message translates to:
  /// **'Ta réservation est dans Mes matchs.'**
  String get taReservationEstDansMes;

  /// No description provided for @fermerEtRevenirAuRecapitulatif.
  ///
  /// In fr, this message translates to:
  /// **'Fermer et revenir au récapitulatif'**
  String get fermerEtRevenirAuRecapitulatif;

  /// No description provided for @lePaiementAEchoue.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement a échoué'**
  String get lePaiementAEchoue;

  /// No description provided for @apresEssaisTaBanqueRefuse.
  ///
  /// In fr, this message translates to:
  /// **'Après 3 essais, ta banque refuse toujours ta {p0} : {p1}. Rien n’a été débité.'**
  String apresEssaisTaBanqueRefuse(Object p0, Object p1);

  /// No description provided for @taPart5.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · ta part {p1}'**
  String taPart5(Object p0, Object p1);

  /// No description provided for @taPlaceEstGardeeMin.
  ///
  /// In fr, this message translates to:
  /// **'Ta place est gardée 15 min'**
  String get taPlaceEstGardeeMin;

  /// No description provided for @passeCeDelaiLaReservation.
  ///
  /// In fr, this message translates to:
  /// **'Passé ce délai, la réservation est annulée et tes 5 amis sont remboursés sur leur solde MatchUp.'**
  String get passeCeDelaiLaReservation;

  /// No description provided for @queFaire.
  ///
  /// In fr, this message translates to:
  /// **'Que faire ?'**
  String get queFaire;

  /// No description provided for @paieAvecTonSolde.
  ///
  /// In fr, this message translates to:
  /// **'Paie avec ton solde.'**
  String get paieAvecTonSolde;

  /// No description provided for @tesCouvrentTaPartSans.
  ///
  /// In fr, this message translates to:
  /// **'Tes {p0} couvrent ta part, sans passer par ta banque.'**
  String tesCouvrentTaPartSans(Object p0);

  /// No description provided for @essaieUneAutreCarte.
  ///
  /// In fr, this message translates to:
  /// **'Essaie une autre carte.'**
  String get essaieUneAutreCarte;

  /// No description provided for @taMastercardEstValableJusqu.
  ///
  /// In fr, this message translates to:
  /// **'Ta Mastercard •••• 5454 est valable jusqu’à fin novembre.'**
  String get taMastercardEstValableJusqu;

  /// No description provided for @appelleTaBanque.
  ///
  /// In fr, this message translates to:
  /// **'Appelle ta banque.'**
  String get appelleTaBanque;

  /// No description provided for @lePaiementEnLigneEst.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement en ligne est peut-être bloqué ou plafonné.'**
  String get lePaiementEnLigneEst;

  /// No description provided for @changerDeMoyenDePaiement.
  ///
  /// In fr, this message translates to:
  /// **'Changer de moyen de paiement'**
  String get changerDeMoyenDePaiement;

  /// No description provided for @rienNeSeraDebiteDeux.
  ///
  /// In fr, this message translates to:
  /// **'Rien ne sera débité deux fois.'**
  String get rienNeSeraDebiteDeux;

  /// No description provided for @partDeReservation2.
  ///
  /// In fr, this message translates to:
  /// **'Part de réservation {p0}'**
  String partDeReservation2(Object p0);

  /// No description provided for @gratuiteJusquAuPuisJusqu.
  ///
  /// In fr, this message translates to:
  /// **'Gratuite jusqu’au {p0}, puis 50 % jusqu’au {p1}. Remboursement sur le solde MatchUp.'**
  String gratuiteJusquAuPuisJusqu(Object p0, Object p1);

  /// No description provided for @laMarsaTunisie.
  ///
  /// In fr, this message translates to:
  /// **'La Marsa, Tunisie'**
  String get laMarsaTunisie;

  /// No description provided for @recu2.
  ///
  /// In fr, this message translates to:
  /// **'Reçu {p0}'**
  String recu2(Object p0);

  /// No description provided for @imprimerOuEnregistrer.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer ou enregistrer'**
  String get imprimerOuEnregistrer;

  /// No description provided for @organisateurAvanceLesPartsPour.
  ///
  /// In fr, this message translates to:
  /// **'Organisateur : avance les {p0} parts pour garantir le match. {p1} te remboursent via l’app.'**
  String organisateurAvanceLesPartsPour(Object p0, Object p1);

  /// No description provided for @payerLeReste.
  ///
  /// In fr, this message translates to:
  /// **'Payer le reste'**
  String get payerLeReste;

  /// No description provided for @tuAvances.
  ///
  /// In fr, this message translates to:
  /// **'Tu avances '**
  String get tuAvances;

  /// No description provided for @pourIlsPourrontTeRembourser.
  ///
  /// In fr, this message translates to:
  /// **' pour {p0}. Ils pourront te rembourser via l’app.'**
  String pourIlsPourrontTeRembourser(Object p0);

  /// No description provided for @detailDuMontant.
  ///
  /// In fr, this message translates to:
  /// **'Détail du montant'**
  String get detailDuMontant;

  /// No description provided for @partsDe.
  ///
  /// In fr, this message translates to:
  /// **'Parts de {p0}'**
  String partsDe(Object p0);

  /// No description provided for @payerAvec.
  ///
  /// In fr, this message translates to:
  /// **'Payer avec'**
  String get payerAvec;

  /// No description provided for @visa.
  ///
  /// In fr, this message translates to:
  /// **'Visa •••• 4242'**
  String get visa;

  /// No description provided for @parDefautExpire.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut · expire 08/27'**
  String get parDefautExpire;

  /// No description provided for @disponiblesIlTeRestera.
  ///
  /// In fr, this message translates to:
  /// **'{p0} disponibles · il te restera {p1}'**
  String disponiblesIlTeRestera(Object p0, Object p1);

  /// No description provided for @ilsRecoiventUneDemandeDe.
  ///
  /// In fr, this message translates to:
  /// **'Ils reçoivent une demande de {p0} chacun ; leur paiement arrive sur ton solde MatchUp.'**
  String ilsRecoiventUneDemandeDe(Object p0);

  /// No description provided for @payer2.
  ///
  /// In fr, this message translates to:
  /// **'Payer {p0}'**
  String payer2(Object p0);

  /// No description provided for @paiementSecuriseParStripe.
  ///
  /// In fr, this message translates to:
  /// **'Paiement sécurisé par Stripe'**
  String get paiementSecuriseParStripe;

  /// No description provided for @partsAvanceesReservation.
  ///
  /// In fr, this message translates to:
  /// **'Parts avancées · réservation {p0}'**
  String partsAvanceesReservation(Object p0);

  /// No description provided for @partsDe2.
  ///
  /// In fr, this message translates to:
  /// **'Parts de {p0} · {p1} × {p2}'**
  String partsDe2(Object p0, Object p1, Object p2);

  /// No description provided for @partsAvancees.
  ///
  /// In fr, this message translates to:
  /// **'Parts avancées · {p0}'**
  String partsAvancees(Object p0);

  /// No description provided for @paiementsDeLaPartie.
  ///
  /// In fr, this message translates to:
  /// **'Paiements de la partie'**
  String get paiementsDeLaPartie;

  /// No description provided for @retourAMaReservation.
  ///
  /// In fr, this message translates to:
  /// **'Retour à ma réservation'**
  String get retourAMaReservation;

  /// No description provided for @collecte.
  ///
  /// In fr, this message translates to:
  /// **'COLLECTÉ'**
  String get collecte;

  /// No description provided for @partsEnAttente.
  ///
  /// In fr, this message translates to:
  /// **'{p0} parts en attente'**
  String partsEnAttente(Object p0);

  /// No description provided for @toutEstPaye.
  ///
  /// In fr, this message translates to:
  /// **'Tout est payé'**
  String get toutEstPaye;

  /// No description provided for @avancementDesPaiements.
  ///
  /// In fr, this message translates to:
  /// **'Avancement des paiements'**
  String get avancementDesPaiements;

  /// No description provided for @partsPayees.
  ///
  /// In fr, this message translates to:
  /// **'{p0} parts payées'**
  String partsPayees(Object p0);

  /// No description provided for @enAttente2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} en attente'**
  String enAttente2(Object p0);

  /// No description provided for @placeLibre2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} place{p1} libre{p2}'**
  String placeLibre2(Object p0, Object p1, Object p2);

  /// No description provided for @toutDoitEtrePaye.
  ///
  /// In fr, this message translates to:
  /// **'Tout doit être payé'**
  String get toutDoitEtrePaye;

  /// No description provided for @hAvantLeMatch.
  ///
  /// In fr, this message translates to:
  /// **'3 h avant le match'**
  String get hAvantLeMatch;

  /// No description provided for @laReservationSeraAnnuleeSi.
  ///
  /// In fr, this message translates to:
  /// **'La réservation sera annulée si tout n’est pas payé 3 h avant le match. '**
  String get laReservationSeraAnnuleeSi;

  /// No description provided for @chacunSeraitAlorsRembourseSur.
  ///
  /// In fr, this message translates to:
  /// **'Chacun serait alors remboursé sur son solde MatchUp.'**
  String get chacunSeraitAlorsRembourseSur;

  /// No description provided for @aRecevoir.
  ///
  /// In fr, this message translates to:
  /// **' à recevoir'**
  String get aRecevoir;

  /// No description provided for @aPayer.
  ///
  /// In fr, this message translates to:
  /// **'{p0} à payer'**
  String aPayer(Object p0);

  /// No description provided for @relancee.
  ///
  /// In fr, this message translates to:
  /// **'Relancée'**
  String get relancee;

  /// No description provided for @relance.
  ///
  /// In fr, this message translates to:
  /// **'Relancé'**
  String get relance;

  /// No description provided for @relancer.
  ///
  /// In fr, this message translates to:
  /// **'Relancer'**
  String get relancer;

  /// No description provided for @rappelsEnvoyes.
  ///
  /// In fr, this message translates to:
  /// **'Rappels envoyés'**
  String get rappelsEnvoyes;

  /// No description provided for @relancerToutLeMonde.
  ///
  /// In fr, this message translates to:
  /// **'Relancer tout le monde'**
  String get relancerToutLeMonde;

  /// No description provided for @notificationEtEmailAvecLe.
  ///
  /// In fr, this message translates to:
  /// **'Notification et email avec le lien « Payer ma part · {p0} ».'**
  String notificationEtEmailAvecLe(Object p0);

  /// No description provided for @aRejointLaPartiePublique.
  ///
  /// In fr, this message translates to:
  /// **'A rejoint la partie publique'**
  String get aRejointLaPartiePublique;

  /// No description provided for @avanceeParToi.
  ///
  /// In fr, this message translates to:
  /// **'Avancée par toi'**
  String get avanceeParToi;

  /// No description provided for @placePublique.
  ///
  /// In fr, this message translates to:
  /// **'{p0} place{p1} publique{p2}'**
  String placePublique(Object p0, Object p1, Object p2);

  /// No description provided for @leJoueurQuiLaPrend.
  ///
  /// In fr, this message translates to:
  /// **'Le joueur qui la prend paie {p0} en rejoignant.'**
  String leJoueurQuiLaPrend(Object p0);

  /// No description provided for @modeTest.
  ///
  /// In fr, this message translates to:
  /// **'MODE TEST'**
  String get modeTest;

  /// No description provided for @carte2.
  ///
  /// In fr, this message translates to:
  /// **'  ·  carte '**
  String get carte2;

  /// No description provided for @expireLeMoisProchain.
  ///
  /// In fr, this message translates to:
  /// **'Expire le mois prochain ({p0})'**
  String expireLeMoisProchain(Object p0);

  /// No description provided for @expire.
  ///
  /// In fr, this message translates to:
  /// **'Expire {p0}'**
  String expire(Object p0);

  /// No description provided for @parDefaut.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut'**
  String get parDefaut;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @reduction.
  ///
  /// In fr, this message translates to:
  /// **'Réduction'**
  String get reduction;

  /// No description provided for @totalAPayer.
  ///
  /// In fr, this message translates to:
  /// **'Total à payer'**
  String get totalAPayer;

  /// No description provided for @politique.
  ///
  /// In fr, this message translates to:
  /// **'Politique {p0}'**
  String politique(Object p0);

  /// No description provided for @rembourseSurTonSoldeMatchup2.
  ///
  /// In fr, this message translates to:
  /// **'100 % remboursé sur ton solde MatchUp'**
  String get rembourseSurTonSoldeMatchup2;

  /// No description provided for @jusquAu.
  ///
  /// In fr, this message translates to:
  /// **'50 % jusqu’au {p0}'**
  String jusquAu(Object p0);

  /// No description provided for @entreHEtHAvant2.
  ///
  /// In fr, this message translates to:
  /// **'Entre 24 h et 6 h avant le match'**
  String get entreHEtHAvant2;

  /// No description provided for @nonRemboursableEnsuite.
  ///
  /// In fr, this message translates to:
  /// **'Non remboursable ensuite'**
  String get nonRemboursableEnsuite;

  /// No description provided for @saufSiAnnuleToutEst.
  ///
  /// In fr, this message translates to:
  /// **'Sauf si {p0} annule : tout est remboursé'**
  String saufSiAnnuleToutEst(Object p0);

  /// No description provided for @tunisie.
  ///
  /// In fr, this message translates to:
  /// **'Tunisie'**
  String get tunisie;

  /// No description provided for @france.
  ///
  /// In fr, this message translates to:
  /// **'France'**
  String get france;

  /// No description provided for @algerie.
  ///
  /// In fr, this message translates to:
  /// **'Algérie'**
  String get algerie;

  /// No description provided for @maroc.
  ///
  /// In fr, this message translates to:
  /// **'Maroc'**
  String get maroc;

  /// No description provided for @italie.
  ///
  /// In fr, this message translates to:
  /// **'Italie'**
  String get italie;

  /// No description provided for @nomSurLaCarte.
  ///
  /// In fr, this message translates to:
  /// **'Nom sur la carte'**
  String get nomSurLaCarte;

  /// No description provided for @telQuIlEstEcrit.
  ///
  /// In fr, this message translates to:
  /// **'Tel qu’il est écrit sur ta carte.'**
  String get telQuIlEstEcrit;

  /// No description provided for @cartesAcceptees.
  ///
  /// In fr, this message translates to:
  /// **'Cartes acceptées'**
  String get cartesAcceptees;

  /// No description provided for @visa2.
  ///
  /// In fr, this message translates to:
  /// **'VISA'**
  String get visa2;

  /// No description provided for @numeroDeCarte.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de carte'**
  String get numeroDeCarte;

  /// No description provided for @expiration.
  ///
  /// In fr, this message translates to:
  /// **'Expiration'**
  String get expiration;

  /// No description provided for @mmAa.
  ///
  /// In fr, this message translates to:
  /// **'MM / AA'**
  String get mmAa;

  /// No description provided for @cvc.
  ///
  /// In fr, this message translates to:
  /// **'CVC'**
  String get cvc;

  /// No description provided for @chiffresAuDos.
  ///
  /// In fr, this message translates to:
  /// **'3 chiffres au dos'**
  String get chiffresAuDos;

  /// No description provided for @pays.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get pays;

  /// No description provided for @zoneSecuriseeStripePaymentElement.
  ///
  /// In fr, this message translates to:
  /// **'Zone sécurisée Stripe · Payment Element'**
  String get zoneSecuriseeStripePaymentElement;

  /// No description provided for @paiementSecurise.
  ///
  /// In fr, this message translates to:
  /// **'Paiement sécurisé'**
  String get paiementSecurise;

  /// No description provided for @fenetreDeTaBanque.
  ///
  /// In fr, this message translates to:
  /// **'Fenêtre de ta banque'**
  String get fenetreDeTaBanque;

  /// No description provided for @taBanque.
  ///
  /// In fr, this message translates to:
  /// **'Ta banque'**
  String get taBanque;

  /// No description provided for @paiementEnLigneSecurise.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en ligne sécurisé'**
  String get paiementEnLigneSecurise;

  /// No description provided for @confirmeCePaiement.
  ///
  /// In fr, this message translates to:
  /// **'Confirme ce paiement'**
  String get confirmeCePaiement;

  /// No description provided for @marchand.
  ///
  /// In fr, this message translates to:
  /// **'Marchand'**
  String get marchand;

  /// No description provided for @matchup2.
  ///
  /// In fr, this message translates to:
  /// **'MATCHUP'**
  String get matchup2;

  /// No description provided for @tnd.
  ///
  /// In fr, this message translates to:
  /// **'{p0},000 TND'**
  String tnd(Object p0);

  /// No description provided for @codeEnvoyeParSmsAu.
  ///
  /// In fr, this message translates to:
  /// **'Code envoyé par SMS au {p0}'**
  String codeEnvoyeParSmsAu(Object p0);

  /// No description provided for @valider.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get valider;

  /// No description provided for @serviceClientDeTaBanque.
  ///
  /// In fr, this message translates to:
  /// **'Service client de ta banque · 24 h/24'**
  String get serviceClientDeTaBanque;

  /// No description provided for @neFermePasCettePage.
  ///
  /// In fr, this message translates to:
  /// **'Ne ferme pas cette page. Tu reviendras automatiquement sur MatchUp. Pour annuler, utilise « Annuler » dans la fenêtre de ta banque : rien ne sera débité.'**
  String get neFermePasCettePage;

  /// No description provided for @apresMidi2.
  ///
  /// In fr, this message translates to:
  /// **'après-midi'**
  String get apresMidi2;

  /// No description provided for @soir.
  ///
  /// In fr, this message translates to:
  /// **'Soir'**
  String get soir;

  /// No description provided for @tesDisponibilites.
  ///
  /// In fr, this message translates to:
  /// **'Tes disponibilités'**
  String get tesDisponibilites;

  /// No description provided for @quandEsTuDispo.
  ///
  /// In fr, this message translates to:
  /// **'Quand es-tu dispo ?'**
  String get quandEsTuDispo;

  /// No description provided for @toucheLesCreneauxOuTu.
  ///
  /// In fr, this message translates to:
  /// **'Touche les créneaux où tu peux jouer, on s’en sert pour te proposer des parties.'**
  String get toucheLesCreneauxOuTu;

  /// No description provided for @tesDisponibilitesDansLaSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Tes disponibilités dans la semaine'**
  String get tesDisponibilitesDansLaSemaine;

  /// No description provided for @dispo.
  ///
  /// In fr, this message translates to:
  /// **'Dispo'**
  String get dispo;

  /// No description provided for @pasDispo.
  ///
  /// In fr, this message translates to:
  /// **'Pas dispo'**
  String get pasDispo;

  /// No description provided for @creneau.
  ///
  /// In fr, this message translates to:
  /// **'1 créneau'**
  String get creneau;

  /// No description provided for @creneaux.
  ///
  /// In fr, this message translates to:
  /// **'{p0} créneaux'**
  String creneaux(Object p0);

  /// No description provided for @tonNiveau.
  ///
  /// In fr, this message translates to:
  /// **'Ton niveau'**
  String get tonNiveau;

  /// No description provided for @tonNiveau2.
  ///
  /// In fr, this message translates to:
  /// **'Ton niveau {p0}'**
  String tonNiveau2(Object p0);

  /// No description provided for @ajusterMonNiveau.
  ///
  /// In fr, this message translates to:
  /// **'Ajuster mon niveau'**
  String get ajusterMonNiveau;

  /// No description provided for @tuConnaisTonJeuMieux.
  ///
  /// In fr, this message translates to:
  /// **'Tu connais ton jeu mieux que personne : ton choix remplace l’estimation.'**
  String get tuConnaisTonJeuMieux;

  /// No description provided for @leNiveauSeMetA.
  ///
  /// In fr, this message translates to:
  /// **'Le niveau se met à jour automatiquement après tes matchs.'**
  String get leNiveauSeMetA;

  /// No description provided for @aEstimer.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · à estimer'**
  String aEstimer(Object p0);

  /// No description provided for @questionsMoinsDUneMinute.
  ///
  /// In fr, this message translates to:
  /// **'6 questions, moins d’une minute'**
  String get questionsMoinsDUneMinute;

  /// No description provided for @estimer.
  ///
  /// In fr, this message translates to:
  /// **'Estimer'**
  String get estimer;

  /// No description provided for @cEstBon.
  ///
  /// In fr, this message translates to:
  /// **'C’est bon'**
  String get cEstBon;

  /// No description provided for @elevee.
  ///
  /// In fr, this message translates to:
  /// **'élevée'**
  String get elevee;

  /// No description provided for @niveauChoisi.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {p0} choisi'**
  String niveauChoisi(Object p0);

  /// No description provided for @niveauEstime.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {p0} estimé'**
  String niveauEstime(Object p0);

  /// No description provided for @niveauEstime2.
  ///
  /// In fr, this message translates to:
  /// **'Niveau estimé'**
  String get niveauEstime2;

  /// No description provided for @sur.
  ///
  /// In fr, this message translates to:
  /// **'{p0} sur 7'**
  String sur(Object p0);

  /// No description provided for @surUneEchelleDeA.
  ///
  /// In fr, this message translates to:
  /// **'sur une échelle de 1,0 à 7,0'**
  String get surUneEchelleDeA;

  /// No description provided for @confiance.
  ///
  /// In fr, this message translates to:
  /// **'Confiance : {p0}'**
  String confiance(Object p0);

  /// No description provided for @sAffineApresMatchs.
  ///
  /// In fr, this message translates to:
  /// **' · s’affine après 3 matchs'**
  String get sAffineApresMatchs;

  /// No description provided for @pourquoiCeNiveau.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi ce niveau ?'**
  String get pourquoiCeNiveau;

  /// No description provided for @baseSurTesReponses.
  ///
  /// In fr, this message translates to:
  /// **'Basé sur tes réponses'**
  String get baseSurTesReponses;

  /// No description provided for @reglages.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get reglages;

  /// No description provided for @position.
  ///
  /// In fr, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @lorsqueLAppEstActive.
  ///
  /// In fr, this message translates to:
  /// **'« Lorsque l’app est active »'**
  String get lorsqueLAppEstActive;

  /// No description provided for @localisation.
  ///
  /// In fr, this message translates to:
  /// **'Localisation'**
  String get localisation;

  /// No description provided for @localisationDesactivee.
  ///
  /// In fr, this message translates to:
  /// **'Localisation désactivée'**
  String get localisationDesactivee;

  /// No description provided for @choisisTesZonesALa.
  ///
  /// In fr, this message translates to:
  /// **'Choisis tes zones à la main, ou active ta position dans Réglages.'**
  String get choisisTesZonesALa;

  /// No description provided for @pourLActiver.
  ///
  /// In fr, this message translates to:
  /// **'Pour l’activer'**
  String get pourLActiver;

  /// No description provided for @ouvrirReglages.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir Réglages'**
  String get ouvrirReglages;

  /// No description provided for @choisisTesZonesDeJeu.
  ///
  /// In fr, this message translates to:
  /// **'Choisis tes zones de jeu'**
  String get choisisTesZonesDeJeu;

  /// No description provided for @onTeProposeraDesParties.
  ///
  /// In fr, this message translates to:
  /// **'On te proposera des parties dans ces quartiers.'**
  String get onTeProposeraDesParties;

  /// No description provided for @zonesProposees.
  ///
  /// In fr, this message translates to:
  /// **'Zones proposées'**
  String get zonesProposees;

  /// No description provided for @continuerAvecMesZones.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec mes zones'**
  String get continuerAvecMesZones;

  /// No description provided for @smashPadelClub.
  ///
  /// In fr, this message translates to:
  /// **'Smash Padel Club'**
  String get smashPadelClub;

  /// No description provided for @lac.
  ///
  /// In fr, this message translates to:
  /// **'Lac 2'**
  String get lac;

  /// No description provided for @padelHouseCarthage.
  ///
  /// In fr, this message translates to:
  /// **'Padel House Carthage'**
  String get padelHouseCarthage;

  /// No description provided for @carthage.
  ///
  /// In fr, this message translates to:
  /// **'Carthage'**
  String get carthage;

  /// No description provided for @gammarthFive.
  ///
  /// In fr, this message translates to:
  /// **'Gammarth Five'**
  String get gammarthFive;

  /// No description provided for @gammarth.
  ///
  /// In fr, this message translates to:
  /// **'Gammarth'**
  String get gammarth;

  /// No description provided for @urbanCourt.
  ///
  /// In fr, this message translates to:
  /// **'Urban Court'**
  String get urbanCourt;

  /// No description provided for @routeLaMarsa.
  ///
  /// In fr, this message translates to:
  /// **'Route La Marsa'**
  String get routeLaMarsa;

  /// No description provided for @terrainsAutourDeLaMarsa.
  ///
  /// In fr, this message translates to:
  /// **'Terrains autour de La Marsa'**
  String get terrainsAutourDeLaMarsa;

  /// No description provided for @km4.
  ///
  /// In fr, this message translates to:
  /// **'5 km'**
  String get km4;

  /// No description provided for @jouePresDeChezToi.
  ///
  /// In fr, this message translates to:
  /// **'Joue près de chez toi'**
  String get jouePresDeChezToi;

  /// No description provided for @activeTaPositionPourVoir.
  ///
  /// In fr, this message translates to:
  /// **'Active ta position pour voir ce qui se passe autour de toi.'**
  String get activeTaPositionPourVoir;

  /// No description provided for @desPartiesAMoinsDe.
  ///
  /// In fr, this message translates to:
  /// **'Des parties à moins de 5 km'**
  String get desPartiesAMoinsDe;

  /// No description provided for @trieesParDistanceATon.
  ///
  /// In fr, this message translates to:
  /// **'Triées par distance, à ton niveau.'**
  String get trieesParDistanceATon;

  /// No description provided for @lItineraireJusquAuTerrain.
  ///
  /// In fr, this message translates to:
  /// **'L’itinéraire jusqu’au terrain'**
  String get lItineraireJusquAuTerrain;

  /// No description provided for @avecLeTempsDeTrajet.
  ///
  /// In fr, this message translates to:
  /// **'Avec le temps de trajet avant chaque match.'**
  String get avecLeTempsDeTrajet;

  /// No description provided for @lesTerrainsAutourDeToi.
  ///
  /// In fr, this message translates to:
  /// **'Les terrains autour de toi'**
  String get lesTerrainsAutourDeToi;

  /// No description provided for @creneauxLibresEtPrixPar.
  ///
  /// In fr, this message translates to:
  /// **'Créneaux libres et prix par personne.'**
  String get creneauxLibresEtPrixPar;

  /// No description provided for @tonTelephoneVaTeDemander.
  ///
  /// In fr, this message translates to:
  /// **'Ton téléphone va te demander l’autorisation juste après. Tu peux la retirer à tout moment dans les réglages.'**
  String get tonTelephoneVaTeDemander;

  /// No description provided for @activerLaLocalisation.
  ///
  /// In fr, this message translates to:
  /// **'Activer la localisation'**
  String get activerLaLocalisation;

  /// No description provided for @choisirMesZonesALa.
  ///
  /// In fr, this message translates to:
  /// **'Choisir mes zones à la main'**
  String get choisirMesZonesALa;

  /// No description provided for @exemplesDeNotificationsMatchupUne.
  ///
  /// In fr, this message translates to:
  /// **'Exemples de notifications MatchUp : une place libérée, une invitation de Mariem K., un rappel de match'**
  String get exemplesDeNotificationsMatchupUne;

  /// No description provided for @unePlaceSEstLiberee.
  ///
  /// In fr, this message translates to:
  /// **'Une place s’est libérée'**
  String get unePlaceSEstLiberee;

  /// No description provided for @padelCeSoirASmash.
  ///
  /// In fr, this message translates to:
  /// **'Padel ce soir à Smash Padel Club. Tu as 14:59 pour la réclamer.'**
  String get padelCeSoirASmash;

  /// No description provided for @mariemK.
  ///
  /// In fr, this message translates to:
  /// **'Mariem K.'**
  String get mariemK;

  /// No description provided for @mariemKTInviteA.
  ///
  /// In fr, this message translates to:
  /// **'Mariem K. t’invite à jouer'**
  String get mariemKTInviteA;

  /// No description provided for @padelVsDimOct18h30.
  ///
  /// In fr, this message translates to:
  /// **'Padel 2 vs 2 · dim. 19 oct. · 18h30 · 15 DT par personne.'**
  String get padelVsDimOct18h30;

  /// No description provided for @min2.
  ///
  /// In fr, this message translates to:
  /// **'12 min'**
  String get min2;

  /// No description provided for @rappelMatchCeSoir20h00.
  ///
  /// In fr, this message translates to:
  /// **'Rappel : match ce soir 20h00'**
  String get rappelMatchCeSoir20h00;

  /// No description provided for @arenaFiveTerrainLaMarsa.
  ///
  /// In fr, this message translates to:
  /// **'Arena Five · Terrain 2 · La Marsa. Pars vers 19h35.'**
  String get arenaFiveTerrainLaMarsa;

  /// No description provided for @neRateAucunePartie.
  ///
  /// In fr, this message translates to:
  /// **'Ne rate aucune partie'**
  String get neRateAucunePartie;

  /// No description provided for @placesLibereesInvitationsRappelsOn.
  ///
  /// In fr, this message translates to:
  /// **'Places libérées, invitations, rappels : on te prévient seulement pour ce qui compte. Tu règles tout dans Paramètres.'**
  String get placesLibereesInvitationsRappelsOn;

  /// No description provided for @tonTelephoneVaTeDemander2.
  ///
  /// In fr, this message translates to:
  /// **'Ton téléphone va te demander l’autorisation juste après.'**
  String get tonTelephoneVaTeDemander2;

  /// No description provided for @activerLesNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Activer les notifications'**
  String get activerLesNotifications;

  /// No description provided for @lePosteOuTuJoues.
  ///
  /// In fr, this message translates to:
  /// **'Le poste où tu joues le plus souvent'**
  String get lePosteOuTuJoues;

  /// No description provided for @leCoteOuTuRecois.
  ///
  /// In fr, this message translates to:
  /// **'Le côté où tu reçois le service'**
  String get leCoteOuTuRecois;

  /// No description provided for @leRoleQueTuPrends.
  ///
  /// In fr, this message translates to:
  /// **'Le rôle que tu prends le plus souvent'**
  String get leRoleQueTuPrends;

  /// No description provided for @posteAuFootball.
  ///
  /// In fr, this message translates to:
  /// **'Poste au football'**
  String get posteAuFootball;

  /// No description provided for @coteAuPadel.
  ///
  /// In fr, this message translates to:
  /// **'Côté au padel'**
  String get coteAuPadel;

  /// No description provided for @roleAuBasket.
  ///
  /// In fr, this message translates to:
  /// **'Rôle au basket'**
  String get roleAuBasket;

  /// No description provided for @gardienTuTiensLaCage.
  ///
  /// In fr, this message translates to:
  /// **'Gardien : tu tiens la cage et tu relances le jeu.'**
  String get gardienTuTiensLaCage;

  /// No description provided for @defenseurTuCouvresLArriere.
  ///
  /// In fr, this message translates to:
  /// **'Défenseur : tu couvres l’arrière et tu bloques les contres.'**
  String get defenseurTuCouvresLArriere;

  /// No description provided for @milieuTuFaisLeLien.
  ///
  /// In fr, this message translates to:
  /// **'Milieu : tu fais le lien entre la défense et l’attaque.'**
  String get milieuTuFaisLeLien;

  /// No description provided for @attaquantTuJouesHautEt.
  ///
  /// In fr, this message translates to:
  /// **'Attaquant : tu joues haut et tu finis les actions.'**
  String get attaquantTuJouesHautEt;

  /// No description provided for @coteDroit.
  ///
  /// In fr, this message translates to:
  /// **'Côté droit'**
  String get coteDroit;

  /// No description provided for @coteDroitCoupDroitAu.
  ///
  /// In fr, this message translates to:
  /// **'Côté droit : coup droit au centre, tu construis le point.'**
  String get coteDroitCoupDroitAu;

  /// No description provided for @coteGauche.
  ///
  /// In fr, this message translates to:
  /// **'Côté gauche'**
  String get coteGauche;

  /// No description provided for @coteGaucheReversCoteVitre.
  ///
  /// In fr, this message translates to:
  /// **'Côté gauche : revers côté vitre, souvent celui qui finit au smash.'**
  String get coteGaucheReversCoteVitre;

  /// No description provided for @lesDeux.
  ///
  /// In fr, this message translates to:
  /// **'Les deux'**
  String get lesDeux;

  /// No description provided for @lesDeuxTuTAdaptes.
  ///
  /// In fr, this message translates to:
  /// **'Les deux : tu t’adaptes au côté de ton partenaire.'**
  String get lesDeuxTuTAdaptes;

  /// No description provided for @meneur.
  ///
  /// In fr, this message translates to:
  /// **'Meneur'**
  String get meneur;

  /// No description provided for @meneurTuMontesLaBalle.
  ///
  /// In fr, this message translates to:
  /// **'Meneur : tu montes la balle et tu lances le jeu.'**
  String get meneurTuMontesLaBalle;

  /// No description provided for @ailier.
  ///
  /// In fr, this message translates to:
  /// **'Ailier'**
  String get ailier;

  /// No description provided for @ailierTuAttaquesLeCercle.
  ///
  /// In fr, this message translates to:
  /// **'Ailier : tu attaques le cercle et tu tires de loin.'**
  String get ailierTuAttaquesLeCercle;

  /// No description provided for @interieurTuPrendsLesRebonds.
  ///
  /// In fr, this message translates to:
  /// **'Intérieur : tu prends les rebonds et tu joues près du panier.'**
  String get interieurTuPrendsLesRebonds;

  /// No description provided for @polyvalent.
  ///
  /// In fr, this message translates to:
  /// **'Polyvalent'**
  String get polyvalent;

  /// No description provided for @polyvalentTuTAdaptesA.
  ///
  /// In fr, this message translates to:
  /// **'Polyvalent : tu t’adaptes à ce dont l’équipe a besoin.'**
  String get polyvalentTuTAdaptesA;

  /// No description provided for @tonPoste.
  ///
  /// In fr, this message translates to:
  /// **'Ton poste'**
  String get tonPoste;

  /// No description provided for @ouPreferesTuJouer.
  ///
  /// In fr, this message translates to:
  /// **'Où préfères-tu jouer ?'**
  String get ouPreferesTuJouer;

  /// No description provided for @onSEnSertPour.
  ///
  /// In fr, this message translates to:
  /// **'On s’en sert pour équilibrer les équipes. Tu pourras en changer depuis ton profil.'**
  String get onSEnSertPour;

  /// No description provided for @impossibleDOuvrirTesPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’ouvrir tes photos'**
  String get impossibleDOuvrirTesPhotos;

  /// No description provided for @verifieLAccesAuxPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie l’accès aux photos dans les réglages.'**
  String get verifieLAccesAuxPhotos;

  /// No description provided for @tonProfil.
  ///
  /// In fr, this message translates to:
  /// **'Ton profil'**
  String get tonProfil;

  /// No description provided for @montreToi.
  ///
  /// In fr, this message translates to:
  /// **'Montre-toi'**
  String get montreToi;

  /// No description provided for @unePhotoEtUnPseudo.
  ///
  /// In fr, this message translates to:
  /// **'Une photo et un pseudo, pour que les joueurs te reconnaissent sur le terrain.'**
  String get unePhotoEtUnPseudo;

  /// No description provided for @prendreOuChoisirUnePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre ou choisir une photo'**
  String get prendreOuChoisirUnePhoto;

  /// No description provided for @ajouterUnePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get ajouterUnePhoto;

  /// No description provided for @changerDePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer de photo'**
  String get changerDePhoto;

  /// No description provided for @pseudo.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo'**
  String get pseudo;

  /// No description provided for @prenomEtNom.
  ///
  /// In fr, this message translates to:
  /// **'Prénom et nom'**
  String get prenomEtNom;

  /// No description provided for @exYassineBelhadj.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Yassine Belhadj'**
  String get exYassineBelhadj;

  /// No description provided for @lesAutresJoueursVoientTon.
  ///
  /// In fr, this message translates to:
  /// **'Les autres joueurs voient ton prénom et l’initiale de ton nom, jamais ton nom complet.'**
  String get lesAutresJoueursVoientTon;

  /// No description provided for @lesAutresJoueursVoientJamais.
  ///
  /// In fr, this message translates to:
  /// **'Les autres joueurs voient « {p0} », jamais ton nom complet.'**
  String lesAutresJoueursVoientJamais(Object p0);

  /// No description provided for @terminer.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get terminer;

  /// No description provided for @questionPrecedente.
  ///
  /// In fr, this message translates to:
  /// **'Question précédente'**
  String get questionPrecedente;

  /// No description provided for @questionSur.
  ///
  /// In fr, this message translates to:
  /// **'Question {p0} sur {p1}'**
  String questionSur(Object p0, Object p1);

  /// No description provided for @questionsRapidesPourTeProposer.
  ///
  /// In fr, this message translates to:
  /// **'6 questions rapides pour te proposer des parties équilibrées.'**
  String get questionsRapidesPourTeProposer;

  /// No description provided for @voirMonNiveau.
  ///
  /// In fr, this message translates to:
  /// **'Voir mon niveau'**
  String get voirMonNiveau;

  /// No description provided for @tesSports.
  ///
  /// In fr, this message translates to:
  /// **'Tes sports'**
  String get tesSports;

  /// No description provided for @quelsSportsTuJoues.
  ///
  /// In fr, this message translates to:
  /// **'Quels sports tu joues ?'**
  String get quelsSportsTuJoues;

  /// No description provided for @choisisEnUnOuPlusieurs.
  ///
  /// In fr, this message translates to:
  /// **'Choisis-en un ou plusieurs. On te proposera des parties et des joueurs à ton niveau.'**
  String get choisisEnUnOuPlusieurs;

  /// No description provided for @taProgressionEstEnregistreeTu.
  ///
  /// In fr, this message translates to:
  /// **'Ta progression est enregistrée, tu peux reprendre plus tard.'**
  String get taProgressionEstEnregistreeTu;

  /// No description provided for @tesZonesDeJeu.
  ///
  /// In fr, this message translates to:
  /// **'Tes zones de jeu'**
  String get tesZonesDeJeu;

  /// No description provided for @ajouteLesQuartiersOuTu.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute les quartiers où tu joues souvent, même loin de chez toi.'**
  String get ajouteLesQuartiersOuTu;

  /// No description provided for @positionActivee.
  ///
  /// In fr, this message translates to:
  /// **'Position activée'**
  String get positionActivee;

  /// No description provided for @tesZones.
  ///
  /// In fr, this message translates to:
  /// **'Tes zones'**
  String get tesZones;

  /// No description provided for @zone.
  ///
  /// In fr, this message translates to:
  /// **'1 zone'**
  String get zone;

  /// No description provided for @suggestionsAutourDeToi.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions autour de toi'**
  String get suggestionsAutourDeToi;

  /// No description provided for @distanceMaximale.
  ///
  /// In fr, this message translates to:
  /// **'Distance maximale'**
  String get distanceMaximale;

  /// No description provided for @jusquAKm2.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu’à {p0} km'**
  String jusquAKm2(Object p0);

  /// No description provided for @ajouterUneZone.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une zone'**
  String get ajouterUneZone;

  /// No description provided for @ajouterUneZoneQuartierVille.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une zone : quartier, ville…'**
  String get ajouterUneZoneQuartierVille;

  /// No description provided for @aucuneZoneTrouveePourEssaie.
  ///
  /// In fr, this message translates to:
  /// **'Aucune zone trouvée pour « {p0} ». Essaie un quartier ou une ville.'**
  String aucuneZoneTrouveePourEssaie(Object p0);

  /// No description provided for @peuImporte.
  ///
  /// In fr, this message translates to:
  /// **'Peu importe'**
  String get peuImporte;

  /// No description provided for @profilEnregistre.
  ///
  /// In fr, this message translates to:
  /// **'Profil enregistré'**
  String get profilEnregistre;

  /// No description provided for @modifierLeProfil.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get modifierLeProfil;

  /// No description provided for @retourAuProfilSansEnregistrer.
  ///
  /// In fr, this message translates to:
  /// **'Retour au profil sans enregistrer'**
  String get retourAuProfilSansEnregistrer;

  /// No description provided for @photoEtCouverture.
  ///
  /// In fr, this message translates to:
  /// **'Photo et couverture'**
  String get photoEtCouverture;

  /// No description provided for @couverture.
  ///
  /// In fr, this message translates to:
  /// **'Couverture'**
  String get couverture;

  /// No description provided for @couvertureActuelle.
  ///
  /// In fr, this message translates to:
  /// **'Couverture actuelle'**
  String get couvertureActuelle;

  /// No description provided for @changer.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get changer;

  /// No description provided for @tonTerrainPrefereOuUne.
  ///
  /// In fr, this message translates to:
  /// **'Ton terrain préféré, ou une des 6 couvertures MatchUp.'**
  String get tonTerrainPrefereOuUne;

  /// No description provided for @jpgPngMoMaxVisage.
  ///
  /// In fr, this message translates to:
  /// **'JPG, PNG · 10 Mo max · visage bien visible'**
  String get jpgPngMoMaxVisage;

  /// No description provided for @infos.
  ///
  /// In fr, this message translates to:
  /// **'Infos'**
  String get infos;

  /// No description provided for @tonLienDeProfilMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Ton lien de profil : matchup.tn/@{p0}'**
  String tonLienDeProfilMatchup(Object p0);

  /// No description provided for @sportsEtPostes.
  ///
  /// In fr, this message translates to:
  /// **'Sports et postes'**
  String get sportsEtPostes;

  /// No description provided for @lesOrganisateursCherchentSouventUn.
  ///
  /// In fr, this message translates to:
  /// **'Les organisateurs cherchent souvent un poste précis.'**
  String get lesOrganisateursCherchentSouventUn;

  /// No description provided for @padelTonCote.
  ///
  /// In fr, this message translates to:
  /// **'Padel · ton côté'**
  String get padelTonCote;

  /// No description provided for @footballTonPoste.
  ///
  /// In fr, this message translates to:
  /// **'Football · ton poste'**
  String get footballTonPoste;

  /// No description provided for @tonNiveauNEstPas.
  ///
  /// In fr, this message translates to:
  /// **'Ton niveau n’est pas un champ : l’IA l’estime après tes matchs. '**
  String get tonNiveauNEstPas;

  /// No description provided for @voirOuAjuster.
  ///
  /// In fr, this message translates to:
  /// **'Voir ou ajuster'**
  String get voirOuAjuster;

  /// No description provided for @ouTuJoues.
  ///
  /// In fr, this message translates to:
  /// **'Où tu joues'**
  String get ouTuJoues;

  /// No description provided for @onTeProposeDesParties.
  ///
  /// In fr, this message translates to:
  /// **'On te propose des parties dans ces zones en priorité.'**
  String get onTeProposeDesParties;

  /// No description provided for @visibilite.
  ///
  /// In fr, this message translates to:
  /// **'Visibilité'**
  String get visibilite;

  /// No description provided for @quiPeutVoirTonProfil.
  ///
  /// In fr, this message translates to:
  /// **'Qui peut voir ton profil ?'**
  String get quiPeutVoirTonProfil;

  /// No description provided for @visibleDansExplorerEtDans.
  ///
  /// In fr, this message translates to:
  /// **'Visible dans Explorer et dans les parties.'**
  String get visibleDansExplorerEtDans;

  /// No description provided for @lesAutresVoientTonPseudo.
  ///
  /// In fr, this message translates to:
  /// **'Les autres voient ton pseudo et ta photo.'**
  String get lesAutresVoientTonPseudo;

  /// No description provided for @afficherMonNiveau.
  ///
  /// In fr, this message translates to:
  /// **'Afficher mon niveau'**
  String get afficherMonNiveau;

  /// No description provided for @pourEtreInviteAuBon.
  ///
  /// In fr, this message translates to:
  /// **'Pour être invité au bon niveau.'**
  String get pourEtreInviteAuBon;

  /// No description provided for @afficherMaFiabilite.
  ///
  /// In fr, this message translates to:
  /// **'Afficher ma fiabilité'**
  String get afficherMaFiabilite;

  /// No description provided for @rassureLesOrganisateursDeParties.
  ///
  /// In fr, this message translates to:
  /// **'Rassure les organisateurs de parties.'**
  String get rassureLesOrganisateursDeParties;

  /// No description provided for @meProposerCommePartenaire.
  ///
  /// In fr, this message translates to:
  /// **'Me proposer comme partenaire'**
  String get meProposerCommePartenaire;

  /// No description provided for @suggereParLIaAux.
  ///
  /// In fr, this message translates to:
  /// **'Suggéré par l’IA aux joueurs de ton niveau.'**
  String get suggereParLIaAux;

  /// No description provided for @plusDeReglagesDeConfidentialite.
  ///
  /// In fr, this message translates to:
  /// **'Plus de réglages de confidentialité'**
  String get plusDeReglagesDeConfidentialite;

  /// No description provided for @profilIndisponible.
  ///
  /// In fr, this message translates to:
  /// **'Profil indisponible'**
  String get profilIndisponible;

  /// No description provided for @chargementDuProfil.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du profil'**
  String get chargementDuProfil;

  /// No description provided for @partagerMonProfil.
  ///
  /// In fr, this message translates to:
  /// **'Partager mon profil'**
  String get partagerMonProfil;

  /// No description provided for @monProfilMatchupHttpsMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil MatchUp : https://matchup.tn/@{p0}'**
  String monProfilMatchupHttpsMatchup(Object p0);

  /// No description provided for @mesNiveaux.
  ///
  /// In fr, this message translates to:
  /// **'Mes niveaux'**
  String get mesNiveaux;

  /// No description provided for @estimesParLIaApres.
  ///
  /// In fr, this message translates to:
  /// **'Estimés par l’IA après chaque match. Tu peux les ajuster ou les contester.'**
  String get estimesParLIaApres;

  /// No description provided for @fiabilite.
  ///
  /// In fr, this message translates to:
  /// **'Fiabilité'**
  String get fiabilite;

  /// No description provided for @badges.
  ///
  /// In fr, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @voirLes.
  ///
  /// In fr, this message translates to:
  /// **'Voir les {p0}'**
  String voirLes(Object p0);

  /// No description provided for @derniersMatchs.
  ///
  /// In fr, this message translates to:
  /// **'Derniers matchs'**
  String get derniersMatchs;

  /// No description provided for @avisDesCoequipiers.
  ///
  /// In fr, this message translates to:
  /// **'Avis des coéquipiers'**
  String get avisDesCoequipiers;

  /// No description provided for @profilIntrouvable.
  ///
  /// In fr, this message translates to:
  /// **'Profil introuvable'**
  String get profilIntrouvable;

  /// No description provided for @inviterAUnePartie.
  ///
  /// In fr, this message translates to:
  /// **'Inviter à une partie'**
  String get inviterAUnePartie;

  /// No description provided for @tuNeSuisPlus.
  ///
  /// In fr, this message translates to:
  /// **'Tu ne suis plus {p0}'**
  String tuNeSuisPlus(Object p0);

  /// No description provided for @tuSuis.
  ///
  /// In fr, this message translates to:
  /// **'Tu suis {p0}'**
  String tuSuis(Object p0);

  /// No description provided for @partagerLeProfil.
  ///
  /// In fr, this message translates to:
  /// **'Partager le profil'**
  String get partagerLeProfil;

  /// No description provided for @actionsSurLeProfilDe.
  ///
  /// In fr, this message translates to:
  /// **'Actions sur le profil de {p0}'**
  String actionsSurLeProfilDe(Object p0);

  /// No description provided for @bloquer.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer {p0}'**
  String bloquer(Object p0);

  /// No description provided for @signalerCeProfil.
  ///
  /// In fr, this message translates to:
  /// **'Signaler ce profil'**
  String get signalerCeProfil;

  /// No description provided for @suivi.
  ///
  /// In fr, this message translates to:
  /// **'Suivi'**
  String get suivi;

  /// No description provided for @suivre.
  ///
  /// In fr, this message translates to:
  /// **'Suivre'**
  String get suivre;

  /// No description provided for @sesPartiesTeCorrespondent.
  ///
  /// In fr, this message translates to:
  /// **'Ses parties te correspondent'**
  String get sesPartiesTeCorrespondent;

  /// No description provided for @voirSaProchainePartiePlaces.
  ///
  /// In fr, this message translates to:
  /// **'Voir sa prochaine partie : {p0}, {p1}, {p2} places, {p3} par personne'**
  String voirSaProchainePartiePlaces(
    Object p0,
    Object p1,
    Object p2,
    Object p3,
  );

  /// No description provided for @ilOrganise.
  ///
  /// In fr, this message translates to:
  /// **'Il organise · '**
  String get ilOrganise;

  /// No description provided for @places2.
  ///
  /// In fr, this message translates to:
  /// **' places · '**
  String get places2;

  /// No description provided for @niveaux.
  ///
  /// In fr, this message translates to:
  /// **'Niveaux'**
  String get niveaux;

  /// No description provided for @monCompte.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get monCompte;

  /// No description provided for @monProfil2.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil, {p0}'**
  String monProfil2(Object p0);

  /// No description provided for @portefeuille.
  ///
  /// In fr, this message translates to:
  /// **'Portefeuille'**
  String get portefeuille;

  /// No description provided for @remboursementsEtPartsPayees.
  ///
  /// In fr, this message translates to:
  /// **'Remboursements et parts payées'**
  String get remboursementsEtPartsPayees;

  /// No description provided for @portefeuilleSolde.
  ///
  /// In fr, this message translates to:
  /// **'Portefeuille, solde {p0}'**
  String portefeuilleSolde(Object p0);

  /// No description provided for @matchupPremium.
  ///
  /// In fr, this message translates to:
  /// **'MatchUp Premium'**
  String get matchupPremium;

  /// No description provided for @essaiGratuitEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Essai gratuit en cours'**
  String get essaiGratuitEnCours;

  /// No description provided for @resilieActifJusquAuOct.
  ///
  /// In fr, this message translates to:
  /// **'Résilié · actif jusqu’au 30 oct.'**
  String get resilieActifJusquAuOct;

  /// No description provided for @joursGratuitsSansEngagement.
  ///
  /// In fr, this message translates to:
  /// **'14 jours gratuits, sans engagement'**
  String get joursGratuitsSansEngagement;

  /// No description provided for @joueurProprietaireDeTerrainA.
  ///
  /// In fr, this message translates to:
  /// **'Joueur · Propriétaire de terrain à terminer'**
  String get joueurProprietaireDeTerrainA;

  /// No description provided for @uneConfigurationATerminer.
  ///
  /// In fr, this message translates to:
  /// **'Une configuration à terminer'**
  String get uneConfigurationATerminer;

  /// No description provided for @aide.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get aide;

  /// No description provided for @padel2.
  ///
  /// In fr, this message translates to:
  /// **'Padel {p0} · {p1}'**
  String padel2(Object p0, Object p1);

  /// No description provided for @configurationATerminerEtapes.
  ///
  /// In fr, this message translates to:
  /// **'Configuration à terminer · 3 étapes'**
  String get configurationATerminerEtapes;

  /// No description provided for @passerEnProprietaireDeTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Passer en Propriétaire de terrain et terminer la configuration'**
  String get passerEnProprietaireDeTerrain;

  /// No description provided for @couvertureDuProfil.
  ///
  /// In fr, this message translates to:
  /// **'Couverture du profil'**
  String get couvertureDuProfil;

  /// No description provided for @abonnes.
  ///
  /// In fr, this message translates to:
  /// **' abonnés    '**
  String get abonnes;

  /// No description provided for @statistiquesDepuisDeVictoiresMatchs.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques : depuis {p0}, {p1} % de victoires, {p2} matchs, {p3} victoires, {p4} tournois'**
  String statistiquesDepuisDeVictoiresMatchs(
    Object p0,
    Object p1,
    Object p2,
    Object p3,
    Object p4,
  );

  /// No description provided for @depuis.
  ///
  /// In fr, this message translates to:
  /// **'DEPUIS {p0}'**
  String depuis(Object p0);

  /// No description provided for @deVictoires.
  ///
  /// In fr, this message translates to:
  /// **'{p0} % de victoires'**
  String deVictoires(Object p0);

  /// No description provided for @matchs.
  ///
  /// In fr, this message translates to:
  /// **'Matchs'**
  String get matchs;

  /// No description provided for @victoires.
  ///
  /// In fr, this message translates to:
  /// **'Victoires'**
  String get victoires;

  /// No description provided for @matchs2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} matchs · {p1}'**
  String matchs2(Object p0, Object p1);

  /// No description provided for @niveau4.
  ///
  /// In fr, this message translates to:
  /// **'NIVEAU {p0}'**
  String niveau4(Object p0);

  /// No description provided for @surJours2.
  ///
  /// In fr, this message translates to:
  /// **'sur 30 jours'**
  String get surJours2;

  /// No description provided for @derniersMatchs2.
  ///
  /// In fr, this message translates to:
  /// **'10 derniers matchs'**
  String get derniersMatchs2;

  /// No description provided for @niveauSurLesDerniersMatchs.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {p0} sur les 10 derniers matchs : de {p1} à {p2}'**
  String niveauSurLesDerniersMatchs(Object p0, Object p1, Object p2);

  /// No description provided for @ecart.
  ///
  /// In fr, this message translates to:
  /// **' · écart '**
  String get ecart;

  /// No description provided for @derniersMois.
  ///
  /// In fr, this message translates to:
  /// **'12 derniers mois'**
  String get derniersMois;

  /// No description provided for @matchsHonores.
  ///
  /// In fr, this message translates to:
  /// **' matchs honorés'**
  String get matchsHonores;

  /// No description provided for @badge.
  ///
  /// In fr, this message translates to:
  /// **'Badge {p0} : {p1}{p2}'**
  String badge(Object p0, Object p1, Object p2);

  /// No description provided for @avis2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} avis · {p1}'**
  String avis2(Object p0, Object p1);

  /// No description provided for @pourquoiEn.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi {p0} en {p1} ?'**
  String pourquoiEn(Object p0, Object p1);

  /// No description provided for @jAiCompris.
  ///
  /// In fr, this message translates to:
  /// **'J’ai compris'**
  String get jAiCompris;

  /// No description provided for @miseAJourApresTon.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour {p0}, après ton dernier match'**
  String miseAJourApresTon(Object p0);

  /// No description provided for @tresProbablementEntreEt.
  ///
  /// In fr, this message translates to:
  /// **'Très probablement entre {p0} et {p1}.'**
  String tresProbablementEntreEt(Object p0, Object p1);

  /// No description provided for @ceQueLIaA.
  ///
  /// In fr, this message translates to:
  /// **'CE QUE L’IA A PRIS EN COMPTE'**
  String get ceQueLIaA;

  /// No description provided for @lesMatchsQuiLOnt.
  ///
  /// In fr, this message translates to:
  /// **'LES MATCHS QUI L’ONT FAIT BOUGER'**
  String get lesMatchsQuiLOnt;

  /// No description provided for @pasDAccordAvecCe.
  ///
  /// In fr, this message translates to:
  /// **'Pas d’accord avec ce niveau ?'**
  String get pasDAccordAvecCe;

  /// No description provided for @ajuster.
  ///
  /// In fr, this message translates to:
  /// **'Ajuster'**
  String get ajuster;

  /// No description provided for @ceNiveauMeSembleFaux.
  ///
  /// In fr, this message translates to:
  /// **'Ce niveau me semble faux'**
  String get ceNiveauMeSembleFaux;

  /// No description provided for @contestationEnvoyee.
  ///
  /// In fr, this message translates to:
  /// **'Contestation envoyée'**
  String get contestationEnvoyee;

  /// No description provided for @unHumainRelitTonNiveau.
  ///
  /// In fr, this message translates to:
  /// **'Un humain relit ton niveau sous 48 h.'**
  String get unHumainRelitTonNiveau;

  /// No description provided for @lIaPeutSeTromper.
  ///
  /// In fr, this message translates to:
  /// **'L’IA peut se tromper. Un humain relit chaque contestation.'**
  String get lIaPeutSeTromper;

  /// No description provided for @dApresTesMatchs.
  ///
  /// In fr, this message translates to:
  /// **'d’après tes {p0} matchs'**
  String dApresTesMatchs(Object p0);

  /// No description provided for @tonChoixCompteCommeUne.
  ///
  /// In fr, this message translates to:
  /// **'Ton choix compte comme une auto-évaluation : tes 3 prochains matchs le confirmeront.'**
  String get tonChoixCompteCommeUne;

  /// No description provided for @niveauAjusteA.
  ///
  /// In fr, this message translates to:
  /// **'Niveau ajusté à {p0}'**
  String niveauAjusteA(Object p0);

  /// No description provided for @compteEnregistre.
  ///
  /// In fr, this message translates to:
  /// **'Compte enregistré'**
  String get compteEnregistre;

  /// No description provided for @unCodeDeVerificationT.
  ///
  /// In fr, this message translates to:
  /// **'Un code de vérification t’a été envoyé.'**
  String get unCodeDeVerificationT;

  /// No description provided for @compte.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get compte;

  /// No description provided for @retourAuxParametres.
  ///
  /// In fr, this message translates to:
  /// **'Retour aux paramètres'**
  String get retourAuxParametres;

  /// No description provided for @siTuChangesLUn.
  ///
  /// In fr, this message translates to:
  /// **'Si tu changes l’un des deux, on t’envoie un code pour le vérifier à nouveau.'**
  String get siTuChangesLUn;

  /// No description provided for @infosPersonnelles.
  ///
  /// In fr, this message translates to:
  /// **'Infos personnelles'**
  String get infosPersonnelles;

  /// No description provided for @lesAutresJoueursVoientTon2.
  ///
  /// In fr, this message translates to:
  /// **'Les autres joueurs voient « {p0} {p1} » : ton prénom et l’initiale de ton nom.'**
  String lesAutresJoueursVoientTon2(Object p0, Object p1);

  /// No description provided for @prenom.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get prenom;

  /// No description provided for @dateDeNaissance.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get dateDeNaissance;

  /// No description provided for @jjMmAaaa.
  ///
  /// In fr, this message translates to:
  /// **'JJ/MM/AAAA'**
  String get jjMmAaaa;

  /// No description provided for @jamaisAfficheeSurTonProfil.
  ///
  /// In fr, this message translates to:
  /// **'Jamais affichée sur ton profil.'**
  String get jamaisAfficheeSurTonProfil;

  /// No description provided for @genre.
  ///
  /// In fr, this message translates to:
  /// **'Genre'**
  String get genre;

  /// No description provided for @sertSeulementATeProposer.
  ///
  /// In fr, this message translates to:
  /// **'Sert seulement à te proposer les parties femmes ou hommes.'**
  String get sertSeulementATeProposer;

  /// No description provided for @homme.
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get homme;

  /// No description provided for @femme.
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get femme;

  /// No description provided for @jePrefereNePasDire.
  ///
  /// In fr, this message translates to:
  /// **'Je préfère ne pas dire'**
  String get jePrefereNePasDire;

  /// No description provided for @connecte.
  ///
  /// In fr, this message translates to:
  /// **'Connecté'**
  String get connecte;

  /// No description provided for @comptesConnectes.
  ///
  /// In fr, this message translates to:
  /// **'Comptes connectés'**
  String get comptesConnectes;

  /// No description provided for @tesMethodesDeConnexion.
  ///
  /// In fr, this message translates to:
  /// **'Tes méthodes de connexion'**
  String get tesMethodesDeConnexion;

  /// No description provided for @emailEtMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Email et mot de passe'**
  String get emailEtMotDePasse;

  /// No description provided for @google.
  ///
  /// In fr, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @nonConnecte.
  ///
  /// In fr, this message translates to:
  /// **'Non connecté'**
  String get nonConnecte;

  /// No description provided for @deconnecter.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter'**
  String get deconnecter;

  /// No description provided for @googleDeconnecte.
  ///
  /// In fr, this message translates to:
  /// **'Google déconnecté'**
  String get googleDeconnecte;

  /// No description provided for @apple.
  ///
  /// In fr, this message translates to:
  /// **'Apple'**
  String get apple;

  /// No description provided for @gardeAuMoinsUneMethode.
  ///
  /// In fr, this message translates to:
  /// **'Garde au moins une méthode de connexion'**
  String get gardeAuMoinsUneMethode;

  /// No description provided for @sansElleTuPerdraisL.
  ///
  /// In fr, this message translates to:
  /// **'Sans elle, tu perdrais l’accès à ton compte. Ton email reste actif si tu déconnectes Google.'**
  String get sansElleTuPerdraisL;

  /// No description provided for @ajouterUneMethode.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une méthode'**
  String get ajouterUneMethode;

  /// No description provided for @continuerAvecGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continuerAvecGoogle;

  /// No description provided for @yassineBGmailCom.
  ///
  /// In fr, this message translates to:
  /// **'yassine.b@gmail.com'**
  String get yassineBGmailCom;

  /// No description provided for @googleConnecte.
  ///
  /// In fr, this message translates to:
  /// **'Google connecté'**
  String get googleConnecte;

  /// No description provided for @continuerAvecApple.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get continuerAvecApple;

  /// No description provided for @appleConnecte.
  ///
  /// In fr, this message translates to:
  /// **'Apple connecté'**
  String get appleConnecte;

  /// No description provided for @onNePublieJamaisRien.
  ///
  /// In fr, this message translates to:
  /// **'On ne publie jamais rien sur tes comptes. Apple peut masquer ton adresse email.'**
  String get onNePublieJamaisRien;

  /// No description provided for @supprimer2.
  ///
  /// In fr, this message translates to:
  /// **'SUPPRIMER'**
  String get supprimer2;

  /// No description provided for @jeNeJouePlus.
  ///
  /// In fr, this message translates to:
  /// **'Je ne joue plus'**
  String get jeNeJouePlus;

  /// No description provided for @pasAssezDePartiesPres.
  ///
  /// In fr, this message translates to:
  /// **'Pas assez de parties près de chez moi'**
  String get pasAssezDePartiesPres;

  /// No description provided for @tropDeNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Trop de notifications'**
  String get tropDeNotifications;

  /// No description provided for @jAiUnAutreCompte.
  ///
  /// In fr, this message translates to:
  /// **'J’ai un autre compte'**
  String get jAiUnAutreCompte;

  /// No description provided for @autreRaison.
  ///
  /// In fr, this message translates to:
  /// **'Autre raison'**
  String get autreRaison;

  /// No description provided for @compteSupprime.
  ///
  /// In fr, this message translates to:
  /// **'Compte supprimé'**
  String get compteSupprime;

  /// No description provided for @reconnecteToiAvantLeNov.
  ///
  /// In fr, this message translates to:
  /// **'Reconnecte-toi avant le 15 nov. pour tout garder.'**
  String get reconnecteToiAvantLeNov;

  /// No description provided for @supprimerLeCompte.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get supprimerLeCompte;

  /// No description provided for @ceQuiVaSePasser.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui va se passer'**
  String get ceQuiVaSePasser;

  /// No description provided for @tesMatchsAVenirSont.
  ///
  /// In fr, this message translates to:
  /// **'Tes 2 matchs à venir sont annulés'**
  String get tesMatchsAVenirSont;

  /// No description provided for @dimOctEtMerOct.
  ///
  /// In fr, this message translates to:
  /// **'dim. 18 oct. et mer. 21 oct. Chaque joueur est remboursé, toi compris.'**
  String get dimOctEtMerOct;

  /// No description provided for @retireDAbordTonSolde.
  ///
  /// In fr, this message translates to:
  /// **'Retire d’abord ton solde de {p0}'**
  String retireDAbordTonSolde(Object p0);

  /// No description provided for @uneFoisLeCompteSupprime.
  ///
  /// In fr, this message translates to:
  /// **'Une fois le compte supprimé, on ne pourra plus te le verser.'**
  String get uneFoisLeCompteSupprime;

  /// No description provided for @retirerMonSolde.
  ///
  /// In fr, this message translates to:
  /// **'Retirer mon solde'**
  String get retirerMonSolde;

  /// No description provided for @tonProfilEstEffaceDans.
  ///
  /// In fr, this message translates to:
  /// **'Ton profil est effacé dans 30 jours'**
  String get tonProfilEstEffaceDans;

  /// No description provided for @niveauMatchsEtAvisReconnecte.
  ///
  /// In fr, this message translates to:
  /// **'Niveau, matchs et avis. Reconnecte-toi avant le 15 nov. pour tout garder.'**
  String get niveauMatchsEtAvisReconnecte;

  /// No description provided for @apresLeNovCEst.
  ///
  /// In fr, this message translates to:
  /// **'Après le 15 nov., c’est définitif'**
  String get apresLeNovCEst;

  /// No description provided for @personneNePourraRecupererTon.
  ///
  /// In fr, this message translates to:
  /// **'Personne ne pourra récupérer ton compte, même en nous écrivant.'**
  String get personneNePourraRecupererTon;

  /// No description provided for @confirmer.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirmer;

  /// No description provided for @pourquoiParsTu.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi pars-tu ?'**
  String get pourquoiParsTu;

  /// No description provided for @choisisUneRaison.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une raison'**
  String get choisisUneRaison;

  /// No description provided for @caNousAideAAmeliorer.
  ///
  /// In fr, this message translates to:
  /// **'Ça nous aide à améliorer MatchUp.'**
  String get caNousAideAAmeliorer;

  /// No description provided for @tapePourConfirmer.
  ///
  /// In fr, this message translates to:
  /// **'Tape {p0} pour confirmer'**
  String tapePourConfirmer(Object p0);

  /// No description provided for @tuPeuxSupprimerTonCompte.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux supprimer ton compte.'**
  String get tuPeuxSupprimerTonCompte;

  /// No description provided for @leBoutonSActiveQuand.
  ///
  /// In fr, this message translates to:
  /// **'Le bouton s’active quand le mot est tapé.'**
  String get leBoutonSActiveQuand;

  /// No description provided for @garderMonCompte.
  ///
  /// In fr, this message translates to:
  /// **'Garder mon compte'**
  String get garderMonCompte;

  /// No description provided for @supprimerMonCompte.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get supprimerMonCompte;

  /// No description provided for @langueEtTheme.
  ///
  /// In fr, this message translates to:
  /// **'Langue et thème'**
  String get langueEtTheme;

  /// No description provided for @langue.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get langue;

  /// No description provided for @francais.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get francais;

  /// No description provided for @langueParDefautDeMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Langue par défaut de MatchUp'**
  String get langueParDefautDeMatchup;

  /// No description provided for @arabeLInterfacePasseDe.
  ///
  /// In fr, this message translates to:
  /// **'Arabe · l’interface passe de droite à gauche'**
  String get arabeLInterfacePasseDe;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @anglais.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get anglais;

  /// No description provided for @enArabeLesMenusEt.
  ///
  /// In fr, this message translates to:
  /// **'En arabe, les menus et les flèches s’inversent. Les chiffres, les scores et les cartes restent dans le même sens.'**
  String get enArabeLesMenusEt;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// No description provided for @clair.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get clair;

  /// No description provided for @sombre.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get sombre;

  /// No description provided for @systeme.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get systeme;

  /// No description provided for @systemeSuitLeReglageDe.
  ///
  /// In fr, this message translates to:
  /// **'Système suit le réglage de ton téléphone. Sombre, c’est « Night match » : pensé pour les matchs du soir.'**
  String get systemeSuitLeReglageDe;

  /// No description provided for @confidentialite.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get confidentialite;

  /// No description provided for @quiVoitMonProfil.
  ///
  /// In fr, this message translates to:
  /// **'Qui voit mon profil'**
  String get quiVoitMonProfil;

  /// No description provided for @quiPeutMInviter.
  ///
  /// In fr, this message translates to:
  /// **'Qui peut m’inviter'**
  String get quiPeutMInviter;

  /// No description provided for @mesCoequipiers.
  ///
  /// In fr, this message translates to:
  /// **'Mes coéquipiers'**
  String get mesCoequipiers;

  /// No description provided for @personne.
  ///
  /// In fr, this message translates to:
  /// **'Personne'**
  String get personne;

  /// No description provided for @enPadelEtEnFoot.
  ///
  /// In fr, this message translates to:
  /// **'3,5 en padel et 3,0 en foot, sur ton profil et dans les parties.'**
  String get enPadelEtEnFoot;

  /// No description provided for @masqueeLesOrganisateursLisentFiabilite.
  ///
  /// In fr, this message translates to:
  /// **'Masquée, les organisateurs lisent « Fiabilité masquée ».'**
  String get masqueeLesOrganisateursLisentFiabilite;

  /// No description provided for @positionPrecise.
  ///
  /// In fr, this message translates to:
  /// **'Position précise'**
  String get positionPrecise;

  /// No description provided for @pourDesDistancesExactesLes.
  ///
  /// In fr, this message translates to:
  /// **'Pour des distances exactes. Les autres voient « La Marsa ».'**
  String get pourDesDistancesExactesLes;

  /// No description provided for @tesDonnees.
  ///
  /// In fr, this message translates to:
  /// **'Tes données'**
  String get tesDonnees;

  /// No description provided for @telechargerMesDonnees.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger mes données'**
  String get telechargerMesDonnees;

  /// No description provided for @profilMatchsEtPaiementsPar.
  ///
  /// In fr, this message translates to:
  /// **'Profil, matchs et paiements, par email sous 48 h'**
  String get profilMatchsEtPaiementsPar;

  /// No description provided for @demandeEnvoyee.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée'**
  String get demandeEnvoyee;

  /// No description provided for @tuRecevrasTesDonneesPar.
  ///
  /// In fr, this message translates to:
  /// **'Tu recevras tes données par email sous 48 h.'**
  String get tuRecevrasTesDonneesPar;

  /// No description provided for @joueursBloques.
  ///
  /// In fr, this message translates to:
  /// **'Joueurs bloqués'**
  String get joueursBloques;

  /// No description provided for @securite.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get securite;

  /// No description provided for @motDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get motDePasse;

  /// No description provided for @changerLeMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get changerLeMotDePasse;

  /// No description provided for @modifie.
  ///
  /// In fr, this message translates to:
  /// **'Modifié {p0}'**
  String modifie(Object p0);

  /// No description provided for @doubleAuthentification.
  ///
  /// In fr, this message translates to:
  /// **'Double authentification'**
  String get doubleAuthentification;

  /// No description provided for @codeAChaqueNouvelAppareil.
  ///
  /// In fr, this message translates to:
  /// **'Code à chaque nouvel appareil'**
  String get codeAChaqueNouvelAppareil;

  /// No description provided for @unCodeParSmsEn.
  ///
  /// In fr, this message translates to:
  /// **'Un code par SMS en plus de ton mot de passe.'**
  String get unCodeParSmsEn;

  /// No description provided for @methode.
  ///
  /// In fr, this message translates to:
  /// **'Méthode'**
  String get methode;

  /// No description provided for @sms.
  ///
  /// In fr, this message translates to:
  /// **'SMS · {p0}'**
  String sms(Object p0);

  /// No description provided for @sansCodeSeulTonMot.
  ///
  /// In fr, this message translates to:
  /// **'Sans code, seul ton mot de passe protège ton compte et ton solde de {p0}.'**
  String sansCodeSeulTonMot(Object p0);

  /// No description provided for @sessionsActives.
  ///
  /// In fr, this message translates to:
  /// **'Sessions actives'**
  String get sessionsActives;

  /// No description provided for @cetAppareil.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil'**
  String get cetAppareil;

  /// No description provided for @deconnecte.
  ///
  /// In fr, this message translates to:
  /// **'{p0} déconnecté'**
  String deconnecte(Object p0);

  /// No description provided for @aucuneAutreSessionOuverteSeul.
  ///
  /// In fr, this message translates to:
  /// **'Aucune autre session ouverte. Seul cet {p0} est connecté.'**
  String aucuneAutreSessionOuverteSeul(Object p0);

  /// No description provided for @tuNeReconnaisPasUn.
  ///
  /// In fr, this message translates to:
  /// **'Tu ne reconnais pas un appareil ? Déconnecte-le, puis change ton mot de passe.'**
  String get tuNeReconnaisPasUn;

  /// No description provided for @deconnecterToutesLesAutresSessions.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter toutes les autres sessions'**
  String get deconnecterToutesLesAutresSessions;

  /// No description provided for @autresSessionsDeconnectees.
  ///
  /// In fr, this message translates to:
  /// **'Autres sessions déconnectées'**
  String get autresSessionsDeconnectees;

  /// No description provided for @retourAuProfil.
  ///
  /// In fr, this message translates to:
  /// **'Retour au profil'**
  String get retourAuProfil;

  /// No description provided for @t2faActivee.
  ///
  /// In fr, this message translates to:
  /// **'2FA activée'**
  String get t2faActivee;

  /// No description provided for @t2faDesactivee.
  ///
  /// In fr, this message translates to:
  /// **'2FA désactivée'**
  String get t2faDesactivee;

  /// No description provided for @preferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get preferences;

  /// No description provided for @profilPublic.
  ///
  /// In fr, this message translates to:
  /// **'Profil public'**
  String get profilPublic;

  /// No description provided for @profilLimite.
  ///
  /// In fr, this message translates to:
  /// **'Profil limité'**
  String get profilLimite;

  /// No description provided for @assistance.
  ///
  /// In fr, this message translates to:
  /// **'Assistance'**
  String get assistance;

  /// No description provided for @faqNousEcrire.
  ///
  /// In fr, this message translates to:
  /// **'FAQ · nous écrire'**
  String get faqNousEcrire;

  /// No description provided for @aPropos.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get aPropos;

  /// No description provided for @version.
  ///
  /// In fr, this message translates to:
  /// **'Version 1.0'**
  String get version;

  /// No description provided for @session.
  ///
  /// In fr, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @resilierPremium.
  ///
  /// In fr, this message translates to:
  /// **'Résilier Premium'**
  String get resilierPremium;

  /// No description provided for @pourquoiTuVeuxResilier.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi tu veux résilier ?'**
  String get pourquoiTuVeuxResilier;

  /// No description provided for @facultatifTaReponseNousAide.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif. Ta réponse nous aide à améliorer Premium.'**
  String get facultatifTaReponseNousAide;

  /// No description provided for @raison.
  ///
  /// In fr, this message translates to:
  /// **'Raison'**
  String get raison;

  /// No description provided for @tuVeuxEnDirePlus.
  ///
  /// In fr, this message translates to:
  /// **'Tu veux en dire plus ?'**
  String get tuVeuxEnDirePlus;

  /// No description provided for @exJeJoueSurtoutL.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : je joue surtout l’été'**
  String get exJeJoueSurtoutL;

  /// No description provided for @siTuResilies.
  ///
  /// In fr, this message translates to:
  /// **'Si tu résilies'**
  String get siTuResilies;

  /// No description provided for @premiumResteActifJusquAu.
  ///
  /// In fr, this message translates to:
  /// **'Premium reste actif jusqu’au {p0}'**
  String premiumResteActifJusquAu(Object p0);

  /// No description provided for @aucunPrelevementSurTa.
  ///
  /// In fr, this message translates to:
  /// **'Aucun prélèvement sur ta {p0}'**
  String aucunPrelevementSurTa(Object p0);

  /// No description provided for @tesMatchsTonNiveauEt.
  ///
  /// In fr, this message translates to:
  /// **'Tes matchs, ton niveau et ton solde de {p0} restent'**
  String tesMatchsTonNiveauEt(Object p0);

  /// No description provided for @garderPremium.
  ///
  /// In fr, this message translates to:
  /// **'Garder Premium'**
  String get garderPremium;

  /// No description provided for @offreActivee.
  ///
  /// In fr, this message translates to:
  /// **'Offre activée'**
  String get offreActivee;

  /// No description provided for @uneDerniereOption.
  ///
  /// In fr, this message translates to:
  /// **'Une dernière option'**
  String get uneDerniereOption;

  /// No description provided for @siTuPreferesResilierChoisis.
  ///
  /// In fr, this message translates to:
  /// **'Si tu préfères résilier, choisis « Non merci, résilier » : rien d’autre à faire.'**
  String get siTuPreferesResilierChoisis;

  /// No description provided for @tuAsReponduSiTu.
  ///
  /// In fr, this message translates to:
  /// **'Tu as répondu « {p0} ». Si tu préfères résilier, choisis « Non merci, résilier » : rien d’autre à faire.'**
  String tuAsReponduSiTu(Object p0);

  /// No description provided for @offrePourToi.
  ///
  /// In fr, this message translates to:
  /// **'Offre pour toi'**
  String get offrePourToi;

  /// No description provided for @pendantMois.
  ///
  /// In fr, this message translates to:
  /// **'−30 % pendant 2 mois'**
  String get pendantMois;

  /// No description provided for @tuAsJoueMatchsCe.
  ///
  /// In fr, this message translates to:
  /// **'tu as joué 4 matchs ce mois-ci : Premium te sert encore.'**
  String get tuAsJoueMatchsCe;

  /// No description provided for @lesOctEtNovPuis.
  ///
  /// In fr, this message translates to:
  /// **'Les 30 oct. et 30 nov., puis {p0}/mois. Toujours résiliable.'**
  String lesOctEtNovPuis(Object p0);

  /// No description provided for @avecLOffre.
  ///
  /// In fr, this message translates to:
  /// **'Avec l’offre'**
  String get avecLOffre;

  /// No description provided for @premiumContinue.
  ///
  /// In fr, this message translates to:
  /// **'Premium continue'**
  String get premiumContinue;

  /// No description provided for @leOct.
  ///
  /// In fr, this message translates to:
  /// **'{p0} le 30 oct.'**
  String leOct(Object p0);

  /// No description provided for @desLeDec.
  ///
  /// In fr, this message translates to:
  /// **'{p0} dès le 30 déc.'**
  String desLeDec(Object p0);

  /// No description provided for @actifJusquAuOct.
  ///
  /// In fr, this message translates to:
  /// **'Actif jusqu’au 30 oct.'**
  String get actifJusquAuOct;

  /// No description provided for @aucunPrelevement.
  ///
  /// In fr, this message translates to:
  /// **'Aucun prélèvement'**
  String get aucunPrelevement;

  /// No description provided for @puisOffreGratuit.
  ///
  /// In fr, this message translates to:
  /// **'Puis offre Gratuit'**
  String get puisOffreGratuit;

  /// No description provided for @accepterLOffre.
  ///
  /// In fr, this message translates to:
  /// **'Accepter l’offre'**
  String get accepterLOffre;

  /// No description provided for @nonMerciResilier.
  ///
  /// In fr, this message translates to:
  /// **'Non merci, résilier'**
  String get nonMerciResilier;

  /// No description provided for @fermer.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get fermer;

  /// No description provided for @resiliationConfirmee.
  ///
  /// In fr, this message translates to:
  /// **'Résiliation confirmée'**
  String get resiliationConfirmee;

  /// No description provided for @premiumResteActifJusquAu2.
  ///
  /// In fr, this message translates to:
  /// **'Premium reste actif jusqu’au {p0}. Aucun prélèvement.'**
  String premiumResteActifJusquAu2(Object p0);

  /// No description provided for @finDePremium.
  ///
  /// In fr, this message translates to:
  /// **'Fin de Premium · {p0}'**
  String finDePremium(Object p0);

  /// No description provided for @taNeSeraPasDebitee.
  ///
  /// In fr, this message translates to:
  /// **'Ta {p0} ne sera pas débitée. Tu repasses ensuite en offre Gratuit.'**
  String taNeSeraPasDebitee(Object p0);

  /// No description provided for @jusqueLaTuGardesTout.
  ///
  /// In fr, this message translates to:
  /// **'Jusque-là, tu gardes tout'**
  String get jusqueLaTuGardesTout;

  /// No description provided for @prioriteSurLesListesD.
  ///
  /// In fr, this message translates to:
  /// **'Priorité sur les listes d’attente'**
  String get prioriteSurLesListesD;

  /// No description provided for @plansDEntrainementIaEt.
  ///
  /// In fr, this message translates to:
  /// **'Plans d’entraînement IA et programmes'**
  String get plansDEntrainementIaEt;

  /// No description provided for @statistiquesAvancees.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques avancées'**
  String get statistiquesAvancees;

  /// No description provided for @pasDeFraisDeService.
  ///
  /// In fr, this message translates to:
  /// **'Pas de frais de service'**
  String get pasDeFraisDeService;

  /// No description provided for @apresLeTesMatchsTon.
  ///
  /// In fr, this message translates to:
  /// **'Après le {p0} {p1}, tes matchs, ton niveau, ta fiabilité et ton solde de {p2} restent intacts.'**
  String apresLeTesMatchsTon(Object p0, Object p1, Object p2);

  /// No description provided for @confirmationEnvoyeeA.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation envoyée à {p0}'**
  String confirmationEnvoyeeA(Object p0);

  /// No description provided for @reactiverPremium.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver Premium'**
  String get reactiverPremium;

  /// No description provided for @tuPassesALAnnuel.
  ///
  /// In fr, this message translates to:
  /// **'Tu passes à l’annuel'**
  String get tuPassesALAnnuel;

  /// No description provided for @tuRestesAuMensuel.
  ///
  /// In fr, this message translates to:
  /// **'Tu restes au mensuel'**
  String get tuRestesAuMensuel;

  /// No description provided for @leChangementCompteAPartir.
  ///
  /// In fr, this message translates to:
  /// **'Le changement compte à partir du {p0}.'**
  String leChangementCompteAPartir(Object p0);

  /// No description provided for @tonOffreActuelle.
  ///
  /// In fr, this message translates to:
  /// **'Ton offre actuelle'**
  String get tonOffreActuelle;

  /// No description provided for @changerDOffre.
  ///
  /// In fr, this message translates to:
  /// **'Changer d’offre'**
  String get changerDOffre;

  /// No description provided for @mensuelOuAnnuel.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel ou annuel ?'**
  String get mensuelOuAnnuel;

  /// No description provided for @tonEssaiContinueJusquAu.
  ///
  /// In fr, this message translates to:
  /// **'Ton essai continue jusqu’au {p0}. Le changement compte à partir de là.'**
  String tonEssaiContinueJusquAu(Object p0);

  /// No description provided for @mensuelMois.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel · {p0}/mois'**
  String mensuelMois(Object p0);

  /// No description provided for @sansEngagementResiliableChaqueMois.
  ///
  /// In fr, this message translates to:
  /// **'Sans engagement, résiliable chaque mois.'**
  String get sansEngagementResiliableChaqueMois;

  /// No description provided for @annuelAn.
  ///
  /// In fr, this message translates to:
  /// **'Annuel · {p0}/an'**
  String annuelAn(Object p0);

  /// No description provided for @soitMoisMoisOfferts.
  ///
  /// In fr, this message translates to:
  /// **'Soit {p0}/mois : 2 mois offerts.'**
  String soitMoisMoisOfferts(Object p0);

  /// No description provided for @ceQueTuPaierasAvec.
  ///
  /// In fr, this message translates to:
  /// **'Ce que tu paieras avec l’annuel'**
  String get ceQueTuPaierasAvec;

  /// No description provided for @ceQueTuPaierasAvec2.
  ///
  /// In fr, this message translates to:
  /// **'Ce que tu paieras avec le mensuel'**
  String get ceQueTuPaierasAvec2;

  /// No description provided for @rienNeChange.
  ///
  /// In fr, this message translates to:
  /// **'Rien ne change'**
  String get rienNeChange;

  /// No description provided for @le.
  ///
  /// In fr, this message translates to:
  /// **'Le {p0}'**
  String le(Object p0);

  /// No description provided for @auLieuDe.
  ///
  /// In fr, this message translates to:
  /// **'au lieu de {p0}'**
  String auLieuDe(Object p0);

  /// No description provided for @ensuite.
  ///
  /// In fr, this message translates to:
  /// **'Ensuite'**
  String get ensuite;

  /// No description provided for @chaqueOct.
  ///
  /// In fr, this message translates to:
  /// **'{p0} chaque 30 oct.'**
  String chaqueOct(Object p0);

  /// No description provided for @chaqueMoisLe.
  ///
  /// In fr, this message translates to:
  /// **'{p0} chaque mois, le 30'**
  String chaqueMoisLe(Object p0);

  /// No description provided for @tuEconomisesParAn.
  ///
  /// In fr, this message translates to:
  /// **'Tu économises {p0} par an'**
  String tuEconomisesParAn(Object p0);

  /// No description provided for @vs2.
  ///
  /// In fr, this message translates to:
  /// **'vs 12 × {p0}'**
  String vs2(Object p0);

  /// No description provided for @surTaTuPeuxRevenir.
  ///
  /// In fr, this message translates to:
  /// **'Sur ta {p0}. Tu peux revenir au mensuel jusqu’au 30 oct., sans frais.'**
  String surTaTuPeuxRevenir(Object p0);

  /// No description provided for @surTaTuPeuxPasser.
  ///
  /// In fr, this message translates to:
  /// **'Sur ta {p0}. Tu peux passer à l’annuel à tout moment.'**
  String surTaTuPeuxPasser(Object p0);

  /// No description provided for @passerALAnnuel.
  ///
  /// In fr, this message translates to:
  /// **'Passer à l’annuel'**
  String get passerALAnnuel;

  /// No description provided for @garderLAnnuel.
  ///
  /// In fr, this message translates to:
  /// **'Garder l’annuel'**
  String get garderLAnnuel;

  /// No description provided for @passerAuMensuel.
  ///
  /// In fr, this message translates to:
  /// **'Passer au mensuel'**
  String get passerAuMensuel;

  /// No description provided for @garderLeMensuel.
  ///
  /// In fr, this message translates to:
  /// **'Garder le mensuel'**
  String get garderLeMensuel;

  /// No description provided for @premium.
  ///
  /// In fr, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @passeAvantLesAutresEt.
  ///
  /// In fr, this message translates to:
  /// **'Passe avant les autres et progresse avec l’IA.'**
  String get passeAvantLesAutresEt;

  /// No description provided for @plansDEntrainementIa.
  ///
  /// In fr, this message translates to:
  /// **'Plans d’entraînement IA'**
  String get plansDEntrainementIa;

  /// No description provided for @programmesDesCoachsInclus.
  ///
  /// In fr, this message translates to:
  /// **'Programmes des coachs inclus'**
  String get programmesDesCoachsInclus;

  /// No description provided for @gratuit.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get gratuit;

  /// No description provided for @partiesReservationsEtNiveauIa.
  ///
  /// In fr, this message translates to:
  /// **'Parties, réservations et niveau IA, sans engagement.'**
  String get partiesReservationsEtNiveauIa;

  /// No description provided for @partiesOuvertesATonNiveau.
  ///
  /// In fr, this message translates to:
  /// **'Parties ouvertes à ton niveau'**
  String get partiesOuvertesATonNiveau;

  /// No description provided for @reservationEtPaiementDeTa.
  ///
  /// In fr, this message translates to:
  /// **'Réservation et paiement de ta part'**
  String get reservationEtPaiementDeTa;

  /// No description provided for @niveauIaEtFiabilite.
  ///
  /// In fr, this message translates to:
  /// **'Niveau IA et fiabilité'**
  String get niveauIaEtFiabilite;

  /// No description provided for @remplisTesCreneauxCreuxEt.
  ///
  /// In fr, this message translates to:
  /// **'Remplis tes créneaux creux et gère plusieurs sites.'**
  String get remplisTesCreneauxCreuxEt;

  /// No description provided for @reservationsEnLigne.
  ///
  /// In fr, this message translates to:
  /// **'Réservations en ligne'**
  String get reservationsEnLigne;

  /// No description provided for @paiementsDesJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Paiements des joueurs'**
  String get paiementsDesJoueurs;

  /// No description provided for @tarifsDynamiques.
  ///
  /// In fr, this message translates to:
  /// **'Tarifs dynamiques'**
  String get tarifsDynamiques;

  /// No description provided for @insightsIa.
  ///
  /// In fr, this message translates to:
  /// **'Insights IA'**
  String get insightsIa;

  /// No description provided for @plusieursSites.
  ///
  /// In fr, this message translates to:
  /// **'Plusieurs sites'**
  String get plusieursSites;

  /// No description provided for @siteJusquATerrains.
  ///
  /// In fr, this message translates to:
  /// **'1 site · jusqu’à 3 terrains'**
  String get siteJusquATerrains;

  /// No description provided for @entraineurs.
  ///
  /// In fr, this message translates to:
  /// **'Entraîneurs'**
  String get entraineurs;

  /// No description provided for @publieTesProgrammesEtSuis2.
  ///
  /// In fr, this message translates to:
  /// **'Publie tes programmes et suis tes élèves.'**
  String get publieTesProgrammesEtSuis2;

  /// No description provided for @programmesIllimites.
  ///
  /// In fr, this message translates to:
  /// **'Programmes illimités'**
  String get programmesIllimites;

  /// No description provided for @paiementsDesEleves.
  ///
  /// In fr, this message translates to:
  /// **'Paiements des élèves'**
  String get paiementsDesEleves;

  /// No description provided for @statistiquesDeTesEleves.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques de tes élèves'**
  String get statistiquesDeTesEleves;

  /// No description provided for @commissionDeSurLesVentes.
  ///
  /// In fr, this message translates to:
  /// **'Commission de 10 % sur les ventes'**
  String get commissionDeSurLesVentes;

  /// No description provided for @joursGratuitsPuisResiliableA.
  ///
  /// In fr, this message translates to:
  /// **'14 jours gratuits, puis {p0} · Résiliable à tout moment'**
  String joursGratuitsPuisResiliableA(Object p0);

  /// No description provided for @essaiePremiumJoursGratuitementAucun.
  ///
  /// In fr, this message translates to:
  /// **'Essaie Premium 14 jours gratuitement. Aucun prélèvement avant le ven. 30 oct., résiliable en 2 étapes.'**
  String get essaiePremiumJoursGratuitementAucun;

  /// No description provided for @metsTonTerrainEnLigne.
  ///
  /// In fr, this message translates to:
  /// **'Mets ton terrain en ligne et encaisse les parts des joueurs. 14 jours d’essai sur les deux offres.'**
  String get metsTonTerrainEnLigne;

  /// No description provided for @vendsTesProgrammesEtSuis.
  ///
  /// In fr, this message translates to:
  /// **'Vends tes programmes et suis tes élèves. 14 jours d’essai, puis une commission de 10 % sur tes ventes.'**
  String get vendsTesProgrammesEtSuis;

  /// No description provided for @partiesOuvertesEtReservations.
  ///
  /// In fr, this message translates to:
  /// **'Parties ouvertes et réservations'**
  String get partiesOuvertesEtReservations;

  /// No description provided for @paiementDeTaPartEn.
  ///
  /// In fr, this message translates to:
  /// **'Paiement de ta part en ligne'**
  String get paiementDeTaPartEn;

  /// No description provided for @programmesDesCoachs.
  ///
  /// In fr, this message translates to:
  /// **'Programmes des coachs'**
  String get programmesDesCoachs;

  /// No description provided for @statistiques.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statistiques;

  /// No description provided for @deBase.
  ///
  /// In fr, this message translates to:
  /// **'De base'**
  String get deBase;

  /// No description provided for @avancees.
  ///
  /// In fr, this message translates to:
  /// **'Avancées'**
  String get avancees;

  /// No description provided for @offertsAuLancement.
  ///
  /// In fr, this message translates to:
  /// **'Offerts au lancement'**
  String get offertsAuLancement;

  /// No description provided for @dt.
  ///
  /// In fr, this message translates to:
  /// **'0 DT'**
  String get dt;

  /// No description provided for @estCeQueJePaie.
  ///
  /// In fr, this message translates to:
  /// **'Est-ce que je paie pendant l’essai ?'**
  String get estCeQueJePaie;

  /// No description provided for @nonDtAujourdHuiOn.
  ///
  /// In fr, this message translates to:
  /// **'Non : 0 DT aujourd’hui. On te prévient le mar. 27 oct., 3 jours avant le premier prélèvement de 19 DT le ven. 30 oct.'**
  String get nonDtAujourdHuiOn;

  /// No description provided for @commentJeResilie.
  ///
  /// In fr, this message translates to:
  /// **'Comment je résilie ?'**
  String get commentJeResilie;

  /// No description provided for @dansMonCompteAbonnementResilier.
  ///
  /// In fr, this message translates to:
  /// **'Dans Mon compte › Abonnement › « Résilier l’abonnement », en 2 étapes, sans appel ni frais. Premium reste actif jusqu’à la fin de la période déjà payée.'**
  String get dansMonCompteAbonnementResilier;

  /// No description provided for @jePeuxPasserAL.
  ///
  /// In fr, this message translates to:
  /// **'Je peux passer à l’annuel plus tard ?'**
  String get jePeuxPasserAL;

  /// No description provided for @ouiAToutMomentTu.
  ///
  /// In fr, this message translates to:
  /// **'Oui, à tout moment. Tu vois le montant exact avant de confirmer, et ce que tu as déjà payé est déduit au prorata.'**
  String get ouiAToutMomentTu;

  /// No description provided for @queSePasseTIl.
  ///
  /// In fr, this message translates to:
  /// **'Que se passe-t-il si je repasse en Gratuit ?'**
  String get queSePasseTIl;

  /// No description provided for @tuGardesTesMatchsTon.
  ///
  /// In fr, this message translates to:
  /// **'Tu gardes tes matchs, ton niveau, ta fiabilité et ton solde. Tu perds la priorité sur les listes d’attente, les plans IA et les statistiques avancées.'**
  String get tuGardesTesMatchsTon;

  /// No description provided for @inclus.
  ///
  /// In fr, this message translates to:
  /// **'Inclus'**
  String get inclus;

  /// No description provided for @nonInclus.
  ///
  /// In fr, this message translates to:
  /// **'Non inclus'**
  String get nonInclus;

  /// No description provided for @essayerJoursGratuits.
  ///
  /// In fr, this message translates to:
  /// **'Essayer 14 jours gratuits'**
  String get essayerJoursGratuits;

  /// No description provided for @choisirPro.
  ///
  /// In fr, this message translates to:
  /// **'Choisir Pro'**
  String get choisirPro;

  /// No description provided for @choisirStarter.
  ///
  /// In fr, this message translates to:
  /// **'Choisir Starter'**
  String get choisirStarter;

  /// No description provided for @devenirCoach.
  ///
  /// In fr, this message translates to:
  /// **'Devenir coach'**
  String get devenirCoach;

  /// No description provided for @gererMonAbonnement.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mon abonnement'**
  String get gererMonAbonnement;

  /// No description provided for @essayerPremiumGratuitement.
  ///
  /// In fr, this message translates to:
  /// **'Essayer Premium gratuitement'**
  String get essayerPremiumGratuitement;

  /// No description provided for @dtAujourdHuiPuisDes.
  ///
  /// In fr, this message translates to:
  /// **'0 DT aujourd’hui, puis {p0} dès le ven. 30 oct. · Résiliable à tout moment'**
  String dtAujourdHuiPuisDes(Object p0);

  /// No description provided for @terminerMonEspaceProprietaire.
  ///
  /// In fr, this message translates to:
  /// **'Terminer mon espace propriétaire'**
  String get terminerMonEspaceProprietaire;

  /// No description provided for @tuChoisisTonOffreA.
  ///
  /// In fr, this message translates to:
  /// **'Tu choisis ton offre à la dernière étape · 14 jours gratuits'**
  String get tuChoisisTonOffreA;

  /// No description provided for @profilVerifieAvantTaPremiere.
  ///
  /// In fr, this message translates to:
  /// **'Profil vérifié avant ta première vente · 14 jours gratuits'**
  String get profilVerifieAvantTaPremiere;

  /// No description provided for @offresEtAbonnements.
  ///
  /// In fr, this message translates to:
  /// **'Offres et abonnements'**
  String get offresEtAbonnements;

  /// No description provided for @jouePlusProgressePlusVite.
  ///
  /// In fr, this message translates to:
  /// **'Joue plus. Progresse plus vite.'**
  String get jouePlusProgressePlusVite;

  /// No description provided for @offresParProfil.
  ///
  /// In fr, this message translates to:
  /// **'Offres par profil'**
  String get offresParProfil;

  /// No description provided for @compareGratuitEtPremium.
  ///
  /// In fr, this message translates to:
  /// **'Compare Gratuit et Premium'**
  String get compareGratuitEtPremium;

  /// No description provided for @tesReservationsTonNiveauEt.
  ///
  /// In fr, this message translates to:
  /// **'Tes réservations, ton niveau et ton historique restent dans les deux offres.'**
  String get tesReservationsTonNiveauEt;

  /// No description provided for @inclus2.
  ///
  /// In fr, this message translates to:
  /// **'INCLUS'**
  String get inclus2;

  /// No description provided for @questionsFrequentes.
  ///
  /// In fr, this message translates to:
  /// **'Questions fréquentes'**
  String get questionsFrequentes;

  /// No description provided for @prixTtcEnDinarsPaiement.
  ///
  /// In fr, this message translates to:
  /// **'Prix TTC en dinars · Paiement sécurisé par Stripe'**
  String get prixTtcEnDinarsPaiement;

  /// No description provided for @parAn.
  ///
  /// In fr, this message translates to:
  /// **'par an'**
  String get parAn;

  /// No description provided for @parMois.
  ///
  /// In fr, this message translates to:
  /// **'par mois'**
  String get parMois;

  /// No description provided for @demarreTonEssaiPremium.
  ///
  /// In fr, this message translates to:
  /// **'Démarre ton essai Premium'**
  String get demarreTonEssaiPremium;

  /// No description provided for @joursPourToutEssayerTu.
  ///
  /// In fr, this message translates to:
  /// **'14 jours pour tout essayer. Tu ne paies rien aujourd’hui.'**
  String get joursPourToutEssayerTu;

  /// No description provided for @joueurSansEngagement.
  ///
  /// In fr, this message translates to:
  /// **'Joueur · sans engagement'**
  String get joueurSansEngagement;

  /// No description provided for @mensuel2.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel · {p0}'**
  String mensuel2(Object p0);

  /// No description provided for @annuel2.
  ///
  /// In fr, this message translates to:
  /// **'Annuel · {p0}'**
  String annuel2(Object p0);

  /// No description provided for @aujourdHuiEssaiGratuit.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui · essai gratuit'**
  String get aujourdHuiEssaiGratuit;

  /// No description provided for @toutPremiumDebloquePendantJours.
  ///
  /// In fr, this message translates to:
  /// **'Tout Premium débloqué pendant 14 jours'**
  String get toutPremiumDebloquePendantJours;

  /// No description provided for @marOctRappel.
  ///
  /// In fr, this message translates to:
  /// **'mar. 27 oct. · rappel'**
  String get marOctRappel;

  /// No description provided for @onTePrevientJoursAvant.
  ///
  /// In fr, this message translates to:
  /// **'On te prévient 3 jours avant, par notification et email'**
  String get onTePrevientJoursAvant;

  /// No description provided for @venOct1erPrelevement.
  ///
  /// In fr, this message translates to:
  /// **'ven. 30 oct. · 1er prélèvement'**
  String get venOct1erPrelevement;

  /// No description provided for @surTaCartePuisChaque.
  ///
  /// In fr, this message translates to:
  /// **'Sur ta carte, puis chaque année le 30 oct.'**
  String get surTaCartePuisChaque;

  /// No description provided for @surTaCartePuisChaque2.
  ///
  /// In fr, this message translates to:
  /// **'Sur ta carte, puis chaque mois le 30'**
  String get surTaCartePuisChaque2;

  /// No description provided for @aPayerAujourdHui.
  ///
  /// In fr, this message translates to:
  /// **'À payer aujourd’hui'**
  String get aPayerAujourdHui;

  /// No description provided for @cartePourApresLEssai.
  ///
  /// In fr, this message translates to:
  /// **'Carte pour après l’essai'**
  String get cartePourApresLEssai;

  /// No description provided for @rienNEstDebiteAujourd.
  ///
  /// In fr, this message translates to:
  /// **'Rien n’est débité aujourd’hui : ta banque peut juste afficher une vérification à 0 DT.'**
  String get rienNEstDebiteAujourd;

  /// No description provided for @cetteCarteExpireAvantTon.
  ///
  /// In fr, this message translates to:
  /// **'Cette carte expire avant ton 2e prélèvement'**
  String get cetteCarteExpireAvantTon;

  /// No description provided for @leNovLePaiementEchouerait.
  ///
  /// In fr, this message translates to:
  /// **'Le 30 nov., le paiement échouerait. Choisis ta Visa ou mets cette carte à jour.'**
  String get leNovLePaiementEchouerait;

  /// No description provided for @resiliableAToutMoment.
  ///
  /// In fr, this message translates to:
  /// **'Résiliable à tout moment'**
  String get resiliableAToutMoment;

  /// No description provided for @enEtapesDepuisTonCompte.
  ///
  /// In fr, this message translates to:
  /// **' en 2 étapes depuis ton compte, sans frais.'**
  String get enEtapesDepuisTonCompte;

  /// No description provided for @rappelJoursAvant.
  ///
  /// In fr, this message translates to:
  /// **'Rappel 3 jours avant'**
  String get rappelJoursAvant;

  /// No description provided for @lePremierPrelevementTuAs.
  ///
  /// In fr, this message translates to:
  /// **' le premier prélèvement : tu as le temps de décider.'**
  String get lePremierPrelevementTuAs;

  /// No description provided for @jAccepteLesConditionsD2.
  ///
  /// In fr, this message translates to:
  /// **'J’accepte les conditions d’abonnement'**
  String get jAccepteLesConditionsD2;

  /// No description provided for @jAutoriseMatchupAPrelever.
  ///
  /// In fr, this message translates to:
  /// **'J’autorise MatchUp à prélever {p0} {p1} sur ma {p2} à partir du ven. 30 oct. 2026, jusqu’à ce que je résilie.'**
  String jAutoriseMatchupAPrelever(Object p0, Object p1, Object p2);

  /// No description provided for @cocheCetteCasePourDemarrer.
  ///
  /// In fr, this message translates to:
  /// **'Coche cette case pour démarrer l’essai.'**
  String get cocheCetteCasePourDemarrer;

  /// No description provided for @commencerLEssaiGratuit.
  ///
  /// In fr, this message translates to:
  /// **'Commencer l’essai gratuit'**
  String get commencerLEssaiGratuit;

  /// No description provided for @puisDesLeVenOct.
  ///
  /// In fr, this message translates to:
  /// **'Puis {p0} dès le ven. 30 oct. · résiliable à tout moment'**
  String puisDesLeVenOct(Object p0);

  /// No description provided for @essaiActive.
  ///
  /// In fr, this message translates to:
  /// **'Essai activé'**
  String get essaiActive;

  /// No description provided for @matchupPremium2.
  ///
  /// In fr, this message translates to:
  /// **'MATCHUP PREMIUM'**
  String get matchupPremium2;

  /// No description provided for @bienvenueDansPremium.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans Premium, {p0} !'**
  String bienvenueDansPremium(Object p0);

  /// No description provided for @toutEstDebloqueJusquAu.
  ///
  /// In fr, this message translates to:
  /// **'Tout est débloqué jusqu’au '**
  String get toutEstDebloqueJusquAu;

  /// No description provided for @ceQuiChangeDesMaintenant.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui change dès maintenant'**
  String get ceQuiChangeDesMaintenant;

  /// No description provided for @quandUnePlaceSeLibere.
  ///
  /// In fr, this message translates to:
  /// **'Quand une place se libère, tu es prévenu avant les autres.'**
  String get quandUnePlaceSeLibere;

  /// No description provided for @plansDEntrainement.
  ///
  /// In fr, this message translates to:
  /// **'Plans d’entraînement'**
  String get plansDEntrainement;

  /// No description provided for @unPlanParSemaineSelon.
  ///
  /// In fr, this message translates to:
  /// **'Un plan par semaine selon ton niveau padel {p0} et tes dispos. Tu l’ajustes quand tu veux.'**
  String unPlanParSemaineSelon(Object p0);

  /// No description provided for @plusBesoinDeLesAcheter.
  ///
  /// In fr, this message translates to:
  /// **'Plus besoin de les acheter un par un.'**
  String get plusBesoinDeLesAcheter;

  /// No description provided for @tendancesMeilleursCoequipiersHistoriqueC.
  ///
  /// In fr, this message translates to:
  /// **'Tendances, meilleurs coéquipiers, historique complet de tes 50 matchs.'**
  String get tendancesMeilleursCoequipiersHistoriqueC;

  /// No description provided for @surToutesTesReservationsEt.
  ///
  /// In fr, this message translates to:
  /// **'Sur toutes tes réservations et tes parts.'**
  String get surToutesTesReservationsEt;

  /// No description provided for @tonAbonnement.
  ///
  /// In fr, this message translates to:
  /// **'Ton abonnement'**
  String get tonAbonnement;

  /// No description provided for @essaiGratuit.
  ///
  /// In fr, this message translates to:
  /// **'Essai gratuit'**
  String get essaiGratuit;

  /// No description provided for @jusquAu2.
  ///
  /// In fr, this message translates to:
  /// **'jusqu’au {p0}'**
  String jusquAu2(Object p0);

  /// No description provided for @rappel.
  ///
  /// In fr, this message translates to:
  /// **'Rappel'**
  String get rappel;

  /// No description provided for @decouvrirPremium.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir Premium'**
  String get decouvrirPremium;

  /// No description provided for @offreGratuitApresLe.
  ///
  /// In fr, this message translates to:
  /// **'Offre Gratuit après le {p0} {p1}'**
  String offreGratuitApresLe(Object p0, Object p1);

  /// No description provided for @leOct2.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, le 30 oct.'**
  String leOct2(Object p0);

  /// No description provided for @le2.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, le 30'**
  String le2(Object p0);

  /// No description provided for @joueur2.
  ///
  /// In fr, this message translates to:
  /// **'Joueur · {p0}'**
  String joueur2(Object p0);

  /// No description provided for @resilie.
  ///
  /// In fr, this message translates to:
  /// **'Résilié'**
  String get resilie;

  /// No description provided for @premiumActif.
  ///
  /// In fr, this message translates to:
  /// **'Premium actif'**
  String get premiumActif;

  /// No description provided for @joursDEssaiRestants.
  ///
  /// In fr, this message translates to:
  /// **'{p0} jours d’essai restants'**
  String joursDEssaiRestants(Object p0);

  /// No description provided for @prochainPrelevement.
  ///
  /// In fr, this message translates to:
  /// **'Prochain prélèvement'**
  String get prochainPrelevement;

  /// No description provided for @voirLesAvantages.
  ///
  /// In fr, this message translates to:
  /// **'Voir les avantages'**
  String get voirLesAvantages;

  /// No description provided for @rappelLe.
  ///
  /// In fr, this message translates to:
  /// **'Rappel le {p0}'**
  String rappelLe(Object p0);

  /// No description provided for @onTePrevientJoursAvant2.
  ///
  /// In fr, this message translates to:
  /// **'On te prévient 3 jours avant le premier prélèvement, par notification et email.'**
  String get onTePrevientJoursAvant2;

  /// No description provided for @moyensDePaiement.
  ///
  /// In fr, this message translates to:
  /// **'Moyens de paiement'**
  String get moyensDePaiement;

  /// No description provided for @mettreAJourLaCarte.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour la carte'**
  String get mettreAJourLaCarte;

  /// No description provided for @expire2.
  ///
  /// In fr, this message translates to:
  /// **'Expire {p0}{p1}'**
  String expire2(Object p0, Object p1);

  /// No description provided for @facturesEtRecus.
  ///
  /// In fr, this message translates to:
  /// **'Factures et reçus'**
  String get facturesEtRecus;

  /// No description provided for @recu3.
  ///
  /// In fr, this message translates to:
  /// **'Reçu · {p0} {p1} · {p2}'**
  String recu3(Object p0, Object p1, Object p2);

  /// No description provided for @telechargerLeRecuPdf.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le reçu PDF, {p0}, {p1} {p2}'**
  String telechargerLeRecuPdf(Object p0, Object p1, Object p2);

  /// No description provided for @pdf.
  ///
  /// In fr, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @taPremiereFacturePremiumArrivera.
  ///
  /// In fr, this message translates to:
  /// **'Ta première facture Premium arrivera le {p0}, avec le prélèvement.'**
  String taPremiereFacturePremiumArrivera(Object p0);

  /// No description provided for @enEtapesSansFraisSi.
  ///
  /// In fr, this message translates to:
  /// **'En 2 étapes, sans frais. Si tu résilies pendant l’essai, tu gardes Premium jusqu’au {p0} et rien n’est prélevé.'**
  String enEtapesSansFraisSi(Object p0);

  /// No description provided for @resilierLAbonnement.
  ///
  /// In fr, this message translates to:
  /// **'Résilier l’abonnement'**
  String get resilierLAbonnement;

  /// No description provided for @fermerLeDetailDuCreneau.
  ///
  /// In fr, this message translates to:
  /// **'Fermer le détail du créneau'**
  String get fermerLeDetailDuCreneau;

  /// No description provided for @vestiaires.
  ///
  /// In fr, this message translates to:
  /// **'Vestiaires'**
  String get vestiaires;

  /// No description provided for @heureDePointe2.
  ///
  /// In fr, this message translates to:
  /// **'Heure de pointe'**
  String get heureDePointe2;

  /// No description provided for @heureCreuse.
  ///
  /// In fr, this message translates to:
  /// **'Heure creuse'**
  String get heureCreuse;

  /// No description provided for @parPersonne.
  ///
  /// In fr, this message translates to:
  /// **'Par personne'**
  String get parPersonne;

  /// No description provided for @aJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'à {p0} joueurs'**
  String aJoueurs(Object p0);

  /// No description provided for @annulationGratuiteJusquAu.
  ///
  /// In fr, this message translates to:
  /// **'Annulation gratuite jusqu’au '**
  String get annulationGratuiteJusquAu;

  /// No description provided for @terrainIntrouvable.
  ///
  /// In fr, this message translates to:
  /// **'Terrain introuvable'**
  String get terrainIntrouvable;

  /// No description provided for @ilNExistePlusOu.
  ///
  /// In fr, this message translates to:
  /// **'Il n’existe plus ou le lien est incomplet.'**
  String get ilNExistePlusOu;

  /// No description provided for @chargementDuTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du terrain'**
  String get chargementDuTerrain;

  /// No description provided for @tousLesJours.
  ///
  /// In fr, this message translates to:
  /// **'{p0} – {p1} tous les jours'**
  String tousLesJours(Object p0, Object p1);

  /// No description provided for @photoDe.
  ///
  /// In fr, this message translates to:
  /// **'Photo de {p0}'**
  String photoDe(Object p0);

  /// No description provided for @partagerLeTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Partager le terrain'**
  String get partagerLeTerrain;

  /// No description provided for @surMatchupHttpsMatchupTn.
  ///
  /// In fr, this message translates to:
  /// **'{p0} sur MatchUp : https://matchup.tn/t/{p1}'**
  String surMatchupHttpsMatchupTn(Object p0, Object p1);

  /// No description provided for @ajouterAuxFavoris.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get ajouterAuxFavoris;

  /// No description provided for @photoSur.
  ///
  /// In fr, this message translates to:
  /// **'Photo 1 sur {p0}'**
  String photoSur(Object p0);

  /// No description provided for @terrainVerifie.
  ///
  /// In fr, this message translates to:
  /// **'Terrain vérifié'**
  String get terrainVerifie;

  /// No description provided for @ouvert.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert'**
  String get ouvert;

  /// No description provided for @ferme2.
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get ferme2;

  /// No description provided for @parJoueur.
  ///
  /// In fr, this message translates to:
  /// **'Par joueur'**
  String get parJoueur;

  /// No description provided for @choisisTonCreneau.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton créneau'**
  String get choisisTonCreneau;

  /// No description provided for @aJoueurs2.
  ///
  /// In fr, this message translates to:
  /// **'À {p0} joueurs : '**
  String aJoueurs2(Object p0);

  /// No description provided for @deHAHAvant.
  ///
  /// In fr, this message translates to:
  /// **' de {p0}h à {p1}h · {p2} avant.'**
  String deHAHAvant(Object p0, Object p1, Object p2);

  /// No description provided for @autresTerrains.
  ///
  /// In fr, this message translates to:
  /// **'+ {p0} autres terrains'**
  String autresTerrains(Object p0);

  /// No description provided for @kmDeToi.
  ///
  /// In fr, this message translates to:
  /// **'{p0} km de toi'**
  String kmDeToi(Object p0);

  /// No description provided for @annulationEtRemboursement.
  ///
  /// In fr, this message translates to:
  /// **'Annulation et remboursement'**
  String get annulationEtRemboursement;

  /// No description provided for @sur2.
  ///
  /// In fr, this message translates to:
  /// **'sur 5'**
  String get sur2;

  /// No description provided for @voirLesAvis.
  ///
  /// In fr, this message translates to:
  /// **'Voir les {p0} avis'**
  String voirLesAvis(Object p0);

  /// No description provided for @des.
  ///
  /// In fr, this message translates to:
  /// **'dès '**
  String get des;

  /// No description provided for @dtLeTerrainA.
  ///
  /// In fr, this message translates to:
  /// **'{p0} DT le terrain · {p1} · à {p2}'**
  String dtLeTerrainA(Object p0, Object p1, Object p2);

  /// No description provided for @reserver.
  ///
  /// In fr, this message translates to:
  /// **'Réserver'**
  String get reserver;

  /// No description provided for @impossibleDeChargerLesCreneaux.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les créneaux.'**
  String get impossibleDeChargerLesCreneaux;

  /// No description provided for @chargementDesCreneaux.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des créneaux'**
  String get chargementDesCreneaux;

  /// No description provided for @aucunCreneauCeJourLa.
  ///
  /// In fr, this message translates to:
  /// **'Aucun créneau ce jour-là'**
  String get aucunCreneauCeJourLa;

  /// No description provided for @voirDemain.
  ///
  /// In fr, this message translates to:
  /// **'Voir demain'**
  String get voirDemain;

  /// No description provided for @prixDuTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Prix du terrain / {p0}'**
  String prixDuTerrain(Object p0);

  /// No description provided for @creneaux2.
  ///
  /// In fr, this message translates to:
  /// **'Créneaux {p0}, {p1}'**
  String creneaux2(Object p0, Object p1);

  /// No description provided for @ouvrirLeCalendrier.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le calendrier'**
  String get ouvrirLeCalendrier;

  /// No description provided for @jourDeReservation.
  ///
  /// In fr, this message translates to:
  /// **'Jour de réservation'**
  String get jourDeReservation;

  /// No description provided for @touteLaJournee.
  ///
  /// In fr, this message translates to:
  /// **'Toute la journée'**
  String get touteLaJournee;

  /// No description provided for @gratuiteJusquAHAvant.
  ///
  /// In fr, this message translates to:
  /// **'Gratuite jusqu’à 24 h avant'**
  String get gratuiteJusquAHAvant;

  /// No description provided for @gratuitJusquAu.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit jusqu’au {p0}'**
  String gratuitJusquAu(Object p0);

  /// No description provided for @remboursesEntreHEtH.
  ///
  /// In fr, this message translates to:
  /// **'50 % remboursés entre 24 h et 6 h avant'**
  String get remboursesEntreHEtH;

  /// No description provided for @laMoitieDeTaPart.
  ///
  /// In fr, this message translates to:
  /// **'La moitié de ta part te revient'**
  String get laMoitieDeTaPart;

  /// No description provided for @nonRemboursableMoinsDeH.
  ///
  /// In fr, this message translates to:
  /// **'Non remboursable moins de 6 h avant'**
  String get nonRemboursableMoinsDeH;

  /// No description provided for @onRevientVersToiSous.
  ///
  /// In fr, this message translates to:
  /// **'On revient vers toi sous 5 jours ouvrés.'**
  String get onRevientVersToiSous;

  /// No description provided for @demanderUnRemboursement.
  ///
  /// In fr, this message translates to:
  /// **'Demander un remboursement'**
  String get demanderUnRemboursement;

  /// No description provided for @retourAuPortefeuille.
  ///
  /// In fr, this message translates to:
  /// **'Retour au portefeuille'**
  String get retourAuPortefeuille;

  /// No description provided for @unSouciAvecUnPaiement.
  ///
  /// In fr, this message translates to:
  /// **'Un souci avec un paiement ? Dis-nous ce qui s’est passé : on vérifie avec le terrain, puis on te rembourse.'**
  String get unSouciAvecUnPaiement;

  /// No description provided for @quelPaiement.
  ///
  /// In fr, this message translates to:
  /// **'Quel paiement ?'**
  String get quelPaiement;

  /// No description provided for @unePartieAVenirAnnule.
  ///
  /// In fr, this message translates to:
  /// **'Une partie à venir ? Annule ta place depuis '**
  String get unePartieAVenirAnnule;

  /// No description provided for @leRemboursementEstAutomatique.
  ///
  /// In fr, this message translates to:
  /// **' : le remboursement est automatique.'**
  String get leRemboursementEstAutomatique;

  /// No description provided for @queSEstIlPasse.
  ///
  /// In fr, this message translates to:
  /// **'Que s’est-il passé ?'**
  String get queSEstIlPasse;

  /// No description provided for @expliqueEnQuelquesMots.
  ///
  /// In fr, this message translates to:
  /// **'Explique en quelques mots'**
  String get expliqueEnQuelquesMots;

  /// No description provided for @photo.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @ajouteUnePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute une photo'**
  String get ajouteUnePhoto;

  /// No description provided for @jpgPngMoMax.
  ///
  /// In fr, this message translates to:
  /// **'JPG, PNG · 10 Mo max'**
  String get jpgPngMoMax;

  /// No description provided for @unePhotoDuTerrainFerme.
  ///
  /// In fr, this message translates to:
  /// **'Une photo du terrain fermé aide à traiter ta demande plus vite.'**
  String get unePhotoDuTerrainFerme;

  /// No description provided for @ouVeuxTuEtreRembourse.
  ///
  /// In fr, this message translates to:
  /// **'Où veux-tu être remboursé ?'**
  String get ouVeuxTuEtreRembourse;

  /// No description provided for @destination.
  ///
  /// In fr, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @surMonSoldeMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Sur mon solde MatchUp'**
  String get surMonSoldeMatchup;

  /// No description provided for @plusRapideSousJoursOuvres.
  ///
  /// In fr, this message translates to:
  /// **'Plus rapide · sous 5 jours ouvrés au plus tard, utilisable dès réception.'**
  String get plusRapideSousJoursOuvres;

  /// No description provided for @surMaCarte.
  ///
  /// In fr, this message translates to:
  /// **'Sur ma carte {p0}'**
  String surMaCarte(Object p0);

  /// No description provided for @aJoursOuvresSelonTa.
  ///
  /// In fr, this message translates to:
  /// **'5 à 10 jours ouvrés, selon ta banque.'**
  String get aJoursOuvresSelonTa;

  /// No description provided for @montantDemande.
  ///
  /// In fr, this message translates to:
  /// **'Montant demandé · {p0}'**
  String montantDemande(Object p0);

  /// No description provided for @envoyerLaDemande.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la demande'**
  String get envoyerLaDemande;

  /// No description provided for @suiviDuRemboursement.
  ///
  /// In fr, this message translates to:
  /// **'Suivi du remboursement'**
  String get suiviDuRemboursement;

  /// No description provided for @demandeDeRemboursement.
  ///
  /// In fr, this message translates to:
  /// **'Demande de remboursement'**
  String get demandeDeRemboursement;

  /// No description provided for @aRembourser.
  ///
  /// In fr, this message translates to:
  /// **'À rembourser'**
  String get aRembourser;

  /// No description provided for @ouEnEstTaDemande.
  ///
  /// In fr, this message translates to:
  /// **'Où en est ta demande ?'**
  String get ouEnEstTaDemande;

  /// No description provided for @enCoursDExamen.
  ///
  /// In fr, this message translates to:
  /// **'En cours d’examen'**
  String get enCoursDExamen;

  /// No description provided for @envoyee.
  ///
  /// In fr, this message translates to:
  /// **'Envoyée'**
  String get envoyee;

  /// No description provided for @motifRecus.
  ///
  /// In fr, this message translates to:
  /// **'Motif{p0} reçus.'**
  String motifRecus(Object p0);

  /// No description provided for @onVerifieAvecQueLe.
  ///
  /// In fr, this message translates to:
  /// **'On vérifie avec {p0} que le terrain était fermé. Tu n’as rien à faire.'**
  String onVerifieAvecQueLe(Object p0);

  /// No description provided for @rembourseSurTonSolde.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé sur ton solde'**
  String get rembourseSurTonSolde;

  /// No description provided for @rembourseSurTaCarte.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé sur ta carte'**
  String get rembourseSurTaCarte;

  /// No description provided for @attenduSousJoursOuvres.
  ///
  /// In fr, this message translates to:
  /// **'Attendu sous {p0} jours ouvrés · +{p1}'**
  String attenduSousJoursOuvres(Object p0, Object p1);

  /// No description provided for @etEnsuite.
  ///
  /// In fr, this message translates to:
  /// **'Et ensuite ?'**
  String get etEnsuite;

  /// No description provided for @demandeAcceptee.
  ///
  /// In fr, this message translates to:
  /// **'Demande acceptée'**
  String get demandeAcceptee;

  /// No description provided for @arriventSurTonSoldeMatchup.
  ///
  /// In fr, this message translates to:
  /// **'{p0} arrivent sur ton solde MatchUp : ton solde passera à {p1}. On te prévient par notification.'**
  String arriventSurTonSoldeMatchup(Object p0, Object p1);

  /// No description provided for @besoinDUnePrecision.
  ///
  /// In fr, this message translates to:
  /// **'Besoin d’une précision'**
  String get besoinDUnePrecision;

  /// No description provided for @onTEcritIciEt.
  ///
  /// In fr, this message translates to:
  /// **'On t’écrit ici et par email. Ta réponse relance l’examen.'**
  String get onTEcritIciEt;

  /// No description provided for @demandeRefusee.
  ///
  /// In fr, this message translates to:
  /// **'Demande refusée'**
  String get demandeRefusee;

  /// No description provided for @onTExpliquePourquoiEt.
  ///
  /// In fr, this message translates to:
  /// **'On t’explique pourquoi, et tu peux contester auprès du support.'**
  String get onTExpliquePourquoiEt;

  /// No description provided for @taDemande.
  ///
  /// In fr, this message translates to:
  /// **'Ta demande'**
  String get taDemande;

  /// No description provided for @motif.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get motif;

  /// No description provided for @photoJointe.
  ///
  /// In fr, this message translates to:
  /// **'{p0} photo{p1} jointe{p2}'**
  String photoJointe(Object p0, Object p1, Object p2);

  /// No description provided for @vers.
  ///
  /// In fr, this message translates to:
  /// **'Vers'**
  String get vers;

  /// No description provided for @uneQuestionSurTaDemande.
  ///
  /// In fr, this message translates to:
  /// **'Une question sur ta demande ?'**
  String get uneQuestionSurTaDemande;

  /// No description provided for @lEquipeMatchupTeRepond.
  ///
  /// In fr, this message translates to:
  /// **'L’équipe MatchUp te répond par message, 7 j/7.'**
  String get lEquipeMatchupTeRepond;

  /// No description provided for @portefeuilleMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Portefeuille MatchUp'**
  String get portefeuilleMatchup;

  /// No description provided for @rechargeDuSolde.
  ///
  /// In fr, this message translates to:
  /// **'Recharge du solde · {p0}'**
  String rechargeDuSolde(Object p0);

  /// No description provided for @crediteDesLePaiementSans.
  ///
  /// In fr, this message translates to:
  /// **'Crédité dès le paiement · sans frais'**
  String get crediteDesLePaiementSans;

  /// No description provided for @rechargeDuSolde2.
  ///
  /// In fr, this message translates to:
  /// **'Recharge du solde'**
  String get rechargeDuSolde2;

  /// No description provided for @soldeActuel.
  ///
  /// In fr, this message translates to:
  /// **'Solde actuel'**
  String get soldeActuel;

  /// No description provided for @recharge.
  ///
  /// In fr, this message translates to:
  /// **'Recharge'**
  String get recharge;

  /// No description provided for @nouveauSolde.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau solde'**
  String get nouveauSolde;

  /// No description provided for @disponibleToutDeSuite.
  ///
  /// In fr, this message translates to:
  /// **'Disponible tout de suite'**
  String get disponibleToutDeSuite;

  /// No description provided for @tonSoldePasseDeA.
  ///
  /// In fr, this message translates to:
  /// **'Ton solde passe de {p0} à {p1} dès que le paiement est accepté.'**
  String tonSoldePasseDeA(Object p0, Object p1);

  /// No description provided for @tonSoldeNExpirePas.
  ///
  /// In fr, this message translates to:
  /// **'Ton solde n’expire pas'**
  String get tonSoldeNExpirePas;

  /// No description provided for @ilSertPourTesParts.
  ///
  /// In fr, this message translates to:
  /// **'Il sert pour tes parts, réservations et inscriptions aux tournois.'**
  String get ilSertPourTesParts;

  /// No description provided for @recuParEmail.
  ///
  /// In fr, this message translates to:
  /// **'Reçu par email'**
  String get recuParEmail;

  /// No description provided for @envoyeAEtDisponibleDans.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé à {p0} et disponible dans ton portefeuille.'**
  String envoyeAEtDisponibleDans(Object p0);

  /// No description provided for @conditionsDuSoldeMatchup.
  ///
  /// In fr, this message translates to:
  /// **'conditions du solde MatchUp'**
  String get conditionsDuSoldeMatchup;

  /// No description provided for @rechargerMonSolde.
  ///
  /// In fr, this message translates to:
  /// **'Recharger mon solde'**
  String get rechargerMonSolde;

  /// No description provided for @combienVeuxTuAjouter.
  ///
  /// In fr, this message translates to:
  /// **'Combien veux-tu ajouter ?'**
  String get combienVeuxTuAjouter;

  /// No description provided for @solde.
  ///
  /// In fr, this message translates to:
  /// **'Solde '**
  String get solde;

  /// No description provided for @apresRecharge.
  ///
  /// In fr, this message translates to:
  /// **'après recharge '**
  String get apresRecharge;

  /// No description provided for @autreMontant.
  ///
  /// In fr, this message translates to:
  /// **'Autre montant'**
  String get autreMontant;

  /// No description provided for @entreEtDt.
  ///
  /// In fr, this message translates to:
  /// **'Entre {p0} et {p1} DT'**
  String entreEtDt(Object p0, Object p1);

  /// No description provided for @parDefautExpire2.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut · expire {p0}'**
  String parDefautExpire2(Object p0);

  /// No description provided for @pourquoiRecharger.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi recharger'**
  String get pourquoiRecharger;

  /// No description provided for @taPartPayeeEnUn.
  ///
  /// In fr, this message translates to:
  /// **'Ta part payée en un tap'**
  String get taPartPayeeEnUn;

  /// No description provided for @sansRessortirTaCarteA.
  ///
  /// In fr, this message translates to:
  /// **'Sans ressortir ta carte à chaque partie.'**
  String get sansRessortirTaCarteA;

  /// No description provided for @remboursementsPlusRapides.
  ///
  /// In fr, this message translates to:
  /// **'Remboursements plus rapides'**
  String get remboursementsPlusRapides;

  /// No description provided for @ilsArriventSurTonSolde.
  ///
  /// In fr, this message translates to:
  /// **'Ils arrivent sur ton solde plutôt qu’en 5 à 10 jours sur ta carte.'**
  String get ilsArriventSurTonSolde;

  /// No description provided for @aucunFraisDeRecharge.
  ///
  /// In fr, this message translates to:
  /// **'Aucun frais de recharge'**
  String get aucunFraisDeRecharge;

  /// No description provided for @tuPaiesExactementLeMontant.
  ///
  /// In fr, this message translates to:
  /// **'Tu paies exactement le montant choisi.'**
  String get tuPaiesExactementLeMontant;

  /// No description provided for @retourAuMenuDuCompte.
  ///
  /// In fr, this message translates to:
  /// **'Retour au menu du compte'**
  String get retourAuMenuDuCompte;

  /// No description provided for @soldeMatchup3.
  ///
  /// In fr, this message translates to:
  /// **'Solde MatchUp : {p0}'**
  String soldeMatchup3(Object p0);

  /// No description provided for @soldeMatchup4.
  ///
  /// In fr, this message translates to:
  /// **'SOLDE MATCHUP'**
  String get soldeMatchup4;

  /// No description provided for @paieTesPartsEnUn.
  ///
  /// In fr, this message translates to:
  /// **'Paie tes parts en un tap. Tes remboursements arrivent ici.'**
  String get paieTesPartsEnUn;

  /// No description provided for @recharger.
  ///
  /// In fr, this message translates to:
  /// **'Recharger'**
  String get recharger;

  /// No description provided for @remboursementDemande.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement demandé · {p0}'**
  String remboursementDemande(Object p0);

  /// No description provided for @terrainFermeMatchAnnule.
  ///
  /// In fr, this message translates to:
  /// **'Terrain fermé, match annulé…'**
  String get terrainFermeMatchAnnule;

  /// No description provided for @historique.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get historique;

  /// No description provided for @lesPaiementsParCarteSont.
  ///
  /// In fr, this message translates to:
  /// **'Les paiements par carte sont listés pour ton suivi, sans toucher à ton solde.'**
  String get lesPaiementsParCarteSont;

  /// No description provided for @filtrerLHistorique.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer l’historique'**
  String get filtrerLHistorique;

  /// No description provided for @remboursements.
  ///
  /// In fr, this message translates to:
  /// **'Remboursements'**
  String get remboursements;

  /// No description provided for @recharges.
  ///
  /// In fr, this message translates to:
  /// **'Recharges'**
  String get recharges;

  /// No description provided for @rienDansCetteCategorie.
  ///
  /// In fr, this message translates to:
  /// **'Rien dans cette catégorie'**
  String get rienDansCetteCategorie;

  /// No description provided for @cEstToutTonHistorique.
  ///
  /// In fr, this message translates to:
  /// **'C’est tout ton historique.'**
  String get cEstToutTonHistorique;

  /// No description provided for @janvier.
  ///
  /// In fr, this message translates to:
  /// **'Janvier'**
  String get janvier;

  /// No description provided for @fevrier2.
  ///
  /// In fr, this message translates to:
  /// **'Février'**
  String get fevrier2;

  /// No description provided for @mars2.
  ///
  /// In fr, this message translates to:
  /// **'Mars'**
  String get mars2;

  /// No description provided for @avril.
  ///
  /// In fr, this message translates to:
  /// **'Avril'**
  String get avril;

  /// No description provided for @mai.
  ///
  /// In fr, this message translates to:
  /// **'Mai'**
  String get mai;

  /// No description provided for @juin.
  ///
  /// In fr, this message translates to:
  /// **'Juin'**
  String get juin;

  /// No description provided for @juillet.
  ///
  /// In fr, this message translates to:
  /// **'Juillet'**
  String get juillet;

  /// No description provided for @aout2.
  ///
  /// In fr, this message translates to:
  /// **'Août'**
  String get aout2;

  /// No description provided for @septembre.
  ///
  /// In fr, this message translates to:
  /// **'Septembre'**
  String get septembre;

  /// No description provided for @octobre.
  ///
  /// In fr, this message translates to:
  /// **'Octobre'**
  String get octobre;

  /// No description provided for @novembre.
  ///
  /// In fr, this message translates to:
  /// **'Novembre'**
  String get novembre;

  /// No description provided for @decembre2.
  ///
  /// In fr, this message translates to:
  /// **'Décembre'**
  String get decembre2;

  /// No description provided for @entrainement.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement'**
  String get entrainement;

  /// No description provided for @communaute.
  ///
  /// In fr, this message translates to:
  /// **'Communauté'**
  String get communaute;

  /// No description provided for @genereParLIa.
  ///
  /// In fr, this message translates to:
  /// **'Généré par l’IA'**
  String get genereParLIa;

  /// No description provided for @recommandeCar.
  ///
  /// In fr, this message translates to:
  /// **'Recommandé car'**
  String get recommandeCar;

  /// No description provided for @suggestionMasquee.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion masquée'**
  String get suggestionMasquee;

  /// No description provided for @suggestionUtile.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion utile'**
  String get suggestionUtile;

  /// No description provided for @suggestionPasUtile.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion pas utile'**
  String get suggestionPasUtile;

  /// No description provided for @merciPourTonRetour.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour ton retour'**
  String get merciPourTonRetour;

  /// No description provided for @masquerLaSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Masquer la suggestion'**
  String get masquerLaSuggestion;

  /// No description provided for @enLigne.
  ///
  /// In fr, this message translates to:
  /// **'en ligne'**
  String get enLigne;

  /// No description provided for @masquer.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get masquer;

  /// No description provided for @confirmePaye.
  ///
  /// In fr, this message translates to:
  /// **'confirmé, payé'**
  String get confirmePaye;

  /// No description provided for @enAttenteDePaiement.
  ///
  /// In fr, this message translates to:
  /// **'en attente de paiement'**
  String get enAttenteDePaiement;

  /// No description provided for @termine2.
  ///
  /// In fr, this message translates to:
  /// **'terminé'**
  String get termine2;

  /// No description provided for @annule.
  ///
  /// In fr, this message translates to:
  /// **'annulé'**
  String get annule;

  /// No description provided for @taPart6.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1}, {p2}, {p3}, {p4}, {p5}, ta part {p6}'**
  String taPart6(
    Object p0,
    Object p1,
    Object p2,
    Object p3,
    Object p4,
    Object p5,
    Object p6,
  );

  /// No description provided for @surTonSolde.
  ///
  /// In fr, this message translates to:
  /// **'sur ton solde'**
  String get surTonSolde;

  /// No description provided for @aPayer2.
  ///
  /// In fr, this message translates to:
  /// **'À payer'**
  String get aPayer2;

  /// No description provided for @aPayerAvant.
  ///
  /// In fr, this message translates to:
  /// **'À payer avant {p0}'**
  String aPayerAvant(Object p0);

  /// No description provided for @noterLesJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Noter les joueurs'**
  String get noterLesJoueurs;

  /// No description provided for @reserverANouveau.
  ///
  /// In fr, this message translates to:
  /// **'Réserver à nouveau'**
  String get reserverANouveau;

  /// No description provided for @payes.
  ///
  /// In fr, this message translates to:
  /// **'{p0} payés'**
  String payes(Object p0);

  /// No description provided for @avant.
  ///
  /// In fr, this message translates to:
  /// **'Avant {p0}'**
  String avant(Object p0);

  /// No description provided for @surTonSolde2.
  ///
  /// In fr, this message translates to:
  /// **'+{p0} sur ton solde'**
  String surTonSolde2(Object p0);

  /// No description provided for @agrandirLePanneau.
  ///
  /// In fr, this message translates to:
  /// **'Agrandir le panneau'**
  String get agrandirLePanneau;

  /// No description provided for @reduireLePanneau.
  ///
  /// In fr, this message translates to:
  /// **'Réduire le panneau'**
  String get reduireLePanneau;

  /// No description provided for @auj.
  ///
  /// In fr, this message translates to:
  /// **'Auj.'**
  String get auj;

  /// No description provided for @aujourdHui3.
  ///
  /// In fr, this message translates to:
  /// **', aujourd’hui'**
  String get aujourdHui3;

  /// No description provided for @creneauxDisponibles.
  ///
  /// In fr, this message translates to:
  /// **', créneaux disponibles'**
  String get creneauxDisponibles;

  /// No description provided for @complet3.
  ///
  /// In fr, this message translates to:
  /// **', complet'**
  String get complet3;

  /// No description provided for @ferme3.
  ///
  /// In fr, this message translates to:
  /// **', fermé'**
  String get ferme3;

  /// No description provided for @niveau5.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {p0}, {p1}'**
  String niveau5(Object p0, Object p1);

  /// No description provided for @tempsEcoule.
  ///
  /// In fr, this message translates to:
  /// **'Temps écoulé'**
  String get tempsEcoule;

  /// No description provided for @dansMin.
  ///
  /// In fr, this message translates to:
  /// **'Dans < 1 min'**
  String get dansMin;

  /// No description provided for @dansJ.
  ///
  /// In fr, this message translates to:
  /// **'Dans {p0} j{p1}'**
  String dansJ(Object p0, Object p1);

  /// No description provided for @dansHMin.
  ///
  /// In fr, this message translates to:
  /// **'Dans {p0} h {p1} min'**
  String dansHMin(Object p0, Object p1);

  /// No description provided for @dansMin2.
  ///
  /// In fr, this message translates to:
  /// **'Dans {p0} min'**
  String dansMin2(Object p0);

  /// No description provided for @tempsRestant.
  ///
  /// In fr, this message translates to:
  /// **'Temps restant'**
  String get tempsRestant;

  /// No description provided for @moinsDUneMinute.
  ///
  /// In fr, this message translates to:
  /// **'moins d’une minute'**
  String get moinsDUneMinute;

  /// No description provided for @demandeAMatchup2.
  ///
  /// In fr, this message translates to:
  /// **'Demande à MatchUp'**
  String get demandeAMatchup2;

  /// No description provided for @assistantMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Assistant MatchUp'**
  String get assistantMatchup;

  /// No description provided for @mo.
  ///
  /// In fr, this message translates to:
  /// **'{p0} Mo'**
  String mo(Object p0);

  /// No description provided for @ko.
  ///
  /// In fr, this message translates to:
  /// **'{p0} Ko'**
  String ko(Object p0);

  /// No description provided for @parcoursTesFichiers.
  ///
  /// In fr, this message translates to:
  /// **'parcours tes fichiers'**
  String get parcoursTesFichiers;

  /// No description provided for @glisseTesPhotosIciOu.
  ///
  /// In fr, this message translates to:
  /// **'Glisse tes photos ici ou parcours tes fichiers'**
  String get glisseTesPhotosIciOu;

  /// No description provided for @changerLaPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get changerLaPhoto;

  /// No description provided for @choisirUnePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une photo'**
  String get choisirUnePhoto;

  /// No description provided for @envoye.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé'**
  String get envoye;

  /// No description provided for @remplacer.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer'**
  String get remplacer;

  /// No description provided for @annulerLEnvoi.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l’envoi'**
  String get annulerLEnvoi;

  /// No description provided for @supprimer3.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer {p0}'**
  String supprimer3(Object p0);

  /// No description provided for @erreur.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get erreur;

  /// No description provided for @couverture2.
  ///
  /// In fr, this message translates to:
  /// **', couverture'**
  String get couverture2;

  /// No description provided for @envoi.
  ///
  /// In fr, this message translates to:
  /// **', envoi {p0} %'**
  String envoi(Object p0);

  /// No description provided for @utiliserCommeCouverture.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser comme couverture'**
  String get utiliserCommeCouverture;

  /// No description provided for @deplacerAvant.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer avant'**
  String get deplacerAvant;

  /// No description provided for @deplacerApres.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer après'**
  String get deplacerApres;

  /// No description provided for @ajouterDesPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des photos'**
  String get ajouterDesPhotos;

  /// No description provided for @placeLibre3.
  ///
  /// In fr, this message translates to:
  /// **'place libre'**
  String get placeLibre3;

  /// No description provided for @placesLibres2.
  ///
  /// In fr, this message translates to:
  /// **'places libres'**
  String get placesLibres2;

  /// No description provided for @parJoueur2.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1}, {p2}, {p3}, {p4} par joueur'**
  String parJoueur2(Object p0, Object p1, Object p2, Object p3, Object p4);

  /// No description provided for @annulee.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get annulee;

  /// No description provided for @tuJoues2.
  ///
  /// In fr, this message translates to:
  /// **'Tu joues'**
  String get tuJoues2;

  /// No description provided for @plusQuePlace.
  ///
  /// In fr, this message translates to:
  /// **'Plus que 1 place'**
  String get plusQuePlace;

  /// No description provided for @voirLaPartie.
  ///
  /// In fr, this message translates to:
  /// **'Voir la partie'**
  String get voirLaPartie;

  /// No description provided for @rejoindre.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get rejoindre;

  /// No description provided for @par.
  ///
  /// In fr, this message translates to:
  /// **'Par '**
  String get par;

  /// No description provided for @fiable.
  ///
  /// In fr, this message translates to:
  /// **' Fiable '**
  String get fiable;

  /// No description provided for @partieAnnulee.
  ///
  /// In fr, this message translates to:
  /// **'Partie annulée'**
  String get partieAnnulee;

  /// No description provided for @rembourseSurTonSolde2.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé {p0} sur ton solde'**
  String rembourseSurTonSolde2(Object p0);

  /// No description provided for @prix.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get prix;

  /// No description provided for @parJoueur3.
  ///
  /// In fr, this message translates to:
  /// **'par joueur'**
  String get parJoueur3;

  /// No description provided for @heureLibresSurParJoueur.
  ///
  /// In fr, this message translates to:
  /// **'Heure {p0}, {p1} libres sur {p2}, {p3} par joueur'**
  String heureLibresSurParJoueur(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @heure.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get heure;

  /// No description provided for @partiesPourToi2.
  ///
  /// In fr, this message translates to:
  /// **'PARTIES POUR TOI'**
  String get partiesPourToi2;

  /// No description provided for @libresSurParJoueur.
  ///
  /// In fr, this message translates to:
  /// **'{p0} libres sur {p1}, {p2} par joueur{p3}'**
  String libresSurParJoueur(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @niveau6.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get niveau6;

  /// No description provided for @pasEncoreDeValeur.
  ///
  /// In fr, this message translates to:
  /// **'pas encore de valeur'**
  String get pasEncoreDeValeur;

  /// No description provided for @sur3.
  ///
  /// In fr, this message translates to:
  /// **'{p0} sur 7, {p1}'**
  String sur3(Object p0, Object p1);

  /// No description provided for @confianceFaible.
  ///
  /// In fr, this message translates to:
  /// **'Confiance faible'**
  String get confianceFaible;

  /// No description provided for @confianceMoyenne.
  ///
  /// In fr, this message translates to:
  /// **'Confiance moyenne'**
  String get confianceMoyenne;

  /// No description provided for @confianceElevee.
  ///
  /// In fr, this message translates to:
  /// **'Confiance élevée'**
  String get confianceElevee;

  /// No description provided for @stable.
  ///
  /// In fr, this message translates to:
  /// **'Stable'**
  String get stable;

  /// No description provided for @stable2.
  ///
  /// In fr, this message translates to:
  /// **', stable'**
  String get stable2;

  /// No description provided for @estimationIa.
  ///
  /// In fr, this message translates to:
  /// **'Estimation IA'**
  String get estimationIa;

  /// No description provided for @dApresTesReponses.
  ///
  /// In fr, this message translates to:
  /// **'d’après tes réponses'**
  String get dApresTesReponses;

  /// No description provided for @estimeParLIa.
  ///
  /// In fr, this message translates to:
  /// **'Estimé par l’IA : {p0} · {p1}'**
  String estimeParLIa(Object p0, Object p1);

  /// No description provided for @revenirA.
  ///
  /// In fr, this message translates to:
  /// **'Revenir à {p0}'**
  String revenirA(Object p0);

  /// No description provided for @pivot.
  ///
  /// In fr, this message translates to:
  /// **'Pivot'**
  String get pivot;

  /// No description provided for @footballContre.
  ///
  /// In fr, this message translates to:
  /// **'Football 5 contre 5'**
  String get footballContre;

  /// No description provided for @padelContre.
  ///
  /// In fr, this message translates to:
  /// **'Padel 2 contre 2'**
  String get padelContre;

  /// No description provided for @basketContre.
  ///
  /// In fr, this message translates to:
  /// **'Basket 3 contre 3'**
  String get basketContre;

  /// No description provided for @joueursSur.
  ///
  /// In fr, this message translates to:
  /// **'{p0} — {p1} joueurs sur {p2}'**
  String joueursSur(Object p0, Object p1, Object p2);

  /// No description provided for @libre.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, libre'**
  String libre(Object p0);

  /// No description provided for @rejoindreCePoste.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre ce poste — {p0}, {p1}'**
  String rejoindreCePoste(Object p0, Object p1);

  /// No description provided for @organisateur2.
  ///
  /// In fr, this message translates to:
  /// **', organisateur'**
  String get organisateur2;

  /// No description provided for @capitaine.
  ///
  /// In fr, this message translates to:
  /// **', capitaine'**
  String get capitaine;

  /// No description provided for @niveau7.
  ///
  /// In fr, this message translates to:
  /// **', niveau {p0}'**
  String niveau7(Object p0);

  /// No description provided for @joueursSur2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} : {p1} joueurs sur {p2}, {p3}'**
  String joueursSur2(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @paiementEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en cours'**
  String get paiementEnCours;

  /// No description provided for @paiementEnCours2.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en cours, {p0}'**
  String paiementEnCours2(Object p0);

  /// No description provided for @paiementEnCours3.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en cours…'**
  String get paiementEnCours3;

  /// No description provided for @neFermePasCettePage2.
  ///
  /// In fr, this message translates to:
  /// **'Ne ferme pas cette page'**
  String get neFermePasCettePage2;

  /// No description provided for @carteDesTerrainsGlissePour.
  ///
  /// In fr, this message translates to:
  /// **'Carte des terrains — glisse pour te déplacer, pince ou utilise + et − pour zoomer'**
  String get carteDesTerrainsGlissePour;

  /// No description provided for @contre.
  ///
  /// In fr, this message translates to:
  /// **'{p0} contre {p1}{p2}, {p3}'**
  String contre(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @enDirect.
  ///
  /// In fr, this message translates to:
  /// **'En direct'**
  String get enDirect;

  /// No description provided for @termine3.
  ///
  /// In fr, this message translates to:
  /// **'TERMINÉ'**
  String get termine3;

  /// No description provided for @vainqueur.
  ///
  /// In fr, this message translates to:
  /// **'Vainqueur'**
  String get vainqueur;

  /// No description provided for @premierAPoints.
  ///
  /// In fr, this message translates to:
  /// **'Premier à {p0} points'**
  String premierAPoints(Object p0);

  /// No description provided for @iaCompatible.
  ///
  /// In fr, this message translates to:
  /// **'IA : {p0} % compatible'**
  String iaCompatible(Object p0);

  /// No description provided for @recommandeCar2.
  ///
  /// In fr, this message translates to:
  /// **'Recommandé car {p0}'**
  String recommandeCar2(Object p0);

  /// No description provided for @compatible.
  ///
  /// In fr, this message translates to:
  /// **'{p0} % compatible'**
  String compatible(Object p0);

  /// No description provided for @enDefaveur.
  ///
  /// In fr, this message translates to:
  /// **'En défaveur'**
  String get enDefaveur;

  /// No description provided for @enFaveur.
  ///
  /// In fr, this message translates to:
  /// **'En faveur'**
  String get enFaveur;

  /// No description provided for @nonLu.
  ///
  /// In fr, this message translates to:
  /// **'Non lu'**
  String get nonLu;

  /// No description provided for @urgent.
  ///
  /// In fr, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @important.
  ///
  /// In fr, this message translates to:
  /// **'Important'**
  String get important;

  /// No description provided for @lu.
  ///
  /// In fr, this message translates to:
  /// **'Lu'**
  String get lu;

  /// No description provided for @chiffreSur.
  ///
  /// In fr, this message translates to:
  /// **'Chiffre {p0} sur {p1}'**
  String chiffreSur(Object p0, Object p1);

  /// No description provided for @verificationDuCode.
  ///
  /// In fr, this message translates to:
  /// **'Vérification du code…'**
  String get verificationDuCode;

  /// No description provided for @renvoyerLeCodeDans.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code dans '**
  String get renvoyerLeCodeDans;

  /// No description provided for @renvoyerLeCode.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get renvoyerLeCode;

  /// No description provided for @caracteresMinimum.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères minimum'**
  String get caracteresMinimum;

  /// No description provided for @uneMajuscule.
  ///
  /// In fr, this message translates to:
  /// **'Une majuscule'**
  String get uneMajuscule;

  /// No description provided for @unChiffre.
  ///
  /// In fr, this message translates to:
  /// **'Un chiffre'**
  String get unChiffre;

  /// No description provided for @masquerLeMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get masquerLeMotDePasse;

  /// No description provided for @afficherLeMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get afficherLeMotDePasse;

  /// No description provided for @faible.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get faible;

  /// No description provided for @moyen.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get moyen;

  /// No description provided for @bon.
  ///
  /// In fr, this message translates to:
  /// **'Bon'**
  String get bon;

  /// No description provided for @excellent.
  ///
  /// In fr, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @securiteDuMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité du mot de passe : {p0}'**
  String securiteDuMotDePasse(Object p0);

  /// No description provided for @aFaire2.
  ///
  /// In fr, this message translates to:
  /// **'à faire'**
  String get aFaire2;

  /// No description provided for @numeroDeTelephone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get numeroDeTelephone;

  /// No description provided for @indicatifTunisie.
  ///
  /// In fr, this message translates to:
  /// **'Indicatif +216, Tunisie'**
  String get indicatifTunisie;

  /// No description provided for @offreChoisie.
  ///
  /// In fr, this message translates to:
  /// **'Offre choisie'**
  String get offreChoisie;

  /// No description provided for @choisir2.
  ///
  /// In fr, this message translates to:
  /// **'Choisir {p0}'**
  String choisir2(Object p0);

  /// No description provided for @pourToujours.
  ///
  /// In fr, this message translates to:
  /// **'pour toujours'**
  String get pourToujours;

  /// No description provided for @populaire.
  ///
  /// In fr, this message translates to:
  /// **', populaire'**
  String get populaire;

  /// No description provided for @populaire2.
  ///
  /// In fr, this message translates to:
  /// **'Populaire'**
  String get populaire2;

  /// No description provided for @soitMois.
  ///
  /// In fr, this message translates to:
  /// **'soit {p0}/mois'**
  String soitMois(Object p0);

  /// No description provided for @joursGratuitsPuisResiliableA2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} jours gratuits, puis {p1} · Résiliable à tout moment'**
  String joursGratuitsPuisResiliableA2(Object p0, Object p1);

  /// No description provided for @nonInclus2.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, non inclus'**
  String nonInclus2(Object p0);

  /// No description provided for @tonOffreActuelle2.
  ///
  /// In fr, this message translates to:
  /// **', ton offre actuelle'**
  String get tonOffreActuelle2;

  /// No description provided for @dontEnAttente.
  ///
  /// In fr, this message translates to:
  /// **', dont {p0} en attente'**
  String dontEnAttente(Object p0);

  /// No description provided for @joueursSurConfirmesEnAttente.
  ///
  /// In fr, this message translates to:
  /// **'{p0} joueurs sur {p1}, {p2} confirmés, {p3} en attente, {p4} libres'**
  String joueursSurConfirmesEnAttente(
    Object p0,
    Object p1,
    Object p2,
    Object p3,
    Object p4,
  );

  /// No description provided for @confirme.
  ///
  /// In fr, this message translates to:
  /// **'confirmé'**
  String get confirme;

  /// No description provided for @confirmes.
  ///
  /// In fr, this message translates to:
  /// **'confirmés'**
  String get confirmes;

  /// No description provided for @maximum.
  ///
  /// In fr, this message translates to:
  /// **'Maximum'**
  String get maximum;

  /// No description provided for @minimum.
  ///
  /// In fr, this message translates to:
  /// **'Minimum'**
  String get minimum;

  /// No description provided for @fiable2.
  ///
  /// In fr, this message translates to:
  /// **'Fiable {p0} %'**
  String fiable2(Object p0);

  /// No description provided for @fiable3.
  ///
  /// In fr, this message translates to:
  /// **'Fiable '**
  String get fiable3;

  /// No description provided for @matchsHonores2.
  ///
  /// In fr, this message translates to:
  /// **'Matchs honorés'**
  String get matchsHonores2;

  /// No description provided for @coachOuOrganisateurDeTournois.
  ///
  /// In fr, this message translates to:
  /// **'Coach ou organisateur de tournois'**
  String get coachOuOrganisateurDeTournois;

  /// No description provided for @ajouterUnRole.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un rôle'**
  String get ajouterUnRole;

  /// No description provided for @roleActuel.
  ///
  /// In fr, this message translates to:
  /// **', rôle actuel'**
  String get roleActuel;

  /// No description provided for @enDirect2.
  ///
  /// In fr, this message translates to:
  /// **'En direct{p0}'**
  String enDirect2(Object p0);

  /// No description provided for @termine4.
  ///
  /// In fr, this message translates to:
  /// **'Terminé{p0}'**
  String termine4(Object p0);

  /// No description provided for @aVenir2.
  ///
  /// In fr, this message translates to:
  /// **'À venir{p0}'**
  String aVenir2(Object p0);

  /// No description provided for @enDirect3.
  ///
  /// In fr, this message translates to:
  /// **'EN DIRECT'**
  String get enDirect3;

  /// No description provided for @tonEquipe.
  ///
  /// In fr, this message translates to:
  /// **'Ton équipe'**
  String get tonEquipe;

  /// No description provided for @setText3.
  ///
  /// In fr, this message translates to:
  /// **'SET {p0}'**
  String setText3(Object p0);

  /// No description provided for @pointsSur.
  ///
  /// In fr, this message translates to:
  /// **'{p0} points sur {p1}'**
  String pointsSur(Object p0, Object p1);

  /// No description provided for @premierA.
  ///
  /// In fr, this message translates to:
  /// **'Premier à {p0}'**
  String premierA(Object p0);

  /// No description provided for @effacer.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get effacer;

  /// No description provided for @aucunResultatPour.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat pour « {p0} »'**
  String aucunResultatPour(Object p0);

  /// No description provided for @verifieLOrthographeOuCherche.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie l’orthographe ou cherche un quartier, un terrain ou un joueur.'**
  String get verifieLOrthographeOuCherche;

  /// No description provided for @recherchesRecentes.
  ///
  /// In fr, this message translates to:
  /// **'Recherches récentes'**
  String get recherchesRecentes;

  /// No description provided for @toutEffacer.
  ///
  /// In fr, this message translates to:
  /// **'Tout effacer'**
  String get toutEffacer;

  /// No description provided for @rechercheRecente.
  ///
  /// In fr, this message translates to:
  /// **'Recherche récente : {p0}'**
  String rechercheRecente(Object p0);

  /// No description provided for @retirerDesRecherchesRecentes.
  ///
  /// In fr, this message translates to:
  /// **'Retirer « {p0} » des recherches récentes'**
  String retirerDesRecherchesRecentes(Object p0);

  /// No description provided for @navigationDuTableauDeBord.
  ///
  /// In fr, this message translates to:
  /// **'Navigation du tableau de bord'**
  String get navigationDuTableauDeBord;

  /// No description provided for @aideEtSupport.
  ///
  /// In fr, this message translates to:
  /// **'Aide et support'**
  String get aideEtSupport;

  /// No description provided for @agrandirLeMenu.
  ///
  /// In fr, this message translates to:
  /// **'Agrandir le menu'**
  String get agrandirLeMenu;

  /// No description provided for @reduireLeMenu.
  ///
  /// In fr, this message translates to:
  /// **'Réduire le menu'**
  String get reduireLeMenu;

  /// No description provided for @optionsDuCompte.
  ///
  /// In fr, this message translates to:
  /// **'Options du compte'**
  String get optionsDuCompte;

  /// No description provided for @changerDeRole2.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1}. Changer de rôle'**
  String changerDeRole2(Object p0, Object p1);

  /// No description provided for @chargement2.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get chargement2;

  /// No description provided for @prixDuTerrainH.
  ///
  /// In fr, this message translates to:
  /// **'Prix du terrain / h'**
  String get prixDuTerrainH;

  /// No description provided for @selectionne.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1}, sélectionné'**
  String selectionne(Object p0, Object p1);

  /// No description provided for @disponible.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1}, disponible{p2}{p3}'**
  String disponible(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @taReservation.
  ///
  /// In fr, this message translates to:
  /// **'ta réservation'**
  String get taReservation;

  /// No description provided for @bloque.
  ///
  /// In fr, this message translates to:
  /// **'Bloqué'**
  String get bloque;

  /// No description provided for @reserve.
  ///
  /// In fr, this message translates to:
  /// **'réservé'**
  String get reserve;

  /// No description provided for @reserve2.
  ///
  /// In fr, this message translates to:
  /// **'Réservé'**
  String get reserve2;

  /// No description provided for @disponible2.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get disponible2;

  /// No description provided for @taSelection.
  ///
  /// In fr, this message translates to:
  /// **'Ta sélection'**
  String get taSelection;

  /// No description provided for @promo.
  ///
  /// In fr, this message translates to:
  /// **'Promo'**
  String get promo;

  /// No description provided for @taReservation2.
  ///
  /// In fr, this message translates to:
  /// **'Ta réservation'**
  String get taReservation2;

  /// No description provided for @pasEncoreAssezDeDonnees.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore assez de données pour une tendance'**
  String get pasEncoreAssezDeDonnees;

  /// No description provided for @tendanceSurPointsDeA.
  ///
  /// In fr, this message translates to:
  /// **'Tendance sur {p0} points : de {p1} à {p2}'**
  String tendanceSurPointsDeA(Object p0, Object p1, Object p2);

  /// No description provided for @decevant.
  ///
  /// In fr, this message translates to:
  /// **'Décevant'**
  String get decevant;

  /// No description provided for @bien.
  ///
  /// In fr, this message translates to:
  /// **'Bien'**
  String get bien;

  /// No description provided for @noteSur.
  ///
  /// In fr, this message translates to:
  /// **'Note {p0} sur 5{p1}'**
  String noteSur(Object p0, Object p1);

  /// No description provided for @avis3.
  ///
  /// In fr, this message translates to:
  /// **'({p0} avis)'**
  String avis3(Object p0);

  /// No description provided for @sur4.
  ///
  /// In fr, this message translates to:
  /// **'{p0} sur 5 · {p1}'**
  String sur4(Object p0, Object p1);

  /// No description provided for @aNoter.
  ///
  /// In fr, this message translates to:
  /// **'À noter'**
  String get aNoter;

  /// No description provided for @note.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @touchePourNoter.
  ///
  /// In fr, this message translates to:
  /// **'Touche pour noter'**
  String get touchePourNoter;

  /// No description provided for @confirme2.
  ///
  /// In fr, this message translates to:
  /// **'Confirmé'**
  String get confirme2;

  /// No description provided for @echec.
  ///
  /// In fr, this message translates to:
  /// **'Échec'**
  String get echec;

  /// No description provided for @annule2.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get annule2;

  /// No description provided for @brouillon.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get brouillon;

  /// No description provided for @etapeSur2.
  ///
  /// In fr, this message translates to:
  /// **'Étape {p0} sur {p1}{p2}'**
  String etapeSur2(Object p0, Object p1, Object p2);

  /// No description provided for @diapoSur.
  ///
  /// In fr, this message translates to:
  /// **'Diapo {p0} sur {p1}'**
  String diapoSur(Object p0, Object p1);

  /// No description provided for @navigationPrincipale.
  ///
  /// In fr, this message translates to:
  /// **'Navigation principale'**
  String get navigationPrincipale;

  /// No description provided for @ajouteUneZone.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute une zone'**
  String get ajouteUneZone;

  /// No description provided for @billetDeLaReservation.
  ///
  /// In fr, this message translates to:
  /// **'Billet de la réservation {p0}'**
  String billetDeLaReservation(Object p0);

  /// No description provided for @qrCodeDeLaReservation.
  ///
  /// In fr, this message translates to:
  /// **'QR code de la réservation {p0}'**
  String qrCodeDeLaReservation(Object p0);

  /// No description provided for @unePlaceSEstLiberee2.
  ///
  /// In fr, this message translates to:
  /// **'Une place s’est libérée !'**
  String get unePlaceSEstLiberee2;

  /// No description provided for @deciderPlusTard.
  ///
  /// In fr, this message translates to:
  /// **'Décider plus tard'**
  String get deciderPlusTard;

  /// No description provided for @tempsRestant2.
  ///
  /// In fr, this message translates to:
  /// **'Temps restant {p0}'**
  String tempsRestant2(Object p0);

  /// No description provided for @pourReclamerTaPlace.
  ///
  /// In fr, this message translates to:
  /// **'pour réclamer ta place'**
  String get pourReclamerTaPlace;

  /// No description provided for @laisserPasser.
  ///
  /// In fr, this message translates to:
  /// **'Laisser passer'**
  String get laisserPasser;

  /// No description provided for @reclamerLaPlace.
  ///
  /// In fr, this message translates to:
  /// **'Réclamer la place'**
  String get reclamerLaPlace;

  /// No description provided for @caracteresEnTropRaccourcisUn.
  ///
  /// In fr, this message translates to:
  /// **'{p0} caractères en trop — raccourcis un peu ton texte.'**
  String caracteresEnTropRaccourcisUn(Object p0);

  /// No description provided for @facultatif2.
  ///
  /// In fr, this message translates to:
  /// **' (facultatif)'**
  String get facultatif2;

  /// No description provided for @choisirLeQuartier.
  ///
  /// In fr, this message translates to:
  /// **'Choisir le quartier'**
  String get choisirLeQuartier;

  /// No description provided for @notificationsNonLues.
  ///
  /// In fr, this message translates to:
  /// **'Notifications, {p0} non lues'**
  String notificationsNonLues(Object p0);

  /// No description provided for @monCompte2.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte, {p0}'**
  String monCompte2(Object p0);

  /// No description provided for @rechercherUnJoueurUnTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un joueur, un terrain, une réservation…'**
  String get rechercherUnJoueurUnTerrain;

  /// No description provided for @ctrlK.
  ///
  /// In fr, this message translates to:
  /// **'Ctrl K'**
  String get ctrlK;

  /// No description provided for @assistant.
  ///
  /// In fr, this message translates to:
  /// **'Assistant'**
  String get assistant;

  /// No description provided for @menuDuCompte.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1}. Menu du compte'**
  String menuDuCompte(Object p0, Object p1);

  /// No description provided for @raccourci.
  ///
  /// In fr, this message translates to:
  /// **'Raccourci {p0}'**
  String raccourci(Object p0);

  /// No description provided for @plusQue.
  ///
  /// In fr, this message translates to:
  /// **'Plus que {p0} {p1}'**
  String plusQue(Object p0, Object p1);

  /// No description provided for @inscriptionsOuvertes.
  ///
  /// In fr, this message translates to:
  /// **'Inscriptions ouvertes'**
  String get inscriptionsOuvertes;

  /// No description provided for @libresSurEquipes.
  ///
  /// In fr, this message translates to:
  /// **'{p0} libres sur {p1} équipes'**
  String libresSurEquipes(Object p0, Object p1);

  /// No description provided for @parEquipe.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1}, {p2} · {p3}, {p4}, {p5} par équipe'**
  String parEquipe(
    Object p0,
    Object p1,
    Object p2,
    Object p3,
    Object p4,
    Object p5,
  );

  /// No description provided for @afficheDuTournoi.
  ///
  /// In fr, this message translates to:
  /// **'Affiche du tournoi {p0}'**
  String afficheDuTournoi(Object p0);

  /// No description provided for @inscriptionParEquipe.
  ///
  /// In fr, this message translates to:
  /// **'Inscription {p0} par équipe{p1}, {p2}'**
  String inscriptionParEquipe(Object p0, Object p1, Object p2);

  /// No description provided for @inscription.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get inscription;

  /// No description provided for @parEquipe2.
  ///
  /// In fr, this message translates to:
  /// **'par équipe'**
  String get parEquipe2;

  /// No description provided for @dotation.
  ///
  /// In fr, this message translates to:
  /// **'Dotation'**
  String get dotation;

  /// No description provided for @equipesInscrites.
  ///
  /// In fr, this message translates to:
  /// **' équipes inscrites'**
  String get equipesInscrites;

  /// No description provided for @sInscrire.
  ///
  /// In fr, this message translates to:
  /// **'S’inscrire'**
  String get sInscrire;

  /// No description provided for @parEquipe3.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1}, {p2}, {p3}, {p4} par équipe'**
  String parEquipe3(Object p0, Object p1, Object p2, Object p3, Object p4);

  /// No description provided for @nonDebite.
  ///
  /// In fr, this message translates to:
  /// **', non débité'**
  String get nonDebite;

  /// No description provided for @rembourse3.
  ///
  /// In fr, this message translates to:
  /// **', remboursé'**
  String get rembourse3;

  /// No description provided for @enAttente3.
  ///
  /// In fr, this message translates to:
  /// **', en attente'**
  String get enAttente3;

  /// No description provided for @douches.
  ///
  /// In fr, this message translates to:
  /// **'Douches'**
  String get douches;

  /// No description provided for @desParPersonne.
  ///
  /// In fr, this message translates to:
  /// **'{p0}{p1}, {p2}, {p3}{p4}, dès {p5} par personne'**
  String desParPersonne(
    Object p0,
    Object p1,
    Object p2,
    Object p3,
    Object p4,
    Object p5,
  );

  /// No description provided for @mettreEnFavori.
  ///
  /// In fr, this message translates to:
  /// **'Mettre {p0} en favori'**
  String mettreEnFavori(Object p0);

  /// No description provided for @fermeOuvreA.
  ///
  /// In fr, this message translates to:
  /// **'Fermé · ouvre à {p0}'**
  String fermeOuvreA(Object p0);

  /// No description provided for @completAujourdHui.
  ///
  /// In fr, this message translates to:
  /// **'Complet aujourd’hui'**
  String get completAujourdHui;

  /// No description provided for @prochainsCreneaux.
  ///
  /// In fr, this message translates to:
  /// **'Prochains créneaux'**
  String get prochainsCreneaux;

  /// No description provided for @prochainsCreneaux2.
  ///
  /// In fr, this message translates to:
  /// **'Prochains créneaux · {p0}'**
  String prochainsCreneaux2(Object p0);

  /// No description provided for @desParJoueur.
  ///
  /// In fr, this message translates to:
  /// **'{p0}dès {p1} par joueur{p2}'**
  String desParJoueur(Object p0, Object p1, Object p2);

  /// No description provided for @des2.
  ///
  /// In fr, this message translates to:
  /// **'dès'**
  String get des2;

  /// No description provided for @reserverA.
  ///
  /// In fr, this message translates to:
  /// **'Réserver à {p0}'**
  String reserverA(Object p0);

  /// No description provided for @reserverA2.
  ///
  /// In fr, this message translates to:
  /// **'Réserver {p0} à {p1}'**
  String reserverA2(Object p0, Object p1);

  /// No description provided for @etapeSur3.
  ///
  /// In fr, this message translates to:
  /// **'Étape {p0} sur {p1} : {p2}'**
  String etapeSur3(Object p0, Object p1, Object p2);

  /// No description provided for @etapeSur4.
  ///
  /// In fr, this message translates to:
  /// **'Étape {p0} sur {p1} · '**
  String etapeSur4(Object p0, Object p1);

  /// No description provided for @suivant2.
  ///
  /// In fr, this message translates to:
  /// **'Suivant : {p0}'**
  String suivant2(Object p0);

  /// No description provided for @etapeEnCours.
  ///
  /// In fr, this message translates to:
  /// **'étape en cours'**
  String get etapeEnCours;

  /// No description provided for @aCorriger.
  ///
  /// In fr, this message translates to:
  /// **'à corriger'**
  String get aCorriger;

  /// No description provided for @aVenir3.
  ///
  /// In fr, this message translates to:
  /// **'à venir'**
  String get aVenir3;

  /// No description provided for @openstreetmapCarto.
  ///
  /// In fr, this message translates to:
  /// **'© OpenStreetMap · © CARTO'**
  String get openstreetmapCarto;

  /// No description provided for @meLocaliser.
  ///
  /// In fr, this message translates to:
  /// **'Me localiser'**
  String get meLocaliser;

  /// No description provided for @rechercherDansCetteZone.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans cette zone'**
  String get rechercherDansCetteZone;

  /// No description provided for @taPosition.
  ///
  /// In fr, this message translates to:
  /// **'Ta position'**
  String get taPosition;

  /// No description provided for @desParPersonne2.
  ///
  /// In fr, this message translates to:
  /// **', dès {p0} par personne'**
  String desParPersonne2(Object p0);

  /// No description provided for @terrainsZoomer.
  ///
  /// In fr, this message translates to:
  /// **'{p0} terrains : {p1} — zoomer'**
  String terrainsZoomer(Object p0, Object p1);

  /// No description provided for @avis4.
  ///
  /// In fr, this message translates to:
  /// **' ({p0} avis)'**
  String avis4(Object p0);

  /// No description provided for @voir.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get voir;

  /// No description provided for @tonAdresse.
  ///
  /// In fr, this message translates to:
  /// **'ton adresse'**
  String get tonAdresse;

  /// No description provided for @dansExplorer.
  ///
  /// In fr, this message translates to:
  /// **'Dans Explorer'**
  String get dansExplorer;

  /// No description provided for @pourTesAbonnes.
  ///
  /// In fr, this message translates to:
  /// **'Pour tes abonnés'**
  String get pourTesAbonnes;

  /// No description provided for @amiA.
  ///
  /// In fr, this message translates to:
  /// **'ami a'**
  String get amiA;

  /// No description provided for @amisOnt.
  ///
  /// In fr, this message translates to:
  /// **'amis ont'**
  String get amisOnt;

  /// No description provided for @privee2.
  ///
  /// In fr, this message translates to:
  /// **'privée'**
  String get privee2;

  /// No description provided for @leTerrain2.
  ///
  /// In fr, this message translates to:
  /// **'Le terrain'**
  String get leTerrain2;

  /// No description provided for @vs3.
  ///
  /// In fr, this message translates to:
  /// **'5 vs 5'**
  String get vs3;

  /// No description provided for @aAjouter.
  ///
  /// In fr, this message translates to:
  /// **'à ajouter'**
  String get aAjouter;

  /// No description provided for @ajoute.
  ///
  /// In fr, this message translates to:
  /// **'ajouté'**
  String get ajoute;

  /// No description provided for @taVille.
  ///
  /// In fr, this message translates to:
  /// **'ta ville'**
  String get taVille;

  /// No description provided for @tonEssaiCourtJusquAu.
  ///
  /// In fr, this message translates to:
  /// **'Ton essai {p0} court jusqu’au {p1}'**
  String tonEssaiCourtJusquAu(Object p0, Object p1);

  /// No description provided for @prixADefinir.
  ///
  /// In fr, this message translates to:
  /// **'prix à définir'**
  String get prixADefinir;

  /// No description provided for @parPersonne2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} par personne'**
  String parPersonne2(Object p0);

  /// No description provided for @refusDeLaBanque.
  ///
  /// In fr, this message translates to:
  /// **'refus de la banque'**
  String get refusDeLaBanque;

  /// No description provided for @enCours.
  ///
  /// In fr, this message translates to:
  /// **', en cours'**
  String get enCours;

  /// No description provided for @recemment.
  ///
  /// In fr, this message translates to:
  /// **'récemment'**
  String get recemment;

  /// No description provided for @yassine.
  ///
  /// In fr, this message translates to:
  /// **'Yassine'**
  String get yassine;

  /// No description provided for @utiliseePourPremium.
  ///
  /// In fr, this message translates to:
  /// **' · utilisée pour Premium'**
  String get utiliseePourPremium;

  /// No description provided for @etPhoto.
  ///
  /// In fr, this message translates to:
  /// **' et photo'**
  String get etPhoto;

  /// No description provided for @aVenir4.
  ///
  /// In fr, this message translates to:
  /// **'à venir{p0}'**
  String aVenir4(Object p0);

  /// No description provided for @enDirect4.
  ///
  /// In fr, this message translates to:
  /// **'en direct{p0}'**
  String enDirect4(Object p0);

  /// No description provided for @termine5.
  ///
  /// In fr, this message translates to:
  /// **'terminé, {p0}'**
  String termine5(Object p0);

  /// No description provided for @heureDePointe3.
  ///
  /// In fr, this message translates to:
  /// **', heure de pointe'**
  String get heureDePointe3;

  /// No description provided for @deLHeure.
  ///
  /// In fr, this message translates to:
  /// **', {p0} de l’heure'**
  String deLHeure(Object p0);

  /// No description provided for @avis5.
  ///
  /// In fr, this message translates to:
  /// **', {p0} avis'**
  String avis5(Object p0);

  /// No description provided for @dotation2.
  ///
  /// In fr, this message translates to:
  /// **', dotation {p0}'**
  String dotation2(Object p0);

  /// No description provided for @verifie2.
  ///
  /// In fr, this message translates to:
  /// **', vérifié'**
  String get verifie2;

  /// No description provided for @noteSurAvis.
  ///
  /// In fr, this message translates to:
  /// **', noté {p0} sur 5, {p1} avis'**
  String noteSurAvis(Object p0, Object p1);

  /// No description provided for @note2.
  ///
  /// In fr, this message translates to:
  /// **'Note {p0}, '**
  String note2(Object p0);

  /// No description provided for @terrain5.
  ///
  /// In fr, this message translates to:
  /// **', terrain {p0}'**
  String terrain5(Object p0);

  /// No description provided for @perYear.
  ///
  /// In fr, this message translates to:
  /// **'/ an'**
  String get perYear;

  /// No description provided for @perMonth.
  ///
  /// In fr, this message translates to:
  /// **'/ mois'**
  String get perMonth;

  /// No description provided for @forever.
  ///
  /// In fr, this message translates to:
  /// **'pour toujours'**
  String get forever;

  /// No description provided for @stepOfTotal.
  ///
  /// In fr, this message translates to:
  /// **'{p0} sur {p1}'**
  String stepOfTotal(Object p0, Object p1);

  /// No description provided for @rangeTo.
  ///
  /// In fr, this message translates to:
  /// **'{p0} à {p1}'**
  String rangeTo(Object p0, Object p1);

  /// No description provided for @atTime.
  ///
  /// In fr, this message translates to:
  /// **' à {p0}'**
  String atTime(Object p0);

  /// No description provided for @durationMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{p0} min'**
  String durationMinutes(Object p0);

  /// No description provided for @spotFreeOne.
  ///
  /// In fr, this message translates to:
  /// **'libre'**
  String get spotFreeOne;

  /// No description provided for @spotFreeMany.
  ///
  /// In fr, this message translates to:
  /// **'libres'**
  String get spotFreeMany;

  /// No description provided for @compatibleWord.
  ///
  /// In fr, this message translates to:
  /// **'compatible'**
  String get compatibleWord;

  /// No description provided for @onTheWaitlist.
  ///
  /// In fr, this message translates to:
  /// **'Sur la liste'**
  String get onTheWaitlist;

  /// No description provided for @impossibleDeRejoindreLaListe.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de rejoindre la liste d’attente. Rien n’a changé.'**
  String get impossibleDeRejoindreLaListe;

  /// No description provided for @tuAsVuLesParties.
  ///
  /// In fr, this message translates to:
  /// **'Tu as vu les {p0} parties à ton niveau près de {p1}.'**
  String tuAsVuLesParties(Object p0, Object p1);

  /// No description provided for @voirTouteLaSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Voir toute la semaine'**
  String get voirTouteLaSemaine;

  /// No description provided for @cettePartieNExistePlus.
  ///
  /// In fr, this message translates to:
  /// **'Cette partie n’existe plus'**
  String get cettePartieNExistePlus;

  /// No description provided for @leLienAExpireOu.
  ///
  /// In fr, this message translates to:
  /// **'Le lien a expiré ou l’organisateur a supprimé la partie. Si tu avais payé ta part, elle est déjà remboursée sur ton solde MatchUp.'**
  String get leLienAExpireOu;

  /// No description provided for @trouverUneAutrePartie.
  ///
  /// In fr, this message translates to:
  /// **'Trouver une autre partie'**
  String get trouverUneAutrePartie;

  /// No description provided for @partiesProchesCeWeekEnd.
  ///
  /// In fr, this message translates to:
  /// **'Parties proches ce week-end'**
  String get partiesProchesCeWeekEnd;

  /// No description provided for @tesMatchsNeSeChargent.
  ///
  /// In fr, this message translates to:
  /// **'Tes matchs ne se chargent pas'**
  String get tesMatchsNeSeChargent;

  /// No description provided for @tesReservationsEtTaPlace.
  ///
  /// In fr, this message translates to:
  /// **'Tes réservations et ta place du '**
  String get tesReservationsEtTaPlace;

  /// No description provided for @dimOct.
  ///
  /// In fr, this message translates to:
  /// **'dim. 18 oct.'**
  String get dimOct;

  /// No description provided for @sontToujoursLa.
  ///
  /// In fr, this message translates to:
  /// **' sont toujours là.'**
  String get sontToujoursLa;

  /// No description provided for @aucunPaiementNAEte.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement n’a été lancé ni débité.'**
  String get aucunPaiementNAEte;

  /// No description provided for @sportsEtNiveaux.
  ///
  /// In fr, this message translates to:
  /// **'Sports et niveaux'**
  String get sportsEtNiveaux;

  /// No description provided for @zonesDeJeu.
  ///
  /// In fr, this message translates to:
  /// **'Zones de jeu'**
  String get zonesDeJeu;

  /// No description provided for @bioLignes.
  ///
  /// In fr, this message translates to:
  /// **'Bio, 2 lignes'**
  String get bioLignes;

  /// No description provided for @tuEsHorsLigne.
  ///
  /// In fr, this message translates to:
  /// **'Tu es hors ligne'**
  String get tuEsHorsLigne;

  /// No description provided for @tuVoisTesDonneesDu.
  ///
  /// In fr, this message translates to:
  /// **'Tu vois tes données du {p0} à {p1}. Reconnecte-toi pour rejoindre ou payer.'**
  String tuVoisTesDonneesDu(Object p0, Object p1);

  /// No description provided for @tonQrCodeDAcces.
  ///
  /// In fr, this message translates to:
  /// **'Ton QR code d’accès s’affiche même sans réseau.'**
  String get tonQrCodeDAcces;

  /// No description provided for @nosServeursOntUnSouci.
  ///
  /// In fr, this message translates to:
  /// **'Nos serveurs ont un souci, ce n’est pas ta connexion. Réessaie dans un instant.'**
  String get nosServeursOntUnSouci;

  /// No description provided for @erreurRef.
  ///
  /// In fr, this message translates to:
  /// **'Erreur {p0} · réf. '**
  String erreurRef(Object p0);

  /// No description provided for @notreEquipeEstPrevenue.
  ///
  /// In fr, this message translates to:
  /// **' · notre équipe est prévenue'**
  String get notreEquipeEstPrevenue;

  /// No description provided for @taSessionAExpire.
  ///
  /// In fr, this message translates to:
  /// **'Ta session a expiré'**
  String get taSessionAExpire;

  /// No description provided for @pourProtegerTonSoldeEt.
  ///
  /// In fr, this message translates to:
  /// **'Pour protéger ton solde et tes paiements, reconnecte-toi. Tu reviendras ici, sur ton portefeuille.'**
  String get pourProtegerTonSoldeEt;

  /// No description provided for @rienNEstPerduTon.
  ///
  /// In fr, this message translates to:
  /// **'Rien n’est perdu : ton solde de {p0} et tes réservations sont intacts.'**
  String rienNEstPerduTon(Object p0);

  /// No description provided for @meReconnecter.
  ///
  /// In fr, this message translates to:
  /// **'Me reconnecter'**
  String get meReconnecter;

  /// No description provided for @pourLActiverSecondes.
  ///
  /// In fr, this message translates to:
  /// **'Pour l’activer, 30 secondes'**
  String get pourLActiverSecondes;

  /// No description provided for @ouvrirLesReglages.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les Réglages'**
  String get ouvrirLesReglages;

  /// No description provided for @verifieTonEmail.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ton email'**
  String get verifieTonEmail;

  /// No description provided for @lienEnvoyeAIlTe.
  ///
  /// In fr, this message translates to:
  /// **'Lien envoyé à {p0}. Il te permettra de récupérer ton compte.'**
  String lienEnvoyeAIlTe(Object p0);

  /// No description provided for @confirmePourPouvoirRecupererTon.
  ///
  /// In fr, this message translates to:
  /// **'Confirme {p0} pour pouvoir récupérer ton compte.'**
  String confirmePourPouvoirRecupererTon(Object p0);

  /// No description provided for @masquerJusquADemain.
  ///
  /// In fr, this message translates to:
  /// **'Masquer jusqu’à demain'**
  String get masquerJusquADemain;

  /// No description provided for @tonCompteEstSuspenduJours.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte est suspendu {p0} jours'**
  String tonCompteEstSuspenduJours(Object p0);

  /// No description provided for @raison2.
  ///
  /// In fr, this message translates to:
  /// **'Raison : {p0}'**
  String raison2(Object p0);

  /// No description provided for @tuPourrasRejouerLe.
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras rejouer le'**
  String get tuPourrasRejouerLe;

  /// No description provided for @dansJours.
  ///
  /// In fr, this message translates to:
  /// **'dans {p0} jours'**
  String dansJours(Object p0);

  /// No description provided for @pendantLaSuspension.
  ///
  /// In fr, this message translates to:
  /// **'Pendant la suspension'**
  String get pendantLaSuspension;

  /// No description provided for @pasDePartieNiDe.
  ///
  /// In fr, this message translates to:
  /// **'Pas de partie ni de réservation'**
  String get pasDePartieNiDe;

  /// No description provided for @tuPeuxToujoursParcourirExplorer.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux toujours parcourir Explorer.'**
  String get tuPeuxToujoursParcourirExplorer;

  /// No description provided for @remboursesSurTonSolde.
  ///
  /// In fr, this message translates to:
  /// **'{p0} remboursés sur ton solde'**
  String remboursesSurTonSolde(Object p0);

  /// No description provided for @tesPartiesAVenirOnt.
  ///
  /// In fr, this message translates to:
  /// **'Tes {p0} parties à venir ont été libérées pour d’autres joueurs.'**
  String tesPartiesAVenirOnt(Object p0);

  /// No description provided for @taFiabiliteRemonteraEnsuite.
  ///
  /// In fr, this message translates to:
  /// **'Ta fiabilité remontera ensuite'**
  String get taFiabiliteRemonteraEnsuite;

  /// No description provided for @previensAuMoinsHAvant.
  ///
  /// In fr, this message translates to:
  /// **'Préviens au moins 24 h avant si tu ne peux pas venir.'**
  String get previensAuMoinsHAvant;

  /// No description provided for @contesterLaDecision.
  ///
  /// In fr, this message translates to:
  /// **'Contester la décision'**
  String get contesterLaDecision;

  /// No description provided for @unMembreDeLEquipe.
  ///
  /// In fr, this message translates to:
  /// **'Un membre de l’équipe MatchUp te répond sous 48 h.'**
  String get unMembreDeLEquipe;

  /// No description provided for @profilComplete.
  ///
  /// In fr, this message translates to:
  /// **'Profil complété'**
  String get profilComplete;

  /// No description provided for @tonProfilEstCompletA.
  ///
  /// In fr, this message translates to:
  /// **'Ton profil est complet à {p0}'**
  String tonProfilEstCompletA(Object p0);

  /// No description provided for @avecUnePhotoEtUne.
  ///
  /// In fr, this message translates to:
  /// **'Avec une photo et une bio, les organisateurs t’acceptent plus vite.'**
  String get avecUnePhotoEtUne;

  /// No description provided for @completerMonProfil.
  ///
  /// In fr, this message translates to:
  /// **'Compléter mon profil'**
  String get completerMonProfil;

  /// No description provided for @cEstToutPourL.
  ///
  /// In fr, this message translates to:
  /// **'C’est tout pour l’instant'**
  String get cEstToutPourL;

  /// No description provided for @miseAJour.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour…'**
  String get miseAJour;

  /// No description provided for @voirLesEtapes.
  ///
  /// In fr, this message translates to:
  /// **'Voir les étapes'**
  String get voirLesEtapes;

  /// No description provided for @proNTerrains.
  ///
  /// In fr, this message translates to:
  /// **'{p0} terrain{p1}'**
  String proNTerrains(Object p0, Object p1);

  /// No description provided for @indiqueTonMatriculeFiscal.
  ///
  /// In fr, this message translates to:
  /// **'Indique ton matricule fiscal.'**
  String get indiqueTonMatriculeFiscal;

  /// No description provided for @attendsLaFinDeLEnvoiDeTesPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Attends la fin de l’envoi de tes photos.'**
  String get attendsLaFinDeLEnvoiDeTesPhotos;

  /// No description provided for @attendsLaFinDeLEnvoi.
  ///
  /// In fr, this message translates to:
  /// **'Attends la fin de l’envoi.'**
  String get attendsLaFinDeLEnvoi;

  /// No description provided for @matchupNePreleveJamaisRien.
  ///
  /// In fr, this message translates to:
  /// **'. MatchUp ne prélève jamais rien sur ce compte.'**
  String get matchupNePreleveJamaisRien;

  /// No description provided for @horaireA.
  ///
  /// In fr, this message translates to:
  /// **'à'**
  String get horaireA;

  /// No description provided for @parPersAbrege.
  ///
  /// In fr, this message translates to:
  /// **'/pers.'**
  String get parPersAbrege;

  /// No description provided for @fevr.
  ///
  /// In fr, this message translates to:
  /// **'févr.'**
  String get fevr;

  /// No description provided for @dec.
  ///
  /// In fr, this message translates to:
  /// **'déc.'**
  String get dec;

  /// No description provided for @aLInstant.
  ///
  /// In fr, this message translates to:
  /// **'à l’instant'**
  String get aLInstant;

  /// No description provided for @ilYAMin.
  ///
  /// In fr, this message translates to:
  /// **'il y a {p0} min'**
  String ilYAMin(Object p0);

  /// No description provided for @ilYAH.
  ///
  /// In fr, this message translates to:
  /// **'il y a {p0} h'**
  String ilYAH(Object p0);

  /// No description provided for @ilYAJ.
  ///
  /// In fr, this message translates to:
  /// **'il y a {p0} j'**
  String ilYAJ(Object p0);

  /// No description provided for @bloquerUnCreneau.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer un créneau'**
  String get bloquerUnCreneau;

  /// No description provided for @creneauBloque.
  ///
  /// In fr, this message translates to:
  /// **'Créneau bloqué'**
  String get creneauBloque;

  /// No description provided for @reservation2.
  ///
  /// In fr, this message translates to:
  /// **'Réservation'**
  String get reservation2;

  /// No description provided for @reservationAVenir.
  ///
  /// In fr, this message translates to:
  /// **'réservation à venir'**
  String get reservationAVenir;

  /// No description provided for @reservationsAVenir.
  ///
  /// In fr, this message translates to:
  /// **'réservations à venir'**
  String get reservationsAVenir;

  /// No description provided for @paiementEnAttente.
  ///
  /// In fr, this message translates to:
  /// **'paiement en attente'**
  String get paiementEnAttente;

  /// No description provided for @paiementsEnAttente.
  ///
  /// In fr, this message translates to:
  /// **'paiements en attente'**
  String get paiementsEnAttente;

  /// No description provided for @reservationTerminee.
  ///
  /// In fr, this message translates to:
  /// **'réservation terminée'**
  String get reservationTerminee;

  /// No description provided for @reservationsTerminees.
  ///
  /// In fr, this message translates to:
  /// **'réservations terminées'**
  String get reservationsTerminees;

  /// No description provided for @reservationAnnulee2.
  ///
  /// In fr, this message translates to:
  /// **'réservation annulée'**
  String get reservationAnnulee2;

  /// No description provided for @reservationsAnnulees.
  ///
  /// In fr, this message translates to:
  /// **'réservations annulées'**
  String get reservationsAnnulees;

  /// No description provided for @ceSoir3.
  ///
  /// In fr, this message translates to:
  /// **'Ce soir · {p0}'**
  String ceSoir3(Object p0);

  /// No description provided for @aujourdHui4.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui · {p0}'**
  String aujourdHui4(Object p0);

  /// No description provided for @demain.
  ///
  /// In fr, this message translates to:
  /// **'Demain · {p0}'**
  String demain(Object p0);

  /// No description provided for @exporterLesReservationsCsv.
  ///
  /// In fr, this message translates to:
  /// **'Exporter les réservations (CSV)'**
  String get exporterLesReservationsCsv;

  /// No description provided for @rechercherUneReservation.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une réservation'**
  String get rechercherUneReservation;

  /// No description provided for @nomRefMuTelephone.
  ///
  /// In fr, this message translates to:
  /// **'Nom, réf. MU-…, téléphone'**
  String get nomRefMuTelephone;

  /// No description provided for @filtrerLesReservations.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer les réservations'**
  String get filtrerLesReservations;

  /// No description provided for @paiementEnAttente2.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en attente'**
  String get paiementEnAttente2;

  /// No description provided for @terminees.
  ///
  /// In fr, this message translates to:
  /// **'Terminées'**
  String get terminees;

  /// No description provided for @annulees.
  ///
  /// In fr, this message translates to:
  /// **'Annulées'**
  String get annulees;

  /// No description provided for @noShows.
  ///
  /// In fr, this message translates to:
  /// **'No-shows'**
  String get noShows;

  /// No description provided for @terrains3.
  ///
  /// In fr, this message translates to:
  /// **'· {p0} terrains'**
  String terrains3(Object p0);

  /// No description provided for @trierParDateLaPlus.
  ///
  /// In fr, this message translates to:
  /// **'Trier par : date, la plus proche d’abord'**
  String get trierParDateLaPlus;

  /// No description provided for @trierParDateLaPlus2.
  ///
  /// In fr, this message translates to:
  /// **'Trier par : date, la plus lointaine d’abord'**
  String get trierParDateLaPlus2;

  /// No description provided for @aucuneReservationIci.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réservation ici'**
  String get aucuneReservationIci;

  /// No description provided for @aucuneReservationPour.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réservation pour « {p0} »'**
  String aucuneReservationPour(Object p0);

  /// No description provided for @essaieUnAutreFiltreOu.
  ///
  /// In fr, this message translates to:
  /// **'Essaie un autre filtre ou une autre recherche.'**
  String get essaieUnAutreFiltreOu;

  /// No description provided for @aVenir5.
  ///
  /// In fr, this message translates to:
  /// **'{p0} à venir'**
  String aVenir5(Object p0);

  /// No description provided for @reservation3.
  ///
  /// In fr, this message translates to:
  /// **'1 réservation'**
  String get reservation3;

  /// No description provided for @reservations2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} réservations'**
  String reservations2(Object p0);

  /// No description provided for @voirLesAutresDeCe.
  ///
  /// In fr, this message translates to:
  /// **'Voir les {p0} autres de ce soir'**
  String voirLesAutresDeCe(Object p0);

  /// No description provided for @voirLesAutres.
  ///
  /// In fr, this message translates to:
  /// **'Voir les {p0} autres'**
  String voirLesAutres(Object p0);

  /// No description provided for @publique3.
  ///
  /// In fr, this message translates to:
  /// **'Publique · {p0}/{p1}'**
  String publique3(Object p0, Object p1);

  /// No description provided for @noShow.
  ///
  /// In fr, this message translates to:
  /// **'No-show'**
  String get noShow;

  /// No description provided for @terminee.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get terminee;

  /// No description provided for @enCours2.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get enCours2;

  /// No description provided for @tRef.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, T{p1}, {p2}, {p3}, réf. {p4}'**
  String tRef(Object p0, Object p1, Object p2, Object p3, Object p4);

  /// No description provided for @checkIn.
  ///
  /// In fr, this message translates to:
  /// **'Check-in'**
  String get checkIn;

  /// No description provided for @siCEstBienIl.
  ///
  /// In fr, this message translates to:
  /// **'Si c’est bien {p0}, il est déjà compté. Sinon, c’est sûrement une capture d’écran : demande le billet de la personne dans son app.'**
  String siCEstBienIl(Object p0);

  /// No description provided for @scannerLeJoueurSuivant.
  ///
  /// In fr, this message translates to:
  /// **'Scanner le joueur suivant'**
  String get scannerLeJoueurSuivant;

  /// No description provided for @voirLaReservation.
  ///
  /// In fr, this message translates to:
  /// **'Voir la réservation'**
  String get voirLaReservation;

  /// No description provided for @scannerUnAutreBillet.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un autre billet'**
  String get scannerUnAutreBillet;

  /// No description provided for @voirLesJoueursDeLa.
  ///
  /// In fr, this message translates to:
  /// **'Voir les joueurs de la réservation'**
  String get voirLesJoueursDeLa;

  /// No description provided for @scannerANouveau.
  ///
  /// In fr, this message translates to:
  /// **'Scanner à nouveau'**
  String get scannerANouveau;

  /// No description provided for @chercherDansLePlanning.
  ///
  /// In fr, this message translates to:
  /// **'Chercher dans le planning'**
  String get chercherDansLePlanning;

  /// No description provided for @valide.
  ///
  /// In fr, this message translates to:
  /// **'Valide'**
  String get valide;

  /// No description provided for @bonMatchLaisseEntrerLe.
  ///
  /// In fr, this message translates to:
  /// **'Bon match ! Laisse entrer le groupe.'**
  String get bonMatchLaisseEntrerLe;

  /// No description provided for @dejaUtilise.
  ///
  /// In fr, this message translates to:
  /// **'Déjà utilisé'**
  String get dejaUtilise;

  /// No description provided for @ceBilletEstDejaPasse.
  ///
  /// In fr, this message translates to:
  /// **'Ce billet est déjà passé à '**
  String get ceBilletEstDejaPasse;

  /// No description provided for @invalide.
  ///
  /// In fr, this message translates to:
  /// **'Invalide'**
  String get invalide;

  /// No description provided for @ceBilletNEstPas.
  ///
  /// In fr, this message translates to:
  /// **'Ce billet n’est pas pour {p0}.'**
  String ceBilletNEstPas(Object p0);

  /// No description provided for @scanneA.
  ///
  /// In fr, this message translates to:
  /// **'Scanné à '**
  String get scanneA;

  /// No description provided for @football5v5.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · Football 5v5'**
  String football5v5(Object p0);

  /// No description provided for @reservePar.
  ///
  /// In fr, this message translates to:
  /// **'Réservé par '**
  String get reservePar;

  /// No description provided for @arrives.
  ///
  /// In fr, this message translates to:
  /// **'{p0} arrivés'**
  String arrives(Object p0);

  /// No description provided for @joueursArrives.
  ///
  /// In fr, this message translates to:
  /// **' joueurs arrivés'**
  String get joueursArrives;

  /// No description provided for @joueursArrivesSur.
  ///
  /// In fr, this message translates to:
  /// **'{p0} joueurs arrivés sur {p1}'**
  String joueursArrivesSur(Object p0, Object p1);

  /// No description provided for @encoreAttendus.
  ///
  /// In fr, this message translates to:
  /// **'Encore attendus : {p0}'**
  String encoreAttendus(Object p0);

  /// No description provided for @signalerUnAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un absent'**
  String get signalerUnAbsent;

  /// No description provided for @billetDe.
  ///
  /// In fr, this message translates to:
  /// **'Billet de {p0}'**
  String billetDe(Object p0);

  /// No description provided for @premierScan.
  ///
  /// In fr, this message translates to:
  /// **'Premier scan'**
  String get premierScan;

  /// No description provided for @accueilPar.
  ///
  /// In fr, this message translates to:
  /// **' · accueil, par {p0}'**
  String accueilPar(Object p0);

  /// No description provided for @ceScan.
  ///
  /// In fr, this message translates to:
  /// **'Ce scan'**
  String get ceScan;

  /// No description provided for @refuse.
  ///
  /// In fr, this message translates to:
  /// **' · refusé'**
  String get refuse;

  /// No description provided for @joueursEntres.
  ///
  /// In fr, this message translates to:
  /// **'Joueurs entrés'**
  String get joueursEntres;

  /// No description provided for @reserveDansUnAutreTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Réservé dans un autre terrain'**
  String get reserveDansUnAutreTerrain;

  /// No description provided for @leCodeEstBienUn.
  ///
  /// In fr, this message translates to:
  /// **'Le code est bien un billet MatchUp, mais pour un autre lieu. Rien n’est débité ni enregistré chez toi.'**
  String get leCodeEstBienUn;

  /// No description provided for @queFaire2.
  ///
  /// In fr, this message translates to:
  /// **'QUE FAIRE'**
  String get queFaire2;

  /// No description provided for @demandeAuJoueurDOuvrir.
  ///
  /// In fr, this message translates to:
  /// **'1. Demande au joueur d’ouvrir sa réservation {p0} dans '**
  String demandeAuJoueurDOuvrir(Object p0);

  /// No description provided for @pasDeBilletChercheSon.
  ///
  /// In fr, this message translates to:
  /// **'2. Pas de billet ? Cherche son nom dans le planning du jour.'**
  String get pasDeBilletChercheSon;

  /// No description provided for @espaceProprietaire2.
  ///
  /// In fr, this message translates to:
  /// **'Espace propriétaire · {p0}'**
  String espaceProprietaire2(Object p0);

  /// No description provided for @retourAPlus.
  ///
  /// In fr, this message translates to:
  /// **'Retour à Plus'**
  String get retourAPlus;

  /// No description provided for @trierLesClients.
  ///
  /// In fr, this message translates to:
  /// **'Trier les clients'**
  String get trierLesClients;

  /// No description provided for @rechercherUnClient.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un client'**
  String get rechercherUnClient;

  /// No description provided for @nomTelephoneOuNDe.
  ///
  /// In fr, this message translates to:
  /// **'Nom, téléphone ou n° de réservation'**
  String get nomTelephoneOuNDe;

  /// No description provided for @filtrerLesClients.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer les clients'**
  String get filtrerLesClients;

  /// No description provided for @tous.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get tous;

  /// No description provided for @habitues.
  ///
  /// In fr, this message translates to:
  /// **'Habitués'**
  String get habitues;

  /// No description provided for @nouveaux.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux'**
  String get nouveaux;

  /// No description provided for @avecNoShow.
  ///
  /// In fr, this message translates to:
  /// **'Avec no-show'**
  String get avecNoShow;

  /// No description provided for @depuisLe.
  ///
  /// In fr, this message translates to:
  /// **'depuis le {p0} {p1}'**
  String depuisLe(Object p0, Object p1);

  /// No description provided for @aucunClientDansCeFiltre.
  ///
  /// In fr, this message translates to:
  /// **'Aucun client dans ce filtre'**
  String get aucunClientDansCeFiltre;

  /// No description provided for @aucunClientPour.
  ///
  /// In fr, this message translates to:
  /// **'Aucun client pour « {p0} »'**
  String aucunClientPour(Object p0);

  /// No description provided for @essaieUnAutreNomNumero.
  ///
  /// In fr, this message translates to:
  /// **'Essaie un autre nom, numéro ou n° de réservation.'**
  String get essaieUnAutreNomNumero;

  /// No description provided for @afficherClientsDePlus.
  ///
  /// In fr, this message translates to:
  /// **'Afficher 20 clients de plus'**
  String get afficherClientsDePlus;

  /// No description provided for @tuVoisLaFiabiliteMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Tu vois la fiabilité MatchUp de tes clients et ce qu’ils ont payé chez toi, rien d’autre.'**
  String get tuVoisLaFiabiliteMatchup;

  /// No description provided for @prochaine.
  ///
  /// In fr, this message translates to:
  /// **'prochaine · {p0}'**
  String prochaine(Object p0);

  /// No description provided for @aujourdHui5.
  ///
  /// In fr, this message translates to:
  /// **'aujourd’hui · {p0}'**
  String aujourdHui5(Object p0);

  /// No description provided for @noShow2.
  ///
  /// In fr, this message translates to:
  /// **', {p0} no-show{p1}'**
  String noShow2(Object p0, Object p1);

  /// No description provided for @nouveau.
  ///
  /// In fr, this message translates to:
  /// **', nouveau'**
  String get nouveau;

  /// No description provided for @noShow3.
  ///
  /// In fr, this message translates to:
  /// **'1 no-show'**
  String get noShow3;

  /// No description provided for @nouveau2.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get nouveau2;

  /// No description provided for @depenses.
  ///
  /// In fr, this message translates to:
  /// **'dépensés'**
  String get depenses;

  /// No description provided for @fiabiliteMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Fiabilité MatchUp'**
  String get fiabiliteMatchup;

  /// No description provided for @creneauPrefere.
  ///
  /// In fr, this message translates to:
  /// **'Créneau préféré'**
  String get creneauPrefere;

  /// No description provided for @premierMatchIci.
  ///
  /// In fr, this message translates to:
  /// **'Premier match ici'**
  String get premierMatchIci;

  /// No description provided for @message.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @terrainVisibleLesJoueursPeuvent.
  ///
  /// In fr, this message translates to:
  /// **'Terrain {p0} visible : les joueurs peuvent le réserver.'**
  String terrainVisibleLesJoueursPeuvent(Object p0);

  /// No description provided for @terrainMasquePlusReservable.
  ///
  /// In fr, this message translates to:
  /// **'Terrain {p0} masqué : plus réservable.'**
  String terrainMasquePlusReservable(Object p0);

  /// No description provided for @terrainEnEntretienCreneauxFermes.
  ///
  /// In fr, this message translates to:
  /// **'Terrain {p0} en entretien : créneaux fermés.'**
  String terrainEnEntretienCreneauxFermes(Object p0);

  /// No description provided for @terrainRouvertALaReservation.
  ///
  /// In fr, this message translates to:
  /// **'Terrain {p0} rouvert à la réservation.'**
  String terrainRouvertALaReservation(Object p0);

  /// No description provided for @visibleEtReservable.
  ///
  /// In fr, this message translates to:
  /// **'Visible et réservable'**
  String get visibleEtReservable;

  /// No description provided for @masqueIlNApparaitPlus.
  ///
  /// In fr, this message translates to:
  /// **'Masqué, il n’apparaît plus aux joueurs.'**
  String get masqueIlNApparaitPlus;

  /// No description provided for @enEntretien.
  ///
  /// In fr, this message translates to:
  /// **'En entretien'**
  String get enEntretien;

  /// No description provided for @fermeTousSesCreneauxJusqu.
  ///
  /// In fr, this message translates to:
  /// **'Ferme tous ses créneaux jusqu’à ce que tu le rouvres.'**
  String get fermeTousSesCreneauxJusqu;

  /// No description provided for @modifierLeSportLaSurface.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le sport, la surface, l’éclairage'**
  String get modifierLeSportLaSurface;

  /// No description provided for @terrainActif.
  ///
  /// In fr, this message translates to:
  /// **'terrain actif'**
  String get terrainActif;

  /// No description provided for @terrainsActifs.
  ///
  /// In fr, this message translates to:
  /// **'terrains actifs'**
  String get terrainsActifs;

  /// No description provided for @occupesJ.
  ///
  /// In fr, this message translates to:
  /// **'occupés · 7 j'**
  String get occupesJ;

  /// No description provided for @tousLesJours2.
  ///
  /// In fr, this message translates to:
  /// **'tous les jours'**
  String get tousLesJours2;

  /// No description provided for @tesTerrains2.
  ///
  /// In fr, this message translates to:
  /// **'TES TERRAINS'**
  String get tesTerrains2;

  /// No description provided for @masquePlusReservable.
  ///
  /// In fr, this message translates to:
  /// **'Masqué = plus réservable'**
  String get masquePlusReservable;

  /// No description provided for @tarifsEtHeuresDePointe.
  ///
  /// In fr, this message translates to:
  /// **'Tarifs et heures de pointe'**
  String get tarifsEtHeuresDePointe;

  /// No description provided for @prixParTerrainDatesSpeciales.
  ///
  /// In fr, this message translates to:
  /// **'Prix par terrain, dates spéciales'**
  String get prixParTerrainDatesSpeciales;

  /// No description provided for @prixParTerrainDatesSpeciales2.
  ///
  /// In fr, this message translates to:
  /// **'Prix par terrain, dates spéciales · {p0} /pers. à 10 en soirée'**
  String prixParTerrainDatesSpeciales2(Object p0);

  /// No description provided for @enEntretienTousSesCreneaux.
  ///
  /// In fr, this message translates to:
  /// **'En entretien : tous ses créneaux sont fermés à la réservation.'**
  String get enEntretienTousSesCreneaux;

  /// No description provided for @hHCreneauxBloques.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · {p1} · {p2}h–{p3}h, créneaux bloqués'**
  String hHCreneauxBloques(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @terrainSalleCouverte.
  ///
  /// In fr, this message translates to:
  /// **'Terrain {p0}, salle couverte'**
  String terrainSalleCouverte(Object p0);

  /// No description provided for @terrainGazonSynthetiqueEclaire.
  ///
  /// In fr, this message translates to:
  /// **'Terrain {p0}, gazon synthétique éclairé'**
  String terrainGazonSynthetiqueEclaire(Object p0);

  /// No description provided for @football5v52.
  ///
  /// In fr, this message translates to:
  /// **'Football 5v5'**
  String get football5v52;

  /// No description provided for @synthetiqueInterieur.
  ///
  /// In fr, this message translates to:
  /// **'Synthétique · Intérieur'**
  String get synthetiqueInterieur;

  /// No description provided for @synthetiqueExterieurEclaire.
  ///
  /// In fr, this message translates to:
  /// **'Synthétique · Extérieur · Éclairé'**
  String get synthetiqueExterieurEclaire;

  /// No description provided for @terrainVisibleEtReservable.
  ///
  /// In fr, this message translates to:
  /// **'Terrain {p0} visible et réservable'**
  String terrainVisibleEtReservable(Object p0);

  /// No description provided for @visible.
  ///
  /// In fr, this message translates to:
  /// **'Visible'**
  String get visible;

  /// No description provided for @masque.
  ///
  /// In fr, this message translates to:
  /// **'Masqué'**
  String get masque;

  /// No description provided for @creuses.
  ///
  /// In fr, this message translates to:
  /// **'Creuses'**
  String get creuses;

  /// No description provided for @pointe.
  ///
  /// In fr, this message translates to:
  /// **'Pointe'**
  String get pointe;

  /// No description provided for @occupeJ.
  ///
  /// In fr, this message translates to:
  /// **'Occupé · 7 j'**
  String get occupeJ;

  /// No description provided for @bloquer2.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer'**
  String get bloquer2;

  /// No description provided for @sportSurfaceEclairagePuisSes.
  ///
  /// In fr, this message translates to:
  /// **'Sport, surface, éclairage, puis ses horaires et tarifs. Ton plan Pro n’a pas de limite de terrains.'**
  String get sportSurfaceEclairagePuisSes;

  /// No description provided for @plus.
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get plus;

  /// No description provided for @notificationsNonLues2.
  ///
  /// In fr, this message translates to:
  /// **'Notifications, 2 non lues'**
  String get notificationsNonLues2;

  /// No description provided for @monComplexe.
  ///
  /// In fr, this message translates to:
  /// **'Mon complexe'**
  String get monComplexe;

  /// No description provided for @habituesNoShows.
  ///
  /// In fr, this message translates to:
  /// **'Habitués, no-shows'**
  String get habituesNoShows;

  /// No description provided for @avisSansReponse.
  ///
  /// In fr, this message translates to:
  /// **'1 avis sans réponse'**
  String get avisSansReponse;

  /// No description provided for @avisSansReponse2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} avis sans réponse'**
  String avisSansReponse2(Object p0);

  /// No description provided for @argent.
  ///
  /// In fr, this message translates to:
  /// **'Argent'**
  String get argent;

  /// No description provided for @versementLunOct.
  ///
  /// In fr, this message translates to:
  /// **'Versement lun. 19 oct.'**
  String get versementLunOct;

  /// No description provided for @proEssai.
  ///
  /// In fr, this message translates to:
  /// **'Pro · essai'**
  String get proEssai;

  /// No description provided for @compteSecurite.
  ///
  /// In fr, this message translates to:
  /// **'Compte, sécurité'**
  String get compteSecurite;

  /// No description provided for @roles.
  ///
  /// In fr, this message translates to:
  /// **'2 rôles'**
  String get roles;

  /// No description provided for @avis6.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · {p1} avis'**
  String avis6(Object p0, Object p1);

  /// No description provided for @monCompteProprietaire.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte propriétaire'**
  String get monCompteProprietaire;

  /// No description provided for @planProEssaiGratuit.
  ///
  /// In fr, this message translates to:
  /// **'Plan Pro · essai gratuit'**
  String get planProEssaiGratuit;

  /// No description provided for @jusquAuMerOctPuis.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu’au mer. 28 oct., puis 149 DT/mois. Rappel 3 jours avant.'**
  String get jusquAuMerOctPuis;

  /// No description provided for @noShowSignale.
  ///
  /// In fr, this message translates to:
  /// **'No-show signalé'**
  String get noShowSignale;

  /// No description provided for @noShowsSignales.
  ///
  /// In fr, this message translates to:
  /// **'{p0} no-shows signalés'**
  String noShowsSignales(Object p0);

  /// No description provided for @estPrevenu.
  ///
  /// In fr, this message translates to:
  /// **'est prévenu'**
  String get estPrevenu;

  /// No description provided for @sontPrevenus.
  ///
  /// In fr, this message translates to:
  /// **'sont prévenus'**
  String get sontPrevenus;

  /// No description provided for @signalerUnNoShow.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un no-show'**
  String get signalerUnNoShow;

  /// No description provided for @retourAuCheckIn.
  ///
  /// In fr, this message translates to:
  /// **'Retour au check-in'**
  String get retourAuCheckIn;

  /// No description provided for @choisisLeJoueurAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Choisis le joueur absent'**
  String get choisisLeJoueurAbsent;

  /// No description provided for @marquerAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Marquer {p0} absent'**
  String marquerAbsent(Object p0);

  /// No description provided for @marquerJoueursAbsents.
  ///
  /// In fr, this message translates to:
  /// **'Marquer {p0} joueurs absents'**
  String marquerJoueursAbsents(Object p0);

  /// No description provided for @debut2.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · {p1} · début {p2}'**
  String debut2(Object p0, Object p1, Object p2);

  /// No description provided for @quiNEstPasVenu.
  ///
  /// In fr, this message translates to:
  /// **'QUI N’EST PAS VENU ?'**
  String get quiNEstPasVenu;

  /// No description provided for @tousLesJoueursSontArrives.
  ///
  /// In fr, this message translates to:
  /// **'Tous les joueurs sont arrivés.'**
  String get tousLesJoueursSontArrives;

  /// No description provided for @dejaSignale.
  ///
  /// In fr, this message translates to:
  /// **'Déjà signalé : {p0}.'**
  String dejaSignale(Object p0);

  /// No description provided for @possibleDesMinApresLe.
  ///
  /// In fr, this message translates to:
  /// **'Possible dès 15 min après le début, si personne n’a prévenu. Les {p0} autres joueurs ont été scannés.'**
  String possibleDesMinApresLe(Object p0);

  /// No description provided for @ceQuiVaSePasser2.
  ///
  /// In fr, this message translates to:
  /// **'CE QUI VA SE PASSER'**
  String get ceQuiVaSePasser2;

  /// No description provided for @leurFiabiliteBaisse.
  ///
  /// In fr, this message translates to:
  /// **'Leur fiabilité baisse'**
  String get leurFiabiliteBaisse;

  /// No description provided for @saFiabiliteBaisse.
  ///
  /// In fr, this message translates to:
  /// **'Sa fiabilité baisse'**
  String get saFiabiliteBaisse;

  /// No description provided for @leurPartResteDue.
  ///
  /// In fr, this message translates to:
  /// **'Leur part reste due'**
  String get leurPartResteDue;

  /// No description provided for @saPartResteDue.
  ///
  /// In fr, this message translates to:
  /// **'Sa part reste due'**
  String get saPartResteDue;

  /// No description provided for @restentVersesASansRemboursement.
  ///
  /// In fr, this message translates to:
  /// **'{p0} restent versés à {p1}, sans remboursement.'**
  String restentVersesASansRemboursement(Object p0, Object p1);

  /// No description provided for @ilsSontPrevenusEtPeuvent.
  ///
  /// In fr, this message translates to:
  /// **'Ils sont prévenus et peuvent contester'**
  String get ilsSontPrevenusEtPeuvent;

  /// No description provided for @ilEstPrevenuEtPeut.
  ///
  /// In fr, this message translates to:
  /// **'Il est prévenu et peut contester'**
  String get ilEstPrevenuEtPeut;

  /// No description provided for @ilAHPourRepondre.
  ///
  /// In fr, this message translates to:
  /// **'Il a 48 h pour répondre. Tu peux retirer ce signalement pendant 24 h.'**
  String get ilAHPourRepondre;

  /// No description provided for @notePourMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Note pour MatchUp'**
  String get notePourMatchup;

  /// No description provided for @exInjoignablePersonneNA.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : injoignable, personne n’a prévenu'**
  String get exInjoignablePersonneNA;

  /// No description provided for @nEstPasVenu.
  ///
  /// In fr, this message translates to:
  /// **'{p0} n’est pas venu'**
  String nEstPasVenu(Object p0);

  /// No description provided for @partPayeePasDeBillet.
  ///
  /// In fr, this message translates to:
  /// **'Part payée · {p0} · pas de billet scanné'**
  String partPayeePasDeBillet(Object p0);

  /// No description provided for @pasArrive.
  ///
  /// In fr, this message translates to:
  /// **'Pas arrivé'**
  String get pasArrive;

  /// No description provided for @creneauxBloques.
  ///
  /// In fr, this message translates to:
  /// **'Créneaux bloqués'**
  String get creneauxBloques;

  /// No description provided for @debloquerCeCreneau.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer ce créneau ?'**
  String get debloquerCeCreneau;

  /// No description provided for @lesJoueursPourrontDeNouveau.
  ///
  /// In fr, this message translates to:
  /// **'Les joueurs pourront de nouveau le réserver.'**
  String get lesJoueursPourrontDeNouveau;

  /// No description provided for @garderBloque.
  ///
  /// In fr, this message translates to:
  /// **'Garder bloqué'**
  String get garderBloque;

  /// No description provided for @debloquer.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer'**
  String get debloquer;

  /// No description provided for @creneauDebloque.
  ///
  /// In fr, this message translates to:
  /// **'Créneau débloqué'**
  String get creneauDebloque;

  /// No description provided for @bloque2.
  ///
  /// In fr, this message translates to:
  /// **'bloqué'**
  String get bloque2;

  /// No description provided for @bloques.
  ///
  /// In fr, this message translates to:
  /// **'bloqués'**
  String get bloques;

  /// No description provided for @vueDuPlanning.
  ///
  /// In fr, this message translates to:
  /// **'Vue du planning'**
  String get vueDuPlanning;

  /// No description provided for @semaine.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get semaine;

  /// No description provided for @jourDuPlanning.
  ///
  /// In fr, this message translates to:
  /// **'Jour du planning'**
  String get jourDuPlanning;

  /// No description provided for @chargementDuPlanning.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du planning'**
  String get chargementDuPlanning;

  /// No description provided for @planning2.
  ///
  /// In fr, this message translates to:
  /// **'Planning {p0}, {p1}'**
  String planning2(Object p0, Object p1);

  /// No description provided for @aucuneReservation.
  ///
  /// In fr, this message translates to:
  /// **'{p0} – {p1} · aucune réservation'**
  String aucuneReservation(Object p0, Object p1);

  /// No description provided for @bloque3.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, bloqué : {p1}'**
  String bloque3(Object p0, Object p1);

  /// No description provided for @libre2.
  ///
  /// In fr, this message translates to:
  /// **'Libre'**
  String get libre2;

  /// No description provided for @creneauPasseLibre.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, créneau passé, libre'**
  String creneauPasseLibre(Object p0);

  /// No description provided for @libreAppuiLongPourBloquer.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, libre, {p1}, appui long pour bloquer'**
  String libreAppuiLongPourBloquer(Object p0, Object p1);

  /// No description provided for @legende.
  ///
  /// In fr, this message translates to:
  /// **'Légende'**
  String get legende;

  /// No description provided for @appuiLongSurUnCreneau.
  ///
  /// In fr, this message translates to:
  /// **'Appui long sur un créneau libre pour le bloquer'**
  String get appuiLongSurUnCreneau;

  /// No description provided for @chargementDeLaSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de la semaine'**
  String get chargementDeLaSemaine;

  /// No description provided for @reservations3.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1} réservations, {p2} %'**
  String reservations3(Object p0, Object p1, Object p2);

  /// No description provided for @resa.
  ///
  /// In fr, this message translates to:
  /// **'{p0} résa · {p1} %'**
  String resa(Object p0, Object p1);

  /// No description provided for @tousLesLundis.
  ///
  /// In fr, this message translates to:
  /// **'Tous les lundis'**
  String get tousLesLundis;

  /// No description provided for @tousLesMardis.
  ///
  /// In fr, this message translates to:
  /// **'Tous les mardis'**
  String get tousLesMardis;

  /// No description provided for @tousLesMercredis.
  ///
  /// In fr, this message translates to:
  /// **'Tous les mercredis'**
  String get tousLesMercredis;

  /// No description provided for @tousLesJeudis.
  ///
  /// In fr, this message translates to:
  /// **'Tous les jeudis'**
  String get tousLesJeudis;

  /// No description provided for @tousLesVendredis.
  ///
  /// In fr, this message translates to:
  /// **'Tous les vendredis'**
  String get tousLesVendredis;

  /// No description provided for @tousLesSamedis.
  ///
  /// In fr, this message translates to:
  /// **'Tous les samedis'**
  String get tousLesSamedis;

  /// No description provided for @tousLesDimanches.
  ///
  /// In fr, this message translates to:
  /// **'Tous les dimanches'**
  String get tousLesDimanches;

  /// No description provided for @derniersLundis.
  ///
  /// In fr, this message translates to:
  /// **'derniers lundis'**
  String get derniersLundis;

  /// No description provided for @derniersMardis.
  ///
  /// In fr, this message translates to:
  /// **'derniers mardis'**
  String get derniersMardis;

  /// No description provided for @derniersMercredis.
  ///
  /// In fr, this message translates to:
  /// **'derniers mercredis'**
  String get derniersMercredis;

  /// No description provided for @derniersJeudis.
  ///
  /// In fr, this message translates to:
  /// **'derniers jeudis'**
  String get derniersJeudis;

  /// No description provided for @derniersVendredis.
  ///
  /// In fr, this message translates to:
  /// **'derniers vendredis'**
  String get derniersVendredis;

  /// No description provided for @derniersSamedis.
  ///
  /// In fr, this message translates to:
  /// **'derniers samedis'**
  String get derniersSamedis;

  /// No description provided for @derniersDimanches.
  ///
  /// In fr, this message translates to:
  /// **'derniers dimanches'**
  String get derniersDimanches;

  /// No description provided for @indiqueUnPrix2.
  ///
  /// In fr, this message translates to:
  /// **'Indique un prix'**
  String get indiqueUnPrix2;

  /// No description provided for @promoPubliee.
  ///
  /// In fr, this message translates to:
  /// **'Promo publiée'**
  String get promoPubliee;

  /// No description provided for @le3.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, le {p1}.'**
  String le3(Object p0, Object p1);

  /// No description provided for @tarifsEnregistres.
  ///
  /// In fr, this message translates to:
  /// **'Tarifs enregistrés'**
  String get tarifsEnregistres;

  /// No description provided for @promoPubliee2.
  ///
  /// In fr, this message translates to:
  /// **'Promo {p0} publiée.'**
  String promoPubliee2(Object p0);

  /// No description provided for @lesReservationsDejaPayeesGardent.
  ///
  /// In fr, this message translates to:
  /// **'Les réservations déjà payées gardent leur prix.'**
  String get lesReservationsDejaPayeesGardent;

  /// No description provided for @terrains4.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · {p1} terrains'**
  String terrains4(Object p0, Object p1);

  /// No description provided for @enregistrerLesTarifs.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les tarifs'**
  String get enregistrerLesTarifs;

  /// No description provided for @plagesHoraires.
  ///
  /// In fr, this message translates to:
  /// **'Plages horaires'**
  String get plagesHoraires;

  /// No description provided for @duLundiAuVendredi.
  ///
  /// In fr, this message translates to:
  /// **'Du lundi au vendredi'**
  String get duLundiAuVendredi;

  /// No description provided for @heuresCreusesDeAHeures.
  ///
  /// In fr, this message translates to:
  /// **'Heures creuses de {p0} à {p1}, heures de pointe de {p2} à {p3}, heures creuses de {p4} à minuit'**
  String heuresCreusesDeAHeures(
    Object p0,
    Object p1,
    Object p2,
    Object p3,
    Object p4,
  );

  /// No description provided for @samediEtDimancheDeA.
  ///
  /// In fr, this message translates to:
  /// **'Samedi et dimanche, de {p0} à {p1}.'**
  String samediEtDimancheDeA(Object p0, Object p1);

  /// No description provided for @lesJoueursVoientLePrix.
  ///
  /// In fr, this message translates to:
  /// **'Les joueurs voient le prix par personne, calculé pour {p0} joueurs.'**
  String lesJoueursVoientLePrix(Object p0);

  /// No description provided for @terrainsEt.
  ///
  /// In fr, this message translates to:
  /// **'Terrains {p0} et {p1}'**
  String terrainsEt(Object p0, Object p1);

  /// No description provided for @indoorCouvert.
  ///
  /// In fr, this message translates to:
  /// **'Indoor · couvert'**
  String get indoorCouvert;

  /// No description provided for @exterieurGazonSynthetiqueEclaires.
  ///
  /// In fr, this message translates to:
  /// **'Extérieur · gazon synthétique · éclairés'**
  String get exterieurGazonSynthetiqueEclaires;

  /// No description provided for @promotions.
  ///
  /// In fr, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// No description provided for @aucunePromotionEnCoursL.
  ///
  /// In fr, this message translates to:
  /// **'Aucune promotion en cours. L’assistant t’en proposera quand des créneaux restent vides.'**
  String get aucunePromotionEnCoursL;

  /// No description provided for @dApresTaSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'D’après ta suggestion'**
  String get dApresTaSuggestion;

  /// No description provided for @publiee.
  ///
  /// In fr, this message translates to:
  /// **'Publiée'**
  String get publiee;

  /// No description provided for @aConfirmer.
  ///
  /// In fr, this message translates to:
  /// **'À confirmer'**
  String get aConfirmer;

  /// No description provided for @dureeDeLaPromo.
  ///
  /// In fr, this message translates to:
  /// **'Durée de la promo'**
  String get dureeDeLaPromo;

  /// No description provided for @terrainsCreneauxRecommandeCarCreneaux.
  ///
  /// In fr, this message translates to:
  /// **'{p0} terrains · {p1} créneaux {p2} Recommandé car {p3} créneaux sur {p4} sont restés vides ces {p5} {p6}.'**
  String terrainsCreneauxRecommandeCarCreneaux(
    Object p0,
    Object p1,
    Object p2,
    Object p3,
    Object p4,
    Object p5,
    Object p6,
  );

  /// No description provided for @publierLaPromo.
  ///
  /// In fr, this message translates to:
  /// **'Publier la promo'**
  String get publierLaPromo;

  /// No description provided for @ceQueVoientLesJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Ce que voient les joueurs'**
  String get ceQueVoientLesJoueurs;

  /// No description provided for @hHPrixDuTerrain.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · {p1}h – {p2}h · prix du terrain à l’heure'**
  String hHPrixDuTerrain(Object p0, Object p1, Object p2);

  /// No description provided for @apercuJoueur.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu joueur, {p0}'**
  String apercuJoueur(Object p0);

  /// No description provided for @indoor.
  ///
  /// In fr, this message translates to:
  /// **'Indoor'**
  String get indoor;

  /// No description provided for @pointeTouteLaJournee.
  ///
  /// In fr, this message translates to:
  /// **'Pointe toute la journée · {p0}'**
  String pointeTouteLaJournee(Object p0);

  /// No description provided for @pointe2.
  ///
  /// In fr, this message translates to:
  /// **'Pointe {p0} – {p1}{p2}'**
  String pointe2(Object p0, Object p1, Object p2);

  /// No description provided for @modifier3.
  ///
  /// In fr, this message translates to:
  /// **'Modifier : {p0}'**
  String modifier3(Object p0);

  /// No description provided for @exporterLesRevenus.
  ///
  /// In fr, this message translates to:
  /// **'Exporter les revenus'**
  String get exporterLesRevenus;

  /// No description provided for @periode.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get periode;

  /// No description provided for @jours.
  ///
  /// In fr, this message translates to:
  /// **'7 jours'**
  String get jours;

  /// No description provided for @jours2.
  ///
  /// In fr, this message translates to:
  /// **'30 jours'**
  String get jours2;

  /// No description provided for @mois.
  ///
  /// In fr, this message translates to:
  /// **'12 mois'**
  String get mois;

  /// No description provided for @telechargerLeReleveDOctobre.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le relevé d’octobre'**
  String get telechargerLeReleveDOctobre;

  /// No description provided for @pdfPourTaComptabiliteTva.
  ///
  /// In fr, this message translates to:
  /// **'PDF pour ta comptabilité · TVA détaillée'**
  String get pdfPourTaComptabiliteTva;

  /// No description provided for @compteDeVersement.
  ///
  /// In fr, this message translates to:
  /// **'Compte de versement'**
  String get compteDeVersement;

  /// No description provided for @duAu.
  ///
  /// In fr, this message translates to:
  /// **'du {p0} au {p1} {p2}'**
  String duAu(Object p0, Object p1, Object p2);

  /// No description provided for @prochainVersementEstimeSurDeja.
  ///
  /// In fr, this message translates to:
  /// **'Prochain versement estimé : {p0}, {p1} sur {p2}. Déjà encaissé {p3} {p4}. Encore attendu environ {p5}, {p6}.'**
  String prochainVersementEstimeSurDeja(
    Object p0,
    Object p1,
    Object p2,
    Object p3,
    Object p4,
    Object p5,
    Object p6,
  );

  /// No description provided for @dejaEncaisse.
  ///
  /// In fr, this message translates to:
  /// **'Déjà encaissé'**
  String get dejaEncaisse;

  /// No description provided for @encoreAttendu.
  ///
  /// In fr, this message translates to:
  /// **'Encore attendu'**
  String get encoreAttendu;

  /// No description provided for @vsJAvant.
  ///
  /// In fr, this message translates to:
  /// **'vs 7 j avant'**
  String get vsJAvant;

  /// No description provided for @vsJAvant2.
  ///
  /// In fr, this message translates to:
  /// **'vs 30 j avant'**
  String get vsJAvant2;

  /// No description provided for @vsMoisAvant.
  ///
  /// In fr, this message translates to:
  /// **'vs 12 mois avant'**
  String get vsMoisAvant;

  /// No description provided for @revenus2.
  ///
  /// In fr, this message translates to:
  /// **'Revenus · {p0}'**
  String revenus2(Object p0);

  /// No description provided for @revenusParMois.
  ///
  /// In fr, this message translates to:
  /// **'Revenus par mois'**
  String get revenusParMois;

  /// No description provided for @revenusParJour.
  ///
  /// In fr, this message translates to:
  /// **'Revenus par jour'**
  String get revenusParJour;

  /// No description provided for @terrainsEnLigneEtSur.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · 3 terrains · en ligne et sur place, en {p1}'**
  String terrainsEnLigneEtSur(Object p0, Object p1);

  /// No description provided for @mois2.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get mois2;

  /// No description provided for @dOuViennentLes.
  ///
  /// In fr, this message translates to:
  /// **'D’où viennent les {p0}'**
  String dOuViennentLes(Object p0);

  /// No description provided for @payesEnLigne.
  ///
  /// In fr, this message translates to:
  /// **'{p0} % payés en ligne'**
  String payesEnLigne(Object p0);

  /// No description provided for @payeEnLigne.
  ///
  /// In fr, this message translates to:
  /// **'Payé en ligne · {p0} %'**
  String payeEnLigne(Object p0);

  /// No description provided for @verseChaqueLundi.
  ///
  /// In fr, this message translates to:
  /// **'versé chaque lundi'**
  String get verseChaqueLundi;

  /// No description provided for @encaisseSurPlace.
  ///
  /// In fr, this message translates to:
  /// **'Encaissé sur place · {p0} %'**
  String encaisseSurPlace(Object p0);

  /// No description provided for @noteALAccueil.
  ///
  /// In fr, this message translates to:
  /// **'noté à l’accueil'**
  String get noteALAccueil;

  /// No description provided for @chaqueLundi.
  ///
  /// In fr, this message translates to:
  /// **'chaque lundi'**
  String get chaqueLundi;

  /// No description provided for @prevu.
  ///
  /// In fr, this message translates to:
  /// **'Prévu · {p0}'**
  String prevu(Object p0);

  /// No description provided for @paiementsDuAu.
  ///
  /// In fr, this message translates to:
  /// **'Paiements du {p0} au {p1} {p2}'**
  String paiementsDuAu(Object p0, Object p1, Object p2);

  /// No description provided for @verse.
  ///
  /// In fr, this message translates to:
  /// **'Versé · {p0}'**
  String verse(Object p0);

  /// No description provided for @seulsLesJoueursQuiOnt.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les joueurs qui ont joué chez toi peuvent laisser un avis.'**
  String get seulsLesJoueursQuiOnt;

  /// No description provided for @filtrerLesAvis.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer les avis'**
  String get filtrerLesAvis;

  /// No description provided for @sansReponse.
  ///
  /// In fr, this message translates to:
  /// **'Sans réponse'**
  String get sansReponse;

  /// No description provided for @etoiles.
  ///
  /// In fr, this message translates to:
  /// **'5 étoiles'**
  String get etoiles;

  /// No description provided for @etoilesEtMoins.
  ///
  /// In fr, this message translates to:
  /// **'3 étoiles et moins'**
  String get etoilesEtMoins;

  /// No description provided for @plusRecents.
  ///
  /// In fr, this message translates to:
  /// **'PLUS RÉCENTS'**
  String get plusRecents;

  /// No description provided for @tuAsReponduATous.
  ///
  /// In fr, this message translates to:
  /// **'Tu as répondu à tous les avis'**
  String get tuAsReponduATous;

  /// No description provided for @aucunAvisRecentIci.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis récent ici'**
  String get aucunAvisRecentIci;

  /// No description provided for @lesPlusAnciensSontDans.
  ///
  /// In fr, this message translates to:
  /// **'Les plus anciens sont dans « Voir les autres avis ».'**
  String get lesPlusAnciensSontDans;

  /// No description provided for @voirLesAutresAvis.
  ///
  /// In fr, this message translates to:
  /// **'Voir les {p0} autres avis'**
  String voirLesAutresAvis(Object p0);

  /// No description provided for @unAvisInjurieuxOuFaux.
  ///
  /// In fr, this message translates to:
  /// **'Un avis injurieux ou faux ? Signale-le avec « … » : l’équipe MatchUp le vérifie sous 48 h. Tu ne peux pas supprimer un avis.'**
  String get unAvisInjurieuxOuFaux;

  /// No description provided for @noteMoyenneSurAvis.
  ///
  /// In fr, this message translates to:
  /// **'Note moyenne {p0} sur 5, {p1} avis'**
  String noteMoyenneSurAvis(Object p0, Object p1);

  /// No description provided for @avisVerifies.
  ///
  /// In fr, this message translates to:
  /// **'{p0} avis vérifiés'**
  String avisVerifies(Object p0);

  /// No description provided for @repartitionDesNotes.
  ///
  /// In fr, this message translates to:
  /// **'Répartition des notes'**
  String get repartitionDesNotes;

  /// No description provided for @etoileAvis.
  ///
  /// In fr, this message translates to:
  /// **'{p0} étoile{p1} : {p2} avis'**
  String etoileAvis(Object p0, Object p1, Object p2);

  /// No description provided for @reponsePublieeSurLaPage.
  ///
  /// In fr, this message translates to:
  /// **'Réponse publiée sur la page d’{p0}.'**
  String reponsePublieeSurLaPage(Object p0);

  /// No description provided for @avisDeSur.
  ///
  /// In fr, this message translates to:
  /// **'Avis de {p0}, {p1} sur 5'**
  String avisDeSur(Object p0, Object p1);

  /// No description provided for @terrain6.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · Terrain {p1}'**
  String terrain6(Object p0, Object p1);

  /// No description provided for @repondu.
  ///
  /// In fr, this message translates to:
  /// **'Répondu'**
  String get repondu;

  /// No description provided for @plusDActionsSurL.
  ///
  /// In fr, this message translates to:
  /// **'Plus d’actions sur l’avis de {p0}'**
  String plusDActionsSurL(Object p0);

  /// No description provided for @taReponsePublique.
  ///
  /// In fr, this message translates to:
  /// **'Ta réponse publique'**
  String get taReponsePublique;

  /// No description provided for @visibleParTousSurLa.
  ///
  /// In fr, this message translates to:
  /// **'Visible par tous sur la page d’{p0}.'**
  String visibleParTousSurLa(Object p0);

  /// No description provided for @publierLaReponse.
  ///
  /// In fr, this message translates to:
  /// **'Publier la réponse'**
  String get publierLaReponse;

  /// No description provided for @ouvreLesReglagesDuTelephone.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre les Réglages du téléphone'**
  String get ouvreLesReglagesDuTelephone;

  /// No description provided for @puisMatchupCamera.
  ///
  /// In fr, this message translates to:
  /// **'Puis MatchUp › Caméra.'**
  String get puisMatchupCamera;

  /// No description provided for @cameraBloquee.
  ///
  /// In fr, this message translates to:
  /// **'Caméra bloquée'**
  String get cameraBloquee;

  /// No description provided for @tuAsRefuseLAcces.
  ///
  /// In fr, this message translates to:
  /// **'Tu as refusé l’accès à la caméra : impossible de scanner les QR codes des joueurs.'**
  String get tuAsRefuseLAcces;

  /// No description provided for @toucheMatchup.
  ///
  /// In fr, this message translates to:
  /// **'Touche MatchUp'**
  String get toucheMatchup;

  /// No description provided for @activeCameraPuisReviensIci.
  ///
  /// In fr, this message translates to:
  /// **'Active Caméra, puis reviens ici'**
  String get activeCameraPuisReviensIci;

  /// No description provided for @saisirLeCodeALa.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le code à la main'**
  String get saisirLeCodeALa;

  /// No description provided for @leScanPartToutSeul.
  ///
  /// In fr, this message translates to:
  /// **'Le scan part tout seul dès que le code est net.'**
  String get leScanPartToutSeul;

  /// No description provided for @lampeAllumee.
  ///
  /// In fr, this message translates to:
  /// **'Lampe allumée'**
  String get lampeAllumee;

  /// No description provided for @lampe.
  ///
  /// In fr, this message translates to:
  /// **'Lampe'**
  String get lampe;

  /// No description provided for @saisirLeCode.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le code'**
  String get saisirLeCode;

  /// No description provided for @laCameraNeSOuvre.
  ///
  /// In fr, this message translates to:
  /// **'La caméra ne s’ouvre pas ? '**
  String get laCameraNeSOuvre;

  /// No description provided for @autoriserLAcces.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser l’accès'**
  String get autoriserLAcces;

  /// No description provided for @leCodeEstEcritSous.
  ///
  /// In fr, this message translates to:
  /// **'Le code est écrit sous le QR, dans le billet du joueur.'**
  String get leCodeEstEcritSous;

  /// No description provided for @codeDuBillet.
  ///
  /// In fr, this message translates to:
  /// **'Code du billet'**
  String get codeDuBillet;

  /// No description provided for @viseLeQrCodeDu.
  ///
  /// In fr, this message translates to:
  /// **'Vise le QR code du joueur'**
  String get viseLeQrCodeDu;

  /// No description provided for @scannerLeBilletVise.
  ///
  /// In fr, this message translates to:
  /// **'Scanner le billet visé'**
  String get scannerLeBilletVise;

  /// No description provided for @verification.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get verification;

  /// No description provided for @prochainCreneau.
  ///
  /// In fr, this message translates to:
  /// **'Prochain créneau, {p0}, {p1}, {p2}, {p3}'**
  String prochainCreneau(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @prochainCreneau2.
  ///
  /// In fr, this message translates to:
  /// **'PROCHAIN CRÉNEAU'**
  String get prochainCreneau2;

  /// No description provided for @joueurs4.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · {p1} joueurs'**
  String joueurs4(Object p0, Object p1);

  /// No description provided for @encoreCeSoir.
  ///
  /// In fr, this message translates to:
  /// **' · {p0} {p1} encore ce soir'**
  String encoreCeSoir(Object p0, Object p1);

  /// No description provided for @programmeDuJour.
  ///
  /// In fr, this message translates to:
  /// **'Programme du jour'**
  String get programmeDuJour;

  /// No description provided for @dejaEncaissesEnCoursDe.
  ///
  /// In fr, this message translates to:
  /// **'{p0} déjà encaissés · {p1} en cours de paiement par les joueurs (dus 3 h avant chaque match).'**
  String dejaEncaissesEnCoursDe(Object p0, Object p1);

  /// No description provided for @derniersAvis.
  ///
  /// In fr, this message translates to:
  /// **'Derniers avis'**
  String get derniersAvis;

  /// No description provided for @tousLesAvis.
  ///
  /// In fr, this message translates to:
  /// **'Tous les avis'**
  String get tousLesAvis;

  /// No description provided for @chiffresDuJour.
  ///
  /// In fr, this message translates to:
  /// **'Chiffres du jour'**
  String get chiffresDuJour;

  /// No description provided for @partiePubliqueJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Partie publique · {p0}/{p1} joueurs'**
  String partiePubliqueJoueurs(Object p0, Object p1);

  /// No description provided for @partiePriveeJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'Partie privée · {p0} joueurs'**
  String partiePriveeJoueurs(Object p0);

  /// No description provided for @prochaineArrivee.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine arrivée · {p0}'**
  String prochaineArrivee(Object p0);

  /// No description provided for @scanner.
  ///
  /// In fr, this message translates to:
  /// **'Scanner'**
  String get scanner;

  /// No description provided for @aucuneReservationAujourdHui.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réservation aujourd’hui'**
  String get aucuneReservationAujourdHui;

  /// No description provided for @reservation4.
  ///
  /// In fr, this message translates to:
  /// **'réservation'**
  String get reservation4;

  /// No description provided for @reservations4.
  ///
  /// In fr, this message translates to:
  /// **'réservations'**
  String get reservations4;

  /// No description provided for @creneauLibre.
  ///
  /// In fr, this message translates to:
  /// **'créneau libre'**
  String get creneauLibre;

  /// No description provided for @creneauxLibres.
  ///
  /// In fr, this message translates to:
  /// **'créneaux libres'**
  String get creneauxLibres;

  /// No description provided for @enAttente4.
  ///
  /// In fr, this message translates to:
  /// **'{p0} {p1} en attente'**
  String enAttente4(Object p0, Object p1);

  /// No description provided for @maintenant.
  ///
  /// In fr, this message translates to:
  /// **'Maintenant'**
  String get maintenant;

  /// No description provided for @termine6.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · terminé'**
  String termine6(Object p0);

  /// No description provided for @personneAuCheckIn.
  ///
  /// In fr, this message translates to:
  /// **'Personne au check-in'**
  String get personneAuCheckIn;

  /// No description provided for @terrain7.
  ///
  /// In fr, this message translates to:
  /// **'Terrain {p0}, {p1}, {p2}'**
  String terrain7(Object p0, Object p1, Object p2);

  /// No description provided for @terrainBloque.
  ///
  /// In fr, this message translates to:
  /// **'Terrain {p0}, bloqué, {p1}'**
  String terrainBloque(Object p0, Object p1);

  /// No description provided for @pers3.
  ///
  /// In fr, this message translates to:
  /// **'{p0} · {p1} /pers.'**
  String pers3(Object p0, Object p1);

  /// No description provided for @terrainLibre.
  ///
  /// In fr, this message translates to:
  /// **'Terrain {p0}, libre, {p1}'**
  String terrainLibre(Object p0, Object p1);

  /// No description provided for @suggestionDeLIa.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion de l’IA'**
  String get suggestionDeLIa;

  /// No description provided for @tarifs2.
  ///
  /// In fr, this message translates to:
  /// **'Tarifs · {p0}'**
  String tarifs2(Object p0);

  /// No description provided for @jeudiHHDeCreneaux.
  ///
  /// In fr, this message translates to:
  /// **'Jeudi {p0}h–{p1}h : 80 % de créneaux vides. Proposer −{p2} % ?'**
  String jeudiHHDeCreneaux(Object p0, Object p1, Object p2);

  /// No description provided for @surTesDerniersJeudisCreneaux.
  ///
  /// In fr, this message translates to:
  /// **'sur tes 5 derniers jeudis, 36 créneaux sur 45 sont restés vides entre {p0}h et {p1}h.'**
  String surTesDerniersJeudisCreneaux(Object p0, Object p1);

  /// No description provided for @apres.
  ///
  /// In fr, this message translates to:
  /// **'après {p0}'**
  String apres(Object p0);

  /// No description provided for @terrainsCreneauxLesJoueursVoient.
  ///
  /// In fr, this message translates to:
  /// **'{p0} terrains · {p1} créneaux · {p2} Les joueurs voient le prix barré. Rien ne change sans ta confirmation.'**
  String terrainsCreneauxLesJoueursVoient(Object p0, Object p1, Object p2);

  /// No description provided for @ignorer.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get ignorer;

  /// No description provided for @revenusProchainVersementVersLe.
  ///
  /// In fr, this message translates to:
  /// **'Revenus : prochain versement vers le {p0}'**
  String revenusProchainVersementVersLe(Object p0);

  /// No description provided for @versementPrevuVersLe.
  ///
  /// In fr, this message translates to:
  /// **'Versement prévu vers le {p0}'**
  String versementPrevuVersLe(Object p0);

  /// No description provided for @dernier.
  ///
  /// In fr, this message translates to:
  /// **'Dernier : {p0} · {p1}'**
  String dernier(Object p0, Object p1);

  /// No description provided for @avisSansReponse3.
  ///
  /// In fr, this message translates to:
  /// **'{p0} avis · {p1} sans réponse'**
  String avisSansReponse3(Object p0, Object p1);

  /// No description provided for @terrain8.
  ///
  /// In fr, this message translates to:
  /// **'Terrain {p0} · {p1}'**
  String terrain8(Object p0, Object p1);

  /// No description provided for @tuAsReponduLe.
  ///
  /// In fr, this message translates to:
  /// **'Tu as répondu le {p0}'**
  String tuAsReponduLe(Object p0);

  /// No description provided for @jourABloquer.
  ///
  /// In fr, this message translates to:
  /// **'Jour à bloquer'**
  String get jourABloquer;

  /// No description provided for @plageHoraire.
  ///
  /// In fr, this message translates to:
  /// **'Plage horaire'**
  String get plageHoraire;

  /// No description provided for @de.
  ///
  /// In fr, this message translates to:
  /// **'De'**
  String get de;

  /// No description provided for @noteInterne.
  ///
  /// In fr, this message translates to:
  /// **'Note interne'**
  String get noteInterne;

  /// No description provided for @visibleParTonEquipeSeulement.
  ///
  /// In fr, this message translates to:
  /// **'Visible par ton équipe seulement.'**
  String get visibleParTonEquipeSeulement;

  /// No description provided for @repeterChaqueSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Répéter chaque semaine'**
  String get repeterChaqueSemaine;

  /// No description provided for @tousLesSTouteLa.
  ///
  /// In fr, this message translates to:
  /// **'Tous les {p0}s, toute la journée'**
  String tousLesSTouteLa(Object p0);

  /// No description provided for @tousLesSDeA.
  ///
  /// In fr, this message translates to:
  /// **'Tous les {p0}s, de {p1} à {p2}'**
  String tousLesSDeA(Object p0, Object p1, Object p2);

  /// No description provided for @lesJoueursVoientIndisponibleSur.
  ///
  /// In fr, this message translates to:
  /// **'Les joueurs voient « Indisponible » sur ces créneaux. Tu peux les débloquer à tout moment depuis le planning.'**
  String get lesJoueursVoientIndisponibleSur;

  /// No description provided for @hAucuneReservationTouchee.
  ///
  /// In fr, this message translates to:
  /// **'{p0} h · {p1} {p2} · aucune réservation touchée'**
  String hAucuneReservationTouchee(Object p0, Object p1, Object p2);

  /// No description provided for @creneau2.
  ///
  /// In fr, this message translates to:
  /// **'créneau'**
  String get creneau2;

  /// No description provided for @creneaux3.
  ///
  /// In fr, this message translates to:
  /// **'créneaux'**
  String get creneaux3;

  /// No description provided for @reservationADeplacer.
  ///
  /// In fr, this message translates to:
  /// **'1 réservation à déplacer'**
  String get reservationADeplacer;

  /// No description provided for @reservationsADeplacer.
  ///
  /// In fr, this message translates to:
  /// **'{p0} réservations à déplacer'**
  String reservationsADeplacer(Object p0);

  /// No description provided for @bloquerCreneau.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer 1 créneau'**
  String get bloquerCreneau;

  /// No description provided for @bloquerCreneaux.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer {p0} créneaux'**
  String bloquerCreneaux(Object p0);

  /// No description provided for @organisateur3.
  ///
  /// In fr, this message translates to:
  /// **' · organisateur'**
  String get organisateur3;

  /// No description provided for @fiableMatchsHonores.
  ///
  /// In fr, this message translates to:
  /// **'Fiable {p0} % · {p1}/{p2} matchs honorés'**
  String fiableMatchsHonores(Object p0, Object p1, Object p2);

  /// No description provided for @ecrireA.
  ///
  /// In fr, this message translates to:
  /// **'Écrire à {p0}'**
  String ecrireA(Object p0);

  /// No description provided for @placeLibre4.
  ///
  /// In fr, this message translates to:
  /// **'1 place libre'**
  String get placeLibre4;

  /// No description provided for @joueursSur3.
  ///
  /// In fr, this message translates to:
  /// **'{p0} joueurs sur {p1}'**
  String joueursSur3(Object p0, Object p1);

  /// No description provided for @terrainH.
  ///
  /// In fr, this message translates to:
  /// **'TERRAIN · {p0} H'**
  String terrainH(Object p0);

  /// No description provided for @dejaEncaisse2.
  ///
  /// In fr, this message translates to:
  /// **'DÉJÀ ENCAISSÉ'**
  String get dejaEncaisse2;

  /// No description provided for @partsDe3.
  ///
  /// In fr, this message translates to:
  /// **'{p0} parts de {p1}'**
  String partsDe3(Object p0, Object p1);

  /// No description provided for @payeEnLigne2.
  ///
  /// In fr, this message translates to:
  /// **'Payé en ligne'**
  String get payeEnLigne2;

  /// No description provided for @attendusDeAvant.
  ///
  /// In fr, this message translates to:
  /// **'{p0} attendus de {p1} {p2} avant '**
  String attendusDeAvant(Object p0, Object p1, Object p2);

  /// No description provided for @t18h00LeJourJ.
  ///
  /// In fr, this message translates to:
  /// **'18h00 le jour J'**
  String get t18h00LeJourJ;

  /// No description provided for @sinonLaPartieEstAnnulee.
  ///
  /// In fr, this message translates to:
  /// **', sinon la partie est annulée et remboursée.'**
  String get sinonLaPartieEstAnnulee;

  /// No description provided for @deplacer.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer'**
  String get deplacer;

  /// No description provided for @noShowPossibleDesAnnuler.
  ///
  /// In fr, this message translates to:
  /// **'No-show possible dès {p0} · annuler rembourse les {p1} joueurs.'**
  String noShowPossibleDesAnnuler(Object p0, Object p1);

  /// No description provided for @etLesJoueursSontPrevenus.
  ///
  /// In fr, this message translates to:
  /// **'{p0} et les joueurs sont prévenus tout de suite. Le créneau redevient libre.'**
  String etLesJoueursSontPrevenus(Object p0);

  /// No description provided for @sontRemboursesAuxJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'{p0} sont remboursés aux {p1} joueurs.'**
  String sontRemboursesAuxJoueurs(Object p0, Object p1);

  /// No description provided for @remboursesAuxJoueurs.
  ///
  /// In fr, this message translates to:
  /// **'{p0} remboursés aux joueurs.'**
  String remboursesAuxJoueurs(Object p0);

  /// No description provided for @faireLeCheckIn.
  ///
  /// In fr, this message translates to:
  /// **'Faire le check-in'**
  String get faireLeCheckIn;

  /// No description provided for @des3.
  ///
  /// In fr, this message translates to:
  /// **'dès {p0}'**
  String des3(Object p0);

  /// No description provided for @changerDeRoleProprietaire.
  ///
  /// In fr, this message translates to:
  /// **'Changer de rôle, {p0}, propriétaire'**
  String changerDeRoleProprietaire(Object p0);

  /// No description provided for @entretien.
  ///
  /// In fr, this message translates to:
  /// **'Entretien'**
  String get entretien;

  /// No description provided for @evenementPrive.
  ///
  /// In fr, this message translates to:
  /// **'Événement privé'**
  String get evenementPrive;

  /// No description provided for @tournoi.
  ///
  /// In fr, this message translates to:
  /// **'Tournoi'**
  String get tournoi;

  /// No description provided for @meteo.
  ///
  /// In fr, this message translates to:
  /// **'Météo'**
  String get meteo;

  /// No description provided for @autre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get autre;

  /// No description provided for @suite.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1}, suite'**
  String suite(Object p0, Object p1);

  /// No description provided for @terminePaye.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1}, terminé, payé'**
  String terminePaye(Object p0, Object p1);

  /// No description provided for @noShow4.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1}, no-show'**
  String noShow4(Object p0, Object p1);

  /// No description provided for @enCours3.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1}, en cours'**
  String enCours3(Object p0, Object p1);

  /// No description provided for @taPartieSur.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, ta partie, {p1} sur {p2}'**
  String taPartieSur(Object p0, Object p1, Object p2);

  /// No description provided for @partiePubliqueDeSur.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, partie publique de {p1}, {p2} sur {p3}'**
  String partiePubliqueDeSur(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @surPaye.
  ///
  /// In fr, this message translates to:
  /// **'{p0}, {p1}, {p2} sur {p3} payé'**
  String surPaye(Object p0, Object p1, Object p2, Object p3);

  /// No description provided for @priveePaye.
  ///
  /// In fr, this message translates to:
  /// **'Privée · payé'**
  String get priveePaye;

  /// No description provided for @voirLeGraphique.
  ///
  /// In fr, this message translates to:
  /// **'Voir le graphique'**
  String get voirLeGraphique;

  /// No description provided for @voirLeTableau.
  ///
  /// In fr, this message translates to:
  /// **'Voir le tableau'**
  String get voirLeTableau;

  /// No description provided for @datesAConfirmer.
  ///
  /// In fr, this message translates to:
  /// **' · dates à confirmer'**
  String get datesAConfirmer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
