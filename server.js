"use strict";

const http = require("http");
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");
const mysql = require("mysql2/promise");

const ROOT = __dirname;
const PORT = Number(process.env.PORT || 4173);

const DB_CONFIG = {
  host: process.env.DB_HOST || "127.0.0.1",
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || "indieforge",
  password: process.env.DB_PASSWORD || "indieforge2026",
  database: process.env.DB_NAME || "indieforge",
  charset: "utf8mb4",
  waitForConnections: true,
  connectionLimit: 5,
  queueLimit: 0
};

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".avif": "image/avif",
  ".gif": "image/gif",
  ".mp4": "video/mp4",
  ".webm": "video/webm",
  ".mp3": "audio/mpeg",
  ".ogg": "audio/ogg",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".ttf": "font/ttf",
  ".otf": "font/otf",
  ".txt": "text/plain; charset=utf-8"
};

const TEXT_EXTENSIONS = new Set([
  ".html", ".css", ".js", ".mjs", ".json", ".svg", ".txt"
]);

const IMMUTABLE_PREFIXES = [
  "/assets/img/",
  "/assets/video/",
  "/assets/vendor/",
  "/assets/fonts/"
];

const compressionCache = new Map();
let pool = null;



function db() {
  if (!pool) pool = mysql.createPool(DB_CONFIG);
  return pool;
}

async function query(sql, params) {
  const [rows] = await db().query(sql, params || []);
  return rows;
}

function groupList(value) {
  return value ? String(value).split("|").filter(Boolean) : [];
}



function accepts(req, encoding) {
  const header = String(req.headers["accept-encoding"] || "").toLowerCase();
  if (!header.includes(encoding)) return false;
  const index = header.indexOf(encoding);
  const before = header.slice(Math.max(0, index - 1), index);
  return before !== ";";
}

function compress(buffer, encoding) {
  if (encoding === "br") {
    return zlib.brotliCompressSync(buffer, {
      params: {
        [zlib.constants.BROTLI_PARAM_QUALITY]: 5,
        [zlib.constants.BROTLI_PARAM_SIZE_HINT]: buffer.length
      }
    });
  }
  return zlib.gzipSync(buffer, { level: 6 });
}

function cacheControlFor(pathname) {
  if (IMMUTABLE_PREFIXES.some((prefix) => pathname.startsWith(prefix))) {
    return "public, max-age=31536000, immutable";
  }
  if (/\.(css|js|woff2?|ttf|otf)$/i.test(pathname)) {
    return "public, max-age=604800, stale-while-revalidate=86400";
  }
  return "no-cache";
}

function sendJson(req, res, status, payload) {
  const body = Buffer.from(JSON.stringify(payload));
  const encoding = accepts(req, "br") ? "br" : accepts(req, "gzip") ? "gzip" : null;
  const output = encoding ? compress(body, encoding) : body;
  const headers = {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": output.length,
    "Cache-Control": "no-store",
    "Vary": "Accept-Encoding",
    "X-Content-Type-Options": "nosniff"
  };
  if (encoding) headers["Content-Encoding"] = encoding;
  res.writeHead(status, headers);
  res.end(req.method === "HEAD" ? undefined : output);
}

function sendError(req, res, status, message) {
  sendJson(req, res, status, { ok: false, error: message });
}

function readBody(req, limit) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on("data", (chunk) => {
      size += chunk.length;
      if (size > (limit || 1024 * 100)) {
        reject(new Error("body_too_large"));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
    req.on("error", reject);
  });
}



async function apiHealth(req, res) {
  const rows = await query("SELECT VERSION() AS version, DATABASE() AS db");
  sendJson(req, res, 200, {
    ok: true,
    database: rows[0].db,
    version: rows[0].version,
    time: new Date().toISOString()
  });
}

