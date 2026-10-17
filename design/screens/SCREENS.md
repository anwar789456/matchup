# MatchUp — every screen of the app

Each screen has a PNG (`png/`) showing exactly how it must look, and its design source (`source/`, HTML) for the exact copy, spacing and which design-system component is used where (`<x-import component-from-global-scope="MatchUp.TextField" …>` = the TextField component; its spec is in `../design-system/components/TextField.md`).

**Phone only.** Screens are 390 wide. A PNG taller than 844 px is the whole scrolled page: the top bar stays at the top, the sticky bar / tab bar sits at the bottom of the visible screen, everything between scrolls. Overlay screens (sheets, dialogs, takeovers) show the screen underneath plus the overlay. Exceptions: the pro onboarding screens OWN-01…09, COA-01…03, ORG-01…02 were drawn 1440 wide — build them as phone forms with the same content (CLAUDE.md rule 9); MAP-/FLW- are diagrams; SUB-09 is an A4 document; EML-* are email templates (server side, not Flutter).

All screens share one fake data set: `STORY-DATA.md`. "Goes to" lists the screens each screen links to in the prototype.

Phases in `../START_HERE.md` say which tables to build when.

---

# Milestone 2 — onboarding, sign-in, sitemap

## Plan du site & parcours

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| MAP-01 | Plan du site (`MAP-01-Plan-du-site`) | 3200×2164 |  | — |
| FLW-01 | Parcours 1 · Rejoindre une partie (`FLW-01-Rejoindre-une-partie`) | 2632×980 |  | — |
| FLW-02 | Parcours 2 · Réserver et partager (`FLW-02-Reserver-et-partager`) | 2648×1180 |  | — |
| FLW-03 | Parcours 3 · Inscrire une équipe (`FLW-03-Inscrire-une-equipe`) | 2708×864 |  | — |
| FLW-04 | Parcours 4 · Passer Premium (`FLW-04-Passer-Premium`) | 2120×1152 |  | — |

## Bienvenue & connexion

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| ONB-01 | Splash (`ONB-01-Splash`) | 390×844 | Ouverture de l’app (1,5 s). Touche l’écran pour continuer. Entrée : lancement de l’app. | ONB-02-Bienvenue-1 |
| ONB-02 | Bienvenue 1/3 (`ONB-02-Bienvenue-1`) | 390×844 | Promesse 1 : des joueurs à ton niveau. « Suivant » ou « Passer ». Entrée : Splash. | ONB-03-Bienvenue-2, ONB-04-Bienvenue-3 |
| ONB-03 | Bienvenue 2/3 (`ONB-03-Bienvenue-2`) | 390×844 | Promesse 2 : réserver et payer sa part en quelques secondes. Entrée : Bienvenue 1. | ONB-02-Bienvenue-1, ONB-04-Bienvenue-3 |
| ONB-04 | Bienvenue 3/3 (`ONB-04-Bienvenue-3`) | 390×844 | Promesse 3 : progresser. « Commencer » ou « J’ai déjà un compte ». Entrée : Bienvenue 2 ou « Passer ». | AUTH-01-Inscription, AUTH-05-Connexion, ONB-03-Bienvenue-2 |
| AUTH-01 | Inscription (`AUTH-01-Inscription`) | 390×844 | Créer un compte par email, Google ou Apple. CTA « Créer mon compte ». Entrée : « Commencer ». | AUTH-02-Telephone, AUTH-05-Connexion, ONB-04-Bienvenue-3 |
| AUTH-01b | Inscription · erreurs (`AUTH-01b-Inscription-erreurs`) | 390×844 | Email déjà utilisé, mot de passe faible, conditions non acceptées ; saisie conservée. Entrée : envoi du formulaire invalide. | AUTH-02-Telephone, AUTH-05-Connexion, ONB-04-Bienvenue-3 |
| AUTH-02 | Téléphone (`AUTH-02-Telephone`) | 390×844 | Ajouter son numéro +216 pour sécuriser parties et paiements. Entrée : compte créé. | AUTH-01-Inscription, AUTH-03-Code-SMS |
| AUTH-03 | Code SMS (`AUTH-03-Code-SMS`) | 390×844 | Saisir le code à 6 chiffres ; renvoi après 0:45. Entrée : « Recevoir le code ». | AUTH-02-Telephone, AUTH-04-Verifie-ton-email |
| AUTH-03b | Code SMS · erreur (`AUTH-03b-Code-SMS-erreur`) | 390×844 | Code incorrect, essais restants, renvoi possible. Entrée : code faux. | AUTH-02-Telephone, AUTH-04-Verifie-ton-email |
| AUTH-04 | Vérifie ton email (`AUTH-04-Verifie-ton-email`) | 390×844 | Ouvrir sa messagerie ou continuer et vérifier plus tard. Entrée : téléphone vérifié. | AUTH-01-Inscription, AUTH-03-Code-SMS, AUTH-11-Choix-du-role |
| AUTH-11 | Choix du rôle (`AUTH-11-Choix-du-role`) | 390×844 | Choisir un ou plusieurs rôles ; « Continuer » ouvre l’onboarding du premier. Entrée : email vérifié ou connexion. | AUTH-04-Verifie-ton-email |
| AUTH-05 | Connexion (`AUTH-05-Connexion`) | 390×844 | Se connecter par email ou Google / Apple ; mot de passe oublié. Entrée : « J’ai déjà un compte ». | AUTH-01-Inscription, AUTH-06-Mot-de-passe-oublie, AUTH-11-Choix-du-role, ONB-04-Bienvenue-3 |
| AUTH-05b | Connexion · erreur (`AUTH-05b-Connexion-erreur`) | 390×844 | Identifiants incorrects, essais restants avant blocage, lien de réinitialisation. Entrée : connexion refusée. | AUTH-01-Inscription, AUTH-06-Mot-de-passe-oublie, AUTH-10-Compte-verrouille, ONB-04-Bienvenue-3 |
| AUTH-06 | Mot de passe oublié 1/3 (`AUTH-06-Mot-de-passe-oublie`) | 390×844 | Saisir son email pour recevoir un code. Entrée : « Mot de passe oublié ? ». | AUTH-05-Connexion, AUTH-07-Code-de-reinitialisation |
| AUTH-07 | Mot de passe oublié 2/3 (`AUTH-07-Code-de-reinitialisation`) | 390×844 | Saisir le code reçu par email. Entrée : « Envoyer le code ». | AUTH-06-Mot-de-passe-oublie, AUTH-08-Nouveau-mot-de-passe |
| AUTH-08 | Mot de passe oublié 3/3 (`AUTH-08-Nouveau-mot-de-passe`) | 390×844 | Choisir et confirmer le nouveau mot de passe. Entrée : code validé. | AUTH-07-Code-de-reinitialisation, AUTH-09-Mot-de-passe-modifie |
| AUTH-09 | Mot de passe modifié (`AUTH-09-Mot-de-passe-modifie`) | 390×844 | Confirmation ; autres sessions fermées. « Se connecter ». Entrée : nouveau mot de passe enregistré. | AUTH-05-Connexion |
| AUTH-10 | Compte bloqué (`AUTH-10-Compte-verrouille`) | 390×844 | Blocage 15 min après 5 échecs ; réinitialiser ou contacter le support. Entrée : 5e échec de connexion. | AUTH-05b-Connexion-erreur, AUTH-06-Mot-de-passe-oublie |

## Onboarding joueur

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| PLY-01 | Sports (`PLY-01-Sports`) | 390×844 | Choisir ses sports (multi-sélection). Entrée : rôle Joueur. | AUTH-11-Choix-du-role, PLY-02-Questionnaire-IA |
| PLY-02 | Questionnaire IA (`PLY-02-Questionnaire-IA`) | 390×844 | 6 questions, une par écran, pour estimer le niveau (interactif). Entrée : sports choisis. | PLY-01-Sports, PLY-03-Niveau-estime |
| PLY-03 | Niveau estimé (IA) (`PLY-03-Niveau-estime`) | 390×844 | Résultat 3,5 · Intermédiaire, confiance, pourquoi, « Ajuster ». Entrée : fin du questionnaire. | PLY-02-Questionnaire-IA, PLY-04-Poste |
| PLY-04 | Poste (`PLY-04-Poste`) | 390×844 | Poste préféré par sport (facultatif). Entrée : niveau validé. | PLY-03-Niveau-estime, PLY-05-Disponibilites |
| PLY-05 | Disponibilités (`PLY-05-Disponibilites`) | 390×844 | Grille jours × matin / après-midi / soir (facultatif). Entrée : poste. | PLY-04-Poste, PLY-06-Localisation |
| PLY-06 | Localisation (`PLY-06-Localisation`) | 390×844 | Écran d’explication avant la demande système. Entrée : disponibilités. | PLY-05-Disponibilites, PLY-07-Zones |
| PLY-07 | Zones préférées (`PLY-07-Zones`) | 390×844 | Ajouter ses quartiers et la distance max. Entrée : localisation activée ou « à la main ». | PLY-06-Localisation, PLY-09-Notifications |
| PLY-08 | Localisation refusée (`PLY-08-Localisation-refusee`) | 390×844 | Étapes pour l’activer dans Réglages, ou zones à la main. Entrée : permission refusée. | PLY-06-Localisation, PLY-09-Notifications |
| PLY-09 | Notifications (`PLY-09-Notifications`) | 390×844 | Exemples concrets avant la demande système ; « Plus tard » aussi visible. Entrée : zones. | PLY-07-Zones, PLY-10-Profil |
| PLY-10 | Profil (`PLY-10-Profil`) | 390×844 | Photo et pseudo. « Terminer ». Entrée : notifications. | PLY-09-Notifications, PLY-11-Accueil-visite |
| PLY-11 | Accueil + visite guidée (`PLY-11-Accueil-visite`) | 390×844 | Accueil personnalisé et visite en 3 étapes (interactif). Entrée : fin de l’onboarding. | ENT-01-Mon-entrainement, EXP-01-Explorer-parties, FRM-01-Communaute, GAM-01-Partie-ouverte, HOM-01-Accueil, MAT-01-A-venir |

