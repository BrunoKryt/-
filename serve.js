const http = require("http");
const https = require("https");
const fs = require("fs");
const path = require("path");

const root = __dirname;
const port = Number(process.env.PORT) || 4173;
const types = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".mp4": "video/mp4",
  ".woff2": "font/woff2",
  ".ico": "image/x-icon"
};

function sendJson(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "Access-Control-Allow-Origin": "*"
  });
  res.end(body);
}

function handleRustOnline(req, res) {
  const url = "https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/?appid=252490";
  https
    .get(url, (upstream) => {
      let data = "";
      upstream.on("data", (chunk) => (data += chunk));
      upstream.on("end", () => {
        try {
          const json = JSON.parse(data);
          const count = json && json.response ? Number(json.response.player_count) || 0 : 0;
          sendJson(res, 200, { ok: true, count, source: "steam", fetchedAt: new Date().toISOString() });
        } catch (e) {
          sendJson(res, 502, { ok: false, error: "bad_upstream_json" });
        }
      });
    })
    .on("error", () => {
      sendJson(res, 502, { ok: false, error: "upstream_error" });
    });
}

http
  .createServer((req, res) => {
    const urlPath = decodeURIComponent((req.url || "/").split("?")[0]);

    if (urlPath === "/api/rust-online") {
      handleRustOnline(req, res);
      return;
    }

    let filePath = path.join(root, urlPath === "/" ? "index.html" : urlPath);

    // If path is a directory, try index.html inside it
    try {
      if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
        filePath = path.join(filePath, "index.html");
      }
    } catch (_) {}

    if (!filePath.startsWith(root)) {
      res.writeHead(403).end("Forbidden");
      return;
    }

    fs.readFile(filePath, (error, data) => {
      if (error) {
        res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
        res.end("Not found");
        return;
      }
      res.writeHead(200, {
        "Content-Type": types[path.extname(filePath).toLowerCase()] || "application/octet-stream",
        "Cache-Control": "no-store"
      });
      res.end(data);
    });
  })
  .listen(port, () => console.log(`RustStoria preview: http://localhost:${port}`));
