# Screens — Milestone 2 (onboarding, auth, pro onboarding, sitemap, journeys) and Milestone 3 (player core)

Each screen has a PNG (`png/`) showing exactly how it must look, and its design source (`source/`, HTML) for the exact copy, spacing and which design-system component is used where (`<x-import component-from-global-scope="MatchUp.TextField" …>` = the TextField component; its spec is in `../design-system/components/TextField.md`).

Mobile screens are 390×844 (phone). Desktop screens (OWN-, COA-, ORG-) are 1440×900 and must also work narrower. MAP-/FLW- are diagrams (the sitemap and the 4 critical journeys), not screens.


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
| AUTH-11 | Choix du rôle (`AUTH-11-Choix-du-role`) | 390×844 | Choisir un ou plusieurs rôles ; « Continuer » ouvre l’onboarding du premier. Entrée : email vérifié ou connexion. | AUTH-04-Verifie-ton-email, (role-dependent: PLY-01 / OWN-01 / COA-01 / ORG-01) |
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
| PLY-11 | Accueil + visite guidée (`PLY-11-Accueil-visite`) | 390×844 | Accueil personnalisé et visite en 3 étapes (interactif), shown once; afterwards Home is HOM-01. Entrée : fin de l’onboarding. | GAM-01-Partie-ouverte, HOM-01-Accueil, EXP-01-Explorer-parties, MAT-01-A-venir |

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
| OWN-09 | Tableau de bord · premiers pas (`OWN-09-Tableau-de-bord`) | 1440×900 | Checklist de mise en ligne 4/6 et tableau de bord vide. Entrée : essai démarré. | OWN-01-Entreprise, OWN-02-Adresse, OWN-04-Horaires, OWN-06-Photos |
| COA-01 | Coach 1/3 · Profil (`COA-01-Profil-coach`) | 1440×900 | Bio, spécialités, sports et niveaux encadrés (interactif). Entrée : rôle Coach. | AUTH-11-Choix-du-role, COA-02-Certification, COA-03-Premier-programme |
| COA-02 | Coach 2/3 · Certification (`COA-02-Certification`) | 1440×900 | Diplôme envoyé, vérification en attente 48 h. Entrée : profil coach. | COA-01-Profil-coach, COA-03-Premier-programme |
| COA-03 | Coach 3/3 · Premier programme (`COA-03-Premier-programme`) | 1440×900 | Tableau de bord coach, invitation à créer un programme, aide IA. Entrée : certification envoyée. | COA-01-Profil-coach |
| ORG-01 | Organisateur 1/2 · Organisation (`ORG-01-Organisation`) | 1440×900 | Nom, logo, contact, événements passés (facultatif). Entrée : rôle Organisateur. | AUTH-11-Choix-du-role, ORG-02-Pret |
| ORG-02 | Organisateur 2/2 · Prêt (`ORG-02-Pret`) | 1440×900 | Tableau de bord organisateur, « Crée ton premier tournoi ». Entrée : organisation enregistrée. | ORG-01-Organisation |

## Plan du site & parcours

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| MAP-01 | Plan du site (`MAP-01-Plan-du-site`) | 2832×1712 |  |  |
| FLW-01 | Parcours 1 · Rejoindre une partie (`FLW-01-Rejoindre-une-partie`) | 2632×980 |  |  |
| FLW-02 | Parcours 2 · Réserver et partager (`FLW-02-Reserver-et-partager`) | 2648×1180 |  |  |
| FLW-03 | Parcours 3 · Inscrire une équipe (`FLW-03-Inscrire-une-equipe`) | 2708×864 |  |  |
| FLW-04 | Parcours 4 · Passer Premium (`FLW-04-Passer-Premium`) | 2120×1152 |  |  |

---

# Milestone 3 — Player core (phone only)

Phone screens, 390 wide. **Tall PNGs (height > 844) are full scrolled pages**: the top bar stays at the top, the sticky bottom bar / tab bar sits at the bottom of the visible screen, everything between scrolls. Overlay screens (sheets, dialogs, takeovers) show the screen underneath + the overlay.
All screens share one fake data set: see `STORY-DATA.md`. Payment buttons jump straight to the success screen: the checkout is designed in Milestone 4.


