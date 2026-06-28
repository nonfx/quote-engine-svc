import express, { Request, Response } from "express";
import { calculateQuote } from "./quote";
import { RatingError } from "./rating";
import { QuoteRequest } from "./types";

export function createServer() {
    const app = express();
    app.use(express.json());

    app.get("/health", (_req: Request, res: Response) => {
        res.json({ status: "ok" });
    });

    app.post("/quote", (req: Request, res: Response) => {
        try {
            const result = calculateQuote(req.body as QuoteRequest);
            res.json(result);
        } catch (err) {
            if (err instanceof RatingError) {
                res.status(400).json({ error: err.message });
                return;
            }
            res.status(500).json({ error: "internal error" });
        }
    });

    return app;
}

// istanbul ignore next — process bootstrap is exercised by deployment, not unit tests
if (require.main === module) {
    const port = Number(process.env.PORT ?? 3000);
    createServer().listen(port, () => {
        console.log(`quote-engine-svc listening on :${port}`);
    });
}
