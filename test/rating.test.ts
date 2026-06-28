import { basePremium, ageSurcharge, validateRequest, RatingError, round2 } from "../src/rating";
import { QuoteRequest } from "../src/types";

const baseReq: QuoteRequest = {
    driverAge: 40,
    yearsClaimFree: 0,
    vehicleCategory: "sedan",
    coverageTier: "standard"
};

describe("basePremium", () => {
    it("scales the tier anchor by the vehicle multiplier", () => {
        // standard (950) * sedan (1.0)
        expect(basePremium(baseReq)).toBe(950);
    });

    it("applies the sports loading", () => {
        // premium (1400) * sports (1.6) = 2240
        expect(
            basePremium({ ...baseReq, coverageTier: "premium", vehicleCategory: "sports" })
        ).toBe(2240);
    });

    it("applies the compact discount", () => {
        // basic (600) * compact (0.9) = 540
        expect(basePremium({ ...baseReq, coverageTier: "basic", vehicleCategory: "compact" })).toBe(
            540
        );
    });
});

describe("ageSurcharge", () => {
    it("is zero inside the low-risk band", () => {
        expect(ageSurcharge({ ...baseReq, driverAge: 40 })).toBe(0);
        expect(ageSurcharge({ ...baseReq, driverAge: 25 })).toBe(0);
        expect(ageSurcharge({ ...baseReq, driverAge: 70 })).toBe(0);
    });

    it("loads young drivers proportionally", () => {
        // age 20 -> (25-20)*0.045 = 0.225 ; base 950 -> 213.75
        expect(ageSurcharge({ ...baseReq, driverAge: 20 })).toBe(213.75);
    });

    it("loads the youngest driver the most", () => {
        // age 16 -> (25-16)*0.045 = 0.405 ; base 950 -> 384.75
        expect(ageSurcharge({ ...baseReq, driverAge: 16 })).toBe(384.75);
    });

    it("loads elderly drivers and caps at +30%", () => {
        // age 75 -> 5*0.03 = 0.15 -> 142.5
        expect(ageSurcharge({ ...baseReq, driverAge: 75 })).toBe(142.5);
        // age 90 -> capped at 0.30 -> 285
        expect(ageSurcharge({ ...baseReq, driverAge: 90 })).toBe(285);
    });
});

describe("validateRequest", () => {
    it("accepts a well-formed request", () => {
        expect(() => validateRequest(baseReq)).not.toThrow();
    });

    it.each([15, 101, NaN])("rejects driverAge %p", (driverAge) => {
        expect(() => validateRequest({ ...baseReq, driverAge })).toThrow(RatingError);
    });

    it("rejects negative yearsClaimFree", () => {
        expect(() => validateRequest({ ...baseReq, yearsClaimFree: -1 })).toThrow(RatingError);
    });

    it("rejects negative loyaltyYears when provided", () => {
        expect(() => validateRequest({ ...baseReq, loyaltyYears: -2 })).toThrow(RatingError);
    });

    it("rejects an unknown coverageTier", () => {
        // deliberately bypass the type system to simulate a bad API payload
        const bad = { ...baseReq, coverageTier: "platinum" } as unknown as QuoteRequest;
        expect(() => validateRequest(bad)).toThrow(/coverageTier/);
    });

    it("rejects an unknown vehicleCategory", () => {
        const bad = { ...baseReq, vehicleCategory: "tank" } as unknown as QuoteRequest;
        expect(() => validateRequest(bad)).toThrow(/vehicleCategory/);
    });
});

describe("round2", () => {
    it("rounds to two decimals", () => {
        expect(round2(1.005)).toBe(1.0);
        expect(round2(1.236)).toBe(1.24);
    });
});
