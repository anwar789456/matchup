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
//   "refund"  { paymentIntentId, amount? } → { id, status }   refunds a payment of this user (DT).
// Premium on a Stripe Subscription (Stripe charges the card at the end of the trial, then every
// period, and keeps an invoice each time):
//   "subscribe" { period: "month"|"year", paymentMethodId, amount } → subscription
//   "subscription" {}               → subscription (status, dates, invoices) or null
//   "change"  { period, amount }     · "cancel" {} · "resume" {} · "discount" {}  (−30 % for 2 months)
//   "end_trial" {}                   ends the trial now: Stripe charges at once (test only).
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

const currency = () => Deno.env.get("STRIPE_CURRENCY") ?? "eur";
const rate = () => Number(Deno.env.get("TND_PER_UNIT") ?? "3.4");

/** A Premium invoice's payment has no metadata of ours: it is the user's through their customer. */
async function isOwnersInvoice(stripe: Stripe, pi: Stripe.PaymentIntent, user: string): Promise<boolean> {
  if (typeof pi.customer !== "string") return false;
  const customer = await stripe.customers.retrieve(pi.customer);
  return !customer.deleted && customer.metadata?.supabase_user === user;
}

/** −30 % for 2 months (the retention offer of SUB-07), created on first use. */
async function retentionCoupon(stripe: Stripe): Promise<string> {
  const id = "matchup-retention-30";
  try {
    return (await stripe.coupons.retrieve(id)).id;
  } catch {
    return (await stripe.coupons.create({ id, percent_off: 30, duration: "repeating", duration_in_months: 2, name: "MatchUp −30 % · 2 mois" })).id;
  }
}

const PREMIUM = { app: "matchup", plan: "joueur_premium" };

/** The « MatchUp Premium » product, created on first use. */
async function premiumProduct(stripe: Stripe): Promise<string> {
  const found = await stripe.products.search({ query: "metadata['app']:'matchup' AND metadata['plan']:'joueur_premium'", limit: 1 });
  if (found.data[0]) return found.data[0].id;
  return (await stripe.products.create({ name: "MatchUp Premium", metadata: PREMIUM })).id;
}

/** The user's live Premium subscription (not ended), if any. */
async function premiumOf(stripe: Stripe, customer: string): Promise<Stripe.Subscription | null> {
  const subs = await stripe.subscriptions.list({ customer, status: "all", limit: 20 });
  return subs.data.find((s) => s.metadata?.app === "matchup" && !["canceled", "incomplete_expired"].includes(s.status)) ?? null;
}

const toMinor = (dt: number, rate: number) => Math.max(50, Math.round((dt / rate) * 100));

