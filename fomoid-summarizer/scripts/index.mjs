/**
 * index.mjs — Fomo.id Thread Fetcher & Normalizer
 *
 * Usage:
 *   node index.mjs <threadId>
 *
 * Output: JSON ke stdout dengan struktur yang sudah di-normalize
 * agar token-efficient saat dikirim ke LLM untuk summarization.
 *
 * Flow:
 *   1. Cek token dari config.js — kalau null, exit dengan pesan error
 *   2. Fetch thread detail (POST /activity)
 *   3. Fetch comments (GET /activity/{id}/comments)
 *   4. Normalize: buang field tidak perlu, keep hanya yang relevan
 *   5. Output JSON ke stdout
 */

import { FOMO_CONFIG } from "./config.js";

// ─── Helpers ───────────────────────────────────────────────

async function fetchJson(url, options) {
  const res = await fetch(url, options);
  if (!res.ok) {
    throw new Error(`HTTP ${res.status} ${res.statusText} — ${url}`);
  }
  return res.json();
}

// ─── API Calls ─────────────────────────────────────────────

async function fetchThreadDetail(threadId) {
  const url = `${FOMO_CONFIG.baseUrl}/activity`;
  return fetchJson(url, {
    method: "POST",
    headers: FOMO_CONFIG.headers(),
    body: JSON.stringify({ activityId: threadId, notification: null }),
  });
}

async function fetchCommentsPage(threadId, page = 1, limit = 50) {
  const url = `${FOMO_CONFIG.baseUrl}/activity/${threadId}/comments?page=${page}&limit=${limit}`;
  return fetchJson(url, {
    method: "GET",
    headers: FOMO_CONFIG.headers(),
  });
}

/**
 * Fetch ALL comments with auto-pagination.
 * Fetches pages until a page returns fewer than `limit` items (last page).
 */
async function fetchAllComments(threadId, limit = 50) {
  const allData = [];
  let page = 1;
  const maxPages = 20; // safety guard (20 × 50 = 1000 comments max)

  while (page <= maxPages) {
    const result = await fetchCommentsPage(threadId, page, limit);
    const batch = result.data || [];
    allData.push(...batch);

    // Last page reached (fewer items than requested, or empty)
    if (batch.length < limit) break;

    page++;
  }

  return { data: allData };
}

// ─── Normalizers ───────────────────────────────────────────
// Tujuan: strip noise, keep hanya field yang relevan untuk summary.
// Ini menghemat token LLM secara signifikan.

function normalizeUser(user) {
  if (!user) return null;
  return {
    username: user.username,
    company: user.companyName,
    gender: user.gender,
  };
}

function normalizeThread(raw) {
  const inner = raw.inner || {};
  return {
    threadId: raw.key || inner.activityId,
    title: inner.title,
    content: inner.content,
    tax: inner.tax || null, // konteks/pajak thread
    channel: inner.channel?.label || null,
    type: inner.type,
    author: normalizeUser(raw.user || inner.user),
    stats: {
      likes: inner.numberOfLikes || 0,
      dislikes: inner.numberOfDislikes || 0,
      comments: inner.numberOfComments || 0,
      views: inner.numberOfViews || 0,
    },
    createdAt: inner.creationTime,
    edited: inner.edited || false,
    promoted: inner.promoted || false,
    pollOptions: inner.pollOptions?.length
      ? inner.pollOptions.map((p) => ({ text: p.text, votes: p.votes }))
      : [],
  };
}

function normalizeComment(raw, depth = 0) {
  const inner = raw.inner || raw; // top-level comments punya wrapper "inner"
  const replies = (inner.comments || []).map((c) => normalizeComment(c, depth + 1));

  return {
    author: normalizeUser(inner.user),
    text: inner.value,
    likes: inner.numberOfLikes || 0,
    replies: replies.length > 0 ? replies : undefined,
  };
}

function normalizeAll(threadRaw, commentsRaw) {
  const thread = normalizeThread(threadRaw);
  const comments = (commentsRaw.data || [])
    .map((c) => normalizeComment(c))
    // Sort by likes descending — most relevant first
    .sort((a, b) => (b.likes || 0) - (a.likes || 0));

  return {
    thread,
    comments,
    meta: {
      totalComments: comments.length,
      fetchedAt: new Date().toISOString(),
    },
  };
}

// ─── Main ──────────────────────────────────────────────────

async function main() {
  const threadId = process.argv[2];

  if (!threadId) {
    console.error("Usage: node index.mjs <threadId>");
    process.exit(1);
  }

  if (!FOMO_CONFIG.token) {
    console.error(
      JSON.stringify({
        error: "NO_TOKEN",
        message:
          "Token Fomo.id belum diset. Edit config.js dan isi field `token` dengan kode portal kamu.",
      })
    );
    process.exit(2);
  }

  try {
    // Fetch thread detail and all comments
    const threadRaw = await fetchThreadDetail(Number(threadId));
    const commentsRaw = await fetchAllComments(Number(threadId));

    const normalized = normalizeAll(threadRaw, commentsRaw);
    // Paginated comment count to meta
    normalized.meta.pagesFetched = Math.ceil(normalized.meta.totalComments / 50);
    console.log(JSON.stringify(normalized, null, 2));
  } catch (err) {
    console.error(
      JSON.stringify({
        error: "FETCH_FAILED",
        message: err.message,
      })
    );
    process.exit(3);
  }
}

main();
