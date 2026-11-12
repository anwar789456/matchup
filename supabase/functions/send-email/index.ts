// Supabase Edge Function: MatchUp emails over plain SMTP (no email provider). Port 465 (SSL),
// because Supabase blocks 25 and 587 from functions.
//
// Secrets (Supabase › Edge Functions › Secrets):
//   SMTP_HOST   smtp.gmail.com          SMTP_PORT  465
//   SMTP_USER   the Gmail address       SMTP_PASS  a Google app password (never the real password)
//   MAIL_TEST_TO  where emails go while the user has no email of their own (anonymous users)
//
// Only ever sends to the signed-in user's own email (or MAIL_TEST_TO): nobody can use it to
// email strangers. Templates follow EML-05 (receipt) and EML-07 (Premium) of the design.
//
// POST { template, data, attachment? }  (signed-in Supabase user required)
//   template: "receipt" | "refund" | "premium_renewed" | "premium_failed" | "trial_ending"
//   attachment: { filename, base64 }   the receipt PDF made by the app
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

/** The signed-in user (the gateway checked the token): their id and email, if any. */
function userOf(req: Request): { id: string; email: string | null } | null {
  try {
    const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
    const p = JSON.parse(atob(token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")));
    return p.role === "authenticated" ? { id: p.sub, email: p.is_anonymous ? null : (p.email || null) } : null;
  } catch {
    return null;
  }
}

// Brand colours (lib/theme/mu_tokens.dart).
const C = { ink900: "#0B1B33", ink500: "#5B6B82", ink100: "#E6EBF2", ink50: "#F5F7FA", volt: "#C6F135", night: "#070F1F", white: "#FFFFFF", error: "#E5484D" };

const esc = (v: unknown) =>
  String(v ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!);

/** « 15 DT », « 13,300 DT ». */
const dt = (n: unknown) => {
  const v = Math.round(Number(n) * 1000) / 1000;
  return `${Number.isInteger(v) ? v : v.toFixed(3).replace(".", ",")} DT`;
};

const row = (label: string, value: string) =>
  `<tr><td style="padding:8px 0;color:${C.ink500};font-size:14px">${esc(label)}</td><td style="padding:8px 0;text-align:right;color:${C.ink900};font-size:14px;font-weight:600">${value}</td></tr>`;

/** The shell shared by every email (the « coque » of EML-05 and EML-07). */
function shell(o: { overline: string; title: string; intro: string; key?: string; rows?: string; button?: string; after?: string; why: string }) {
  return `<!doctype html><html lang="fr"><body style="margin:0;background:${C.ink50};font-family:'Plus Jakarta Sans',Arial,sans-serif">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${C.ink50};padding:24px 12px"><tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:${C.white};border-radius:16px;overflow:hidden">
<tr><td style="background:${C.night};padding:20px 24px;color:${C.white};font-size:20px;font-weight:800">Match<span style="color:${C.volt}">Up</span></td></tr>
<tr><td style="padding:28px 24px 8px">
<div style="font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:${C.ink500};font-weight:700">${esc(o.overline)}</div>
<h1 style="margin:8px 0 8px;font-size:24px;line-height:1.25;color:${C.ink900}">${esc(o.title)}</h1>
<p style="margin:0 0 20px;font-size:15px;line-height:1.5;color:${C.ink500}">${o.intro}</p>
${o.key ?? ""}
${o.rows ? `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-top:1px solid ${C.ink100};margin-top:8px">${o.rows}</table>` : ""}
${o.button ? `<p style="margin:24px 0 8px"><span style="display:inline-block;background:${C.volt};color:${C.ink900};font-weight:700;font-size:15px;padding:14px 22px;border-radius:12px">${esc(o.button)}</span></p>` : ""}
${o.after ?? ""}
<p style="margin:28px 0 4px;font-size:15px;color:${C.ink900}">À très vite sur le terrain,<br><strong>L’équipe MatchUp</strong></p>
<p style="margin:0 0 24px;font-size:13px;color:${C.ink500}">Joue. Réserve. Progresse.</p>
</td></tr>
<tr><td style="background:${C.ink50};padding:16px 24px;font-size:12px;line-height:1.5;color:${C.ink500}">${esc(o.why)}<br>MatchUp · Tunis, Tunisie · contact@matchup.tn</td></tr>
</table></td></tr></table></body></html>`;
}

const keyBlock = (label: string, amount: string, detail: string) =>
  `<div style="background:${C.ink50};border-radius:12px;padding:16px 18px"><div style="font-size:13px;color:${C.ink500}">${esc(label)}</div><div style="font-size:30px;font-weight:800;color:${C.ink900};margin:4px 0">${amount}</div><div style="font-size:13px;color:${C.ink500}">${detail}</div></div>`;

type Data = Record<string, unknown>;

/** Subject and HTML of each template (French, informal « tu »). */
function render(template: string, d: Data): { subject: string; html: string } | null {
  switch (template) {
    case "receipt":
      return {
        subject: `Ton reçu MatchUp · ${dt(d.amount)} · ${d.number}`,
        html: shell({
          overline: "Reçu de paiement",
          title: "Merci, ton paiement est reçu",
          intro: `Voici ton reçu pour ${esc(d.label)}. Le PDF est en pièce jointe.`,
          key: keyBlock("Montant payé", dt(d.amount), `${esc(d.date)} · ${esc(d.card)}`),
          rows:
            row("Reçu N°", esc(d.number)) +
            row("Objet", esc(d.label)) +
            row("Payé par", esc(d.card)) +
            row("Frais de service", "Offerts") +
            row("dont TVA incluse (19 %)", dt(Number(d.amount) - Number(d.amount) / 1.19)) +
            row("Total payé TTC", dt(d.amount)),
          after: `<p style="margin:20px 0 0;font-size:14px;line-height:1.5;color:${C.ink500}"><strong style="color:${C.ink900}">Une question sur ce paiement ?</strong> Réponds à cet email ou ouvre ton portefeuille dans l’app.</p>`,
          why: "Tu reçois cet email car tu as payé sur MatchUp. Les reçus sont toujours envoyés.",
        }),
      };
    case "refund":
      return {
        subject: `Remboursement effectué · ${dt(d.amount)}`,
        html: shell({
          overline: "Remboursement",
          title: "Ton remboursement est fait",
          intro: d.target === "card"
            ? `${dt(d.amount)} reviennent sur ${esc(d.card)}. Selon ta banque, ça peut prendre 5 à 10 jours ouvrés.`
            : `${dt(d.amount)} sont sur ton solde MatchUp, utilisables tout de suite.`,
          key: keyBlock("Montant remboursé", dt(d.amount), esc(d.label)),
          rows: row("Paiement", esc(d.number)) + row("Remboursé sur", d.target === "card" ? esc(d.card) : "Solde MatchUp"),
          why: "Tu reçois cet email car une demande de remboursement a été traitée. Les emails de paiement sont toujours envoyés.",
        }),
      };
    case "premium_renewed":
      return {
        subject: "Premium est renouvelé",
        html: shell({
          overline: "Abonnement",
          title: "Premium est renouvelé",
          intro: `${dt(d.amount)} prélevés le ${esc(d.date)} sur ${esc(d.card)}.${d.next ? ` Prochain prélèvement le ${esc(d.next)}.` : ""} La facture est en pièce jointe.`,
          rows: row("Facture N°", esc(d.number)) + row("Montant", dt(d.amount)) + row("Carte", esc(d.card)),
          button: "Voir le reçu",
          why: "Tu reçois cet email car tu as un abonnement Premium. Les emails de facturation sont toujours envoyés.",
        }),
      };
    case "premium_failed":
      return {
        subject: `Ton paiement de ${dt(d.amount)} n’est pas passé`,
        html: shell({
          overline: "Abonnement",
          title: `Ton paiement de ${dt(d.amount)} n’est pas passé`,
          intro: `Ta banque a refusé le prélèvement du ${esc(d.date)}. Rien n’a été débité. Mets ta carte à jour${d.deadline ? ` avant le ${esc(d.deadline)}` : ""}.`,
          button: "Mettre à jour ma carte",
          why: "Tu reçois cet email car tu as un abonnement Premium. Les emails de facturation sont toujours envoyés.",
        }),
      };
    case "trial_ending":
      return {
        subject: "Ton essai Premium se termine dans 3 jours",
        html: shell({
          overline: "Abonnement",
          title: "Ton essai Premium se termine dans 3 jours",
          intro: `Ton essai gratuit s’arrête le ${esc(d.date)}. Si tu ne fais rien, Premium continue à ${dt(d.amount)} par mois.`,
          rows: row("Premier prélèvement", `${esc(d.date)} · ${dt(d.amount)}`) + row("Carte", esc(d.card)) + row("Engagement", "Aucun · résiliable à tout moment"),
          button: "Gérer mon abonnement",
          after: `<p style="margin:20px 0 0;font-size:14px;line-height:1.5;color:${C.ink500}"><strong style="color:${C.ink900}">Tu ne veux pas continuer ?</strong> Résilie avant le ${esc(d.date)} : aucun prélèvement, et Premium reste actif jusqu’à cette date.</p>`,
          why: "Tu reçois cet email car tu as un essai Premium en cours. Les emails de facturation sont toujours envoyés.",
        }),
      };
    default:
      return null;
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "POST only" }, 405);

  const user = userOf(req);
  if (!user) return json({ error: "Connexion Supabase requise." }, 401);
  const to = user.email ?? (Deno.env.get("MAIL_TEST_TO") ?? "").trim();
  if (!to) return json({ error: "Pas d’adresse email pour cet utilisateur (et pas de MAIL_TEST_TO)." }, 400);

  const host = Deno.env.get("SMTP_HOST") ?? "smtp.gmail.com";
  const port = Number(Deno.env.get("SMTP_PORT") ?? "465");
  const username = (Deno.env.get("SMTP_USER") ?? "").trim();
  const password = (Deno.env.get("SMTP_PASS") ?? "").replace(/\s+/g, "");
  if (!username || !password) return json({ error: "SMTP_USER et SMTP_PASS manquent dans les secrets." }, 500);

  let body: { template?: string; data?: Data; attachment?: { filename?: string; base64?: string } };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Corps JSON invalide." }, 400);
  }
  const mail = render(body.template ?? "", body.data ?? {});
  if (!mail) return json({ error: "Modèle inconnu." }, 400);

  const pdf = body.attachment?.base64;
  if (pdf && pdf.length > 4_000_000) return json({ error: "Pièce jointe trop lourde." }, 413);

  const client = new SMTPClient({ connection: { hostname: host, port, tls: true, auth: { username, password } } });
  try {
    await client.send({
      from: `MatchUp <${username}>`,
      to,
      subject: mail.subject,
      html: mail.html,
      content: "Ouvre cet email dans une messagerie qui affiche le HTML.",
      attachments: pdf
        ? [{ filename: (body.attachment?.filename ?? "recu.pdf").replace(/[^\w.\-]/g, "_"), content: pdf, encoding: "base64", contentType: "application/pdf" }]
        : [],
    });
    return json({ sent: true });
  } catch (e) {
    return json({ error: `Envoi impossible : ${(e as Error).message}` }, 502);
  } finally {
    await client.close().catch(() => {});
  }
});
