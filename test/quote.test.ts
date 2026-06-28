import { calculateQuote, PREMIUM_FLOOR } from "../src/quote";
import { RatingError } from "../src/rating";
import { QuoteRequest } from "../src/types";

const baseReq: QuoteRequest = {
    driverAge: 40,
    yearsClaimFree: 0,
    vehicleCategory: "sedan",
    coverageTier: "standard"
};

describe("calculateQuote", () => {
    it("returns the base premium for a plain request", () => {
        const q = calculateQuote(baseReq);
        expect(q.basePremium).toBe(950);
        expect(q.surcharge).toBe(0);
        expect(q.discount).toBe(0);
        expect(q.finalPremium).toBe(950);
        expect(q.lineItems).toEqual([{ label: "Base premium", amount: 950 }]);
    });

    it("nets surcharge and discounts into the final premium", () => {
        // young driver (age 20, +213.75 surcharge) with 4 claim-free years (-190) and 5 loyalty years (-95)
        const q = calculateQuote({ ...baseReq, driverAge: 20, yearsClaimFree: 4, loyaltyYears: 5 });
        expect(q.surcharge).toBe(213.75);
        expect(q.discount).toBe(285); // 190 + 95
        expect(q.finalPremium).toBe(878.75); // 950 + 213.75 - 285
        expect(q.lineItems).toEqual([
            { label: "Base premium", amount: 950 },
            { label: "Age risk surcharge", amount: 213.75 },
            { label: "No-claims discount", amount: -190 },
            { label: "Loyalty discount", amount: -95 }
        ]);
    });

    it("stays at or above the regulatory floor under the deepest discount", () => {
        // Cheapest base (basic/compact = 540) with both discounts maxed:
        // no-claims caps at 50% (270) + loyalty 10% (54) -> gross 216, which is still
        // above the 200 floor. So the floor does not fire, but the result is guarded.
        const q = calculateQuote({
            ...baseReq,
            coverageTier: "basic",
            vehicleCategory: "compact",
            yearsClaimFree: 30,
            loyaltyYears: 10
        });
        expect(q.finalPremium).toBe(216);
        expect(q.finalPremium).toBeGreaterThanOrEqual(PREMIUM_FLOOR);
    });

    it("propagates validation errors", () => {
        expect(() => calculateQuote({ ...baseReq, driverAge: 5 })).toThrow(RatingError);
    });
});
