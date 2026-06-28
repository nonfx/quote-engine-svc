/**
 * Shared domain types for the insurance quote engine.
 *
 * Coverage tiers map to fixed multipliers in rating.ts; keeping them as a
 * string union (not free text) is what lets the rating table be exhaustive.
 */
export type CoverageTier = "basic" | "standard" | "premium";

export type VehicleCategory = "compact" | "sedan" | "suv" | "sports";

export interface QuoteRequest {
    /** Driver age in whole years. */
    driverAge: number;
    /** Years the driver has held a licence with no at-fault claim. */
    yearsClaimFree: number;
    vehicleCategory: VehicleCategory;
    coverageTier: CoverageTier;
    /** Loyalty membership length in whole years; 0 for new customers. */
    loyaltyYears?: number;
}

export interface QuoteResult {
    basePremium: number;
    /** Sum of all applied surcharges (risk loadings). */
    surcharge: number;
    /** Sum of all applied discounts, as a positive number. */
    discount: number;
    /** Final premium, never below the regulatory floor. */
    finalPremium: number;
    /** Human-readable breakdown of every adjustment, for audit/explainability. */
    lineItems: QuoteLineItem[];
}

export interface QuoteLineItem {
    label: string;
    amount: number;
}