## Accueil & Explorer

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| HOM-01 | Accueil (`HOM-01-Accueil`) | 390×2384 | Accueil complet : parties IA pour toi, actions rapides, prochains matchs, terrains et tournois près de toi. Entrée : onglet Accueil, fin de l’onboarding. | EXP-01-Explorer-parties, EXP-03-Explorer-terrains, GAM-01-Partie-ouverte, MAT-01-A-venir, MAT-05-Detail-reservation, PRF-05-Menu-du-compte, VEN-01-Terrain |
| HOM-02 | Accueil · chargement (`HOM-02-Accueil-chargement`) | 390×2252 | Squelettes à la place du contenu, pas de spinner ; l’en-tête reste utilisable. Entrée : ouverture de l’app. | EXP-01-Explorer-parties, EXP-03-Explorer-terrains, HOM-01-Accueil, MAT-01-A-venir, PRF-05-Menu-du-compte |
| EXP-01 | Explorer · parties (`EXP-01-Explorer-parties`) | 390×844 | Parties ouvertes en liste : recherche, filtres rapides, tri, bascule carte. Entrée : onglet Explorer. | EXP-02-Explorer-carte, EXP-03-Explorer-terrains, EXP-04-Filtres, EXP-05-Recherche, GAM-01-Partie-ouverte, GAM-02-Partie-complete, HOM-01-Accueil, MAT-01-A-venir |
| EXP-02 | Explorer · carte (`EXP-02-Explorer-carte`) | 390×844 | Même recherche en carte : épingles par sport, groupes, mini-fiche de la partie choisie. Entrée : bascule « Carte ». | EXP-01-Explorer-parties, EXP-03-Explorer-terrains, EXP-04-Filtres, EXP-05-Recherche, GAM-01-Partie-ouverte, GAM-02-Partie-complete, HOM-01-Accueil, MAT-01-A-venir |
| EXP-03 | Explorer · terrains (`EXP-03-Explorer-terrains`) | 390×844 | Terrains libres ce soir avec le prix par personne. Entrée : segment Terrains, « Réserver un terrain ». | EXP-01-Explorer-parties, EXP-04-Filtres, EXP-05-Recherche, HOM-01-Accueil, MAT-01-A-venir, VEN-01-Terrain |
| EXP-04 | Filtres (`EXP-04-Filtres`) | 390×844 | Panneau de filtres : sport, date, niveau, prix, distance, type, équipements. Entrée : puce « Filtres ». | EXP-01-Explorer-parties, EXP-02-Explorer-carte, EXP-03-Explorer-terrains, EXP-05-Recherche, GAM-01-Partie-ouverte, GAM-02-Partie-complete, HOM-01-Accueil, MAT-01-A-venir |
| EXP-05 | Recherche (`EXP-05-Recherche`) | 390×844 | Recherches récentes et suggestions (zones, terrains, parties, joueurs). Entrée : champ de recherche. | EXP-01-Explorer-parties, GAM-01-Partie-ouverte, VEN-01-Terrain |
| EXP-06 | Aucun résultat (`EXP-06-Aucun-resultat`) | 390×844 | État vide avec pistes : alerte, élargir, retirer un filtre, créer une partie. Entrée : filtres trop serrés. | EXP-01-Explorer-parties, EXP-03-Explorer-terrains, EXP-04-Filtres, EXP-05-Recherche, HOM-01-Accueil, MAT-01-A-venir |
| EXP-07 | Hors ligne (`EXP-07-Erreur-de-chargement`) | 390×844 | Bandeau hors ligne, « Réessayer », résultats enregistrés affichés. Entrée : pas de connexion. | EXP-01-Explorer-parties, EXP-02-Explorer-carte, EXP-03-Explorer-terrains, EXP-04-Filtres, GAM-01-Partie-ouverte, GAM-02-Partie-complete, HOM-01-Accueil, MAT-01-A-venir |