## Onboarding pros

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| OWN-01 | Propriétaire 1/8 · Entreprise (`OWN-01-Entreprise`) | 1440×900 | Infos légales et contact du terrain. Entrée : rôle Propriétaire. | AUTH-11-Choix-du-role, OWN-02-Adresse, OWN-09-Tableau-de-bord |
| OWN-02 | Propriétaire 2/8 · Adresse (`OWN-02-Adresse`) | 1440×900 | Adresse et épingle sur la carte. Entrée : étape 1. | OWN-01-Entreprise, OWN-03-Terrains, OWN-09-Tableau-de-bord |
| OWN-03 | Propriétaire 3/8 · Terrains (`OWN-03-Terrains`) | 1440×900 | Liste des terrains : sport, surface, intérieur, éclairage. Entrée : étape 2. | OWN-02-Adresse, OWN-04-Horaires, OWN-09-Tableau-de-bord |
| OWN-04 | Propriétaire 4/8 · Horaires (`OWN-04-Horaires`) | 1440×900 | Horaires par jour, fermetures exceptionnelles. Entrée : étape 3. | OWN-03-Terrains, OWN-05-Tarifs, OWN-09-Tableau-de-bord |
| OWN-05 | Propriétaire 5/8 · Tarifs (`OWN-05-Tarifs`) | 1440×900 | Heures creuses / de pointe, aperçu du prix par personne. Entrée : étape 4. | OWN-04-Horaires, OWN-06-Photos, OWN-09-Tableau-de-bord |
| OWN-06 | Propriétaire 6/8 · Photos (`OWN-06-Photos`) | 1440×900 | Import des photos, couverture, erreurs d’envoi. Entrée : étape 5. | OWN-05-Tarifs, OWN-07-Versements, OWN-09-Tableau-de-bord |
| OWN-07 | Propriétaire 7/8 · Versements (`OWN-07-Versements`) | 1440×900 | Compte bancaire (RIB) et attestation. Entrée : étape 6. | OWN-06-Photos, OWN-08-Offre, OWN-09-Tableau-de-bord |
| OWN-08 | Propriétaire 8/8 · Offre (`OWN-08-Offre`) | 1440×900 | Starter ou Pro, mensuel / annuel, essai gratuit (interactif). Entrée : étape 7. | OWN-07-Versements, OWN-09-Tableau-de-bord |
| OWN-09 | Tableau de bord · premiers pas (`OWN-09-Tableau-de-bord`) | 1440×900 | Checklist de mise en ligne 4/6 et tableau de bord vide. Entrée : essai démarré. | OWN-01-Entreprise, OWN-02-Adresse, OWN-04-Horaires, OWN-06-Photos, OWN-11-Planning |
| COA-01 | Coach 1/3 · Profil (`COA-01-Profil-coach`) | 1440×900 | Bio, spécialités, sports et niveaux encadrés (interactif). Entrée : rôle Coach. | AUTH-11-Choix-du-role, COA-02-Certification, COA-03-Premier-programme |
| COA-02 | Coach 2/3 · Certification (`COA-02-Certification`) | 1440×900 | Diplôme envoyé, vérification en attente 48 h. Entrée : profil coach. | COA-01-Profil-coach, COA-03-Premier-programme |
| COA-03 | Coach 3/3 · Premier programme (`COA-03-Premier-programme`) | 1440×900 | Tableau de bord coach, invitation à créer un programme, aide IA. Entrée : certification envoyée. | COA-01-Profil-coach, COA-06-Constructeur |
| ORG-01 | Organisateur 1/2 · Organisation (`ORG-01-Organisation`) | 1440×900 | Nom, logo, contact, événements passés (facultatif). Entrée : rôle Organisateur. | AUTH-11-Choix-du-role, ORG-02-Pret |
| ORG-02 | Organisateur 2/2 · Prêt (`ORG-02-Pret`) | 1440×900 | Tableau de bord organisateur, « Crée ton premier tournoi ». Entrée : organisation enregistrée. | ORG-01-Organisation, ORG-05-Creer-infos |

---

# Milestone 3 — player core

## Accueil & Explorer

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| HOM-01 | Accueil (`HOM-01-Accueil`) | 390×2384 | Accueil complet : parties IA pour toi, actions rapides, prochains matchs, terrains et tournois près de toi. Entrée : onglet Accueil, fin de l’onboarding. | AI-01-Assistant, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, FRM-01-Communaute, GAM-01-Partie-ouverte, MAT-01-A-venir, MAT-05-Detail-reservation, NOT-01-Centre-de-notifications, PRF-05-Menu-du-compte, VEN-01-Terrain |
| HOM-02 | Accueil · chargement (`HOM-02-Accueil-chargement`) | 390×2252 | Squelettes à la place du contenu, pas de spinner ; l’en-tête reste utilisable. Entrée : ouverture de l’app. | AI-01-Assistant, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, FRM-01-Communaute, HOM-01-Accueil, MAT-01-A-venir, PRF-05-Menu-du-compte |
| EXP-01 | Explorer · parties (`EXP-01-Explorer-parties`) | 390×844 | Parties ouvertes en liste : recherche, filtres rapides, tri, bascule carte. Entrée : onglet Explorer. | AI-01-Assistant, ENT-01-Mon-entrainement, EXP-02-Explorer-carte, EXP-03-Explorer-terrains, EXP-04-Filtres, EXP-05-Recherche, FRM-01-Communaute, GAM-01-Partie-ouverte, GAM-02-Partie-complete, HOM-01-Accueil, MAT-01-A-venir, TRN-01-Tournois |
| EXP-02 | Explorer · carte (`EXP-02-Explorer-carte`) | 390×844 | Même recherche en carte : épingles par sport, groupes, mini-fiche de la partie choisie. Entrée : bascule « Carte ». | AI-01-Assistant, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, EXP-04-Filtres, EXP-05-Recherche, FRM-01-Communaute, GAM-01-Partie-ouverte, GAM-02-Partie-complete, HOM-01-Accueil, MAT-01-A-venir, TRN-01-Tournois |
| EXP-03 | Explorer · terrains (`EXP-03-Explorer-terrains`) | 390×844 | Terrains libres ce soir avec le prix par personne. Entrée : segment Terrains, « Réserver un terrain ». | AI-01-Assistant, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-04-Filtres, EXP-05-Recherche, FRM-01-Communaute, HOM-01-Accueil, MAT-01-A-venir, TRN-01-Tournois, VEN-01-Terrain |
| EXP-04 | Filtres (`EXP-04-Filtres`) | 390×844 | Panneau de filtres : sport, date, niveau, prix, distance, type, équipements. Entrée : puce « Filtres ». | ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-02-Explorer-carte, EXP-03-Explorer-terrains, EXP-05-Recherche, FRM-01-Communaute, GAM-01-Partie-ouverte, GAM-02-Partie-complete, HOM-01-Accueil, MAT-01-A-venir |
| EXP-05 | Recherche (`EXP-05-Recherche`) | 390×844 | Recherches récentes et suggestions (zones, terrains, parties, joueurs). Entrée : champ de recherche. | EXP-01-Explorer-parties, GAM-01-Partie-ouverte, VEN-01-Terrain |
| EXP-06 | Aucun résultat (`EXP-06-Aucun-resultat`) | 390×844 | État vide avec pistes : alerte, élargir, retirer un filtre, créer une partie. Entrée : filtres trop serrés. | AI-01-Assistant, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, EXP-04-Filtres, EXP-05-Recherche, FRM-01-Communaute, HOM-01-Accueil, MAT-01-A-venir, TRN-01-Tournois |
| EXP-07 | Hors ligne (`EXP-07-Erreur-de-chargement`) | 390×844 | Bandeau hors ligne, « Réessayer », résultats enregistrés affichés. Entrée : pas de connexion. | AI-01-Assistant, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-02-Explorer-carte, EXP-03-Explorer-terrains, EXP-04-Filtres, FRM-01-Communaute, GAM-01-Partie-ouverte, GAM-02-Partie-complete, HOM-01-Accueil, MAT-01-A-venir, TRN-01-Tournois |

