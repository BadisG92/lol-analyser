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

export async function addAnalysis(
  kv: KVNamespace,
  sessionId: string,
  analysis: ScreenshotAnalysis
): Promise<GameSession | null> {
  const session = await getSession(kv, sessionId);
  if (!session) return null;

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
  ids.unshift(sessionId);
  // Keep last 50 sessions
  if (ids.length > 50) ids.length = 50;
  await kv.put(key, JSON.stringify(ids), { expirationTtl: 30 * 86400 });
}