async function apiStats(req, res) {
  const rows = await query(
    `SELECT
       (SELECT COUNT(*) FROM games) AS games,
       (SELECT COUNT(*) FROM categories) AS categories,
       (SELECT COUNT(*) FROM genres) AS genres,
       (SELECT COUNT(*) FROM trailers) AS trailers,
       (SELECT COUNT(*) FROM mods) AS mods,
       (SELECT COUNT(*) FROM feedback) AS feedback,
       (SELECT COUNT(*) FROM users) AS users`
  );
  sendJson(req, res, 200, { ok: true, stats: rows[0] });
}

async function apiCategories(req, res) {
  const rows = await query(
    `SELECT c.id, c.slug, c.title, COUNT(gc.game_id) AS games
       FROM categories c
       LEFT JOIN game_categories gc ON gc.category_id = c.id
      GROUP BY c.id, c.slug, c.title
      ORDER BY games DESC, c.title`
  );
  sendJson(req, res, 200, { ok: true, categories: rows });
}

async function apiGames(req, res, url) {
  const q = String(url.searchParams.get("q") || "").trim();
  const category = String(url.searchParams.get("category") || "").trim();
  const limit = Math.min(100, Math.max(1, Number(url.searchParams.get("limit") || 100)));

  const filters = [];
  const params = [];
  if (q) {
    filters.push("(g.title LIKE ? OR g.tagline LIKE ? OR g.developer LIKE ?)");
    const like = "%" + q + "%";
    params.push(like, like, like);
  }
  if (category) {
    filters.push("EXISTS (SELECT 1 FROM game_categories x JOIN categories xc ON xc.id = x.category_id WHERE x.game_id = g.id AND (xc.slug = ? OR xc.title = ?))");
    params.push(category, category);
  }
  params.push(limit);

  const rows = await query(
    `SELECT g.id, g.slug, g.title, g.year, g.rating, g.steam_score, g.weight,
            g.tagline, g.cover_path, g.wide_path,
            GROUP_CONCAT(DISTINCT c.title ORDER BY c.title SEPARATOR '|') AS categories
       FROM games g
       LEFT JOIN game_categories gc ON gc.game_id = g.id
       LEFT JOIN categories c ON c.id = gc.category_id
      ${filters.length ? "WHERE " + filters.join(" AND ") : ""}
      GROUP BY g.id
      ORDER BY (g.rating IS NULL), g.rating DESC, g.year DESC, g.title
      LIMIT ?`,
    params
  );

  sendJson(req, res, 200, {
    ok: true,
    count: rows.length,
    games: rows.map((game) => Object.assign({}, game, { categories: groupList(game.categories) }))
  });
}

async function apiGame(req, res, slug) {
  const rows = await query(
    `SELECT g.*,
            GROUP_CONCAT(DISTINCT c.title ORDER BY c.title SEPARATOR '|') AS categories,
            GROUP_CONCAT(DISTINCT ge.name ORDER BY ge.name SEPARATOR '|') AS genres
       FROM games g
       LEFT JOIN game_categories gc ON gc.game_id = g.id
       LEFT JOIN categories c ON c.id = gc.category_id
       LEFT JOIN game_genres gg ON gg.game_id = g.id
       LEFT JOIN genres ge ON ge.id = gg.genre_id
      WHERE g.slug = ?
      GROUP BY g.id`,
    [slug]
  );
  if (!rows.length) return sendError(req, res, 404, "game_not_found");

  const game = rows[0];
  game.categories = groupList(game.categories);
  game.genres = groupList(game.genres);

  const trailers = await query(
    "SELECT name, hls_url, poster_url FROM trailers WHERE game_id = ? LIMIT 1",
    [game.id]
  );
  const mods = await query(
    `SELECT m.slug, m.title, m.status, m.summary
       FROM mods m WHERE m.game_id = ? ORDER BY m.status = 'ready' DESC, m.title`,
    [game.id]
  );

  sendJson(req, res, 200, {
    ok: true,
    game: game,
    trailer: trailers[0] || null,
    mods: mods
  });
}

