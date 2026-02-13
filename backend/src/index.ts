import { Hono } from "hono";
import { cors } from "hono/cors";
import type { Env } from "./types/env";
import game from "./routes/game";

const app = new Hono<{ Bindings: Env }>();

// CORS for iOS app
app.use("*", cors({ origin: "*" }));

// Health check
app.get("/health", (c) => {
  return c.json({
    status: "ok",
    version: "0.1.0",
    timestamp: new Date().toISOString(),
  });
});

// Game routes (the core MVP)
app.route("/game", game);

// 404 fallback
app.notFound((c) => {
  return c.json({ error: "Not found" }, 404);
});

// Error handler
app.onError((err, c) => {
  console.error("Unhandled error:", err);
  return c.json({ error: "Internal server error" }, 500);
});

export default app;
