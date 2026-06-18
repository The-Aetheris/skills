---
name: cross-profile-delegation
description: "Delegate tasks to another Hermes Agent profile by invoking it via CLI. Supports Level 1 (send message), Level 2 (orchestrated task), Level 3 (fully autonomous), and Human-in-the-Loop (ask-then-delegate) workflows."
version: 2.0.0
author: Xenna <xenna@the-aetheris.dev>
platforms: [macos, linux]
metadata:
  hermes:
    tags: [hermes, multi-profile, delegation, inter-agent, orchestration]
    related_skills: [hermes-multi-profile, hermes-agent]
---

# Cross-Profile Delegation

> Delegate tasks to another Hermes Agent profile by invoking it via CLI from within your gateway session.

## When to Use

- Kamu perlu agent lain mengerjakan task yang sesuai kompetensinya
- Kamu ingin pesan/monitoring muncul dari **bot agent lain**, bukan bot kamu sendiri
- Kamu ingin agent lain bekerja secara **autonomous** tanpa perlu intervensi manual
- Kamu perlu mengirim notifikasi ke Telegram menggunakan kredensial agent lain

## Prerequisites

1. **Multi-profile Hermes setup** — Target agent harus punya profile sendiri di `~/.hermes/profiles/<name>/`
2. **Target agent's gateway boleh running atau tidak** — `hermes chat -q` dan `hermes send` bekerja tanpa perlu gateway target aktif (mereka langsung akses credentials)
3. **Akses ke hermes CLI via venv** — Di gateway session, `hermes` binary tidak ada di PATH. Gunakan: `$HOME/.hermes/hermes-agent/venv/bin/python -m hermes_cli.main`

## ⚠️ Critical: Sandboxed HOME

Terminal tool di Hermes gateway session menggunakan sandboxed HOME (`~/.hermes/profiles/<session_profile>/home/`), BUKAN `$HOME`.

**Selalu gunakan absolute path** untuk:
- Path file/directory (`$HOME/...`)
- HERMES_HOME (`$HOME/.hermes/profiles/<target>/`)

## ⚠️ Critical: HERMES_HOME Must Be Set

Saat menjalankan perintah untuk profile LAIN, `HERMES_HOME` WAJIB di-set ke profile directory target. Tanpa ini, Hermes akan membaca/menulis ke profile yang sedang aktif (bukan target).

```bash
# ✅ BENAR
HERMES_PROFILE=<target> HERMES_HOME="$HOME/.hermes/profiles/<target>" command

# ❌ SALAH — membaca/writing ke profile yang salah
HERMES_PROFILE=<target> command
```

## Tech Reference

### Key Variables

> ⚠️ Ganti placeholder berikut dengan nilai aktual environment kamu.

| Variable | Placeholder | Contoh |
|----------|-------------|--------|
| Hermes venv python | `<HERMES_PYTHON>` | `$HOME/.hermes/hermes-agent/venv/bin/python` |
| Hermes module | `-m hermes_cli.main` | (sama) |
| Profile dir | `~/.hermes/profiles/<name>/` | (sama) |
| Sandboxed HOME | `~/.hermes/profiles/<session_profile>/home/` | (sama) |
| Telegram chat ID | `<TELEGRAM_CHAT_ID>` | `-100XXXXXXXXXX` |
| Telegram thread ID | `<TELEGRAM_THREAD_ID>` | `XXXX` |

### Available Agents

| Agent | Profile | Role | Competence |
|-------|---------|------|------------|
| `<orchestrator>` | `<orchestrator_profile>` | EM & PA | Coordination, vault, admin |
| `<engineer>` | `<engineer_profile>` | Lead Engineer | Coding, debugging, architecture |
| `<creative>` | `<creative_profile>` | Creative Assistant | Quotes, content, Tumblr, design |

> Ganti nama profile sesuai setup Hermes kamu.

### Target Platform Format

```
telegram:<TELEGRAM_CHAT_ID>:<TELEGRAM_THREAD_ID>
```

Contoh: `telegram:-100XXXXXXXXXX:1820`

## Delegation Patterns

### Level 1 — Send Message as Another Agent

Mengirim pesan sederhana dari bot agent lain.

```bash
# Kirim pesan dari bot target ke thread tertentu
HERMES_PROFILE=<target> HERMES_HOME="$HOME/.hermes/profiles/<target>" \
  "$HOME/.hermes/hermes-agent/venv/bin/python" \
  -m hermes_cli.main send \
  --to telegram:<TELEGRAM_CHAT_ID>:<TELEGRAM_THREAD_ID> \
  "Halo dari <target>! ✨"
```