## Terrains & réservation

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| VEN-01 | Fiche du terrain (`VEN-01-Terrain`) | 390×2392 | Galerie, Vérifié, avis, créneaux avec prix terrain et par personne, équipements, annulation. « Réserver ». Entrée : Explorer · Terrains, Accueil. | EXP-03-Explorer-terrains, VEN-02-Creneau |
| VEN-02 | Créneau choisi (`VEN-02-Creneau`) | 390×844 | Détail du créneau : 150 DT, 15 DT par personne à 10, annulation gratuite. Entrée : « Réserver ». | BKG-01-Type-de-reservation, VEN-01-Terrain |
| BKG-01 | Réservation 1/3 · type (`BKG-01-Type-de-reservation`) | 390×844 | Privée (j’invite mes amis) ou publique (je complète avec des joueurs). Entrée : créneau choisi. | VEN-02-Creneau |
| BKG-02 | Réservation 2/3 · partie publique (`BKG-02-Partie-publique`) | 390×1132 | Places à compléter, niveau, type, visibilité, mot pour les joueurs. Entrée : type Publique. | BKG-01-Type-de-reservation, BKG-03-Inviter-des-amis, BKG-04-Recapitulatif |
| BKG-03 | Réservation 2/3 · invités (`BKG-03-Inviter-des-amis`) | 390×1360 | Inviter des amis, coéquipiers suggérés, lien à partager. Entrée : type Privée ou « Inviter des joueurs ». | BKG-01-Type-de-reservation, BKG-04-Recapitulatif |
| BKG-04 | Réservation 3/3 · récapitulatif (`BKG-04-Recapitulatif`) | 390×1600 | Qui paie quoi (chacun sa part ou tout), solde, détail du prix, annulation avant de payer. « Payer ma part » ouvre le checkout PAY-01. Entrée : étape 2. | BKG-02-Partie-publique, PAY-01-Checkout |
| BKG-05 | Réservation confirmée (`BKG-05-Reservation-confirmee`) | 390×1468 | Billet QR, calendrier, partage, suivi des paiements, inviter. Entrée : paiement réussi. | BKG-03-Inviter-des-amis, HOM-01-Accueil, MAT-05-Detail-reservation |

## Parties ouvertes

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| GAM-01 | Partie ouverte (`GAM-01-Partie-ouverte`) | 390×2400 | Lobby : composition 5 vs 5 avec places libres, compatibilité IA, organisateur, discussion, règles. « Rejoindre et payer · 15 DT ». Entrée : carte de partie (Accueil, Explorer). | EXP-01-Explorer-parties, GAM-05-Tu-es-inscrit, PRF-02-Profil-public, VEN-01-Terrain |
| GAM-02 | Partie complète (`GAM-02-Partie-complete`) | 390×2400 | Même partie à 10/10 : « Rejoindre la liste d’attente », gratuit tant qu’on ne réclame pas. Entrée : carte d’une partie complète. | EXP-01-Explorer-parties, GAM-03-Liste-d-attente, PRF-02-Profil-public, VEN-01-Terrain |
| GAM-03 | Liste d’attente (`GAM-03-Liste-d-attente`) | 390×844 | Position dans la file, comment ça marche, quitter la liste. Entrée : liste d’attente rejointe. | EXP-01-Explorer-parties, GAM-02-Partie-complete, GAM-04-Place-disponible |
| GAM-04 | Place disponible (`GAM-04-Place-disponible`) | 390×844 | Plein écran : 15 min pour réclamer la place libérée. Entrée : notification « Place libérée ». | GAM-03-Liste-d-attente, GAM-05-Tu-es-inscrit |
| GAM-05 | Tu es inscrit (`GAM-05-Tu-es-inscrit`) | 390×1604 | Confirmation : part payée, composition avec toi, calendrier, discussion, inviter. Entrée : paiement ou place réclamée. | HOM-01-Accueil, MAT-01-A-venir |

## Mes matchs

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| MAT-01 | À venir (`MAT-01-A-venir`) | 390×844 | Invitation à répondre, parties où tu joues, réservations que tu organises. Entrée : onglet Mes matchs. | AI-01-Assistant, BKG-03-Inviter-des-amis, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, FRM-01-Communaute, GAM-01-Partie-ouverte, HOM-01-Accueil, MAT-02-Passes, MAT-03-Annules, MAT-05-Detail-reservation, MAT-07-Quitter-la-partie |
| MAT-02 | Passés (`MAT-02-Passes`) | 390×844 | Résultats, évaluation des coéquipiers à faire. Entrée : onglet Passés. | AI-01-Assistant, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, FRM-01-Communaute, HOM-01-Accueil, MAT-01-A-venir, MAT-03-Annules, MAT-08-Evaluer-les-joueurs, PRF-01-Mon-profil |
| MAT-03 | Annulés (`MAT-03-Annules`) | 390×844 | Matchs annulés et statut du remboursement. Entrée : onglet Annulés. | AI-01-Assistant, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, FRM-01-Communaute, HOM-01-Accueil, MAT-01-A-venir, MAT-02-Passes, VEN-01-Terrain |
| MAT-04 | Aucun match à venir (`MAT-04-Aucun-match`) | 390×844 | État vide : trouver une partie ou réserver. Entrée : Mes matchs sans réservation. | AI-01-Assistant, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, FRM-01-Communaute, HOM-01-Accueil, MAT-01-A-venir, MAT-02-Passes, MAT-03-Annules |
| MAT-05 | Détail de la réservation (`MAT-05-Detail-reservation`) | 390×2280 | QR code, lieu, joueurs et paiements, discussion, annulation, inviter. Entrée : carte de réservation. | BKG-03-Inviter-des-amis, MAT-01-A-venir, MAT-06-Annuler-la-reservation, PAY-11-Suivi-des-paiements, VEN-01-Terrain |
| MAT-06 | Annuler la réservation (`MAT-06-Annuler-la-reservation`) | 390×844 | Confirmation avec remboursement de chaque joueur. Entrée : « Annuler la réservation ». | BKG-03-Inviter-des-amis, MAT-01-A-venir, MAT-03-Annules, MAT-05-Detail-reservation, VEN-01-Terrain |
| MAT-07 | Quitter la partie (`MAT-07-Quitter-la-partie`) | 390×844 | Conséquence et remboursement avant de quitter. Entrée : « Quitter » sur une partie. | BKG-03-Inviter-des-amis, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, FRM-01-Communaute, GAM-01-Partie-ouverte, HOM-01-Accueil, MAT-01-A-venir, MAT-02-Passes, MAT-03-Annules, MAT-05-Detail-reservation |
| MAT-08 | Évaluer les joueurs (`MAT-08-Evaluer-les-joueurs`) | 390×844 | Niveau ce jour-là et fair-play de chaque joueur, signaler une absence. Entrée : « Évaluer les joueurs ». | ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, FRM-01-Communaute, HOM-01-Accueil, MAT-01-A-venir, MAT-02-Passes, MAT-03-Annules, MAT-09-Score-du-match, PRF-01-Mon-profil |
| MAT-09 | Score du match (`MAT-09-Score-du-match`) | 390×844 | Saisie facultative du score, confirmée par l’adversaire. Entrée : évaluation envoyée. | MAT-02-Passes, MAT-08-Evaluer-les-joueurs |

## Profil & paramètres

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| PRF-01 | Mon profil (`PRF-01-Mon-profil`) | 390×2376 | Niveaux IA par sport avec tendance, fiabilité, stats, badges, matchs, avis. Entrée : menu du compte. | HOM-01-Accueil, MAT-02-Passes, PRF-03-Pourquoi-ce-niveau, PRF-04-Modifier-le-profil, SET-01-Parametres |
| PRF-02 | Profil public (`PRF-02-Profil-public`) | 390×2388 | Profil de Skander T. vu par un autre joueur : suivre, inviter, signaler. Entrée : organisateur d’une partie. | GAM-01-Partie-ouverte |
| PRF-03 | Pourquoi ce niveau ? (`PRF-03-Pourquoi-ce-niveau`) | 390×844 | Ce que l’IA a pris en compte, matchs qui ont fait bouger le niveau, ajuster ou contester. Entrée : « Pourquoi ce niveau ? ». | PRF-01-Mon-profil |
| PRF-04 | Modifier le profil (`PRF-04-Modifier-le-profil`) | 390×2020 | Photo, couverture, pseudo, bio, sports et postes, zones, visibilité. Entrée : « Modifier le profil ». | PRF-01-Mon-profil, PRF-03-Pourquoi-ce-niveau, SET-05-Confidentialite |
| PRF-05 | Menu du compte (`PRF-05-Menu-du-compte`) | 390×844 | Profil, portefeuille, paramètres, changer de rôle, aide, déconnexion. Entrée : avatar de l’Accueil. | AUTH-05-Connexion, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, FRM-01-Communaute, HOM-01-Accueil, MAT-01-A-venir, PRF-01-Mon-profil, PRF-06-Changer-de-role, SET-01-Parametres, SUB-01-Offres, WAL-01-Portefeuille |
| PRF-06 | Changer de rôle (`PRF-06-Changer-de-role`) | 390×844 | Joueur actif, propriétaire à terminer, ajouter un rôle. Entrée : menu du compte. | AUTH-11-Choix-du-role, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, FRM-01-Communaute, HOM-01-Accueil, MAT-01-A-venir, OWN-09-Tableau-de-bord, PRF-05-Menu-du-compte |
| SET-01 | Paramètres (`SET-01-Parametres`) | 390×844 | Compte, sécurité, notifications, langue et thème, confidentialité, aide, supprimer le compte. Entrée : profil ou menu du compte. | AUTH-05-Connexion, NOT-10-Preferences, PRF-01-Mon-profil, SET-02-Compte, SET-03-Securite, SET-04-Langue-et-theme, SET-05-Confidentialite, SET-06-Comptes-connectes, SET-07-Supprimer-le-compte |
| SET-02 | Compte (`SET-02-Compte`) | 390×984 | Email et téléphone vérifiés, infos personnelles. Entrée : Paramètres › Compte. | SET-01-Parametres |
| SET-03 | Sécurité (`SET-03-Securite`) | 390×844 | Mot de passe, double authentification, sessions actives. Entrée : Paramètres › Sécurité. | SET-01-Parametres |
| SET-04 | Langue et thème (`SET-04-Langue-et-theme`) | 390×844 | Français, العربية, English ; clair, sombre, système. Entrée : Paramètres › Langue et thème. | SET-01-Parametres |
| SET-05 | Confidentialité (`SET-05-Confidentialite`) | 390×844 | Visibilité du profil, invitations, niveau, fiabilité, position, données. Entrée : Paramètres › Confidentialité. | SET-01-Parametres |
| SET-06 | Comptes connectés (`SET-06-Comptes-connectes`) | 390×844 | Email, Google, Apple ; garder au moins une méthode. Entrée : Paramètres › Comptes connectés. | SET-01-Parametres |
| SET-07 | Supprimer le compte (`SET-07-Supprimer-le-compte`) | 390×984 | Conséquences, raison facultative, taper SUPPRIMER pour confirmer. Entrée : Paramètres › Supprimer le compte. | ONB-01-Splash, SET-01-Parametres |

