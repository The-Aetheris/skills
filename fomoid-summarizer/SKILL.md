---
name: fomoid-summarizer
description: "Summarize Fomo.id threads. Fetches thread + comments via API, normalizes output, generates concise summary."
version: 1.0.0
author: Nooku <nooku@the-aetheris.dev>
license: MIT
---

# Fomo.id Thread Summarizer

## Overview

Skill untuk fetch dan summarize thread Fomo.id tanpa browser. Menggunakan API langsung (`fomo.azurewebsites.net`) dengan Basic Auth token (kode portal).

## When to Use

Trigger saat user mengirim salah satu dari:

- `/fomoid summarize thread <threadId>` — summarize thread spesifik
- `/fomoid summarize <threadId>` — shorthand
- `summarize fomo thread <threadId>` — natural language variant

Juga bisa dipakai internal saat user nanya tentang thread Fomo spesifik dan punya thread ID-nya.

## Prerequisites

### Token Setup

Script butuh **kode portal Fomo** yang disimpan di `config.js`.

**Setup pertama kali:**

```bash
# Copy template, lalu isi token kamu
cp config.template.js config.js
# Edit config.js — isi field token dengan kode portal
```

**Cek token sebelum run:**

```bash
grep "token:" config.js
```

- Kalau `token: null` → minta user kasih kode portal, lalu update `config.js`.
- Kalau sudah ada token → langsung run script.

Token adalah kode portal Fomo.id dengan format `<userId>:<base64string>`.
Dikirim sebagai header `Authorization: Basic <token>`.

## Workflow

### Step 1: Run the fetcher script

```bash
node scripts/index.mjs <threadId>
```

Script akan:
1. Fetch thread detail dari `POST /activity`
2. Fetch comments dari `GET /activity/{id}/comments`
3. Normalize output (buang field tidak perlu, sort comments by likes)
4. Output JSON ke stdout

### Step 2: Parse output

Output punya struktur:

```json
{
  "thread": {
    "threadId": 10410003,
    "title": "...",
    "content": "...",
    "tax": "...",
    "channel": "f/Publik",
    "author": { "username": "...", "company": "...", "gender": "..." },
    "stats": { "likes": 0, "dislikes": 0, "comments": 0, "views": 0 },
    "pollOptions": []
  },
  "comments": [
    {
      "author": { "username": "...", "company": "..." },
      "text": "...",
      "likes": 0,
      "replies": [/* nested */]
    }
  ],
  "meta": { "totalComments": 0, "fetchedAt": "..." }
}
```

### Step 3: Summarize

Buat summary dengan struktur:

1. **Header:** Title, author, stats (views/likes/comments)
2. **Inti pertanyaan/topik:** 1-2 kalimat
3. **Key points dari komentar:** Kelompokkan by theme, sebut username/commentator
4. **Konsensus atau debate:** Apakah komentarnya setuju/berdebat?
5. **TL;DR:** 1 paragraf ringkas

Bahasa summary: **Bahasa Indonesia** (match bahasa content Fomo.id).

## Error Handling

| Exit Code | Error | Action |
|-----------|-------|--------|
| 1 | Thread ID tidak diberikan | Minta user kasih thread ID |
| 2 | Token belum diset | Minta kode portal, update config.js |
| 3 | Fetch failed (HTTP error) | Cek apakah thread ID valid, atau token expired |

Kalau output mengandung `"error": "NO_TOKEN"`:
1. Minta user: "Kode portal Fomo.id kamu apa?"
2. Update `config.js` dengan token
3. Re-run script

Kalau output mengandung `"error": "FETCH_FAILED"`:
1. Cek pesan error detail
2. Coba re-fetch dengan browser untuk validasi token masih aktif
3. Kalau token expired, minta user kasih kode portal baru

## API Reference

Untuk debugging atau extension:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `POST /activity` | POST | Ambil detail thread (body: `{"activityId": <id>, "notification": null}`) |
| `GET /activity/{id}/comments?page=1&limit=50` | GET | Ambil comments |
| `GET /user/me` | GET | Profile user (validasi token) |

**Auth:** `Authorization: Basic <portalCode>`

**Base URL:** `https://fomo.azurewebsites.net`

## Notes

- Kode portal = token itu sendiri. Format: `<userId>:<base64string>`
- Token bisa expire. Kalau API return 401/403, minta user kasih kode baru.
- Script pakai ESM (`.mjs`) karena Node.js modern. `config.js` pakai CommonJS (`module.exports`) untuk simplicity.
- Comments di-sort by likes (most relevant first) untuk summary yang lebih quality.
- **Jangan commit `config.js`** — sudah di `.gitignore`. Copy dari `config.template.js`.
