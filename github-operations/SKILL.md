# GitHub Operations

**Category:** System Administration · Version Control
**For:** All agents (Xenna, Nooku, Naaza)

## Overview

Skill ini menjelaskan cara melakukan operasi Git/GitHub yang benar untuk seluruh agent di The Aetheris. Setiap agent **WAJIB** mengikuti aturan ini saat commit, push, pull, atau operasi Git lainnya.

> **Masalah yang sering terjadi:** Agent commit menggunakan identitas Athalla Rizky (`athallarizk@gmail.com`) dengan SSH key pribadi Athalla. Ini **SALAH**. Semua agent harus commit menggunakan identitas Xenna dengan key `id_ed25519_xenna`.

---

## 🔑 Aturan Wajib (Non-Negotiable)

### 1. Gunakan SSH Key Xenna

Semua repo The Aetheris menggunakan remote **`github-xenna`**, bukan `github.com`.

| Host | SSH Key | Pemilik |
|---|---|---|
| `github-xenna` | `~/.ssh/id_ed25519_xenna` | **Xenna (The Aetheris)** |
| `github.com` | `~/.ssh/id_ed25519` | Athalla Rizky (pribadi) |

```bash
# ✅ BENAR — remote menggunakan github-xenna
git remote -v
# origin  git@github-xenna:The-Aetheris/hermes-core.git

# ❌ SALAH — jangan gunakan github.com untuk repo The Aetheris
git remote -v
# origin  git@github.com:The-Aetheris/hermes-core.git
```

**Cara fix remote yang salah:**
```bash
git remote set-url origin git@github-xenna:The-Aetheris/<nama-repo>.git
```

### 2. Gunakan Identitas Xenna untuk Commit

Semua commit harus menggunakan nama & email Xenna, **bukan** Athalla.

```bash
# ✅ BENAR
git config user.name "Xenna"
git config user.email "xennatheaetheris@gmail.com"

# ❌ SALAH — identitas Athalla
git config user.name "Athalla Rizky"
git config user.email "athallarizk@gmail.com"
```

### 3. Commit Harus Terverifikasi (Verified)

Semua commit **WAJIB** signed menggunakan SSH key Xenna (`id_ed25519_xenna`).

```bash
# Cek apakah commit terverifikasi
git config commit.gpgsign     # harus "true"
git config user.signingkey    # harus mengarah ke id_ed25519_xenna.pub
git config gpg.format         # harus "ssh"
```

Hasil di GitHub harus menunjukkan badge **"Verified"** — bukan "Unverified" atau tanpa badge sama sekali.

### 4. DILARANG Force Push

```bash
# ❌ JANGAN PERNAH
git push --force
git push -f

# ❌ JANGAN PERNAH kecuali situasi darurat + konfirmasi eksplisit
git push --force-with-lease
```

Melakukan force push akan **menghancurkan history** dan berpotensi menghilangkan commit orang lain. Jika history perlu diubah, gunakan `git revert`.

### 5. Gunakan Conventional Commits

Format commit message **WAJIB** mengikuti [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]
```

| Type | Kapan Digunakan |
|---|---|
| `feat` | Fitur baru |
| `fix` | Bug fix |
| `docs` | Dokumentasi |
| `chore` | Maintenance, backup, rutinitas |
| `refactor` | Ubah kode tanpa ubah behavior |
| `style` | Format, whitespace, dll |
| `test` | Tambah/perbaiki test |
| `ci` | CI/CD pipeline |
| `build` | Build system |

**Contoh:**
```bash
# ✅ BENAR
feat(bookmark): add LockedIn AI - real-time interview copilot
fix(model): resolve high-thinking routing to glm-5.2
docs(readme): add agent profile pictures
chore(backup): daily profile backup - 2026-06-17