---

# Milestones 4–5 — payments, notifications, emails

## Paiement

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| PAY-01 | Checkout (`PAY-01-Checkout`) | 390×1500 | Payer sa part : résumé repliable, code promo, solde, cartes enregistrées, paiement express, conditions. « Payer 15 DT ». Entrée : « Payer ma part » du récapitulatif. | BKG-04-Recapitulatif, PAY-02-Checkout-detail, PAY-03-Nouvelle-carte, PAY-06-Paiement-en-cours |
| PAY-02 | Checkout · détail (`PAY-02-Checkout-detail`) | 390×1972 | Résumé déplié et code promo BIENVENUE10 appliqué : 13,500 DT. Entrée : « Voir le détail ». | BKG-04-Recapitulatif, PAY-01-Checkout, PAY-03-Nouvelle-carte, PAY-06-Paiement-en-cours |
| PAY-03 | Nouvelle carte (`PAY-03-Nouvelle-carte`) | 390×1796 | Nom sur la carte + zone sécurisée Stripe (Payment Element), enregistrer la carte. Entrée : « Ajouter une carte ». | PAY-01-Checkout, PAY-06-Paiement-en-cours |
| PAY-04 | Erreurs de saisie (`PAY-04-Erreurs-de-saisie`) | 390×2072 | Récapitulatif des erreurs et erreurs dans les champs ; la saisie est gardée. Entrée : « Payer » avec des champs invalides. | PAY-01-Checkout |
| PAY-05 | Carte refusée (`PAY-05-Carte-refusee`) | 390×1600 | Raison en clair, rien n’est débité ; payer avec le solde ou une autre carte. Entrée : refus de la banque. | PAY-01-Checkout, PAY-03-Nouvelle-carte, PAY-06-Paiement-en-cours |
| PAY-06 | Paiement en cours (`PAY-06-Paiement-en-cours`) | 390×844 | Écran bloquant, formulaire verrouillé : « Ne ferme pas cette page ». Entrée : « Payer ». | PAY-01-Checkout, PAY-07-3D-Secure |
| PAY-07 | 3-D Secure (`PAY-07-3D-Secure`) | 390×844 | Fenêtre de la banque dans notre cadre, sans fermeture pendant l’authentification. Entrée : banque qui demande une validation. | PAY-01-Checkout, PAY-09-Paiement-reussi |
| PAY-08 | Erreur réseau (`PAY-08-Erreur-reseau`) | 390×1216 | Connexion perdue : vérifier le statut avant de réessayer. Variante délai dépassé : « Ta banque met trop de temps à répondre ». Entrée : coupure pendant le paiement. | PAY-01-Checkout, PAY-06-Paiement-en-cours, PAY-09-Paiement-reussi |
| PAY-09 | Paiement réussi (`PAY-09-Paiement-reussi`) | 390×1748 | Reçu, QR de la réservation, calendrier, partage, inviter. Entrée : paiement accepté. | BKG-03-Inviter-des-amis, MAT-05-Detail-reservation, SUB-09-Facture-PDF |
| PAY-10 | Paiement échoué (`PAY-10-Paiement-echoue`) | 390×1116 | Raison, place gardée 15 min, réessayer ou changer de moyen. Entrée : échecs répétés. | BKG-04-Recapitulatif, PAY-01-Checkout, PAY-03-Nouvelle-carte |
| PAY-11 | Suivi des paiements (`PAY-11-Suivi-des-paiements`) | 390×1500 | Qui a payé, relances, compte à rebours jusqu’à 3 h avant, « Payer le reste ». État du mer. 21 oct. à 14h00. Entrée : « Paiements » du détail de réservation. | BKG-03-Inviter-des-amis, MAT-05-Detail-reservation, PAY-12-Payer-le-reste |
| PAY-12 | Payer le reste (`PAY-12-Payer-le-reste`) | 390×844 | L’organisateur avance les 2 parts manquantes (30 DT). Entrée : « Payer le reste ». | PAY-06-Paiement-en-cours, PAY-11-Suivi-des-paiements |

## Portefeuille & abonnement

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| WAL-01 | Portefeuille (`WAL-01-Portefeuille`) | 390×1308 | Solde 30 DT, recharge, remboursements, historique filtrable. Entrée : menu du compte › Portefeuille. | PRF-05-Menu-du-compte, SUB-09-Facture-PDF, WAL-02-Recharger, WAL-04-Demande-de-remboursement, WAL-05-Statut-du-remboursement |
| WAL-02 | Recharger (`WAL-02-Recharger`) | 390×844 | Montant (20 / 50 / 100 DT ou autre) et carte. Entrée : « Recharger ». | WAL-01-Portefeuille, WAL-03-Recharge-checkout |
| WAL-03 | Recharge · paiement (`WAL-03-Recharge-checkout`) | 390×1340 | Checkout de la recharge de 50 DT. Entrée : « Continuer ». | PAY-03-Nouvelle-carte, PAY-06-Paiement-en-cours, WAL-02-Recharger |
| WAL-04 | Demande de remboursement (`WAL-04-Demande-de-remboursement`) | 390×1368 | Quel paiement, que s’est-il passé, où être remboursé. Entrée : « Demander un remboursement ». | MAT-01-A-venir, WAL-01-Portefeuille, WAL-05-Statut-du-remboursement |
| WAL-05 | Suivi du remboursement (`WAL-05-Statut-du-remboursement`) | 390×1384 | Étapes de la demande, ce qui se passe ensuite, support. Entrée : demande envoyée. | WAL-01-Portefeuille |
| SUB-01 | Offres (`SUB-01-Offres`) | 390×2172 | Joueur · Propriétaire · Coach, mensuel ou annuel, comparatif, FAQ. Entrée : menu du compte › MatchUp Premium. | COA-01-Profil-coach, OWN-09-Tableau-de-bord, PRF-05-Menu-du-compte, SUB-02-Checkout-Premium |
| SUB-02 | Checkout Premium (`SUB-02-Checkout-Premium`) | 390×1388 | Essai gratuit 14 jours : 0 DT aujourd’hui, 19 DT le ven. 30 oct. Entrée : « Essayer Premium gratuitement ». | PAY-03-Nouvelle-carte, SUB-01-Offres, SUB-03-Bienvenue-Premium |
| SUB-03 | Bienvenue dans Premium (`SUB-03-Bienvenue-Premium`) | 390×1272 | Ce qui est débloqué et le récap de l’essai. Entrée : essai démarré. | HOM-01-Accueil, SUB-04-Abonnement |
| SUB-04 | Abonnement (`SUB-04-Abonnement`) | 390×1376 | Offre en cours, moyens de paiement, reçus PDF, résilier. Entrée : « Gérer mon abonnement ». | PAY-03-Nouvelle-carte, PRF-05-Menu-du-compte, SUB-01-Offres, SUB-05-Changer-d-offre, SUB-06-Resilier-raison, SUB-09-Facture-PDF |
| SUB-05 | Changer d’offre (`SUB-05-Changer-d-offre`) | 390×844 | Mensuel ou annuel avec l’aperçu de ce qui sera prélevé. Entrée : « Changer d’offre ». | SUB-04-Abonnement |
| SUB-06 | Résilier 1/2 (`SUB-06-Resilier-raison`) | 390×844 | Pourquoi tu pars (facultatif). Entrée : « Résilier l’abonnement ». | SUB-04-Abonnement, SUB-07-Offre-de-retention |
| SUB-07 | Résilier 2/2 · offre IA (`SUB-07-Offre-de-retention`) | 390×844 | Offre −30 % pendant 2 mois et « Non merci, résilier » du même poids. Entrée : « Continuer ». | SUB-04-Abonnement, SUB-06-Resilier-raison, SUB-08-Resiliation-confirmee |
| SUB-08 | Résiliation confirmée (`SUB-08-Resiliation-confirmee`) | 390×844 | Premium actif jusqu’au ven. 30 oct., aucun prélèvement. Entrée : « Non merci, résilier ». | PRF-01-Mon-profil, SUB-04-Abonnement |
| SUB-09 | Reçu PDF (A4) (`SUB-09-Facture-PDF`) | 595×842 | Reçu de paiement imprimable (document A4, pas un écran). Entrée : « PDF » ou « Voir le reçu ». | — |