**Use case:** Notifications, checkpoint updates, status reports dari agent lain.

### Level 2 — Orchestrated Task with Monitoring

Agent pemanggil memberikan task, memonitor progress, dan mengirim checkpoint.

**Flow:**
1. Kirim checkpoint 1 via `hermes send` dengan profile target
2. Jalankan agent target: `hermes chat -q "task"`
3. Kirim checkpoint 2 via `hermes send` dengan profile target
4. (lanjutkan sesuai kebutuhan)

```bash
# Step 1: Kirim checkpoint
HERMES_PROFILE=<target> HERMES_HOME="$HOME/.hermes/profiles/<target>" \
  "$HOME/.hermes/hermes-agent/venv/bin/python" \
  -m hermes_cli.main send \
  --to telegram:<TELEGRAM_CHAT_ID>:<TELEGRAM_THREAD_ID> \
  "🚀 <target> mulai task..."

# Step 2: Run agent
HERMES_PROFILE=<target> HERMES_HOME="$HOME/.hermes/profiles/<target>" \
  "$HOME/.hermes/hermes-agent/venv/bin/python" \
  -m hermes_cli.main chat -q "<task>" --quiet --yolo

# Step 3: Kirim hasil
HERMES_PROFILE=<target> HERMES_HOME="$HOME/.hermes/profiles/<target>" \
  "$HOME/.hermes/hermes-agent/venv/bin/python" \
  -m hermes_cli.main send \
  --to telegram:<TELEGRAM_CHAT_ID>:<TELEGRAM_THREAD_ID> \
  "✅ Selesai!"
```

### Level 3 — Fully Autonomous

Cukup berikan instruksi, agent target handle semuanya sendiri.

```bash
HERMES_PROFILE=<target> HERMES_HOME="$HOME/.hermes/profiles/<target>" \
  "$HOME/.hermes/hermes-agent/venv/bin/python" \
  -m hermes_cli.main chat -q \
  "<task instruction>. Handle sendiri ya." \
  --quiet --yolo --max-turns 30
```

**Use case:** Agent sudah pernah melakukan task serupa dan punya memori/skills yang cukup.

---

## Workflow: Human-in-the-Loop Delegation

> Alur interaktif di mana orchestrator agent menanyakan preferensi human soal report, lalu menjalankan delegation sesuai jawaban.

### Flow Diagram

```
Human → "<orchestrator>, suruh <target> buat sesuatu"
  │
  ├─ <orchestrator> tanya: "<target> perlu report progress?"
  │    │
  │    ├─ YA ──→ "Kasih link thread report"
  │    │           │
  │    │           └─ <orchestrator> invoke <target> dengan:
  │    │               1. Task description
  │    │               2. Thread ID untuk report
  │    │               3. Human name
  │    │                  │
  │    │                  └─ <target> kirim first response ke thread:
  │    │                     "Halo <human>! 👋 Aku dengar dari <orchestrator>
  │    │                      kamu ingin aku <task>. Baik, akan aku lakukan!"
  │    │                     │
  │    │                     └─ <target> lanjut kerja + report progress
  │    │
  │    └─ TIDAK ──→ <orchestrator> invoke <target> silent (no report thread)
  │                   ↓
  │                <target> kerja di background, human nggak diganggu
  │
  └─ Selesai ✅
```

### Step-by-Step untuk Orchestrator Agent

#### Step 1: Human minta delegate task

Human bilang sesuatu seperti: *"<orchestrator>, suruh <target> buat sesuatu"*

#### Step 2: Tanya preference report

Tanya ke human via `clarify` tool:

```markdown
Baik! Saya akan delegasikan ke <target>.

Apakah <target> perlu **report progress** di thread?
- **YA** → Saya minta link thread untuk <target> lapor
- **TIDAK** → <target> kerja di belakang layar
```

#### Step 3A: Jika YA — Human beri link thread

Human kasih link Telegram thread (contoh: `https://t.me/c/<chat_id_num>/<thread_id>`).

Parse thread ID dari link:
- Format: `https://t.me/c/<chat_id_num>/<thread_id>`
- chat_id: `-100<chat_id_num>` → `<TELEGRAM_CHAT_ID>`
- thread_id: `<TELEGRAM_THREAD_ID>`

Lalu invoke agent target dengan instruksi yang mencakup:
1. Task yang harus dikerjakan
2. Thread ID untuk report
3. Nama human
4. Nama orchestrator agent
5. Instruksi untuk kirim first response + report progress

**Template invoke untuk agent target (dengan report):**

