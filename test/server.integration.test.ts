import request from "supertest";
import { createServer } from "../src/server";

const app = createServer();

describe("POST /quote (integration)", () => {
    it("returns a 200 with a full quote breakdown", async () => {
        const res = await request(app)
            .post("/quote")
            .send({
                driverAge: 40,
                yearsClaimFree: 5,
                vehicleCategory: "suv",
                coverageTier: "premium",
                loyaltyYears: 6
            })
            .expect(200);

        expect(res.body.basePremium).toBeGreaterThan(0);
        expect(res.body.finalPremium).toBeGreaterThan(0);
        expect(Array.isArray(res.body.lineItems)).toBe(true);
    });

    it("returns 400 on an invalid request", async () => {
        const res = await request(app)
            .post("/quote")
            .send({
                driverAge: 9,
                yearsClaimFree: 0,
                vehicleCategory: "sedan",
                coverageTier: "standard"
            })
            .expect(400);
        expect(res.body.error).toMatch(/driverAge/);
    });

    it("returns 400 on an unknown coverage tier", async () => {
        await request(app)
            .post("/quote")
            .send({
                driverAge: 30,
                yearsClaimFree: 0,
                vehicleCategory: "sedan",
                coverageTier: "platinum"
            })
            .expect(400);
    });
});

describe("GET /health", () => {
    it("reports ok", async () => {
        const res = await request(app).get("/health").expect(200);
        expect(res.body.status).toBe("ok");
    });
});
