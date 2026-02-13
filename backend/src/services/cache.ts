/**
 * Game Session Store — persists game state in KV
 * Workers are stateless, so we need KV for session continuity
 */

import type { GameSession, ScreenshotAnalysis } from "../types/game";

const SESSION_TTL = 86400; // 24h

export async function getSession(
  kv: KVNamespace,
  sessionId: string
): Promise<GameSession | null> {
  return kv.get<GameSession>(`session:${sessionId}`, "json");
}

export async function saveSession(
  kv: KVNamespace,
  session: GameSession
): Promise<void> {
  await kv.put(`session:${session.id}`, JSON.stringify(session), {
    expirationTtl: SESSION_TTL,
  });
}

/**
 * Add an analysis to an existing session.
 *
 * NOTE: This is a get-then-put operation and is NOT atomic.
 * Cloudflare KV does not support CAS/transactions. If two requests
 * call addAnalysis concurrently for the same session, one analysis
 * may be lost (last-write-wins). This is acceptable for this use case
 * because a single user sends screenshots sequentially from their phone,
 * but we add a deduplication check as a safety net.
 */
export async function addAnalysis(
  kv: KVNamespace,
  sessionId: string,
  analysis: ScreenshotAnalysis
): Promise<GameSession | null> {
  const session = await getSession(kv, sessionId);
  if (!session) return null;

  // Deduplicate: skip if an analysis with the same id already exists
  if (session.analyses.some((a) => a.id === analysis.id)) {
    return session;
  }

  session.analyses.push(analysis);
  await saveSession(kv, session);
  return session;
}

export async function getUserSessions(
  kv: KVNamespace,
  riotId: string
): Promise<string[]> {
  const key = `user_sessions:${riotId}`;
  const ids = await kv.get<string[]>(key, "json");
  return ids ?? [];
}

export async function addUserSession(
  kv: KVNamespace,
  riotId: string,
  sessionId: string
): Promise<void> {
  const key = `user_sessions:${riotId}`;
  const ids = (await kv.get<string[]>(key, "json")) ?? [];
  // Deduplicate: don't add the same session twice
  if (!ids.includes(sessionId)) {
    ids.unshift(sessionId);
  }
  // Keep last 50 sessions
  if (ids.length > 50) ids.length = 50;
  await kv.put(key, JSON.stringify(ids), { expirationTtl: 30 * 86400 });
}
