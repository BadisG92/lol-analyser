import { Hono } from "hono";
import type { Env } from "../types/env";
import { CHAMPIONS } from "../data/champions";
import { ITEMS } from "../data/items";
import { SUMMONER_SPELLS } from "../data/spells";
import {
  CURRENT_PATCH,
  championIconUrl,
  getItemImageUrl,
  getSpellImageUrl,
} from "../data/ddragon";

const data = new Hono<{ Bindings: Env }>();

/**
 * GET /data/assets
 *
 * Returns current patch version and URL templates for the iOS app
 * to load champion, item, and spell icons from DDragon CDN.
 */
data.get("/assets", (c) => {
  return c.json({
    patch: CURRENT_PATCH,
    cdn: `https://ddragon.leagueoflegends.com/cdn/${CURRENT_PATCH}`,
    templates: {
      champion_icon: `https://ddragon.leagueoflegends.com/cdn/${CURRENT_PATCH}/img/champion/{championId}.png`,
      item_icon: `https://ddragon.leagueoflegends.com/cdn/${CURRENT_PATCH}/img/item/{itemId}.png`,
      spell_icon: `https://ddragon.leagueoflegends.com/cdn/${CURRENT_PATCH}/img/spell/{spellKey}.png`,
      profile_icon: `https://ddragon.leagueoflegends.com/cdn/${CURRENT_PATCH}/img/profileicon/{iconId}.png`,
    },
  });
});

/**
 * GET /data/champions
 *
 * Returns all champions with icon URLs.
 */
data.get("/champions", (c) => {
  const champions = CHAMPIONS.map((champ) => ({
    ...champ,
    icon: championIconUrl(champ.id),
  }));
  return c.json({ patch: CURRENT_PATCH, champions });
});

/**
 * GET /data/items
 *
 * Returns all items with icon URLs.
 */
data.get("/items", (c) => {
  const items = ITEMS.map((item) => ({
    ...item,
    icon: getItemImageUrl(item.name) ?? null,
  }));
  return c.json({ patch: CURRENT_PATCH, items });
});

/**
 * GET /data/spells
 *
 * Returns summoner spells with icon URLs.
 */
data.get("/spells", (c) => {
  const spells = SUMMONER_SPELLS.map((spell) => ({
    ...spell,
    icon: getSpellImageUrl(spell.name) ?? null,
  }));
  return c.json({ patch: CURRENT_PATCH, spells });
});

export default data;