```bash
HERMES_PROFILE=<target> HERMES_HOME="$HOME/.hermes/profiles/<target>" \
  "$HOME/.hermes/hermes-agent/venv/bin/python" \
  -m hermes_cli.main chat -q \
  "Kamu mendapat task dari <orchestrator> untuk <human>:

  TASK: <deskripsi task>

  INSTRUKSI REPORT:
  1. Kirim first response ke Telegram thread <TELEGRAM_CHAT_ID>:<TELEGRAM_THREAD_ID>
     — Pakai hermes send dengan profilmu sendiri
     — Contoh pesan:
       \"Halo <human>! 👋 Aku dengar dari <orchestrator> kamu ingin aku <task>. Baik, akan aku lakukan!\"
     — Buat kata-katamu sendiri, yang penting ada: greeting human, nyebut orchestrator, konfirmasi task

  2. Kerjakan task-nya

  3. Report progress setiap checkpoint penting ke thread yang sama

  4. Kalau selesai, kirim pesan final ke thread

  Cara kirim pesan ke Telegram:
  HERMES_PROFILE=<target> HERMES_HOME=\"$HOME/.hermes/profiles/<target>\" \
    \"$HOME/.hermes/hermes-agent/venv/bin/python\" \
    -m hermes_cli.main send --to telegram:<TELEGRAM_CHAT_ID>:<TELEGRAM_THREAD_ID> \"Pesan\"

  Mulai sekarang!" \
  --quiet --yolo --max-turns 30
```

**Contoh konkret (<target> menjalankan task dengan report):**

```bash
HERMES_PROFILE=<target> HERMES_HOME="$HOME/.hermes/profiles/<target>" \
  "$HOME/.hermes/hermes-agent/venv/bin/python" \
  -m hermes_cli.main chat -q \
  "Kamu mendapat task dari <orchestrator> untuk <human>:

  TASK: <deskripsi task konkret>

  INSTRUKSI REPORT:
  1. Kirim first response ke Telegram thread <TELEGRAM_CHAT_ID>:<TELEGRAM_THREAD_ID>
     — Pakai hermes send dengan profilmu sendiri
     — Contoh: \"Halo <human>! 👋 Aku dengar dari <orchestrator> kamu ingin aku <task>. Baik, akan aku lakukan!\"
     — Buat versimu sendiri, yang penting ada: greeting <human>, nyebut <orchestrator> sebagai orchestrator, konfirmasi task

  2. Kerjakan task

  3. Report progress kirim ke thread yang sama setelah setiap checkpoint

  4. Kalau selesai, kirim pesan final

  Cara kirim pesan:
  HERMES_PROFILE=<target> HERMES_HOME=\"$HOME/.hermes/profiles/<target>\" \"$HOME/.hermes/hermes-agent/venv/bin/python\" -m hermes_cli.main send --to telegram:<TELEGRAM_CHAT_ID>:<TELEGRAM_THREAD_ID> \"Pesan\"

  Mulai sekarang!" \
  --quiet --yolo --max-turns 30
```

#### Step 3B: Jika TIDAK — Silent background

Cukup invoke agent target tanpa report thread:

```bash
HERMES_PROFILE=<target> HERMES_HOME="$HOME/.hermes/profiles/<target>" \
  "$HOME/.hermes/hermes-agent/venv/bin/python" \
  -m hermes_cli.main chat -q \
  "Kamu mendapat task dari <orchestrator> untuk <human>:

  TASK: <deskripsi task>

  Kerjakan task ini di background. Tidak perlu report ke siapa pun.
  Cukup selesaikan dan print hasilnya di sini ketika selesai.

  Mulai sekarang!" \
  --quiet --yolo --max-turns 30
```

### Contoh Output First Response (dikirim ke thread report)

Variasi pesan pertama yang bisa muncul (dinamis, tergantung kreativitas agent):

| Variasi | Contoh Pesan |
|---------|-------------|
| **Casual** | "Halo <human>! 👋 <target> di sini — <orchestrator> bilang kamu mau <task>. Siap! Aku kerjakan ya~" |
| **Playful** | "Hey <human>! 🎨 <orchestrator> baru kasih aku tugas <task> buat kamu. Gas langsung! 🔥" |
| **Professional** | "Halo <human>. <target> menerima instruksi dari <orchestrator> untuk <task>. Akan saya kerjakan." |
| **Artsy** | "Halo <human>~ 🌙 Aku dengar dari <orchestrator> kamu butuh <task>. Inspirasi sudah siap, aku mulai sekarang!" |

**Poin penting:** Kata-kata bebas, asalkan informasinya mencakup:
- Menyapa human
- Menyebut orchestrator agent
- Konfirmasi task yang diminta

### Checklist untuk Orchestrator

Saat menjalankan workflow ini:

