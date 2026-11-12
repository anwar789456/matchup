// The database schema, one list of statements per version (lib/core/db/app_database.dart).
// A new install runs every version in order; an update runs only the versions it lacks.
// Never edit a released version: add the next one.

const schemaVersions = <int, List<String>>{
  // ── v1 · accounts, codes, owner courts, bookings (what the server used to keep) ─────────────
  1: [
    '''
    CREATE TABLE utilisateurs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL UNIQUE,
      mot_de_passe TEXT NOT NULL,
      sel TEXT NOT NULL,
      pseudo TEXT UNIQUE,
      prenom TEXT,
      nom TEXT,
      telephone TEXT,
      telephone_verifie INTEGER NOT NULL DEFAULT 0,
      email_verifie INTEGER NOT NULL DEFAULT 0,
      role TEXT NOT NULL DEFAULT 'joueur',
      cree_le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE codes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL,
      usage TEXT NOT NULL CHECK (usage IN ('telephone', 'reinitialisation')),
      hash TEXT NOT NULL,
      expire_le TEXT NOT NULL,
      essais INTEGER NOT NULL DEFAULT 0,
      bloque_jusqua TEXT,
      utilise INTEGER NOT NULL DEFAULT 0,
      cree_le TEXT NOT NULL
    )''',
    'CREATE INDEX codes_email ON codes (email, usage)',
    '''
    CREATE TABLE terrains (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      proprietaire_id INTEGER REFERENCES utilisateurs (id) ON DELETE CASCADE,
      nom TEXT NOT NULL,
      etablissement TEXT NOT NULL,
      sport TEXT NOT NULL,
      surface TEXT,
      interieur INTEGER NOT NULL DEFAULT 0,
      eclairage INTEGER NOT NULL DEFAULT 0,
      prix_heure REAL NOT NULL,
      ville TEXT,
      adresse TEXT,
      cree_le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE reservations (
      reference TEXT PRIMARY KEY,
      sport TEXT NOT NULL,
      etablissement TEXT NOT NULL,
      terrain TEXT,
      lieu TEXT NOT NULL,
      debut TEXT NOT NULL,
      fin TEXT NOT NULL,
      part REAL NOT NULL,
      statut TEXT NOT NULL,
      payer_avant TEXT,
      remboursement REAL,
      cree_le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE reservation_joueurs (
      reference TEXT NOT NULL REFERENCES reservations (reference) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      nom TEXT NOT NULL,
      image_url TEXT,
      PRIMARY KEY (reference, position)
    )''',
    '''
    CREATE TABLE annulations (
      reference TEXT PRIMARY KEY REFERENCES reservations (reference) ON DELETE CASCADE,
      annule_par TEXT NOT NULL,
      par_moi INTEGER NOT NULL DEFAULT 0,
      raison TEXT,
      rembourse_le TEXT NOT NULL,
      remboursement REAL NOT NULL,
      joueurs_rembourses INTEGER NOT NULL DEFAULT 1,
      total_rembourse REAL
    )''',
    '''
    CREATE TABLE invitations (
      id TEXT PRIMARY KEY,
      de TEXT NOT NULL,
      sport TEXT NOT NULL,
      etablissement TEXT NOT NULL,
      lieu TEXT NOT NULL,
      debut TEXT NOT NULL,
      part REAL NOT NULL,
      places_total INTEGER NOT NULL,
      places_restantes INTEGER NOT NULL,
      statut TEXT NOT NULL DEFAULT 'attente' CHECK (statut IN ('attente', 'acceptee', 'refusee'))
    )''',
    'CREATE TABLE matchs_notes (match_id TEXT PRIMARY KEY, note_le TEXT NOT NULL)',
    '''
    CREATE TABLE matchs_scores (
      match_id TEXT NOT NULL,
      set_index INTEGER NOT NULL,
      nous INTEGER NOT NULL,
      eux INTEGER NOT NULL,
      PRIMARY KEY (match_id, set_index)
    )''',
  ],

  // ── v2 · everything that was kept in memory or in shared_preferences ───────────────────────
  2: [
    // Settings and drafts (replace shared_preferences).
    'CREATE TABLE preferences (cle TEXT PRIMARY KEY, valeur TEXT)',
    'CREATE TABLE brouillons (cle TEXT PRIMARY KEY, contenu TEXT NOT NULL, maj_le TEXT NOT NULL)',
    'CREATE TABLE recherches_recentes (requete TEXT PRIMARY KEY, faite_le TEXT NOT NULL)',
    '''
    CREATE TABLE reglages_compte (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      email TEXT NOT NULL,
      telephone TEXT NOT NULL,
      prenom TEXT NOT NULL,
      nom TEXT NOT NULL,
      date_naissance TEXT NOT NULL,
      genre TEXT NOT NULL,
      mdp_change TEXT NOT NULL,
      double_facteur INTEGER NOT NULL,
      google_email TEXT,
      apple INTEGER NOT NULL,
      profil_public INTEGER NOT NULL,
      invitations TEXT NOT NULL,
      montrer_niveau INTEGER NOT NULL,
      montrer_fiabilite INTEGER NOT NULL,
      position_precise INTEGER NOT NULL,
      bloques INTEGER NOT NULL,
      resume_notifications TEXT NOT NULL
    )''',
    '''
    CREATE TABLE sessions_appareils (
      id TEXT PRIMARY KEY,
      nom TEXT NOT NULL,
      lieu TEXT NOT NULL,
      actuelle INTEGER NOT NULL DEFAULT 0,
      mobile INTEGER NOT NULL DEFAULT 1,
      position INTEGER NOT NULL
    )''',

    // Money: balance, history, refunds, cards, payments, Premium.
    'CREATE TABLE porte_monnaie (id INTEGER PRIMARY KEY CHECK (id = 1), solde REAL NOT NULL)',
    '''
    CREATE TABLE transactions (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL,
      sport TEXT,
      libelle TEXT NOT NULL,
      detail TEXT NOT NULL,
      montant REAL NOT NULL,
      date TEXT NOT NULL,
      statut TEXT NOT NULL,
      depuis_solde INTEGER NOT NULL DEFAULT 0
    )''',
    '''
    CREATE TABLE demandes_remboursement (
      id TEXT PRIMARY KEY,
      transaction_id TEXT NOT NULL REFERENCES transactions (id),
      motif TEXT NOT NULL,
      note TEXT NOT NULL,
      cible TEXT NOT NULL,
      envoyee_le TEXT NOT NULL,
      examen_depuis TEXT,
      photos INTEGER NOT NULL DEFAULT 0,
      etape TEXT NOT NULL
    )''',
    '''
    CREATE TABLE cartes (
      id TEXT PRIMARY KEY,
      marque TEXT NOT NULL CHECK (marque IN ('visa', 'mastercard')),
      derniers_chiffres TEXT NOT NULL,
      mois_exp INTEGER NOT NULL,
      annee_exp INTEGER NOT NULL,
      par_defaut INTEGER NOT NULL DEFAULT 0,
      position INTEGER NOT NULL
    )''',
    '''
    CREATE TABLE paiements (
      numero TEXT PRIMARY KEY,
      montant REAL NOT NULL,
      paye_le TEXT NOT NULL,
      moyen TEXT NOT NULL,
      carte_id TEXT,
      motif TEXT
    )''',
    'CREATE TABLE codes_promo (code TEXT PRIMARY KEY, pourcentage INTEGER, erreur TEXT)',
    '''
    CREATE TABLE abonnement (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      statut TEXT NOT NULL,
      periode TEXT NOT NULL,
      fin_essai TEXT NOT NULL,
      rappel TEXT NOT NULL,
      carte TEXT NOT NULL,
      offre_acceptee INTEGER NOT NULL DEFAULT 0,
      motif_annulation TEXT,
      note_annulation TEXT
    )''',
    '''
    CREATE TABLE recus (
      numero TEXT PRIMARY KEY,
      libelle TEXT NOT NULL,
      date TEXT NOT NULL,
      montant REAL NOT NULL,
      carte TEXT NOT NULL,
      reference TEXT,
      politique TEXT
    )''',
    '''
    CREATE TABLE recu_lignes (
      numero TEXT NOT NULL REFERENCES recus (numero) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      libelle TEXT NOT NULL,
      montant REAL NOT NULL,
      quantite INTEGER NOT NULL DEFAULT 1,
      details TEXT NOT NULL DEFAULT '[]',
      PRIMARY KEY (numero, position)
    )''',

    // Player: notifications, games, profile.
    '''
    CREATE TABLE notifications (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL,
      titre TEXT NOT NULL,
      corps TEXT NOT NULL,
      recue_le TEXT NOT NULL,
      priorite TEXT NOT NULL,
      sport TEXT,
      icone TEXT,
      statut TEXT,
      avatar TEXT,
      personnes TEXT NOT NULL DEFAULT '[]',
      vignette TEXT,
      ia INTEGER NOT NULL DEFAULT 0,
      actions TEXT NOT NULL DEFAULT '[]',
      cible TEXT,
      cible_id TEXT,
      expire_le TEXT,
      non_lue INTEGER NOT NULL DEFAULT 0
    )''',
    '''
    CREATE TABLE parties (
      id TEXT PRIMARY KEY,
      etablissement_id TEXT,
      sport TEXT NOT NULL,
      etablissement TEXT NOT NULL,
      terrain TEXT,
      lieu TEXT NOT NULL,
      distance_km REAL,
      debut TEXT NOT NULL,
      places_total INTEGER NOT NULL,
      places_restantes INTEGER NOT NULL,
      places_liberees INTEGER NOT NULL DEFAULT 0,
      prix_joueur REAL NOT NULL,
      type_partie TEXT NOT NULL,
      niveau_min REAL,
      niveau_max REAL,
      date_libelle TEXT,
      organisateur TEXT,
      fiabilite_organisateur INTEGER,
      compatibilite INTEGER,
      raison_compatibilite TEXT,
      statut TEXT NOT NULL,
      remboursement REAL,
      recommandee INTEGER,
      publiee INTEGER NOT NULL DEFAULT 0,
      position INTEGER NOT NULL
    )''',
    '''
    CREATE TABLE partie_joueurs (
      partie_id TEXT NOT NULL REFERENCES parties (id) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      nom TEXT NOT NULL,
      PRIMARY KEY (partie_id, position)
    )''',
    '''
    CREATE TABLE participations (
      partie_id TEXT PRIMARY KEY REFERENCES parties (id) ON DELETE CASCADE,
      statut TEXT NOT NULL CHECK (statut IN ('inscrit', 'attente')),
      equipe INTEGER,
      place INTEGER,
      position_attente INTEGER,
      le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE profil_joueur (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      pseudo TEXT NOT NULL,
      bio TEXT NOT NULL,
      sports TEXT NOT NULL,
      postes TEXT NOT NULL,
      zones TEXT NOT NULL,
      visibilite TEXT NOT NULL,
      montrer_niveau INTEGER NOT NULL,
      montrer_fiabilite INTEGER NOT NULL,
      suggerer_partenaire INTEGER NOT NULL
    )''',
    'CREATE TABLE joueurs_suivis (nom TEXT PRIMARY KEY, suivi_le TEXT NOT NULL)',
    '''
    CREATE TABLE niveaux_ajustes (
      sport TEXT PRIMARY KEY,
      niveau REAL,
      conteste INTEGER NOT NULL DEFAULT 0,
      le TEXT NOT NULL
    )''',

    // Catalogues: venues, tournaments, search, teammates.
    '''
    CREATE TABLE etablissements (
      id TEXT PRIMARY KEY,
      nom TEXT NOT NULL,
      lieu TEXT NOT NULL,
      distance_km REAL,
      note REAL,
      nb_avis INTEGER NOT NULL DEFAULT 0,
      verifie INTEGER NOT NULL DEFAULT 0,
      prix_joueur REAL NOT NULL,
      prix_terrain REAL,
      unite_prix TEXT NOT NULL DEFAULT '/h',
      statut TEXT NOT NULL,
      ouvre_a TEXT,
      jour_creneaux TEXT,
      latitude REAL,
      longitude REAL,
      position INTEGER NOT NULL
    )''',
    '''
    CREATE TABLE etablissement_sports (
      etablissement_id TEXT NOT NULL REFERENCES etablissements (id) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      sport TEXT NOT NULL,
      PRIMARY KEY (etablissement_id, position)
    )''',
    '''
    CREATE TABLE etablissement_equipements (
      etablissement_id TEXT NOT NULL REFERENCES etablissements (id) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      equipement TEXT NOT NULL,
      PRIMARY KEY (etablissement_id, position)
    )''',
    '''
    CREATE TABLE etablissement_creneaux (
      etablissement_id TEXT NOT NULL REFERENCES etablissements (id) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      heure TEXT NOT NULL,
      PRIMARY KEY (etablissement_id, position)
    )''',
    '''
    CREATE TABLE tournois (
      id TEXT PRIMARY KEY,
      sport TEXT NOT NULL,
      nom TEXT NOT NULL,
      debut TEXT NOT NULL,
      fin TEXT NOT NULL,
      etablissement TEXT NOT NULL,
      lieu TEXT NOT NULL,
      frais_equipe REAL NOT NULL,
      dotation REAL,
      equipes_total INTEGER NOT NULL,
      equipes_inscrites INTEGER NOT NULL,
      niveau_min REAL,
      niveau_max REAL
    )''',
    'CREATE TABLE zones (nom TEXT PRIMARY KEY, position INTEGER NOT NULL, autour INTEGER NOT NULL)',
    '''
    CREATE TABLE zone_etablissements (
      zone TEXT NOT NULL REFERENCES zones (nom) ON DELETE CASCADE,
      etablissement_id TEXT NOT NULL REFERENCES etablissements (id) ON DELETE CASCADE,
      PRIMARY KEY (zone, etablissement_id)
    )''',
    '''
    CREATE TABLE joueurs_recherche (
      nom TEXT PRIMARY KEY,
      niveau REAL NOT NULL,
      lieu TEXT NOT NULL,
      position INTEGER NOT NULL
    )''',
    '''
    CREATE TABLE coequipiers (
      nom TEXT PRIMARY KEY,
      niveau REAL NOT NULL,
      poste TEXT NOT NULL,
      matchs_ensemble INTEGER NOT NULL,
      position INTEGER NOT NULL
    )''',

    // Owner space.
    '''
    CREATE TABLE proprio_terrains (
      id TEXT PRIMARY KEY,
      numero INTEGER NOT NULL UNIQUE,
      interieur INTEGER NOT NULL DEFAULT 0,
      visible INTEGER NOT NULL DEFAULT 1,
      maintenance INTEGER NOT NULL DEFAULT 0
    )''',
    '''
    CREATE TABLE proprio_reservations (
      ref TEXT PRIMARY KEY,
      terrain INTEGER NOT NULL,
      debut TEXT NOT NULL,
      heures INTEGER NOT NULL DEFAULT 1,
      organisateur TEXT NOT NULL,
      type TEXT NOT NULL,
      joueurs INTEGER NOT NULL,
      capacite INTEGER NOT NULL,
      prix REAL NOT NULL,
      paye REAL NOT NULL,
      statut TEXT NOT NULL,
      moi INTEGER NOT NULL DEFAULT 0,
      type_partie TEXT NOT NULL,
      niveau_min REAL,
      niveau_max REAL,
      fiabilite INTEGER NOT NULL,
      honores INTEGER NOT NULL,
      matchs INTEGER NOT NULL,
      note TEXT
    )''',
    'CREATE INDEX proprio_reservations_debut ON proprio_reservations (debut)',
    '''
    CREATE TABLE proprio_presences (
      ref TEXT NOT NULL REFERENCES proprio_reservations (ref) ON DELETE CASCADE,
      etat TEXT NOT NULL CHECK (etat IN ('arrive', 'attendu', 'absent')),
      position INTEGER NOT NULL,
      nom TEXT NOT NULL,
      PRIMARY KEY (ref, etat, position)
    )''',
    '''
    CREATE TABLE proprio_blocages (
      id TEXT PRIMARY KEY,
      terrain INTEGER NOT NULL,
      debut TEXT NOT NULL,
      fin TEXT NOT NULL,
      motif TEXT NOT NULL,
      note TEXT,
      hebdo INTEGER NOT NULL DEFAULT 0
    )''',
    '''
    CREATE TABLE tarifs (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      pointe_de INTEGER NOT NULL,
      pointe_a INTEGER NOT NULL,
      weekend_pointe INTEGER NOT NULL
    )''',
    '''
    CREATE TABLE tarif_groupes (
      id TEXT PRIMARY KEY,
      interieur INTEGER NOT NULL DEFAULT 0,
      prix_creuse REAL NOT NULL,
      prix_pointe REAL NOT NULL,
      position INTEGER NOT NULL
    )''',
    '''
    CREATE TABLE tarif_groupe_terrains (
      groupe_id TEXT NOT NULL REFERENCES tarif_groupes (id) ON DELETE CASCADE,
      terrain INTEGER NOT NULL,
      PRIMARY KEY (groupe_id, terrain)
    )''',
    '''
    CREATE TABLE dates_speciales (
      id TEXT PRIMARY KEY,
      jour TEXT NOT NULL,
      nom TEXT NOT NULL,
      pointe_journee INTEGER NOT NULL DEFAULT 0,
      de INTEGER,
      a INTEGER,
      a_confirmer INTEGER NOT NULL DEFAULT 0
    )''',
    '''
    CREATE TABLE promos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      jour_semaine INTEGER NOT NULL,
      de INTEGER NOT NULL,
      a INTEGER NOT NULL,
      pourcentage INTEGER NOT NULL,
      prix_avant REAL NOT NULL,
      premier_jour TEXT NOT NULL,
      hebdo INTEGER NOT NULL DEFAULT 0
    )''',
    '''
    CREATE TABLE avis_etablissement (
      id TEXT PRIMARY KEY,
      auteur TEXT NOT NULL,
      note INTEGER NOT NULL CHECK (note BETWEEN 1 AND 5),
      date TEXT NOT NULL,
      terrain INTEGER NOT NULL,
      texte TEXT NOT NULL,
      reponse TEXT,
      reponse_le TEXT,
      brouillon TEXT
    )''',
    '''
    CREATE TABLE avis_repartition (
      etoiles INTEGER PRIMARY KEY CHECK (etoiles BETWEEN 1 AND 5),
      nombre INTEGER NOT NULL
    )''',
    '''
    CREATE TABLE proprio_clientele (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      total INTEGER NOT NULL,
      habitues INTEGER NOT NULL,
      nouveaux INTEGER NOT NULL,
      avec_absence INTEGER NOT NULL,
      depuis TEXT NOT NULL
    )''',
    '''
    CREATE TABLE proprio_clients (
      nom TEXT PRIMARY KEY,
      telephone TEXT NOT NULL,
      visites INTEGER NOT NULL,
      depense REAL NOT NULL,
      absences INTEGER NOT NULL DEFAULT 0,
      fiabilite INTEGER NOT NULL,
      derniere_visite TEXT NOT NULL,
      prochaine_visite TEXT,
      premiere_visite TEXT NOT NULL,
      favori TEXT NOT NULL,
      habitue INTEGER NOT NULL DEFAULT 0,
      nouveau INTEGER NOT NULL DEFAULT 0,
      position INTEGER NOT NULL
    )''',
    '''
    CREATE TABLE client_reservations (
      client TEXT NOT NULL REFERENCES proprio_clients (nom) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      ref TEXT NOT NULL,
      PRIMARY KEY (client, position)
    )''',

    // Admin: the journal of decisions, replayed over the story's lists.
    '''
    CREATE TABLE admin_journal (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      action TEXT NOT NULL,
      cible TEXT NOT NULL,
      valeur TEXT,
      le TEXT NOT NULL
    )''',
  ],

  // ── v3 · Paiement: payment lifecycle, every attempt, split shares, finished refunds ─────────
  3: [
    // A payment that went through can later be refunded; `reference` is what it paid for
    // (booking « MU-48213 », game « g1 »…), null for a top-up or Premium.
    "ALTER TABLE paiements ADD COLUMN statut TEXT NOT NULL DEFAULT 'paye' "
        "CHECK (statut IN ('paye', 'rembourse'))",
    'ALTER TABLE paiements ADD COLUMN reference TEXT',
    'ALTER TABLE paiements ADD COLUMN rembourse_le TEXT',
    'CREATE INDEX paiements_reference ON paiements (reference)',

    // Every try at the bank, failed ones included (3-D Secure waits as « en_attente »).
    '''
    CREATE TABLE tentatives_paiement (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      montant REAL NOT NULL,
      moyen TEXT NOT NULL,
      carte_id TEXT,
      motif TEXT,
      reference TEXT,
      statut TEXT NOT NULL CHECK (statut IN ('en_attente', 'paye', 'echoue')),
      raison TEXT,
      tentee_le TEXT NOT NULL,
      numero TEXT REFERENCES paiements (numero)
    )''',

    // PAY-11: the shares collected after the booking (who joined, who still owes, who the
    // organiser paid for). The organiser's friends paid with the booking itself.
    '''
    CREATE TABLE parts_paiement (
      reservation_id TEXT NOT NULL,
      joueur TEXT NOT NULL,
      montant REAL NOT NULL,
      statut TEXT NOT NULL CHECK (statut IN ('payee', 'en_attente', 'avancee')),
      partie_publique INTEGER NOT NULL DEFAULT 0,
      relancee_le TEXT,
      payee_le TEXT,
      numero TEXT,
      position INTEGER NOT NULL,
      PRIMARY KEY (reservation_id, joueur)
    )''',

    // When a refund request was paid back.
    'ALTER TABLE demandes_remboursement ADD COLUMN rembourse_le TEXT',
  ],

  // ── v4 · Supabase sync: the changes waiting to be sent (lib/core/sync) ─────────────────────
  4: [
    '''
    CREATE TABLE sync_outbox (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tableau TEXT NOT NULL,
      operation TEXT NOT NULL CHECK (operation IN ('upsert', 'delete')),
      k1 TEXT,
      k2 TEXT,
      k3 TEXT,
      le TEXT NOT NULL
    )''',
    // application = 1 while pulled rows are written (the triggers stay quiet); utilisateur = the
    // Supabase user this phone last pulled for.
    '''
    CREATE TABLE sync_etat (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      application INTEGER NOT NULL DEFAULT 0,
      utilisateur TEXT,
      dernier_pull TEXT
    )''',
    'INSERT INTO sync_etat (id) VALUES (1)',
  ],

  // ── v5 · Entraînement (ENT-01…09): programs joined, sessions done, streak, AI plans, videos ──
  5: [
    '''
    CREATE TABLE entrainement_inscriptions (
      programme TEXT PRIMARY KEY,
      inscrit_le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE entrainement_seances (
      programme TEXT NOT NULL,
      seance INTEGER NOT NULL,
      faite_le TEXT NOT NULL,
      minutes INTEGER NOT NULL,
      exercices_faits INTEGER NOT NULL,
      exercices_total INTEGER NOT NULL,
      reussis INTEGER,
      objectif INTEGER,
      ressenti TEXT CHECK (ressenti IN ('easy', 'right', 'hard')),
      notes TEXT,
      PRIMARY KEY (programme, seance)
    )''',
    '''
    CREATE TABLE entrainement_profil (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      serie_semaines INTEGER NOT NULL,
      objectif_semaine INTEGER NOT NULL,
      plan_masque INTEGER NOT NULL DEFAULT 0
    )''',
    '''
    CREATE TABLE entrainement_plans (
      id TEXT PRIMARY KEY,
      semaine TEXT NOT NULL,
      objectifs TEXT NOT NULL,
      contenu TEXT NOT NULL,
      accepte_le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE entrainement_analyses (
      id TEXT PRIMARY KEY,
      geste TEXT NOT NULL,
      fichier TEXT NOT NULL,
      taille INTEGER NOT NULL,
      partage INTEGER NOT NULL DEFAULT 0,
      cree_le TEXT NOT NULL
    )''',

    // Programs saved (🔖, ENT-03) and the player's rating of a finished program.
    '''
    CREATE TABLE entrainement_favoris (
      programme TEXT PRIMARY KEY,
      ajoute_le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE entrainement_avis (
      programme TEXT PRIMARY KEY,
      note INTEGER NOT NULL CHECK (note BETWEEN 1 AND 5),
      texte TEXT,
      le TEXT NOT NULL
    )''',

    // Coach space (COA-04…12): the program being written, todos handled, feedback sent.
    '''
    CREATE TABLE coach_brouillons (
      id TEXT PRIMARY KEY,
      contenu TEXT NOT NULL,
      modifie_le TEXT NOT NULL,
      supprime INTEGER NOT NULL DEFAULT 0
    )''',
    '''
    CREATE TABLE coach_actions (
      cle TEXT PRIMARY KEY,
      faite_le TEXT NOT NULL
    )''',
    '''
    CREATE TABLE coach_retours (
      eleve TEXT PRIMARY KEY,
      commentaires TEXT NOT NULL,
      message TEXT NOT NULL,
      nouvelle_video INTEGER NOT NULL DEFAULT 0,
      envoye_le TEXT NOT NULL
    )''',
  ],
};
