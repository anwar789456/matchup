// Supabase Edge Function: Stripe for the app's checkout (test mode). The secret key never leaves
// the server: Supabase › Edge Functions › Secrets › STRIPE_SECRET_KEY = sk_test_…
// Optional secrets: STRIPE_CURRENCY (default "eur"), TND_PER_UNIT (default 3.4 DT for 1 EUR).
// Stripe does not take Tunisian dinars: the DT amount is converted for the charge, the app keeps
// the DT amount on its receipt.
//
// POST body { action, … } (signed-in Supabase user required):
//   "payment" (default) { amount, description, reference, save?, paymentMethodId? }
//       → { id, clientSecret }   a PaymentIntent on the user's Stripe customer; `save` keeps the
//                                card for later, `paymentMethodId` pays with a saved card.
//   "setup"   {}                 → { id, clientSecret }   saves a card without charging (Premium trial).
//   "card"    { paymentMethodId } → { id, brand, last4, expMonth, expYear }   a saved card of this user.
import Stripe from "npm:stripe@17.7.0";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

/** The signed-in Supabase user (the gateway already checked the token). */
function userId(req: Request): string | null {
  try {
    const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
    const payload = JSON.parse(atob(token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")));
    return payload.role === "authenticated" ? payload.sub ?? null : null;
  } catch {
    return null;
  }
}

/** The user's Stripe customer, created on first use. */
async function customerOf(stripe: Stripe, user: string): Promise<string> {
  const found = await stripe.customers.search({ query: `metadata['supabase_user']:'${user}'`, limit: 1 });
  if (found.data[0]) return found.data[0].id;
  const created = await stripe.customers.create({ metadata: { supabase_user: user }, description: "MatchUp" });
  return created.id;
}

/** A saved card, only if it belongs to this user. */
async function cardOf(stripe: Stripe, user: string, id: string) {
  const pm = await stripe.paymentMethods.retrieve(id, { expand: ["customer"] });
  const customer = pm.customer as Stripe.Customer | null;
  if (!customer || customer.deleted || customer.metadata?.supabase_user !== user) throw new Error("Carte inconnue.");
  return { pm, customer: customer.id };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "POST only" }, 405);

  const secret = (Deno.env.get("STRIPE_SECRET_KEY") ?? "").trim();
  if (!/^(sk|rk)_test_/.test(secret)) {
    // Only the kind of key is reported (« pk_test », « sk_live »…), never the key itself.
    const kind = /^(sk|rk|pk)_(test|live)_/.exec(secret)?.[0].slice(0, -1) ?? (secret ? "inconnue" : "vide");
    return json({ error: `STRIPE_SECRET_KEY doit être une clé secrète de test (sk_test_…) ; reçu : ${kind}.` }, 500);
  }
  const user = userId(req);
  if (!user) return json({ error: "Connexion Supabase requise." }, 401);
  const stripe = new Stripe(secret);

  let body: { action?: string; amount?: number; description?: string; reference?: string; save?: boolean; paymentMethodId?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Corps JSON invalide." }, 400);
  }

  try {
    switch (body.action ?? "payment") {
      case "payment": {
        const amount = Number(body.amount);
        if (!(amount > 0) || amount > 5000) return json({ error: "Montant invalide (0 à 5000 DT)." }, 400);
        const currency = Deno.env.get("STRIPE_CURRENCY") ?? "eur";
        const rate = Number(Deno.env.get("TND_PER_UNIT") ?? "3.4");
        const saved = body.paymentMethodId ? await cardOf(stripe, user, body.paymentMethodId) : null;
        const intent = await stripe.paymentIntents.create({
          // Smallest unit (cents), at least Stripe's minimum of 0,50.
          amount: Math.max(50, Math.round((amount / rate) * 100)),
          currency,
          customer: saved?.customer ?? (await customerOf(stripe, user)),
          payment_method_types: ["card"],
          ...(saved ? { payment_method: saved.pm.id } : {}),
          ...(body.save && !saved ? { setup_future_usage: "off_session" as const } : {}),
          description: (body.description ?? "MatchUp").slice(0, 200),
          metadata: { montant_dt: String(amount), reference: body.reference ?? "", supabase_user: user },
        });
        return json({ id: intent.id, clientSecret: intent.client_secret });
      }
      case "setup": {
        const intent = await stripe.setupIntents.create({
          customer: await customerOf(stripe, user),
          payment_method_types: ["card"],
          usage: "off_session",
          metadata: { supabase_user: user },
        });
        return json({ id: intent.id, clientSecret: intent.client_secret });
      }
      case "card": {
        const { pm } = await cardOf(stripe, user, body.paymentMethodId ?? "");
        return json({
          id: pm.id,
          brand: pm.card?.brand,
          last4: pm.card?.last4,
          expMonth: pm.card?.exp_month,
          expYear: pm.card?.exp_year,
        });
      }
      default:
        return json({ error: "Action inconnue." }, 400);
    }
  } catch (e) {
    return json({ error: (e as Error).message }, 502);
  }
});