async function apiMods(req, res) {
  const rows = await query(
    `SELECT m.id, m.slug, m.title, m.game_title, m.kicker, m.summary,
            m.status, m.status_label, m.version, m.compatibility,
            m.updated_label, m.cover_path
       FROM mods m
      ORDER BY m.status = 'ready' DESC, m.id`
  );
  sendJson(req, res, 200, { ok: true, count: rows.length, mods: rows });
}

async function apiFeedback(req, res) {
  if (req.method !== "POST") return sendError(req, res, 405, "method_not_allowed");

  let data;
  try {
    data = JSON.parse(await readBody(req, 1024 * 64));
  } catch (error) {
    return sendError(req, res, 400, "invalid_json");
  }

  const name = String(data.name || "").trim().slice(0, 120);
  const email = String(data.email || "").trim().slice(0, 190);
  const phone = String(data.phone || "").trim().slice(0, 40);
  const contact = String(data.contact || "").trim().slice(0, 190);
  const topic = String(data.topic || "Вопрос").trim().slice(0, 64);
  const message = String(data.message || "").trim().slice(0, 6000);

  if (name.length < 2 || message.length < 8) {
    return sendError(req, res, 422, "name_or_message_too_short");
  }
  if (!email && !contact) return sendError(req, res, 422, "contact_required");

  const result = await query(
    `INSERT INTO feedback (user_id, name, email, phone, contact, topic, message, status)
     VALUES (NULL, ?, ?, ?, ?, ?, ?, 'new')`,
    [name, email, phone, contact, topic, message]
  );

  sendJson(req, res, 201, {
    ok: true,
    id: result.insertId,
    status: "new"
  });
}

async function handleApi(req, res, url) {
  const pathname = url.pathname;
  if (req.method === "OPTIONS") {
    res.writeHead(204, { Allow: "GET, HEAD, POST, OPTIONS" });
    return res.end();
  }
  if (req.method !== "GET" && req.method !== "HEAD" && req.method !== "POST") {
    return sendError(req, res, 405, "method_not_allowed");
  }

  if (pathname === "/api/health") return apiHealth(req, res);
  if (pathname === "/api/stats") return apiStats(req, res);
  if (pathname === "/api/categories") return apiCategories(req, res);
  if (pathname === "/api/games") return apiGames(req, res, url);
  if (pathname === "/api/mods") return apiMods(req, res);
  if (pathname === "/api/feedback") return apiFeedback(req, res);

  const gameMatch = pathname.match(/^\/api\/games\/([a-z0-9-]+)$/);
  if (gameMatch) return apiGame(req, res, gameMatch[1]);

  return sendError(req, res, 404, "api_route_not_found");
}



function resolveFile(pathname) {
  let decoded;
  try {
    decoded = decodeURIComponent(pathname);
  } catch (error) {
    return null;
  }
  if (decoded.includes("\0")) return null;
  if (decoded === "/") decoded = "/index.html";
  const file = path.join(ROOT, decoded);
  if (file !== ROOT && !file.startsWith(ROOT + path.sep)) return null;
  return file;
}

function rangeFor(req, size) {
  const header = String(req.headers.range || "");
  const match = header.match(/^bytes=(\d*)-(\d*)$/);
  if (!match) return null;
  let start = match[1] === "" ? null : Number(match[1]);
  let end = match[2] === "" ? null : Number(match[2]);
  if (start === null && end === null) return null;
  if (start === null) {
    start = Math.max(0, size - end);
    end = size - 1;
  } else {
    end = end === null ? size - 1 : Math.min(end, size - 1);
  }
  if (start > end || start >= size) return null;
  return { start, end };
}

