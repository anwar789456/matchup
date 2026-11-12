// Scénario complet du module paiement contre le module qui tourne (npm run start:paiement).
//   node apps/paiement/test/scenario.mjs            (http://localhost:3003 par défaut)
//   API=http://192.168.1.20:3003 node apps/paiement/test/scenario.mjs
// Chaque lancement prend de nouveaux ids d’utilisateurs : on peut le relancer autant qu’on veut.
import assert from 'node:assert/strict';

const API = `${process.env.API ?? 'http://localhost:3003'}/api/paiement`;
const U = 100_000 + Math.floor(Math.random() * 800_000); // organisateur / joueur principal
const BEN_PROPRIO = U + 50;
const BEN_COACH = U + 51;
let etapes = 0;

async function call(method, path, body, attendu) {
  const res = await fetch(`${API}${path}`, {
    method,
    headers: { 'content-type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const json = await res.json().catch(() => null);
  const ok = attendu ? res.status === attendu : res.ok;
  if (!ok) throw new Error(`${method} ${path} → ${res.status} ${JSON.stringify(json)}`);
  return json;
}
const get = (p) => call('GET', p);
const post = (p, b = {}, attendu) => call('POST', p, b, attendu);
const etape = (nom) => console.log(`✓ ${String(++etapes).padStart(2)} ${nom}`);
const solde = async (u) => (await get(`/portefeuilles/${u}`)).solde;
const carte4242 = { numero: '4242 4242 4242 4242', moisExp: 8, anneeExp: 2030, titulaire: 'Yassine B.' };

// ── Plans ──────────────────────────────────────────────────────────────────────────────────
const plans = await get('/abonnements/plans');
assert.equal(plans.length, 5);
assert.deepEqual(plans.find((p) => p.code === 'joueur_premium').economieAnnuelle, { montant: 38, pourcentage: 17, moisOfferts: 2 });
etape('plans : Premium 19/190, −17 %, 2 mois offerts');

// ── Cartes ─────────────────────────────────────────────────────────────────────────────────
const visa = await post('/cartes', { utilisateurId: U, ...carte4242 });
assert.equal(visa.libelle, 'Visa •••• 4242');
assert.equal(visa.parDefaut, true);
assert.equal(visa.numero, undefined);
const mc = await post('/cartes', { utilisateurId: U, numero: '5555555555554444', moisExp: 12, anneeExp: 2031 });
assert.equal(mc.parDefaut, false);
await post(`/cartes/${mc.id}/par-defaut`);
assert.equal((await get(`/cartes?utilisateurId=${U}`))[0].id, mc.id);
await call('DELETE', `/cartes/${mc.id}`);
assert.equal((await get(`/cartes?utilisateurId=${U}`))[0].parDefaut, true);
await post('/cartes', { utilisateurId: U, numero: '4242424242424241', moisExp: 8, anneeExp: 2030 }, 400);
await post('/cartes', { utilisateurId: U, numero: '4242424242424242', moisExp: 1, anneeExp: 2024 }, 400);
etape('cartes : 4 derniers chiffres seulement, défaut, Luhn et expiration refusés');

// ── Codes promo ────────────────────────────────────────────────────────────────────────────
const bienvenue = await post('/codes-promo/verifier', { code: ' bienvenue10 ', montant: 15 });
assert.deepEqual([bienvenue.valide, bienvenue.remise, bienvenue.total], [true, 1.5, 13.5]);
assert.equal((await post('/codes-promo/verifier', { code: 'MARSA2025', montant: 15 })).erreur, 'Ce code a expiré le 31 déc. 2025.');
assert.equal((await post('/codes-promo/verifier', { code: 'NOPE', montant: 15 })).erreur, 'Ce code n’existe pas.');
etape('codes promo : BIENVENUE10 −10 %, MARSA2025 expiré, inconnu');

// ── Recharge et paiement par le solde ──────────────────────────────────────────────────────
const recharge = await post(`/portefeuilles/${U}/recharger`, { montant: 50 });
assert.equal(recharge.statut, 'paye');
assert.match(recharge.reference, /^MU-R-\d{4}-\d{5}$/);
assert.equal(await solde(U), 50);
await post(`/portefeuilles/${U}/recharger`, { montant: 2 }, 400);
etape(`recharge 50 DT par carte → solde 50 (reçu ${recharge.reference})`);

const parSolde = await post('/paiements', {
  utilisateurId: U, objet: 'partie', objetId: 'g1', libelle: 'Part · Arena Five', montant: 15,
  codePromo: 'BIENVENUE10', methode: 'portefeuille',
});
assert.deepEqual([parSolde.statut, parSolde.methode, parSolde.montant, parSolde.remise], ['paye', 'portefeuille', 13.5, 1.5]);
assert.equal(await solde(U), 36.5);
await post('/paiements', { utilisateurId: U, objet: 'partie', libelle: 'Trop cher', montant: 999, methode: 'portefeuille' }, 409);
etape('part payée avec le solde et BIENVENUE10 : 13,5 DT, solde 36,5 ; solde insuffisant refusé');

// ── Banque : refus, 3-D Secure ─────────────────────────────────────────────────────────────
const refuse = await post('/paiements', {
  utilisateurId: U, objet: 'partie', libelle: 'Part', montant: 15, moyen: { simulation: 'fonds_insuffisants' },
});
assert.deepEqual([refuse.statut, refuse.raisonEchec, refuse.reference], ['echoue', 'fonds insuffisants', null]);
const refuseCarte = await post('/paiements', {
  utilisateurId: U, objet: 'partie', libelle: 'Part', montant: 15,
  moyen: { nouvelleCarte: { numero: '4000000000000002', moisExp: 1, anneeExp: 2030 } },
});
assert.equal(refuseCarte.raisonEchec, 'carte refusée');
assert.equal(await solde(U), 36.5);
etape('carte refusée / fonds insuffisants : échec gardé, rien débité');

const tdsOk = await post('/paiements', {
  utilisateurId: U, objet: 'reservation', objetId: 'MU-48213', libelle: 'Arena Five · Terrain 1', montant: 20,
  moyen: { nouvelleCarte: { numero: '4000 0025 0000 3155', moisExp: 3, anneeExp: 2029 } },
});
assert.equal(tdsOk.statut, 'a_authentifier');
const tdsPaye = await post(`/paiements/${tdsOk.id}/authentifier`, { approuve: true });
assert.equal(tdsPaye.statut, 'paye');
assert.equal(tdsPaye.carteLibelle, 'Visa •••• 3155');
await post(`/paiements/${tdsOk.id}/authentifier`, { approuve: true }, 409);
const tdsNon = await post('/paiements', { utilisateurId: U, objet: 'partie', libelle: 'Part', montant: 9, moyen: { simulation: '3ds' } });
assert.equal((await post(`/paiements/${tdsNon.id}/authentifier`, { approuve: false })).raisonEchec, 'authentification annulée');
etape('3-D Secure : validé → payé, annulé → échec');

// ── Paiement mixte, reçu, remboursement sur demande ────────────────────────────────────────
const mixte = await post('/paiements', {
  utilisateurId: U, objet: 'reservation', objetId: 'MU-50001', libelle: 'Padel Club · Terrain 2', montant: 50,
  beneficiaireId: BEN_PROPRIO, moyen: { utiliserSolde: true },
});
assert.deepEqual([mixte.methode, mixte.montantPortefeuille, mixte.montantCarte], ['mixte', 36.5, 13.5]);
assert.equal(await solde(U), 0);
const recu = await get(`/paiements/${mixte.id}/recu`);
assert.deepEqual(recu.reglement.map((r) => r.moyen), ['Solde MatchUp', 'Visa •••• 4242']);
await get(`/paiements/${refuse.id}/recu`).then(() => assert.fail('pas de reçu attendu'), () => {});
etape('mixte : 36,5 DT de solde + 13,5 DT de carte, reçu sur deux lignes');

const demande = await post('/remboursements', {
  utilisateurId: U, paiementId: mixte.id, motif: 'terrain_ferme', note: 'Fermé à notre arrivée.', cible: 'portefeuille', photos: 1,
});
assert.equal(demande.statut, 'envoyee');
await post('/remboursements', { utilisateurId: U, paiementId: mixte.id, motif: 'autre', cible: 'portefeuille' }, 409);
await post('/remboursements', { utilisateurId: U + 1, paiementId: tdsPaye.id, motif: 'autre', cible: 'carte' }, 403);
assert.equal((await post(`/remboursements/${demande.id}/examiner`)).statut, 'en_examen');
assert.equal((await post(`/remboursements/${demande.id}/accepter`)).statut, 'remboursee');
assert.equal((await get(`/paiements/${mixte.id}`)).statut, 'rembourse');
assert.equal(await solde(U), 50);
const refusDemande = await post('/remboursements', { utilisateurId: U, paiementId: tdsPaye.id, motif: 'autre', cible: 'carte' });
assert.equal((await post(`/remboursements/${refusDemande.id}/refuser`, { motif: 'Match joué.' })).statut, 'refusee');
const partiel = await post(`/paiements/${tdsPaye.id}/rembourser`, { montant: 5, vers: 'portefeuille' });
assert.deepEqual([partiel.statut, partiel.montantRembourse], ['partiellement_rembourse', 5]);
await post(`/paiements/${tdsPaye.id}/rembourser`, { montant: 50 }, 400);
assert.equal(await solde(U), 55);
etape('remboursement : demande → examen → accepté (solde +50), doublon 409, refus, partiel');

// ── Paiement partagé (PAY-11 / PAY-12) ─────────────────────────────────────────────────────
const dans2Jours = new Date(Date.now() + 2 * 86_400_000).toISOString();
const joueurs = [{ joueurId: U, nom: 'Yassine B.' }, ...Array.from({ length: 9 }, (_, i) => ({ joueurId: U + 1 + i, nom: `Joueur ${i + 1}` }))];
let partage = await post('/partages', {
  reservationId: `MU-T${U}`, organisateurId: U, libelle: 'Arena Five · Terrain 1', montantTotal: 150,
  beneficiaireId: BEN_PROPRIO, debutMatch: dans2Jours, joueurs,
});
assert.equal(partage.parts.length, 10);
assert.ok(partage.parts.every((p) => p.montant === 15));
await post('/partages', { reservationId: `MU-T${U}`, organisateurId: U, libelle: 'x', montantTotal: 10, debutMatch: dans2Jours, joueurs }, 409);
const p1 = partage.parts[1];
const paye1 = await post(`/partages/${partage.id}/parts/${p1.id}/payer`, { moyen: { nouvelleCarte: carte4242 } });
assert.equal(paye1.paiement.statut, 'paye');
assert.equal(paye1.partage.resume.collecte, 15);
await post(`/partages/${partage.id}/parts/${p1.id}/payer`, { moyen: { nouvelleCarte: carte4242 } }, 409);
const relance = await post(`/partages/${partage.id}/relancer`, {});
assert.equal(relance.destinatairesIds.length, 9);
const reste = await post(`/partages/${partage.id}/payer-le-reste`, {});
assert.deepEqual([reste.paiement.montant, reste.partage.statut, reste.partage.resume.avancees], [135, 'complet', 9]);
partage = await post(`/partages/${partage.id}/annuler`);
assert.equal(partage.statut, 'annule');
assert.ok(partage.parts.every((p) => p.statut === 'remboursee'));
assert.equal(await solde(U + 1), 15);
assert.equal(await solde(U), 55 + 135);
etape('partage 150 DT / 10 : une part payée, relance ×9, « Payer le reste » 135 DT, annulé → chacun remboursé');

const bientot = new Date(Date.now() + 3.5 * 3_600_000).toISOString();
const proche = await post('/partages', { reservationId: `MU-P${U}`, organisateurId: U, libelle: 'Padel', montantTotal: 40, debutMatch: bientot, joueurs: joueurs.slice(0, 4) });
assert.equal((await post(`/partages/${proche.id}/verifier-echeance`)).annule, false);
await post('/partages', { reservationId: `MU-Q${U}`, organisateurId: U, libelle: 'Padel', montantTotal: 40, debutMatch: new Date(Date.now() + 3_600_000).toISOString(), joueurs }, 400);
etape('échéance 3 h avant : pas encore passée ; création trop tardive refusée');

// ── Abonnements ────────────────────────────────────────────────────────────────────────────
let { abonnement: ab } = await post('/abonnements', { utilisateurId: U, plan: 'joueur_premium', periode: 'mensuel' });
assert.deepEqual([ab.statut, ab.prix, ab.joursRestantsEssai], ['essai', 19, 14]);
assert.equal(new Date(ab.finEssai) - new Date(ab.rappelLe), 3 * 86_400_000);
await post('/abonnements', { utilisateurId: U, plan: 'joueur_premium', periode: 'annuel' }, 409);
const versAnnuel = await post(`/abonnements/${ab.id}/changer`, { periode: 'annuel' });
assert.deepEqual([versAnnuel.aPayer, versAnnuel.abonnement.prix, versAnnuel.abonnement.statut], [0, 190, 'essai']);
const offre = await post(`/abonnements/${ab.id}/annuler`, { motif: 'trop_cher' });
assert.deepEqual([offre.annule, offre.offre.prixAvecOffre], [false, 133]);
ab = await post(`/abonnements/${ab.id}/accepter-offre`);
assert.equal(ab.prixActuel, 133);
const annule = await post(`/abonnements/${ab.id}/annuler`, { motif: 'trop_cher' });
assert.deepEqual([annule.annule, annule.abonnement.statut], [true, 'annule']);
assert.equal(annule.abonnement.finLe, annule.abonnement.finEssai);
assert.equal((await post(`/abonnements/${ab.id}/reactiver`)).statut, 'essai');
const prelevement = await post(`/abonnements/${ab.id}/prelever`, { forcer: true });
assert.deepEqual([prelevement.paiement.montant, prelevement.abonnement.statut], [133, 'actif']);
etape('Premium : essai 14 j (rappel J−3), passage à l’annuel, offre −30 %, résilier, réactiver, prélèvement 133 DT');

const W = U + 20;
let r = await post('/abonnements', { utilisateurId: W, plan: 'joueur_premium', periode: 'mensuel', moyen: { nouvelleCarte: carte4242 } });
await post(`/abonnements/${r.abonnement.id}/annuler`, { motif: 'autre', confirmer: true });
assert.equal((await post(`/abonnements/${r.abonnement.id}/prelever`, { forcer: true })).abonnement.statut, 'expire');
r = await post('/abonnements', { utilisateurId: W, plan: 'joueur_premium', periode: 'mensuel' });
assert.deepEqual([r.abonnement.statut, r.paiement.montant], ['actif', 19]);
const apercu = await post(`/abonnements/${r.abonnement.id}/changer`, { periode: 'annuel', apercu: true });
assert.ok(apercu.credit > 18.9 && apercu.credit <= 19);
const change = await post(`/abonnements/${r.abonnement.id}/changer`, { periode: 'annuel' });
assert.deepEqual([change.paiement.statut, change.abonnement.periode, change.abonnement.prix], ['paye', 'annuel', 190]);
const impaye = await post(`/abonnements/${r.abonnement.id}/prelever`, { forcer: true, simulation: 'refuse' });
assert.equal(impaye.abonnement.statut, 'impaye');
etape('2e abonnement sans essai : 19 DT tout de suite, prorata vers l’annuel (~171 DT), prélèvement refusé → impayé');

// ── Versements et finance ──────────────────────────────────────────────────────────────────
await post('/paiements', { utilisateurId: U, objet: 'reservation', libelle: 'Terrain', montant: 60, beneficiaireId: BEN_PROPRIO, methode: 'especes' });
await post('/paiements', { utilisateurId: U, objet: 'programme', libelle: 'Programme service', montant: 100, beneficiaireId: BEN_COACH });
const periode = { du: new Date(Date.now() - 86_400_000).toISOString(), au: new Date(Date.now() + 86_400_000).toISOString() };
const vue = await post('/versements/calculer', { beneficiaireId: BEN_PROPRIO, role: 'proprietaire', ...periode, apercu: true });
// mixte 50 (remboursé 50) + parts du partage 15 + 135 (remboursées) + espèces 60
assert.deepEqual([vue.montantBrut, vue.montantRembourse, vue.montantNet], [260, 200, 60]);
const vp = await post('/versements/calculer', { beneficiaireId: BEN_PROPRIO, role: 'proprietaire', ...periode });
await post('/versements/calculer', { beneficiaireId: BEN_PROPRIO, role: 'proprietaire', ...periode }, 400);
await post(`/versements/${vp.id}/envoyer`, {}, 409);
assert.equal((await post('/versements/valider', { ids: [vp.id] }))[0].statut, 'valide');
assert.match((await post(`/versements/${vp.id}/envoyer`)).reference, /^VIR-\d{4}-\d{5}$/);
const vc = await post('/versements/calculer', { beneficiaireId: BEN_COACH, role: 'coach', ...periode });
assert.deepEqual([vc.montantBrut, vc.commission, vc.montantNet], [100, 10, 90]);
etape('versements : propriétaire 60 DT net (remboursements déduits), coach 100 − 10 % = 90 DT, valider puis envoyer');

const finance = await get('/finance/resume');
assert.ok(finance.encaisse > 0 && finance.paiementsEchoues >= 3);
await post(`/portefeuilles/${U}/ajuster`, { montant: -1_000_000, libelle: 'Trop' }, 409);
etape(`finance : ${finance.encaisse} DT encaissés ce mois-ci, ${finance.paiementsEchoues} échecs ; solde jamais négatif`);

console.log(`\nToutes les étapes passent (${etapes}). Utilisateur de test : ${U}.`);