## Notifications

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| NOT-01 | Centre de notifications (`NOT-01-Centre-de-notifications`) | 390×1580 | Filtres, non lues, Aujourd’hui / Cette semaine / Plus ancien, actions dans les notifications. Entrée : cloche de l’Accueil. | GAM-04-Place-disponible, HOM-01-Accueil, MAT-01-A-venir, MAT-02-Passes, MAT-05-Detail-reservation, MAT-08-Evaluer-les-joueurs, NOT-02-Notifications-paiements, NOT-10-Preferences, PAY-01-Checkout, WAL-01-Portefeuille, WAL-05-Statut-du-remboursement |
| NOT-02 | Filtre Paiements (`NOT-02-Notifications-paiements`) | 390×844 | Filtre actif et une notification glissée (« Lu » / « Supprimer »). Entrée : puce Paiements. | HOM-01-Accueil, NOT-01-Centre-de-notifications, NOT-10-Preferences, PAY-01-Checkout, WAL-01-Portefeuille, WAL-05-Statut-du-remboursement |
| NOT-03 | Aucune notification (`NOT-03-Aucune-notification`) | 390×844 | État vide « Tout est calme ». Entrée : centre sans notification. | HOM-01-Accueil, NOT-10-Preferences |
| NOT-07 | Temps réel · toast (`NOT-07-Toast-temps-reel`) | 390×2036 | Un joueur rejoint la partie affichée : jeton animé, compteur, toast ; anatomie du toast. Entrée : lobby ouvert. | GAM-01-Partie-ouverte, GAM-05-Tu-es-inscrit |
| NOT-10 | Préférences (`NOT-10-Preferences`) | 390×1492 | Catégories × canaux, paiements et sécurité verrouillés, heures calmes, récap, pause. Entrée : Paramètres › Notifications. | SET-01-Parametres |
| NOT-04 | Catalogue 1/3 (`NOT-04-Catalogue-matchs-reservations`) | 390×2056 | Toutes les notifications Matchs et Réservations, avec leur priorité. Documentation. | BKG-03-Inviter-des-amis, EXP-03-Explorer-terrains, GAM-01-Partie-ouverte, GAM-04-Place-disponible, MAT-01-A-venir, MAT-05-Detail-reservation, MAT-08-Evaluer-les-joueurs, NOT-05-Catalogue-paiements-tournois |
| NOT-05 | Catalogue 2/3 (`NOT-05-Catalogue-paiements-tournois`) | 390×2200 | Paiements et Tournois. Documentation. | NOT-04-Catalogue-matchs-reservations, NOT-06-Catalogue-entrainement-communaute-pros, PAY-01-Checkout, PAY-05-Carte-refusee, PAY-09-Paiement-reussi, SUB-04-Abonnement, SUB-09-Facture-PDF, WAL-01-Portefeuille |
| NOT-06 | Catalogue 3/3 (`NOT-06-Catalogue-entrainement-communaute-pros`) | 390×2380 | Entraînement, Communauté et espaces pro. Documentation. | NOT-05-Catalogue-paiements-tournois |
| NOT-08 | Push · iOS (`NOT-08-Push-iOS`) | 390×844 | Écran verrouillé : sensible au temps, groupée, avec actions. Entrée : notification push. | GAM-04-Place-disponible, MAT-01-A-venir, MAT-05-Detail-reservation, PAY-01-Checkout |
| NOT-09 | Push · Android (`NOT-09-Push-Android`) | 390×844 | Volet : notification dépliée avec actions, groupe, rappel. Entrée : notification push. | GAM-04-Place-disponible, MAT-01-A-venir, MAT-05-Detail-reservation, NOT-10-Preferences, PAY-01-Checkout |

## Emails

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| EML-01 | Bienvenue (`EML-01-Bienvenue`) | 390×1748 | Vérifier son email. Envoyé après l’inscription. | NOT-10-Preferences |
| EML-02 | Code de réinitialisation (`EML-02-Code-de-reinitialisation`) | 390×1340 | Code à 6 chiffres, valable 15 min. Envoyé depuis « Mot de passe oublié ». | AUTH-07-Code-de-reinitialisation, NOT-10-Preferences |
| EML-03 | Réservation confirmée (`EML-03-Reservation-confirmee`) | 390×2144 | QR, terrain, horaire, joueurs, accès, annulation. Envoyé après la réservation. | MAT-05-Detail-reservation, NOT-10-Preferences |
| EML-03b | Réservation confirmée · sombre (`EML-03b-Reservation-confirmee-sombre`) | 390×2144 | Le même email dans une messagerie en mode sombre. | MAT-05-Detail-reservation, NOT-10-Preferences |
| EML-04 | Rappel de match (`EML-04-Rappel-de-match`) | 390×1820 | La veille du match. Envoyé automatiquement. | GAM-05-Tu-es-inscrit, MAT-07-Quitter-la-partie, NOT-10-Preferences |
| EML-05 | Reçu de paiement (`EML-05-Recu-de-paiement`) | 390×1652 | Reçu avec TVA et PDF. Envoyé après chaque paiement. | NOT-10-Preferences, SUB-09-Facture-PDF |
| EML-06 | Demande de paiement (`EML-06-Demande-de-paiement`) | 390×1664 | Relance d’une part à payer. Envoyé par « Relancer ». | NOT-10-Preferences, PAY-01-Checkout |
| EML-07 | Abonnement (`EML-07-Abonnement`) | 390×2364 | Fin d’essai J-3, plus les variantes renouvelé et échec. Envoyé par la facturation. | NOT-10-Preferences, SUB-04-Abonnement, SUB-06-Resilier-raison |
| EML-08 | Inscription au tournoi (`EML-08-Inscription-tournoi`) | 390×2300 | Équipe et calendrier des matchs. Envoyé après l’inscription. | NOT-10-Preferences |
| EML-09 | Récap hebdo IA (`EML-09-Recap-hebdo`) | 390×2144 | Ta semaine et 3 parties près de chez toi. Le dimanche à 10h00. | EXP-01-Explorer-parties, NOT-10-Preferences |
| EML-10 | Offre de rétention (`EML-10-Offre-de-retention`) | 390×1784 | −30 % pendant 2 mois, « Non merci » du même poids. Quand l’IA détecte un risque de résiliation. | NOT-10-Preferences, SUB-04-Abonnement |
| EML-11 | Propriétaire · réservation et versement (`EML-11-Nouvelle-reservation-proprietaire`) | 390×1948 | Nouvelle réservation et versement envoyé. Envoyé au propriétaire. | NOT-10-Preferences, OWN-09-Tableau-de-bord |

---

# Milestone 9 — global states, dark mode, Arabic

## États globaux

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| STA-01 | Hors ligne (`STA-01-Hors-ligne`) | 390×844 | Données en cache, QR disponible, réessayer. Entrée : pas de réseau. | ENT-01-Mon-entrainement, EXP-07-Erreur-de-chargement, FRM-01-Communaute, HOM-01-Accueil, MAT-01-A-venir, MAT-05-Detail-reservation, NOT-01-Centre-de-notifications, PRF-05-Menu-du-compte |
| STA-02 | Erreur serveur (`STA-02-Erreur-serveur`) | 390×844 | Ce qui n’a pas changé, réessayer, référence. Entrée : erreur 503. | AI-01-Assistant, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, FRM-01-Communaute, HOM-01-Accueil, MAT-01-A-venir, MAT-02-Passes, MAT-03-Annules |
| STA-03 | Page introuvable (`STA-03-Page-introuvable`) | 390×844 | Lien expiré ou partie supprimée, alternatives. Entrée : lien mort. | EXP-01-Explorer-parties, GAM-01-Partie-ouverte, HOM-01-Accueil |
| STA-04 | Session expirée (`STA-04-Session-expiree`) | 390×844 | Rien n’est perdu, se reconnecter. Entrée : session expirée. | AUTH-05-Connexion |
| STA-05 | Caméra refusée (`STA-05-Permission-camera`) | 390×844 | Étapes pour l’activer, saisie manuelle. Entrée : check-in sans caméra. | AI-07-Assistant-pro, OWN-10-Aujourdhui, OWN-11-Planning, OWN-14-Reservations, OWN-15-Plus, OWN-20-Scanner, PRF-06-Changer-de-role |
| STA-06 | Email non vérifié (`STA-06-Email-non-verifie`) | 390×844 | Bandeau, renvoyer l’email. Entrée : Accueil. | AI-01-Assistant, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, FRM-01-Communaute, GAM-01-Partie-ouverte, HOM-01-Accueil, MAT-01-A-venir, MAT-05-Detail-reservation, NOT-01-Centre-de-notifications, PRF-05-Menu-du-compte, VEN-01-Terrain |
| STA-07 | Compte suspendu (`STA-07-Compte-suspendu`) | 390×844 | Raison, fin, ce qui reste possible, contester. Entrée : Accueil d’un compte suspendu. | ENT-01-Mon-entrainement, EXP-01-Explorer-parties, FRM-01-Communaute, HOM-01-Accueil, MAT-01-A-venir |
| STA-08 | Profil incomplet (`STA-08-Profil-incomplet`) | 390×844 | Rappel avec ce qui manque. Entrée : Mon profil. | HOM-01-Accueil, MAT-02-Passes, PRF-03-Pourquoi-ce-niveau, PRF-04-Modifier-le-profil, SET-01-Parametres |
| STA-09 | Rafraîchir et fin de liste (`STA-09-Rafraichir-et-fin-de-liste`) | 390×1384 | Tirer pour rafraîchir, fin de liste, retour en arrière après échec. Entrée : Explorer. | ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, EXP-04-Filtres, EXP-05-Recherche, FRM-01-Communaute, GAM-02-Partie-complete, GAM-03-Liste-d-attente, HOM-01-Accueil, MAT-01-A-venir |