/** What the app shows: status, dates, and the paid invoices in DT. */
async function view(stripe: Stripe, sub: Stripe.Subscription | null) {
  if (!sub) return null;
  const montant = Number(sub.metadata?.montant_dt ?? "0");
  const full = Number(sub.metadata?.montant_minor ?? "0");
  const invoices = await stripe.invoices.list({ subscription: sub.id, limit: 24, expand: ["data.payment_intent.payment_method"] });
  return {
    id: sub.id,
    status: sub.status, // trialing, active, past_due, canceled…
    period: sub.items.data[0]?.price.recurring?.interval ?? "month",
    trialEnd: sub.trial_end ? new Date(sub.trial_end * 1000).toISOString() : null,
    currentPeriodEnd: new Date(sub.current_period_end * 1000).toISOString(),
    cancelAtPeriodEnd: sub.cancel_at_period_end,
    discount: sub.discount ? true : false,
    invoices: invoices.data
      .filter((i) => i.status === "paid" && i.amount_paid > 0)
      .map((i) => {
        const pi = i.payment_intent as Stripe.PaymentIntent | null;
        const pm = pi?.payment_method as Stripe.PaymentMethod | null;
        return {
          number: i.number,
          paidAt: new Date((i.status_transitions.paid_at ?? i.created) * 1000).toISOString(),
          // Back to DT from the price we charged (the rate is the one used at subscription).
          amount: full > 0 ? Math.round((montant * i.amount_paid * 1000) / full) / 1000 : i.amount_paid / 100,
          paymentIntentId: pi?.id ?? null,
          brand: pm?.card?.brand ?? null,
          last4: pm?.card?.last4 ?? null,
          pdf: i.invoice_pdf,
        };
      }),
  };
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

  let body: {
    action?: string;
    amount?: number;
    description?: string;
    reference?: string;
    save?: boolean;
    paymentMethodId?: string;
    paymentIntentId?: string;
    period?: string;
  };
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
        const saved = body.paymentMethodId ? await cardOf(stripe, user, body.paymentMethodId) : null;
        const intent = await stripe.paymentIntents.create({
          // Smallest unit (cents), at least Stripe's minimum of 0,50.
          amount: toMinor(amount, rate()),
          currency: currency(),
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
      case "refund": {
        const pi = await stripe.paymentIntents.retrieve(body.paymentIntentId ?? "");
        if (pi.metadata?.supabase_user !== user && !(await isOwnersInvoice(stripe, pi, user))) {
          return json({ error: "Paiement inconnu." }, 404);
        }
        const montant = Number(pi.metadata?.montant_dt ?? "0");
        // A part of the payment: the same share of what Stripe charged.
        const part = body.amount && montant > 0 ? Math.min(pi.amount_received, Math.round((pi.amount_received * body.amount) / montant)) : undefined;
        const refund = await stripe.refunds.create({ payment_intent: pi.id, ...(part ? { amount: part } : {}), metadata: { supabase_user: user } });
        return json({ id: refund.id, status: refund.status });
      }
      case "subscribe": {
        const customer = await customerOf(stripe, user);
        const existing = await premiumOf(stripe, customer);
        if (existing) return json(await view(stripe, existing));
        const { pm } = await cardOf(stripe, user, body.paymentMethodId ?? "");
        const amount = Number(body.amount);
        if (!(amount > 0)) return json({ error: "Montant invalide." }, 400);
        const interval = body.period === "year" ? "year" : "month";
        const minor = toMinor(amount, rate());
        await stripe.customers.update(customer, { invoice_settings: { default_payment_method: pm.id } });
        const sub = await stripe.subscriptions.create({
          customer,
          items: [{ price_data: { currency: currency(), product: await premiumProduct(stripe), unit_amount: minor, recurring: { interval } } }],
          trial_period_days: 14,
          default_payment_method: pm.id,
          metadata: { ...PREMIUM, supabase_user: user, montant_dt: String(amount), montant_minor: String(minor) },
        });
        return json(await view(stripe, sub));
      }
      case "subscription": {
        const customer = await customerOf(stripe, user);
        const live = await premiumOf(stripe, customer);
        if (live) return json(await view(stripe, live));
        // The last ended one still has the invoices.
        const all = await stripe.subscriptions.list({ customer, status: "all", limit: 1 });
        return json(all.data[0]?.metadata?.app === "matchup" ? await view(stripe, all.data[0]) : null);
      }
      case "change":
      case "cancel":
      case "resume":
      case "discount":
      case "end_trial": {
        const sub = await premiumOf(stripe, await customerOf(stripe, user));
        if (!sub) return json({ error: "Pas d’abonnement Premium." }, 404);
        let next: Stripe.Subscription;
        if (body.action === "change") {
          const amount = Number(body.amount);
          const minor = toMinor(amount, rate());
          next = await stripe.subscriptions.update(sub.id, {
            items: [{
              id: sub.items.data[0].id,
              price_data: { currency: currency(), product: await premiumProduct(stripe), unit_amount: minor, recurring: { interval: body.period === "year" ? "year" : "month" } },
            }],
            proration_behavior: sub.status === "trialing" ? "none" : "create_prorations",
            metadata: { montant_dt: String(amount), montant_minor: String(minor) },
          });
        } else if (body.action === "cancel") {
          next = await stripe.subscriptions.update(sub.id, { cancel_at_period_end: true });
        } else if (body.action === "resume") {
          next = await stripe.subscriptions.update(sub.id, { cancel_at_period_end: false });
        } else if (body.action === "discount") {
          next = await stripe.subscriptions.update(sub.id, { coupon: await retentionCoupon(stripe) });
        } else {
          next = await stripe.subscriptions.update(sub.id, { trial_end: "now", proration_behavior: "none" });
        }
        return json(await view(stripe, next));
      }
      default:
        return json({ error: "Action inconnue." }, 400);
    }
  } catch (e) {
    return json({ error: (e as Error).message }, 502);
  }
});