## Terrains & réservation

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| VEN-01 | Fiche du terrain (`VEN-01-Terrain`) | 390×2392 | Galerie, Vérifié, avis, créneaux avec prix terrain et par personne, équipements, annulation. « Réserver ». Entrée : Explorer · Terrains, Accueil. | EXP-03-Explorer-terrains, VEN-02-Creneau |
| VEN-02 | Créneau choisi (`VEN-02-Creneau`) | 390×844 | Détail du créneau : 150 DT, 15 DT par personne à 10, annulation gratuite. Entrée : « Réserver ». | BKG-01-Type-de-reservation, VEN-01-Terrain |
| BKG-01 | Réservation 1/3 · type (`BKG-01-Type-de-reservation`) | 390×844 | Privée (j’invite mes amis) ou publique (je complète avec des joueurs). Entrée : créneau choisi. | VEN-02-Creneau |
| BKG-02 | Réservation 2/3 · partie publique (`BKG-02-Partie-publique`) | 390×1132 | Places à compléter, niveau, type, visibilité, mot pour les joueurs. Entrée : type Publique. | BKG-01-Type-de-reservation, BKG-03-Inviter-des-amis, BKG-04-Recapitulatif |
| BKG-03 | Réservation 2/3 · invités (`BKG-03-Inviter-des-amis`) | 390×1360 | Inviter des amis, coéquipiers suggérés, lien à partager. Entrée : type Privée ou « Inviter des joueurs ». | BKG-01-Type-de-reservation, BKG-04-Recapitulatif |
| BKG-04 | Réservation 3/3 · récapitulatif (`BKG-04-Recapitulatif`) | 390×1600 | Qui paie quoi (chacun sa part ou tout), solde, détail du prix, annulation avant de payer. Entrée : étape 2. Le paiement arrive au Milestone 4. | BKG-02-Partie-publique, BKG-05-Reservation-confirmee |
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
| MAT-01 | À venir (`MAT-01-A-venir`) | 390×844 | Invitation à répondre, parties où tu joues, réservations que tu organises. Entrée : onglet Mes matchs. | BKG-03-Inviter-des-amis, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, GAM-01-Partie-ouverte, HOM-01-Accueil, MAT-02-Passes, MAT-03-Annules, MAT-05-Detail-reservation, MAT-07-Quitter-la-partie |
| MAT-02 | Passés (`MAT-02-Passes`) | 390×844 | Résultats, évaluation des coéquipiers à faire. Entrée : onglet Passés. | EXP-01-Explorer-parties, EXP-03-Explorer-terrains, HOM-01-Accueil, MAT-01-A-venir, MAT-03-Annules, MAT-08-Evaluer-les-joueurs, PRF-01-Mon-profil |
| MAT-03 | Annulés (`MAT-03-Annules`) | 390×844 | Matchs annulés et statut du remboursement. Entrée : onglet Annulés. | EXP-01-Explorer-parties, EXP-03-Explorer-terrains, HOM-01-Accueil, MAT-01-A-venir, MAT-02-Passes, VEN-01-Terrain |
| MAT-04 | Aucun match à venir (`MAT-04-Aucun-match`) | 390×844 | État vide : trouver une partie ou réserver. Entrée : Mes matchs sans réservation. | EXP-01-Explorer-parties, EXP-03-Explorer-terrains, HOM-01-Accueil, MAT-01-A-venir, MAT-02-Passes, MAT-03-Annules |
| MAT-05 | Détail de la réservation (`MAT-05-Detail-reservation`) | 390×2280 | QR code, lieu, joueurs et paiements, discussion, annulation, inviter. Entrée : carte de réservation. | BKG-03-Inviter-des-amis, MAT-01-A-venir, MAT-06-Annuler-la-reservation, VEN-01-Terrain |
| MAT-06 | Annuler la réservation (`MAT-06-Annuler-la-reservation`) | 390×844 | Confirmation avec remboursement de chaque joueur. Entrée : « Annuler la réservation ». | BKG-03-Inviter-des-amis, MAT-01-A-venir, MAT-03-Annules, MAT-05-Detail-reservation, VEN-01-Terrain |
| MAT-07 | Quitter la partie (`MAT-07-Quitter-la-partie`) | 390×844 | Conséquence et remboursement avant de quitter. Entrée : « Quitter » sur une partie. | BKG-03-Inviter-des-amis, EXP-01-Explorer-parties, EXP-03-Explorer-terrains, GAM-01-Partie-ouverte, HOM-01-Accueil, MAT-01-A-venir, MAT-02-Passes, MAT-03-Annules, MAT-05-Detail-reservation |
| MAT-08 | Évaluer les joueurs (`MAT-08-Evaluer-les-joueurs`) | 390×844 | Niveau ce jour-là et fair-play de chaque joueur, signaler une absence. Entrée : « Évaluer les joueurs ». | EXP-01-Explorer-parties, EXP-03-Explorer-terrains, HOM-01-Accueil, MAT-01-A-venir, MAT-02-Passes, MAT-03-Annules, MAT-09-Score-du-match, PRF-01-Mon-profil |
| MAT-09 | Score du match (`MAT-09-Score-du-match`) | 390×844 | Saisie facultative du score, confirmée par l’adversaire. Entrée : évaluation envoyée. | MAT-02-Passes, MAT-08-Evaluer-les-joueurs |