async function serveStatic(req, res, url) {
  let file = resolveFile(url.pathname);
  if (!file) return sendError(req, res, 403, "forbidden");

  let stat;
  try {
    stat = await fs.promises.stat(file);
    if (stat.isDirectory()) {
      file = path.join(file, "index.html");
      stat = await fs.promises.stat(file);
    }
  } catch (error) {
    return sendError(req, res, 404, "not_found");
  }
  if (!stat.isFile()) return sendError(req, res, 404, "not_found");

  const ext = path.extname(file).toLowerCase();
  const contentType = MIME[ext] || "application/octet-stream";
  const isText = TEXT_EXTENSIONS.has(ext);
  const encoding = isText && accepts(req, "br") ? "br" : isText && accepts(req, "gzip") ? "gzip" : null;
  const etag = `"${stat.size.toString(16)}-${Math.trunc(stat.mtimeMs).toString(16)}-${encoding || "raw"}"`;

  if (req.headers["if-none-match"] === etag) {
    res.writeHead(304, {
      ETag: etag,
      "Cache-Control": cacheControlFor(url.pathname),
      Vary: "Accept-Encoding"
    });
    return res.end();
  }

  let buffer = await fs.promises.readFile(file);
  if (isText && encoding) {
    const cacheKey = `${file}:${stat.mtimeMs}:${encoding}`;
    const cached = compressionCache.get(cacheKey);
    if (cached) {
      buffer = cached;
    } else {
      const original = buffer;
      buffer = compress(original, encoding);
      if (compressionCache.size > 120) compressionCache.clear();
      compressionCache.set(cacheKey, buffer);
    }
  }

  const headers = {
    "Content-Type": contentType,
    "Cache-Control": cacheControlFor(url.pathname),
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "X-Frame-Options": "SAMEORIGIN"
  };
  if (encoding) {
    headers["Content-Encoding"] = encoding;
    headers.Vary = "Accept-Encoding";
  }
  headers.ETag = etag;

  const range = rangeFor(req, buffer.length);
  if (range) {
    headers["Content-Range"] = `bytes ${range.start}-${range.end}/${buffer.length}`;
    headers["Content-Length"] = range.end - range.start + 1;
    headers["Accept-Ranges"] = "bytes";
    res.writeHead(206, headers);
    return res.end(req.method === "HEAD" ? undefined : buffer.subarray(range.start, range.end + 1));
  }

  headers["Content-Length"] = buffer.length;
  headers["Accept-Ranges"] = "bytes";
  res.writeHead(200, headers);
  res.end(req.method === "HEAD" ? undefined : buffer);
}



const server = http.createServer(async (req, res) => {
  const started = Date.now();
  let url;
  try {
    url = new URL(req.url, `http://${req.headers.host || "localhost"}`);
  } catch (error) {
    return sendError(req, res, 400, "bad_request");
  }

  try {
    if (url.pathname.startsWith("/api/")) {
      await handleApi(req, res, url);
    } else if (req.method === "GET" || req.method === "HEAD") {
      await serveStatic(req, res, url);
    } else {
      sendError(req, res, 405, "method_not_allowed");
    }
  } catch (error) {
    console.error("IndieForge server:", error.message);
    if (!res.headersSent) {
      const databaseDown = /ECONNREFUSED|ER_|PROTOCOL|Access denied/i.test(String(error.message));
      sendError(req, res, databaseDown ? 503 : 500, databaseDown ? "database_unavailable" : "internal_error");
    } else {
      res.end();
    }
  } finally {
    if (process.env.LOG_REQUESTS === "1") {
      console.log(`${req.method} ${url.pathname} ${res.statusCode} ${Date.now() - started}ms`);
    }
  }
});

server.listen(PORT, () => {
  console.log(`IndieForge: http://localhost:${PORT}`);
  console.log(`API:       http://localhost:${PORT}/api/health`);
});

async function shutdown() {
  server.close();
  if (pool) {
    try {
      await pool.end();
    } catch (error) {
      /* ignore */
    }
  }
  process.exit(0);
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
