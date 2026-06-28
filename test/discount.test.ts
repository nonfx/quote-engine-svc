import { noClaimsDiscount, loyaltyDiscount, loyaltyDiscountRate } from "../src/discount";
import { QuoteRequest } from "../src/types";

const baseReq: QuoteRequest = {
    driverAge: 40,
    yearsClaimFree: 0,
    vehicleCategory: "sedan",
    coverageTier: "standard"
};

describe("noClaimsDiscount", () => {
    it("is zero with no claim-free history", () => {
        expect(noClaimsDiscount(baseReq)).toBe(0);
    });

    it("gives 5% per claim-free year", () => {
        // 4 years -> 20% of 950 = 190
        expect(noClaimsDiscount({ ...baseReq, yearsClaimFree: 4 })).toBe(190);
    });

    it("caps at 50%", () => {
        // 20 years would be 100% but is capped at 50% of 950 = 475
        expect(noClaimsDiscount({ ...baseReq, yearsClaimFree: 20 })).toBe(475);
    });
});

describe("loyaltyDiscountRate", () => {
    it.each([
        [0, 0],
        [1, 0.03],
        [2, 0.03],
        [3, 0.06],
        [4, 0.06],
        [5, 0.1],
        [9, 0.1],
        [10, 0.15],
        [12, 0.15]
    ])("years=%i -> rate=%f", (years, rate) => {
        expect(loyaltyDiscountRate(years)).toBe(rate);
    });
});

describe("loyaltyDiscount", () => {
    it("is zero for a new customer (undefined loyaltyYears)", () => {
        expect(loyaltyDiscount(baseReq)).toBe(0);
    });

    it("applies the 1-year bracket", () => {
        // 3% of 950 = 28.5
        expect(loyaltyDiscount({ ...baseReq, loyaltyYears: 2 })).toBe(28.5);
    });

    it("applies the 5-year bracket", () => {
        // 10% of 950 = 95
        expect(loyaltyDiscount({ ...baseReq, loyaltyYears: 7 })).toBe(95);
    });

    it("applies the 10-year long-tenure bracket", () => {
        // 15% of 950 = 142.5
        expect(loyaltyDiscount({ ...baseReq, loyaltyYears: 11 })).toBe(142.5);
    });
});
