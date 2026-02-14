/**
 * OP.GG MCP Client
 *
 * The OP.GG MCP server uses JSON-RPC 2.0 over StreamableHTTP.
 * Flow: initialize → send tool calls → receive results
 */

const OPGG_MCP_URL = "https://mcp-api.op.gg/mcp";

interface MCPToolResult {
  content: Array<{ type: string; text?: string }>;
}

interface MCPResponse {
  jsonrpc: "2.0";
  id: number;
  result?: unknown;
  error?: { code: number; message: string };
}

class OPGGClient {
  private requestId = 0;
  private sessionId: string | null = null;

  private nextId(): number {
    return ++this.requestId;
  }

  private async rpc(method: string, params: Record<string, unknown>): Promise<unknown> {
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };
    if (this.sessionId) {
      headers["mcp-session-id"] = this.sessionId;
    }

    const body = JSON.stringify({
      jsonrpc: "2.0",
      id: this.nextId(),
      method,
      params,
    });

    const resp = await fetch(OPGG_MCP_URL, { method: "POST", headers, body });

    // Capture session ID from response
    const sid = resp.headers.get("mcp-session-id");
    if (sid) this.sessionId = sid;

    if (!resp.ok) {
      throw new Error(`OP.GG MCP error: ${resp.status} ${resp.statusText}`);
    }

    const text = await resp.text();

    // MCP can return multiple JSON-RPC messages (notifications + result)
    // We need to find the one matching our request
    const lines = text.split("\n").filter((l) => l.trim());
    for (const line of lines) {
      try {
        const parsed = JSON.parse(line) as MCPResponse;
        if (parsed.result !== undefined) return parsed.result;
        if (parsed.error) throw new Error(parsed.error.message);
      } catch {
        // Some lines may not be JSON (SSE data: prefix etc.)
        const jsonMatch = line.match(/^data:\s*(.+)/);
        if (jsonMatch) {
          const parsed = JSON.parse(jsonMatch[1]) as MCPResponse;
          if (parsed.result !== undefined) return parsed.result;
          if (parsed.error) throw new Error(parsed.error.message);
        }
      }
    }

    // Try parsing the entire response as a single JSON object
    const single = JSON.parse(text) as MCPResponse;
    if (single.result !== undefined) return single.result;
    if (single.error) throw new Error(single.error.message);

    throw new Error("No result in MCP response");
  }

  async initialize(): Promise<void> {
    await this.rpc("initialize", {
      protocolVersion: "2025-03-26",
      capabilities: {},
      clientInfo: { name: "lol-coach", version: "0.1.0" },
    });
  }

  async callTool(name: string, args: Record<string, unknown>): Promise<string> {
    const result = (await this.rpc("tools/call", {
      name,
      arguments: args,
    })) as MCPToolResult;

    return result.content
      .filter((c) => c.type === "text" && c.text)
      .map((c) => c.text!)
      .join("\n");
  }
}

// ── Public API ──

export interface SummonerData {
  raw: string;
  rank: string;
  winRate: number;
  gamesPlayed: number;
}

export interface ChampionBuild {
  raw: string;
}

export interface ChampionMeta {
  raw: string;
}

export async function fetchSummonerData(
  summonerName: string,
  region: string
): Promise<SummonerData> {
  const client = new OPGGClient();
  try {
    await client.initialize();
    const raw = await client.callTool("lol-summoner-search", {
      summoner_name: summonerName,
      region: mapRegion(region),
    });

    // Parse rank/winrate from the raw text response
    const rank = extractField(raw, "rank", "tier") ?? "Unranked";
    const winRate = parseFloat(extractField(raw, "win_rate", "winRate") ?? "50") || 50;
    const gamesPlayed = parseInt(extractField(raw, "games", "total_games") ?? "0", 10) || 0;

    return { raw, rank, winRate, gamesPlayed };
  } catch (e) {
    console.error(`Failed to fetch summoner ${summonerName}:`, e);
    return {
      raw: `Error fetching ${summonerName}: ${e}`,
      rank: "Unknown",
      winRate: 50,
      gamesPlayed: 0,
    };
  }
}

export async function fetchGameHistory(
  summonerName: string,
  region: string
): Promise<string> {
  const client = new OPGGClient();
  try {
    await client.initialize();
    return await client.callTool("lol-summoner-game-history", {
      summoner_name: summonerName,
      region: mapRegion(region),
    });
  } catch (e) {
    console.error(`Failed to fetch history for ${summonerName}:`, e);
    return `Error: ${e}`;
  }
}

export async function fetchChampionAnalysis(
  championName: string,
  role: string,
  region: string
): Promise<ChampionBuild> {
  const client = new OPGGClient();
  try {
    await client.initialize();
    const raw = await client.callTool("lol-champion-analysis", {
      champion_name: championName,
      position: role,
      region: mapRegion(region),
    });
    return { raw };
  } catch (e) {
    console.error(`Failed to fetch champion analysis for ${championName}:`, e);
    return { raw: `Error: ${e}` };
  }
}

export async function fetchChampionMeta(region: string): Promise<ChampionMeta> {
  const client = new OPGGClient();
  try {
    await client.initialize();
    const raw = await client.callTool("lol-champion-meta-data", {
      region: mapRegion(region),
    });
    return { raw };
  } catch (e) {
    console.error(`Failed to fetch meta:`, e);
    return { raw: `Error: ${e}` };
  }
}

export async function fetchAllPlayersData(
  players: Array<{ name: string; champion: string; role: string }>,
  region: string
): Promise<Map<string, { summoner: SummonerData; build: ChampionBuild }>> {
  const results = new Map<string, { summoner: SummonerData; build: ChampionBuild }>();

  // Fetch all in parallel with concurrency limit (5 at a time)
  const chunks = chunkArray(players, 5);
  for (const chunk of chunks) {
    const promises = chunk.map(async (player) => {
      const [summoner, build] = await Promise.all([
        fetchSummonerData(player.name, region),
        fetchChampionAnalysis(player.champion, player.role, region),
      ]);
      results.set(player.name, { summoner, build });
    });
    await Promise.all(promises);
  }

  return results;
}

// ── Helpers ──

function mapRegion(region: string): string {
  const map: Record<string, string> = {
    euw1: "euw",
    na1: "na",
    kr: "kr",
    eun1: "eune",
    br1: "br",
    jp1: "jp",
    la1: "lan",
    la2: "las",
    oc1: "oce",
    tr1: "tr",
    ru: "ru",
    ph2: "ph",
    sg2: "sg",
    th2: "th",
    tw2: "tw",
    vn2: "vn",
  };
  return map[region] ?? region;
}

function extractField(text: string, ...fieldNames: string[]): string | null {
  for (const field of fieldNames) {
    // Try JSON-style: "field": "value" or "field": value
    const jsonMatch = text.match(new RegExp(`"${field}"\\s*:\\s*"?([^",}\\n]+)"?`));
    if (jsonMatch) return jsonMatch[1].trim();
    // Try plain text: Field: value
    const textMatch = text.match(new RegExp(`${field}[:\\s]+([^\\n,]+)`, "i"));
    if (textMatch) return textMatch[1].trim();
  }
  return null;
}

function chunkArray<T>(arr: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < arr.length; i += size) {
    chunks.push(arr.slice(i, i + size));
  }
  return chunks;
}
