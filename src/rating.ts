import { CoverageTier, QuoteRequest, VehicleCategory } from "./types";

/**
 * Base annual premium by coverage tier, in whole currency units.
 * These are the actuarial anchors; everything else is a multiplier or delta on top.
 */
const TIER_BASE: Record<CoverageTier, number> = {
    basic: 600,
    standard: 950,
    premium: 1400
};

/**
 * Risk multiplier by vehicle category. Sports cars carry a materially higher
 * loss ratio, hence the steepest loading.
 */
const CATEGORY_MULTIPLIER: Record<VehicleCategory, number> = {
    compact: 0.9,
    sedan: 1.0,
    suv: 1.15,
    sports: 1.6
};

const MIN_DRIVER_AGE = 16;
const MAX_DRIVER_AGE = 100;

export class RatingError extends Error {}

/**
 * Validate a request up-front so downstream maths never sees a nonsensical input.
 * Throwing here (rather than clamping) keeps the API contract honest: a bad
 * request is a 400, not a silently-adjusted quote.
 */
export function validateRequest(req: QuoteRequest): void {
    if (
        !Number.isFinite(req.driverAge) ||
        req.driverAge < MIN_DRIVER_AGE ||
        req.driverAge > MAX_DRIVER_AGE
    ) {
        throw new RatingError(`driverAge must be between ${MIN_DRIVER_AGE} and ${MAX_DRIVER_AGE}`);
    }
    if (!Number.isFinite(req.yearsClaimFree) || req.yearsClaimFree < 0) {
        throw new RatingError("yearsClaimFree must be a non-negative number");
    }
    if (req.loyaltyYears != null && (!Number.isFinite(req.loyaltyYears) || req.loyaltyYears < 0)) {
        throw new RatingError("loyaltyYears must be a non-negative number when provided");
    }
    if (!(req.coverageTier in TIER_BASE)) {
        throw new RatingError(`unknown coverageTier: ${req.coverageTier}`);
    }
    if (!(req.vehicleCategory in CATEGORY_MULTIPLIER)) {
        throw new RatingError(`unknown vehicleCategory: ${req.vehicleCategory}`);
    }
}

/** Base premium = tier anchor scaled by the vehicle-category risk multiplier. */
export function basePremium(req: QuoteRequest): number {
    return round2(TIER_BASE[req.coverageTier] * CATEGORY_MULTIPLIER[req.vehicleCategory]);
}

/**
 * Age-based surcharge. Young drivers (< 25) and elderly drivers (> 70) are
 * statistically higher-risk, so each gets a loading proportional to how far
 * outside the low-risk band they sit.
 */
export function ageSurcharge(req: QuoteRequest): number {
    const base = basePremium(req);
    if (req.driverAge < 25) {
        // Up to +40% at age 16, tapering to 0 at 25.
        const factor = (25 - req.driverAge) * 0.045;
        return round2(base * factor);
    }
    if (req.driverAge > 70) {
        // +3% per year over 70, capped at +30%.
        const factor = Math.min((req.driverAge - 70) * 0.03, 0.3);
        return round2(base * factor);
    }
    return 0;
}

export function round2(n: number): number {
    return Math.round(n * 100) / 100;
}