## Sombre & arabe

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| DRK-01 | Accueil · sombre (`DRK-01-Accueil-sombre`) | 390×2384 | Accueil en mode sombre « Night match ». | ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, FRM-01-Communaute, GAM-01-Partie-ouverte, HOM-01-Accueil, MAT-01-A-venir, MAT-05-Detail-reservation, NOT-01-Centre-de-notifications, PRF-05-Menu-du-compte, VEN-01-Terrain |
| DRK-02 | Partie · sombre (`DRK-02-Partie-sombre`) | 390×2400 | Lobby de partie en mode sombre. | EXP-01-Explorer-parties, GAM-05-Tu-es-inscrit, PRF-02-Profil-public, VEN-01-Terrain |
| DRK-03 | Match en direct · sombre (`DRK-03-Match-en-direct-sombre`) | 390×1412 | Match en direct en mode sombre. | TRN-07-Inscription-confirmee, TRN-09-Poules-et-classement, TRN-11-Recap-IA |
| DRK-04 | Checkout · sombre (`DRK-04-Checkout-sombre`) | 390×1500 | Paiement en mode sombre. | BKG-04-Recapitulatif, PAY-02-Checkout-detail, PAY-03-Nouvelle-carte, PAY-06-Paiement-en-cours |
| RTL-01 | Accueil · arabe (`RTL-01-Accueil-arabe`) | 390×1540 | Accueil en arabe, de droite à gauche ; chiffres et cartes non inversés. | AI-01-Assistant, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, FRM-01-Communaute, GAM-01-Partie-ouverte, HOM-01-Accueil, MAT-01-A-venir, MAT-05-Detail-reservation, NOT-01-Centre-de-notifications, PRF-05-Menu-du-compte |
| RTL-02 | Terrain · arabe (`RTL-02-Terrain-arabe`) | 390×2448 | Fiche du terrain en arabe. | EXP-03-Explorer-terrains, VEN-02-Creneau |
| RTL-03 | Checkout · arabe (`RTL-03-Checkout-arabe`) | 390×1564 | Paiement en arabe. | BKG-04-Recapitulatif, PAY-02-Checkout-detail, PAY-03-Nouvelle-carte, PAY-06-Paiement-en-cours |

---

# Milestone 8 — venue owner and admin

## Espace propriétaire

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| OWN-10 | Aujourd’hui (`OWN-10-Aujourdhui`) | 390×2304 | KPIs du jour, prochaine arrivée, programme, suggestion IA, versement, avis. Entrée : onglet Aujourd’hui. | AI-07-Assistant-pro, OWN-11-Planning, OWN-13-Bloquer-un-creneau, OWN-14-Reservations, OWN-15-Plus, OWN-16-Tarifs, OWN-19-Avis, OWN-20-Scanner, OWN-24-No-show, OWN-25-Revenus, PRF-06-Changer-de-role |
| OWN-11 | Planning (`OWN-11-Planning`) | 390×844 | Terrains en colonnes, heures en lignes, états, bloquer. Entrée : onglet Planning. | AI-07-Assistant-pro, OWN-10-Aujourdhui, OWN-12-Reservation, OWN-13-Bloquer-un-creneau, OWN-14-Reservations, OWN-15-Plus, OWN-20-Scanner, OWN-24-No-show, PRF-06-Changer-de-role |
| OWN-12 | Réservation (`OWN-12-Reservation`) | 390×844 | Détail, paiements, actions, check-in. Entrée : une réservation. | OWN-10-Aujourdhui, OWN-11-Planning, OWN-13-Bloquer-un-creneau, OWN-14-Reservations, OWN-15-Plus, OWN-20-Scanner, PRF-06-Changer-de-role |
| OWN-13 | Bloquer un créneau (`OWN-13-Bloquer-un-creneau`) | 390×844 | Terrain, jour, plage, raison, récurrence. Entrée : « Bloquer ». | OWN-10-Aujourdhui, OWN-11-Planning, OWN-12-Reservation, OWN-14-Reservations, OWN-15-Plus, OWN-20-Scanner, OWN-24-No-show, PRF-06-Changer-de-role |
| OWN-14 | Réservations (`OWN-14-Reservations`) | 390×1440 | Recherche, filtres, liste par jour. Entrée : onglet Réservations. | AI-07-Assistant-pro, OWN-10-Aujourdhui, OWN-11-Planning, OWN-12-Reservation, OWN-15-Plus, OWN-20-Scanner, PRF-06-Changer-de-role |
| OWN-15 | Plus (`OWN-15-Plus`) | 390×1212 | Terrains, tarifs, clients, avis, revenus, paramètres, rôle. Entrée : onglet Plus. | AI-07-Assistant-pro, OWN-10-Aujourdhui, OWN-11-Planning, OWN-14-Reservations, OWN-16-Tarifs, OWN-17-Terrains, OWN-18-Clients, OWN-19-Avis, OWN-20-Scanner, OWN-25-Revenus, PRF-06-Changer-de-role, SET-01-Parametres |
| OWN-16 | Tarifs (`OWN-16-Tarifs`) | 390×1792 | Heures creuses / pointe, prix par terrain, promo IA, dates spéciales. Entrée : Plus › Tarifs. | OWN-10-Aujourdhui, OWN-15-Plus |
| OWN-17 | Terrains (`OWN-17-Terrains`) | 390×1236 | Gestion des terrains, visibilité, entretien. Entrée : Plus › Terrains. | OWN-11-Planning, OWN-13-Bloquer-un-creneau, OWN-15-Plus, OWN-16-Tarifs |
| OWN-20 | Check-in (`OWN-20-Scanner`) | 390×844 | Scanner le QR, lampe, saisie manuelle. Entrée : onglet Check-in. | AI-07-Assistant-pro, OWN-10-Aujourdhui, OWN-11-Planning, OWN-14-Reservations, OWN-15-Plus, OWN-21-Check-in-valide, PRF-06-Changer-de-role, STA-05-Permission-camera |
| OWN-21 | Check-in · valide (`OWN-21-Check-in-valide`) | 390×844 | Billet valide, joueurs arrivés. Entrée : scan. | OWN-12-Reservation, OWN-20-Scanner, OWN-24-No-show |
| OWN-22 | Check-in · déjà utilisé (`OWN-22-Check-in-deja-utilise`) | 390×844 | Premier scan, quoi faire. Entrée : scan. | OWN-12-Reservation, OWN-20-Scanner |
| OWN-23 | Check-in · invalide (`OWN-23-Check-in-invalide`) | 390×844 | Billet d’un autre terrain, quoi faire. Entrée : scan. | OWN-11-Planning, OWN-20-Scanner |
| OWN-24 | No-show (`OWN-24-No-show`) | 390×844 | Qui manque, conséquences, confirmer. Entrée : « Signaler un absent ». | OWN-12-Reservation, OWN-21-Check-in-valide |
| OWN-18 | Clients (`OWN-18-Clients`) | 390×1184 | Visites, dépenses, no-shows. Entrée : Plus › Clients. | OWN-14-Reservations, OWN-15-Plus |
| OWN-19 | Avis (`OWN-19-Avis`) | 390×1520 | Répartition, répondre aux avis. Entrée : Plus › Avis. | OWN-15-Plus |
| OWN-25 | Revenus (`OWN-25-Revenus`) | 390×1620 | Prochain versement, revenus, sources, versements. Entrée : Plus › Revenus. | OWN-15-Plus |