# ❌ SALAH
update stuff
fix bug
wip
asdf
```

### 6. JANGAN Commit Credentials / Secrets

File-file ini **WAJIB** ada di `.gitignore` dan **TIDAK BOLEH** di-commit:

| File | Alasan |
|---|---|
| `.env` | API keys, tokens |
| `auth.json` | OAuth tokens |
| `gateway.pid` | Runtime state |
| `state.db` / `state.db-*` | Session database |
| `*.log` | Log files |
| `audio_cache/` | Generated audio |
| `image_cache/` | Cached images |
| `sandboxes/` | Sandbox environments |
| `sessions/` | Chat session data |
| `*.pem`, `*.key` | Private keys |

---

## 🛠️ Set Up Git Config per Repo

### Untuk Xenna Profile (`xenna-core`)

```bash
cd ~/.hermes/profiles/xenna
git config user.name "Xenna"
git config user.email "xennatheaetheris@gmail.com"
git config user.signingkey "~/.ssh/id_ed25519_xenna.pub"
git config commit.gpgsign true
git config gpg.format ssh
```

### Untuk Hermes Core Vault (`hermes-core`)

```bash
cd ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/hermes-core
git config user.name "Xenna"
git config user.email "xennatheaetheris@gmail.com"
git config user.signingkey "~/.ssh/id_ed25519_xenna.pub"
git config commit.gpgsign true
git config gpg.format ssh
```

### Untuk Repo Development (`skills`, `.github`, dll)

```bash
cd ~/development/skills   # atau repo development lainnya
git config user.name "Xenna"
git config user.email "xennatheaetheris@gmail.com"
git config user.signingkey "~/.ssh/id_ed25519_xenna.pub"
git config commit.gpgsign true
git config gpg.format ssh
```

---

## 📋 Workflow Commit & Push yang Benar

```bash
# 1. Pastikan identitas Xenna
git config user.name   # harus: Xenna
git config user.email  # harus: xennatheaetheris@gmail.com

# 2. Cek status
git status

# 3. Stage files dengan hati-hati — JANGAN git add -A / git add . sembarangan
git add SOUL.md config.yaml skills/

# 4. Commit dengan format conventional
git commit -m "feat(skill): add github-operations guide"

# 5. Verifikasi commit signed
git log --show-signature -1
# Harus muncul: Good "git" signature with ED25519 key ...

# 6. Push (pastikan remote github-xenna)
git push origin main
```

---

## 🛡️ Script Wrapper: `safe-git.sh`

Gunakan script ini untuk memastikan semua aturan terpenuhi sebelum push.

```bash
#!/bin/bash
# safe-git.sh — Wrapper untuk operasi Git yang aman
# Usage: safe-git.sh commit "feat(scope): description" file1 file2 ...
#        safe-git.sh push
#        safe-git.sh status

set -euo pipefail

REQUIRED_USER="Xenna"
REQUIRED_EMAIL="xennatheaetheris@gmail.com"
REQUIRED_KEY="~/.ssh/id_ed25519_xenna.pub"
BANNED_FLAGS="--force|-f"

# Fungsi: pastikan identitas Xenna
check_identity() {
    local current_name current_email current_key
    current_name=$(git config user.name 2>/dev/null || echo "")
    current_email=$(git config user.email 2>/dev/null || echo "")
    current_key=$(git config user.signingkey 2>/dev/null || echo "")

    if [ "$current_name" != "$REQUIRED_USER" ]; then
        echo "❌ user.name harus '$REQUIRED_USER', saat ini: '$current_name'"
        echo "   Fix: git config user.name \"$REQUIRED_USER\""
        exit 1
    fi

    if [ "$current_email" != "$REQUIRED_EMAIL" ]; then
        echo "❌ user.email harus '$REQUIRED_EMAIL', saat ini: '$current_email'"
        echo "   Fix: git config user.email \"$REQUIRED_EMAIL\""
        exit 1
    fi

    if [ "$current_key" != "$REQUIRED_KEY" ]; then
        echo "❌ user.signingkey harus '$REQUIRED_KEY', saat ini: '$current_key'"
        echo "   Fix: git config user.signingkey \"$REQUIRED_KEY\""
        exit 1
    fi

    local gpgsign
    gpgsign=$(git config commit.gpgsign 2>/dev/null || echo "false")
    if [ "$gpgsign" != "true" ]; then
        echo "❌ commit.gpgsign harus 'true'"
        echo "   Fix: git config commit.gpgsign true"
        exit 1
    fi

    echo "✅ Identitas Xenna terverifikasi"
}

