import { noClaimsDiscount, loyaltyDiscount } from "./discount";
import { basePremium, ageSurcharge, validateRequest, round2 } from "./rating";
import { QuoteRequest, QuoteResult, QuoteLineItem } from "./types";

/**
 * Regulatory minimum premium. Discounts may stack, but the final figure can
 * never fall below this floor — the insurer cannot write a policy for free.
 */
export const PREMIUM_FLOOR = 200;

/**
 * Compose a full quote from the independent rating + discount modules.
 * The line-item list is the audit trail: every surcharge and discount that
 * moved the number is named, so a quote can be explained after the fact.
 */
export function calculateQuote(req: QuoteRequest): QuoteResult {
    validateRequest(req);

    const base = basePremium(req);
    const age = ageSurcharge(req);
    const noClaims = noClaimsDiscount(req);
    const loyalty = loyaltyDiscount(req);

    const surcharge = round2(age);
    const discount = round2(noClaims + loyalty);
    const gross = round2(base + surcharge - discount);
    const finalPremium = Math.max(gross, PREMIUM_FLOOR);

    const lineItems: QuoteLineItem[] = [{ label: "Base premium", amount: base }];
    if (age > 0) lineItems.push({ label: "Age risk surcharge", amount: age });
    if (noClaims > 0) lineItems.push({ label: "No-claims discount", amount: -noClaims });
    if (loyalty > 0) lineItems.push({ label: "Loyalty discount", amount: -loyalty });
    if (finalPremium !== gross) {
        lineItems.push({
            label: "Regulatory floor adjustment",
            amount: round2(finalPremium - gross)
        });
    }

    return { basePremium: base, surcharge, discount, finalPremium, lineItems };
}