## Admin

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| ADM-01 | Vue d’ensemble (`ADM-01-Vue-d-ensemble`) | 390×1960 | KPIs, à traiter, réservations par sport, signalements, abonnements. Entrée : onglet Vue. | ADM-02-Utilisateurs, ADM-05-Verifications, ADM-06-Finance, ADM-07-Versements-et-remboursements, ADM-08-Risque-de-churn, ADM-09-Moderation, ADM-10-Revue-du-contenu, PRF-06-Changer-de-role |
| ADM-02 | Utilisateurs (`ADM-02-Utilisateurs`) | 390×844 | Recherche, filtres, sélection multiple. Entrée : onglet Utilisateurs. | ADM-01-Vue-d-ensemble, ADM-03-Detail-utilisateur, ADM-05-Verifications, ADM-06-Finance, ADM-09-Moderation, PRF-06-Changer-de-role |
| ADM-03 | Fiche utilisateur (`ADM-03-Detail-utilisateur`) | 390×2040 | Profil, fiabilité, activité, paiements, sanctions. Entrée : un utilisateur. | ADM-02-Utilisateurs, ADM-04-Suspendre |
| ADM-04 | Suspendre (`ADM-04-Suspendre`) | 390×844 | Durée, raison, message, conséquences. Entrée : « Suspendre ». | ADM-02-Utilisateurs, ADM-03-Detail-utilisateur |
| ADM-05 | Vérifications (`ADM-05-Verifications`) | 390×1816 | Coachs et terrains à vérifier, lecture IA. Entrée : onglet Vérifications. | ADM-01-Vue-d-ensemble, ADM-02-Utilisateurs, ADM-06-Finance, ADM-09-Moderation, PRF-06-Changer-de-role |
| ADM-06 | Finance (`ADM-06-Finance`) | 390×2384 | Encaissé, remboursé, sources, transactions. Entrée : onglet Finance. | ADM-01-Vue-d-ensemble, ADM-02-Utilisateurs, ADM-05-Verifications, ADM-07-Versements-et-remboursements, ADM-08-Risque-de-churn, ADM-09-Moderation, PRF-06-Changer-de-role |
| ADM-07 | Versements et remboursements (`ADM-07-Versements-et-remboursements`) | 390×1368 | Valider les versements, traiter les remboursements. Entrée : Finance. | ADM-06-Finance |
| ADM-08 | Risque de churn IA (`ADM-08-Risque-de-churn`) | 390×1832 | Abonnés à risque avec raison et action proposée. Entrée : Finance. | ADM-06-Finance |
| ADM-09 | Modération (`ADM-09-Moderation`) | 390×1488 | Contenus signalés triés par score IA. Entrée : onglet Modération. | ADM-01-Vue-d-ensemble, ADM-02-Utilisateurs, ADM-05-Verifications, ADM-06-Finance, ADM-10-Revue-du-contenu, PRF-06-Changer-de-role |
| ADM-10 | Revue du contenu (`ADM-10-Revue-du-contenu`) | 390×844 | Contexte, analyse IA, décision et conséquence. Entrée : un signalement. | ADM-09-Moderation |

---

# Milestone 6 — tournaments, training, community (optional for launch)

## Tournois

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| TRN-01 | Tournois (`TRN-01-Tournois`) | 390×844 | Segment Tournois d’Explorer : filtres, tournois et événements près de toi. Entrée : Explorer › Tournois. | AI-01-Assistant, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, FRM-01-Communaute, HOM-01-Accueil, MAT-01-A-venir, TRN-02-Detail-du-tournoi, TRN-03-Evenement, TRN-04-Creer-l-equipe |
| TRN-02 | Détail du tournoi (`TRN-02-Detail-du-tournoi`) | 390×2400 | Dotation, format, calendrier, équipes, règles et remboursement, lieu, organisateur. « Inscrire mon équipe ». Entrée : carte tournoi. | TRN-01-Tournois, TRN-04-Creer-l-equipe |
| TRN-03 | Événement (`TRN-03-Evenement`) | 390×1632 | Journée initiation (inscription individuelle), programme, coach, conditions. Entrée : carte événement. | ENT-02-Programmes, TRN-01-Tournois |
| TRN-04 | Créer l’équipe 1/3 (`TRN-04-Creer-l-equipe`) | 390×844 | Nom, logo, capitaine. Entrée : « Inscrire mon équipe ». | TRN-02-Detail-du-tournoi, TRN-05-Membres |
| TRN-05 | Membres 2/3 (`TRN-05-Membres`) | 390×1288 | Partenaire, suggestions IA, lien d’invitation ; « Payer l’inscription · 120 DT ». Entrée : équipe créée. | PAY-01-Checkout, TRN-04-Creer-l-equipe |
| TRN-06 | Inscription envoyée (`TRN-06-Inscription-en-attente`) | 390×1296 | En attente de validation par l’organisateur ; remboursé si refus. Entrée : paiement réussi. | TRN-02-Detail-du-tournoi, TRN-07-Inscription-confirmee |
| TRN-07 | Inscription confirmée (`TRN-07-Inscription-confirmee`) | 390×1216 | Poule tirée, calendrier des matchs, check-in. Entrée : validation (notification). | TRN-02-Detail-du-tournoi, TRN-08-Tableau, TRN-09-Poules-et-classement, TRN-10-Match-en-direct |
| TRN-08 | Tableau final (`TRN-08-Tableau`) | 390×980 | Phase finale par tour, match en direct mis en avant, vue d’ensemble. Entrée : « Le tableau ». | TRN-02-Detail-du-tournoi, TRN-07-Inscription-confirmee, TRN-09-Poules-et-classement |
| TRN-09 | Poules et classement (`TRN-09-Poules-et-classement`) | 390×1536 | Classement de poule, tes matchs, autres poules, classement général. Entrée : « Les poules ». | TRN-02-Detail-du-tournoi, TRN-07-Inscription-confirmee, TRN-08-Tableau, TRN-11-Recap-IA |
| TRN-10 | Match en direct (`TRN-10-Match-en-direct`) | 390×1412 | Score en direct, sets, chronologie, chiffres, poule en direct. Entrée : ton match du jour. | TRN-07-Inscription-confirmee, TRN-09-Poules-et-classement, TRN-11-Recap-IA |
| TRN-11 | Résumé IA (`TRN-11-Recap-IA`) | 390×1368 | Résumé du match par l’IA, modifiable, image à partager. Entrée : fin du match. | FRM-02-Nouveau-post, TRN-10-Match-en-direct |

## Espace organisateur

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| ORG-03 | Tableau de bord (`ORG-03-Tableau-de-bord`) | 390×2064 | Inscriptions, revenus, équipes à valider, suggestion IA, prochains matchs. Entrée : onglet Tableau. | AI-07-Assistant-pro, ORG-04-Mes-tournois, ORG-07-Creer-terrains-dates, ORG-10-Inscriptions, ORG-12-Scores-en-direct, ORG-14-Annonce, PRF-06-Changer-de-role |
| ORG-04 | Mes tournois (`ORG-04-Mes-tournois`) | 390×1444 | Tournois en cours, brouillon, terminés ; raccourcis de gestion. Entrée : onglet Tournois. | AI-07-Assistant-pro, ORG-03-Tableau-de-bord, ORG-05-Creer-infos, ORG-07-Creer-terrains-dates, ORG-10-Inscriptions, ORG-11-Generateur-IA, ORG-12-Scores-en-direct, ORG-14-Annonce, PRF-06-Changer-de-role, TRN-02-Detail-du-tournoi |
| ORG-05 | Créer 1/5 · infos (`ORG-05-Creer-infos`) | 390×1420 | Nom, affiche, sport, catégorie, niveau, présentation. Entrée : « Créer un tournoi ». | ORG-04-Mes-tournois, ORG-06-Creer-format |
| ORG-06 | Créer 2/5 · format (`ORG-06-Creer-format`) | 390×1640 | Poules + phase finale, nombre d’équipes, règles. Entrée : étape 1. | ORG-04-Mes-tournois, ORG-05-Creer-infos, ORG-07-Creer-terrains-dates |
| ORG-07 | Créer 3/5 · terrains et dates (`ORG-07-Creer-terrains-dates`) | 390×1820 | Club, courts, dates, horaires, clôture. Entrée : étape 2. | ORG-04-Mes-tournois, ORG-06-Creer-format, ORG-08-Creer-frais-prix |
| ORG-08 | Créer 4/5 · frais et prix (`ORG-08-Creer-frais-prix`) | 390×1640 | Frais par équipe, validation, dotation, remboursement. Entrée : étape 3. | ORG-04-Mes-tournois, ORG-07-Creer-terrains-dates, ORG-09-Apercu-publier |
| ORG-09 | Créer 5/5 · aperçu (`ORG-09-Apercu-publier`) | 390×1690 | Aperçu et récap, publier après vérification. Entrée : étape 4. | ORG-04-Mes-tournois, ORG-05-Creer-infos, ORG-06-Creer-format, ORG-07-Creer-terrains-dates, ORG-08-Creer-frais-prix |
| ORG-10 | Inscriptions (`ORG-10-Inscriptions`) | 390×1976 | Valider ou refuser les équipes, statut de paiement. Entrée : tableau de bord. | ORG-04-Mes-tournois |
| ORG-11 | Planning IA (`ORG-11-Generateur-IA`) | 390×2084 | Contraintes puis planning proposé, déplacement, régénérer, publier. Entrée : Mes tournois › Planning IA. | ORG-04-Mes-tournois |
| ORG-12 | Scores en direct (`ORG-12-Scores-en-direct`) | 390×2140 | Matchs en cours, à venir et terminés ; alerte court sans score. Entrée : onglet Scores. | AI-07-Assistant-pro, ORG-03-Tableau-de-bord, ORG-04-Mes-tournois, ORG-14-Annonce, PRF-06-Changer-de-role |
| ORG-13 | Saisie au bord du court (`ORG-13-Saisie-du-score`) | 390×844 | Gros boutons à une main, confirmation du score final. Entrée : match « Tu saisis ». | ORG-12-Scores-en-direct |
| ORG-14 | Annonce (`ORG-14-Annonce`) | 390×2520 | Message, destinataires, notification + email, aperçu. Entrée : onglet Annonces. | AI-07-Assistant-pro, ORG-03-Tableau-de-bord, ORG-04-Mes-tournois, ORG-12-Scores-en-direct, PRF-06-Changer-de-role |