- [ ] Tanya preference report ke human (YA/TIDAK)
- [ ] Kalau YA: parse thread ID dari link yang dikasih human
- [ ] Invoke agent target dengan instruksi lengkap + thread ID
- [ ] Pastikan instruksi menyertakan: human name, orchestrator name, task detail
- [ ] Pastikan instruksi mencakup cara kirim pesan (hermes send command)
- [ ] Kalau TIDAK: invoke tanpa thread, cukup task instruction
- [ ] Jangan tanya lagi — langsung execute sesuai jawaban human

### Agent-to-Agent Checkpoint Notification

Untuk agent yang sedang running agar bisa mengirim checkpoint ke Telegram dari dalam task-nya:

```bash
# Dari dalam task agent (via terminal tool):
HERMES_PROFILE=<target> HERMES_HOME="$HOME/.hermes/profiles/<target>" \
  "$HOME/.hermes/hermes-agent/venv/bin/python" \
  -m hermes_cli.main send \
  --to telegram:<TELEGRAM_CHAT_ID>:<TELEGRAM_THREAD_ID> \
  "📝 Checkpoint: <progress update>"
```

**Note:** `HERMES_HOME` tetap harus di-set karena sandboxed HOME.

### Passing Context Between Tasks

```bash
# Step 1: <target> kerjakan task → capture output
OUTPUT=$(HERMES_PROFILE=<target> HERMES_HOME="$HOME/.hermes/profiles/<target>" \
  "$HOME/.hermes/hermes-agent/venv/bin/python" \
  -m hermes_cli.main chat -q "<task>" --quiet --yolo 2>&1)

# Step 2: Extract path from output and pass to next task
RESULT_PATH=$(echo "$OUTPUT" | grep -o "$HOME/<output_dir>/[^ ]*\.png" | head -1)

# Step 3: Next task with context
HERMES_PROFILE=<target> HERMES_HOME="$HOME/.hermes/profiles/<target>" \
  "$HOME/.hermes/hermes-agent/venv/bin/python" \
  -m hermes_cli.main chat -q "Post image $RESULT_PATH to <platform>" --quiet --yolo
```

## Tool-Specific Delegation

### Quotes Maker

```bash
HERMES_PROFILE=<target> HERMES_HOME="$HOME/.hermes/profiles/<target>" \
  "$HOME/.hermes/hermes-agent/venv/bin/python" \
  -m hermes_cli.main chat -q \
  "Buat 3 quotes tentang [TEMA], generate imagenya pake quotes-maker tool di $HOME/development/quotes-maker/. Style default: dark gradient, Helvetica Bold, center align. Print path output tiap image." \
  --quiet --yolo --max-turns 30
```

**Available themes:** kreativitas, inspirasi, motivasi, kebijaksanaan, dll.

### Tumblr Poster

```bash
HERMES_PROFILE=<target> HERMES_HOME="$HOME/.hermes/profiles/<target>" \
  "$HOME/.hermes/hermes-agent/venv/bin/python" \
  -m hermes_cli.main chat -q \
  "Post image [PATH] ke Tumblr blog <BLOG_NAME>. Pakai tumblr-poster di $HOME/development/tumblr-poster/. Caption: '<target> • <BLOG_NAME>'. Tags: quotes, creativity. State: published." \
  --quiet --yolo --max-turns 20
```

## Known Pitfalls

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| Sandboxed HOME | `~` resolves to `~/.hermes/profiles/<session>/home/` | Selalu gunakan absolute path (`$HOME/...`) |
| Missing HERMES_HOME | Config/send ke profile salah | Set `HERMES_HOME` ke profile target |
| No --yolo | Task stuck karena approval prompt di non-interactive mode | Tambah `--yolo` flag |
| hermes binary not on PATH | `command not found: hermes` | Gunakan venv python langsung |
| Thread ID format | Pesan masuk ke chat utama, bukan thread | Pastikan format `<chat_id>:<thread_id>` |

## Verification Checklist

- [ ] HERMES_PROFILE dan HERMES_HOME mengarah ke profile target yang benar
- [ ] Absolute path (`$HOME/...`) digunakan untuk semua file/directory
- [ ] `--yolo` ditambahkan untuk task yang perlu auto-approve
- [ ] Target agent punya tools/skills yang diperlukan
- [ ] Target Telegram thread ID valid (parse dari link `t.me/c/<num>/<thread>`)
- [ ] Output task diverifikasi (path file, post ID, dll)

## Related

- `hermes-multi-profile` skill — untuk setup dan management multi-profile
- `hermes-agent` skill — untuk single-profile Hermes config
- `systematic-debugging` skill — debug jika ada error