# Fungsi: cek remote menggunakan github-xenna
check_remote() {
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")

    if [ -z "$remote_url" ]; then
        echo "❌ Tidak ada remote 'origin'"
        exit 1
    fi

    if [[ ! "$remote_url" =~ github-xenna ]]; then
        echo "❌ Remote harus menggunakan 'github-xenna', saat ini: $remote_url"
        echo "   Fix: git remote set-url origin git@github-xenna:The-Aetheris/<repo>.git"
        exit 1
    fi

    echo "✅ Remote github-xenna terverifikasi: $remote_url"
}

# Fungsi: cek tidak ada force flag
check_no_force() {
    for arg in "$@"; do
        if [[ "$arg" == "--force" || "$arg" == "-f" || "$arg" == "--force-with-lease" ]]; then
            echo "❌ FORCE PUSH DILARANG. Gunakan git revert untuk mengembalikan perubahan."
            exit 1
        fi
    done
}

# Eksekusi perintah
case "${1:-}" in
    commit)
        check_identity
        shift
        git add "${@:2}"
        git commit -m "$1"
        git log --show-signature -1
        ;;
    push)
        check_identity
        check_remote
        check_no_force "${@:2}"
        git push origin main
        ;;
    setup)
        echo "🔧 Menerapkan konfigurasi Git untuk Xenna..."
        git config user.name "$REQUIRED_USER"
        git config user.email "$REQUIRED_EMAIL"
        git config user.signingkey "$REQUIRED_KEY"
        git config commit.gpgsign true
        git config gpg.format ssh
        echo "✅ Konfigurasi selesai"
        git config --local --list | grep -E "user|commit|gpg"
        ;;
    status|log|diff|show|remote)
        git "$@"
        ;;
    *)
        echo "Usage: safe-git.sh {commit|push|setup|status|log|diff}"
        echo ""
        echo "  setup    — Terapkan semua konfigurasi Xenna ke repo ini"
        echo "  commit   — Commit dengan verifikasi identitas"
        echo "  push     — Push dengan pengecekan remote + anti force-push"
        echo "  status   — Git status biasa"
        exit 1
        ;;
esac
```

---

## 🚨 Troubleshooting

### "Unverified" di GitHub
```bash
# Pastikan allowed_signers terdaftar
cat ~/.ssh/allowed_signers
# Harus ada: xennatheaetheris@gmail.com ssh-ed25519 AAAAC3NzaC...

# Pastikan signing key sesuai
git config user.signingkey
# Harus: ~/.ssh/id_ed25519_xenna.pub

# Test sign
echo "test" | ssh-keygen -Y sign -n git -f ~/.ssh/id_ed25519_xenna
```

### "Permission denied (publickey)" saat push
```bash
# Cek SSH key loaded
ssh-add -l | grep xenna

# Kalau tidak ada, tambahkan
ssh-add ~/.ssh/id_ed25519_xenna
```

### Commit muncul sebagai "Athalla Rizky"
```bash
# Ini terjadi karena ~/.gitconfig global override local config
# Solusi: set local config per repo
git config user.name "Xenna"
git config user.email "xennatheaetheris@gmail.com"
git config user.signingkey "~/.ssh/id_ed25519_xenna.pub"
```

---

## 📌 Ringkasan untuk Agent

| Aturan | Perintah Cek |
|---|---|
| SSH key Xenna | `git remote -v` harus `github-xenna` |
| Identitas Xenna | `git config user.name` harus `Xenna` |
| Verified commit | `git config commit.gpgsign` harus `true` |
| No force push | Jangan `--force` / `-f` |
| Conventional commit | `type(scope): description` |
| No credentials | `.env`, `auth.json` di `.gitignore` |

*Jika ragu, jalankan `safe-git.sh setup` terlebih dahulu sebelum operasi Git apapun.*