## Entraînement

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| ENT-01 | Mon entraînement (`ENT-01-Mon-entrainement`) | 390×1748 | Série, séance du jour, programmes, plan IA, analyse vidéo. Entrée : onglet Entraînement. | AI-01-Assistant, ENT-02-Programmes, ENT-03-Detail-du-programme, ENT-04-Seance, ENT-06-Plan-IA-objectifs, ENT-08-Analyse-video, EXP-01-Explorer-parties, FRM-01-Communaute, HOM-01-Accueil, MAT-01-A-venir |
| ENT-02 | Programmes (`ENT-02-Programmes`) | 390×1652 | Catalogue avec filtres, suggestion IA, coachs. Entrée : Mon entraînement. | AI-01-Assistant, ENT-01-Mon-entrainement, ENT-03-Detail-du-programme, EXP-01-Explorer-parties, FRM-01-Communaute, HOM-01-Accueil, MAT-01-A-venir |
| ENT-03 | Détail du programme (`ENT-03-Detail-du-programme`) | 390×2308 | Contenu semaine par semaine, coach, avis, « Inclus dans Premium ». Entrée : carte programme. | ENT-01-Mon-entrainement, ENT-02-Programmes |
| ENT-04 | Séance (`ENT-04-Seance`) | 390×1392 | Vidéo, consignes, séries, minuteur, notes, suivant. Entrée : séance du jour. | ENT-01-Mon-entrainement, ENT-03-Detail-du-programme, ENT-05-Seance-terminee |
| ENT-05 | Séance terminée (`ENT-05-Seance-terminee`) | 390×844 | Bilan, semaine validée, prochaine séance. Entrée : « Marquer comme fait ». | ENT-01-Mon-entrainement, ENT-03-Detail-du-programme, ENT-08-Analyse-video |
| ENT-06 | Plan IA · objectifs (`ENT-06-Plan-IA-objectifs`) | 390×1188 | Objectifs, jours, durée, intensité. Entrée : « Créer mon plan ». | ENT-01-Mon-entrainement, ENT-07-Plan-IA |
| ENT-07 | Plan IA (`ENT-07-Plan-IA`) | 390×1444 | Semaine proposée, calée sur tes matchs et ton tournoi ; régénérer, modifier, accepter. Entrée : plan généré. | ENT-01-Mon-entrainement, ENT-06-Plan-IA-objectifs |
| ENT-08 | Analyse vidéo (`ENT-08-Analyse-video`) | 390×1364 | Envoi de la vidéo, traitement IA, confidentialité. Entrée : « Analyse ta bandeja ». | ENT-01-Mon-entrainement, ENT-09-Analyse-video-resultats |
| ENT-09 | Analyse vidéo · résultats (`ENT-09-Analyse-video-resultats`) | 390×1848 | Moments repérés, conseils horodatés, exercices conseillés. Entrée : analyse terminée. | ENT-03-Detail-du-programme, ENT-07-Plan-IA, ENT-08-Analyse-video |

## Espace coach

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| COA-04 | Tableau de bord (`COA-04-Tableau-de-bord`) | 390×1820 | Revenus, élèves, à traiter, suggestion IA, programmes, avis. Entrée : onglet Tableau. | COA-05-Programmes, COA-06-Constructeur, COA-09-Eleves, COA-11-Retour, COA-12-Revenus, PRF-06-Changer-de-role |
| COA-05 | Programmes (`COA-05-Programmes`) | 390×1144 | Publiés et brouillons. Entrée : onglet Programmes. | COA-04-Tableau-de-bord, COA-06-Constructeur, COA-09-Eleves, COA-12-Revenus, ENT-03-Detail-du-programme, PRF-06-Changer-de-role |
| COA-06 | Constructeur (`COA-06-Constructeur`) | 390×1940 | Semaines, séances, exercices réordonnables ; ajouter un exercice. Entrée : « Créer » ou « Continuer ». | COA-05-Programmes, COA-07-Seance-video, COA-08-Prix-et-publication |
| COA-07 | Séance · vidéo (`COA-07-Seance-video`) | 390×1808 | Exercices, vidéo en envoi et en traitement. Entrée : une séance. | COA-06-Constructeur |
| COA-08 | Prix et publication (`COA-08-Prix-et-publication`) | 390×2084 | Prix (fourchette IA), Premium, aperçu, publication programmée. Entrée : « Continuer vers le prix ». | COA-05-Programmes, COA-06-Constructeur |
| COA-09 | Élèves (`COA-09-Eleves`) | 390×844 | Progression, en retard, terminés. Entrée : onglet Élèves. | COA-04-Tableau-de-bord, COA-05-Programmes, COA-10-Detail-eleve, COA-12-Revenus, PRF-06-Changer-de-role |
| COA-10 | Détail élève (`COA-10-Detail-eleve`) | 390×2008 | Progression, vidéo analysée, notes, retours. Entrée : un élève. | COA-09-Eleves, COA-11-Retour |
| COA-11 | Retour vidéo (`COA-11-Retour`) | 390×1592 | Commentaires horodatés, moment IA, message général. Entrée : « Faire un retour ». | COA-10-Detail-eleve |
| COA-12 | Revenus (`COA-12-Revenus`) | 390×2108 | Net après commission, versements, sources, opérations. Entrée : onglet Revenus. | COA-04-Tableau-de-bord, COA-05-Programmes, COA-09-Eleves, PRF-06-Changer-de-role |

## Communauté

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| FRM-01 | Communauté (`FRM-01-Communaute`) | 390×1872 | Catégories, sports, tri, discussions. Entrée : onglet Communauté. | AI-01-Assistant, ENT-01-Mon-entrainement, EXP-01-Explorer-parties, FRM-02-Nouveau-post, FRM-04-Discussion, HOM-01-Accueil, MAT-01-A-venir |
| FRM-02 | Nouveau post (`FRM-02-Nouveau-post`) | 390×1532 | Titre, discussions similaires, texte, images, tags IA. Entrée : « Pose ta question ». | FRM-01-Communaute |
| FRM-03 | Message à revoir (`FRM-03-Message-a-revoir`) | 390×844 | Alerte avant publication et reformulation IA ; publier quand même ou modifier. Entrée : réponse potentiellement blessante. | FRM-04-Discussion |
| FRM-04 | Discussion (`FRM-04-Discussion`) | 390×1932 | Post, meilleure réponse, réponses sur 2 niveaux, contenu masqué. Entrée : un post. | FRM-01-Communaute, FRM-03-Message-a-revoir, FRM-05-Signaler |
| FRM-05 | Signaler (`FRM-05-Signaler`) | 390×844 | Motifs, masquer l’auteur, anonyme. Entrée : « … › Signaler ». | FRM-04-Discussion |

---

# Milestone 7 — AI assistant (optional for launch)

## Assistant IA

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| AI-01 | Assistant (`AI-01-Assistant`) | 390×844 | Accueil, suggestions, ce que l’IA utilise. Entrée : bouton IA ou « Demande à MatchUp ». | AI-02-Resultats, AI-04-Reflexion, AI-06-Erreur, HOM-01-Accueil, PRF-04-Modifier-le-profil |
| AI-02 | Résultats (`AI-02-Resultats`) | 390×1392 | Ce que l’IA a compris, créneaux, partie ouverte, raisons. Entrée : une demande. | AI-01-Assistant, AI-03-Confirmation, GAM-01-Partie-ouverte, HOM-01-Accueil, VEN-01-Terrain |
| AI-03 | Confirmation (`AI-03-Confirmation`) | 390×844 | Rien n’est réservé ni payé sans « Confirmer ». Entrée : « Réserver 20h00 ». | AI-02-Resultats, HOM-01-Accueil, PAY-01-Checkout, VEN-01-Terrain |
| AI-04 | Réflexion (`AI-04-Reflexion`) | 390×844 | Étapes de recherche et premier résultat partiel. Entrée : une demande. | AI-01-Assistant, AI-05-Aucun-resultat, HOM-01-Accueil |
| AI-05 | Aucun résultat (`AI-05-Aucun-resultat`) | 390×1444 | Alternatives : créer une partie, autre créneau, alerte. Entrée : recherche vide. | AI-01-Assistant, HOM-01-Accueil |
| AI-06 | Erreur (`AI-06-Erreur`) | 390×844 | Connexion instable, message gardé, réessayer. Entrée : erreur réseau. | ENT-02-Programmes, HOM-01-Accueil |
| AI-07 | Assistant · espace pro (`AI-07-Assistant-pro`) | 390×1416 | Question du propriétaire, graphique, suggestion de promo. Entrée : bouton IA des espaces pro. | OWN-10-Aujourdhui, OWN-16-Tarifs |
