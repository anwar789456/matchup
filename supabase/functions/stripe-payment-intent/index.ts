// Supabase Edge Function: creates a Stripe PaymentIntent for the app's checkout (test mode).
// The secret key never leaves the server: set it once with
//   Supabase › Edge Functions › Secrets › STRIPE_SECRET_KEY = sk_test_…
// Optional secrets: STRIPE_CURRENCY (default "eur"), TND_PER_UNIT (default 3.4 DT for 1 EUR).
// Stripe does not take Tunisian dinars, so the DT amount is converted for the charge; the app
// keeps the DT amount on its receipt.
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
    return payload.sub ?? null;
  } catch {
    return null;
  }
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
  const stripe = new Stripe(secret);
  const currency = Deno.env.get("STRIPE_CURRENCY") ?? "eur";
  const rate = Number(Deno.env.get("TND_PER_UNIT") ?? "3.4");

  let body: { amount?: number; description?: string; reference?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Corps JSON invalide." }, 400);
  }
  const amount = Number(body.amount);
  if (!(amount > 0) || amount > 5000) return json({ error: "Montant invalide (0 à 5000 DT)." }, 400);

  // Smallest unit (cents), at least Stripe's minimum of 0,50.
  const minor = Math.max(50, Math.round((amount / rate) * 100));
  try {
    const intent = await stripe.paymentIntents.create({
      amount: minor,
      currency,
      payment_method_types: ["card"],
      description: (body.description ?? "MatchUp").slice(0, 200),
      metadata: {
        montant_dt: String(amount),
        reference: body.reference ?? "",
        supabase_user: userId(req) ?? "",
      },
    });
    return json({ id: intent.id, clientSecret: intent.client_secret, amount: minor / 100, currency });
  } catch (e) {
    return json({ error: (e as Error).message }, 502);
  }
});
