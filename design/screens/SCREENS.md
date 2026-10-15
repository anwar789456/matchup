# Screens — Milestone 2 (onboarding, auth, pro onboarding, sitemap, journeys)

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
| PLY-11 | Accueil + visite guidée (`PLY-11-Accueil-visite`) | 390×844 | Accueil personnalisé et visite en 3 étapes (interactif). Entrée : fin de l’onboarding. |  |

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
