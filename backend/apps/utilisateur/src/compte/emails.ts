import { MailMessage } from '@app/common';

// MatchUp brand: navy ink #0b1b33, Volt #c6f135 (fill only, navy text on it), ink-50 #f5f7fa.
function layout(title: string, body: string): string {
  return `<!doctype html><html lang="fr"><body style="margin:0;background:#f5f7fa;font-family:'Plus Jakarta Sans',Arial,sans-serif;color:#0b1b33">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f5f7fa;padding:32px 16px">
<tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;background:#ffffff;border-radius:16px;overflow:hidden">
<tr><td style="background:#0b1b33;padding:20px 28px;font-size:22px;font-weight:800;color:#ffffff;letter-spacing:.2px">Match<span style="color:#c6f135">Up</span></td></tr>
<tr><td style="padding:28px">
<h1 style="margin:0 0 12px;font-size:22px;line-height:1.25">${title}</h1>
${body}
</td></tr>
<tr><td style="padding:16px 28px 24px;font-size:12px;color:#5b6b82;border-top:1px solid #e6ebf2">Tu reçois cet email parce qu’un compte MatchUp utilise cette adresse. Si ce n’est pas toi, ignore-le.</td></tr>
</table></td></tr></table></body></html>`;
}

/** AUTH-04: « On a envoyé un lien de confirmation à … ». */
export function verificationEmail(to: string, link: string): MailMessage {
  return {
    to,
    subject: 'Confirme ton adresse email',
    text: `Bienvenue sur MatchUp !\n\nConfirme ton adresse email en ouvrant ce lien (valable 24 h) :\n${link}\n`,
    html: layout(
      'Confirme ton adresse email',
      `<p style="margin:0 0 20px;font-size:15px;line-height:1.6;color:#24324a">Bienvenue sur MatchUp ! Un clic pour confirmer ton adresse et sécuriser ton compte.</p>
<a href="${link}" style="display:inline-block;background:#c6f135;color:#0b1b33;text-decoration:none;font-weight:700;font-size:15px;padding:14px 22px;border-radius:12px">Confirmer mon email</a>
<p style="margin:20px 0 0;font-size:13px;color:#5b6b82">Le lien est valable 24 h. S’il ne s’ouvre pas, copie cette adresse :<br><span style="word-break:break-all">${link}</span></p>`,
    ),
  };
}

/** AUTH-06/07: the 6-digit reset code. */
export function resetCodeEmail(to: string, code: string): MailMessage {
  return {
    to,
    subject: `${code} est ton code MatchUp`,
    text: `Ton code pour choisir un nouveau mot de passe : ${code}\nIl est valable 15 minutes.\n`,
    html: layout(
      'Ton code de réinitialisation',
      `<p style="margin:0 0 16px;font-size:15px;line-height:1.6;color:#24324a">Saisis ce code dans l’app pour choisir un nouveau mot de passe.</p>
<p style="margin:0 0 16px;font-size:34px;font-weight:800;letter-spacing:10px;font-family:'Barlow Condensed',Arial,sans-serif">${code}</p>
<p style="margin:0;font-size:13px;color:#5b6b82">Il est valable 15 minutes.</p>`,
    ),
  };
}

/** The page the confirmation link opens. */
export function confirmationPage(ok: boolean): string {
  const [title, text] = ok
    ? ['Ton email est confirmé', 'Tu peux retourner dans l’app MatchUp.']
    : ['Ce lien n’est plus valable', 'Il a expiré ou a déjà servi. Depuis l’app, demande un nouvel email de confirmation.'];
  return `<!doctype html><html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>MatchUp · ${title}</title></head>
<body style="margin:0;min-height:100vh;display:grid;place-items:center;background:#0b1b33;font-family:'Plus Jakarta Sans',Arial,sans-serif;color:#f5f7fa;padding:16px">
<div style="max-width:420px;text-align:center"><div style="font-size:26px;font-weight:800;margin-bottom:24px">Match<span style="color:#c6f135">Up</span></div>
<h1 style="font-size:26px;margin:0 0 10px">${title}</h1><p style="margin:0;color:#a9b4c4;line-height:1.6">${text}</p></div></body></html>`;
}