## Profil & paramètres

| Code | Screen | Size | Purpose · entry | Goes to |
|---|---|---|---|---|
| PRF-01 | Mon profil (`PRF-01-Mon-profil`) | 390×2376 | Niveaux IA par sport avec tendance, fiabilité, stats, badges, matchs, avis. Entrée : menu du compte. | HOM-01-Accueil, MAT-02-Passes, PRF-03-Pourquoi-ce-niveau, PRF-04-Modifier-le-profil, SET-01-Parametres |
| PRF-02 | Profil public (`PRF-02-Profil-public`) | 390×2388 | Profil de Skander T. vu par un autre joueur : suivre, inviter, signaler. Entrée : organisateur d’une partie. | GAM-01-Partie-ouverte |
| PRF-03 | Pourquoi ce niveau ? (`PRF-03-Pourquoi-ce-niveau`) | 390×844 | Ce que l’IA a pris en compte, matchs qui ont fait bouger le niveau, ajuster ou contester. Entrée : « Pourquoi ce niveau ? ». | PRF-01-Mon-profil |
| PRF-04 | Modifier le profil (`PRF-04-Modifier-le-profil`) | 390×2020 | Photo, couverture, pseudo, bio, sports et postes, zones, visibilité. Entrée : « Modifier le profil ». | PRF-01-Mon-profil, PRF-03-Pourquoi-ce-niveau, SET-05-Confidentialite |
| PRF-05 | Menu du compte (`PRF-05-Menu-du-compte`) | 390×844 | Profil, portefeuille, paramètres, changer de rôle, aide, déconnexion. Entrée : avatar de l’Accueil. | AUTH-05-Connexion, EXP-01-Explorer-parties, HOM-01-Accueil, MAT-01-A-venir, PRF-01-Mon-profil, PRF-06-Changer-de-role, SET-01-Parametres |
| PRF-06 | Changer de rôle (`PRF-06-Changer-de-role`) | 390×844 | Joueur actif, propriétaire à terminer, ajouter un rôle. Entrée : menu du compte. | AUTH-11-Choix-du-role, EXP-01-Explorer-parties, HOM-01-Accueil, MAT-01-A-venir, OWN-09-Tableau-de-bord, PRF-05-Menu-du-compte |
| SET-01 | Paramètres (`SET-01-Parametres`) | 390×844 | Compte, sécurité, notifications, langue et thème, confidentialité, aide, supprimer le compte. Entrée : profil ou menu du compte. | AUTH-05-Connexion, PRF-01-Mon-profil, SET-02-Compte, SET-03-Securite, SET-04-Langue-et-theme, SET-05-Confidentialite, SET-06-Comptes-connectes, SET-07-Supprimer-le-compte |
| SET-02 | Compte (`SET-02-Compte`) | 390×984 | Email et téléphone vérifiés, infos personnelles. Entrée : Paramètres › Compte. | SET-01-Parametres |
| SET-03 | Sécurité (`SET-03-Securite`) | 390×844 | Mot de passe, double authentification, sessions actives. Entrée : Paramètres › Sécurité. | SET-01-Parametres |
| SET-04 | Langue et thème (`SET-04-Langue-et-theme`) | 390×844 | Français, العربية, English ; clair, sombre, système. Entrée : Paramètres › Langue et thème. | SET-01-Parametres |
| SET-05 | Confidentialité (`SET-05-Confidentialite`) | 390×844 | Visibilité du profil, invitations, niveau, fiabilité, position, données. Entrée : Paramètres › Confidentialité. | SET-01-Parametres |
| SET-06 | Comptes connectés (`SET-06-Comptes-connectes`) | 390×844 | Email, Google, Apple ; garder au moins une méthode. Entrée : Paramètres › Comptes connectés. | SET-01-Parametres |
| SET-07 | Supprimer le compte (`SET-07-Supprimer-le-compte`) | 390×984 | Conséquences, raison facultative, taper SUPPRIMER pour confirmer. Entrée : Paramètres › Supprimer le compte. | ONB-01-Splash, SET-01-Parametres |
