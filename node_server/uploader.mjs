import http from "node:http";

const RAILS = process.env.RAILS_INTERNAL_URL ?? "http://localhost:3000";
// const SECRET = process.env.INTERNAL_API_SECRET;
const PORT = Number(process.env.PORT ?? 3001);
const PART_SIZE = Number(process.env.PART_SIZE_MB ?? 128) * 1024 * 1024;
const QUEUE_SIZE = Number(process.env.QUEUE_SIZE ?? 3);
const MAX_PARTS = 10_000;
const MAX_SIZE = Math.min(1024 ** 4, PART_SIZE * MAX_PARTS);

// if (!SECRET) {
//   console.error("INTERNAL_API_SECRET is not set");
//   process.exit(1);
// }

const ROUTE = /^\/api\/v2\/datasets\/([^/?]+)\/files\/([^/?]+)(?:\?.*)?$/;


const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// POST to Rails: ${RAILS}/api/v2/file_uploads${path}
async function rails(path, {body, headers = {}, timeout = 30_000} = {}) {
  return fetch(`${RAILS}/api/v2/file_uploads${path}`, {
    method: "POST",
    headers: {
      // "X-Internal-Secret": SECRET,
      "Content-Type": "application/json",
      ...headers,
    },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(timeout),
  });
}

// Split on "/" BEFORE decoding so an encoded %2F inside the DOI stays intact
function parseRoute(req) {
  if (req.method !== "PUT") return null;
  const m = ROUTE.exec(req.url);
  if (!m) return null;
  try {
    return {doi: decodeURIComponent(m[1]), fileName: decodeURIComponent(m[2])};
  } catch {
    return null; // malformed percent-encoding
  }
}

const getBody = (req) => {
  const route = parseRoute(req);
  if (!route) return reply(404, {error: "not found"});

  const {doi, fileName} = route;
  return {doi, fileName};
};

// Presign + PUT one part; every attempt gets a fresh URL
async function putPart(req, id, partNumber, buf) {
  const {doi, fileName} = getBody(req);

  let lastErr;
  for (let attempt = 1; attempt <= 1; attempt++) {
    try {
      const pr = await rails(`/${id}/part_url`, {
        headers: {Authorization: req.headers.authorization ?? ""},
        body: {doi, filename: fileName, part_number: partNumber}
      });
      if (!pr.ok) throw new Error(`part_url ${pr.status} ${await pr.text()}`);
      const {url} = await pr.json();

      const r = await fetch(url, {method: "PUT", body: buf});
      if (!r.ok) throw new Error(`S3 PUT ${r.status} ${await r.text()}`);
      await r.arrayBuffer(); // drain the body

      const etag = r.headers.get("etag");
      if (!etag) throw new Error("S3 returned no ETag");
      return etag;
    } catch (err) {
      lastErr = err;
      console.warn(`part ${partNumber} attempt ${attempt} failed:`, err.message);
      if (attempt < 4) await sleep(1000 * 2 ** attempt);
    }
  }
  throw lastErr;
}



async function handle(req, res, isContinue = false) {
  const reply = (status, body) => {
    res.writeHead(status, {"Content-Type": "application/json", Connection: "close"});
    res.end(JSON.stringify(body));
  };
  const {doi, fileName} = getBody(req);

  // Validate Content-Length (Node lowercases header names)
  const raw = req.headers["content-length"];
  const contentLength = raw !== undefined ? Number(raw) : null; // null = chunked
  if (contentLength !== null && (!Number.isSafeInteger(contentLength) || contentLength < 0)) {
    return reply(400, {error: "invalid content-length"});
  }
  if (contentLength === 0) return reply(400, {error: "empty body"});
  if (contentLength !== null && contentLength > MAX_SIZE) {
    return reply(413, {error: "too large"});
  }

  // 1. Authenticate + create the multipart upload (before any body is sent)
  let id;
  try {
    const r = await rails("/start", {
      headers: {Authorization: req.headers.authorization ?? ""},
      body: {doi, filename: fileName, content_length: contentLength},
    });
    if (!r.ok) {
      const text = await r.text();
      console.warn("start rejected:", r.status, text);
      if ([401, 403, 404, 413, 422].includes(r.status)) {
        return reply(r.status, {error: "rejected"});
      }
      return reply(502, {error: "backend error"});
    }
    ({id} = await r.json());
  } catch (err) {
    console.error("start failed:", err);
    return reply(503, {error: "backend unavailable"});
  }

  // Auth passed: let curl send the body
  if (isContinue) res.writeContinue();

  // 2. Cut the stream into parts, upload up to QUEUE_SIZE at once
  const parts = [];
  const inflight = new Set();
  let failure = null;
  let partNumber = 0;
  let total = 0;

  const dispatch = async (buf) => {
    while (inflight.size >= QUEUE_SIZE) await Promise.race(inflight); // backpressure
    if (failure) throw failure;
    if (partNumber >= MAX_PARTS) throw new Error("file too large for part size");

    const n = ++partNumber;
    const p = putPart(req, id, n, buf)
      .then(
        (etag) => parts.push({part_number: n, etag}),
        (e) => {
          failure = e;
        },
      )
      .finally(() => inflight.delete(p));
    inflight.add(p);
  };

  try {
    let chunks = [];
    let size = 0;

    for await (const chunk of req) { // reading pauses while dispatch waits
      chunks.push(chunk);
      size += chunk.length;
      total += chunk.length;
      if (size >= PART_SIZE) {
        await dispatch(Buffer.concat(chunks));
        chunks = [];
        size = 0;
      }
    }
    if (size > 0) await dispatch(Buffer.concat(chunks));

    await Promise.all(inflight);
    if (failure) throw failure;
    if (total === 0) throw Object.assign(new Error("empty body"), {status: 400});

    // 3. Complete (S3 can take a while to assemble huge objects)
    const r = await rails(`/${id}/complete`, {
      headers: {Authorization: req.headers.authorization ?? ""},
      body: {doi, filename: fileName, content_length: contentLength, parts},
      timeout: 15 * 60_000
    });
    if (!r.ok) throw new Error(`complete ${r.status} ${await r.text()}`);

    return reply(201, await r.json());
  } catch (err) {
    console.error("upload failed", id, err);
    await Promise.allSettled(inflight);
    await rails(`/${id}/abort`, {
      headers: {Authorization: req.headers.authorization ?? ""},
      body: {doi, filename: fileName, content_length: contentLength},
    }).catch(() => {
    });
    return reply(err.status ?? 500, {error: "upload failed"});
  }
}

const server = http.createServer((req, res) => {
  handle(req, res).catch((err) => {
    console.error("unhandled", err);
    if (!res.headersSent) res.writeHead(500);
    res.end();
  });
});

server.on("checkContinue", (req, res) => {
  handle(req, res, true).catch((err) => {
    console.error("unhandled", err);
    if (!res.headersSent) res.writeHead(500);
    res.end();
  });
});

// Uploads can run for hours
server.requestTimeout = 0;
server.headersTimeout = 60_000;
server.timeout = 0;

// Graceful shutdown: stop accepting, let active uploads finish
process.on("SIGTERM", () => {
  server.close(() => process.exit(0));
  server.closeIdleConnections();
});

server.listen(PORT, "127.0.0.1", () => console.log(`uploader on :${PORT}`));