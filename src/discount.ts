import { basePremium, round2 } from "./rating";
import { QuoteRequest } from "./types";

/**
 * No-claims discount. Rewards a clean record at 5% per claim-free year,
 * capped at 50% so the discount can never wholly erase the premium.
 */
export function noClaimsDiscount(req: QuoteRequest): number {
    const rate = Math.min(req.yearsClaimFree * 0.05, 0.5);
    return round2(basePremium(req) * rate);
}

/**
 * Multi-tier loyalty bonus (added by the loyalty-discount feature).
 * Brackets, not linear: the value of retention steps up at the 3-, 5- and
 * 10-year marks rather than accruing smoothly, matching how the retention
 * team models it. The 10-year "long-tenure" bracket rewards the customers
 * with the lowest churn risk and the lowest claims frequency.
 */
export function loyaltyDiscountRate(loyaltyYears: number): number {
    if (loyaltyYears >= 10) return 0.15;
    if (loyaltyYears >= 5) return 0.1;
    if (loyaltyYears >= 3) return 0.06;
    if (loyaltyYears >= 1) return 0.03;
    return 0;
}

export function loyaltyDiscount(req: QuoteRequest): number {
    const years = req.loyaltyYears ?? 0;
    return round2(basePremium(req) * loyaltyDiscountRate(years));
}
