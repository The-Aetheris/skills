#!/bin/bash
# safe-git.sh — Wrapper untuk operasi Git yang aman
# Memastikan semua aturan GitHub Operations terpenuhi sebelum operasi Git
#
# Usage:
#   safe-git.sh setup              — Terapkan konfigurasi Xenna ke repo ini
#   safe-git.sh commit "msg" f1 f2 — Commit dengan verifikasi identitas
#   safe-git.sh push               — Push (tanpa force), cek remote + identitas
#   safe-git.sh status|log|diff    — Git commands biasa
#
# Untuk agent: SELALU gunakan script ini, jangan git commit/push langsung.

set -euo pipefail

REQUIRED_USER="Xenna"
REQUIRED_EMAIL="xennatheaetheris@gmail.com"
REQUIRED_KEY="${HOME}/.ssh/id_ed25519_xenna.pub"
ALLOWED_SIGNERS="${HOME}/.ssh/allowed_signers"

# ── Colors ──────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

# ── check_identity ──────────────────────────────────
check_identity() {
    local current_name current_email current_key current_gpgsign current_gpgfmt
    current_name=$(git config user.name 2>/dev/null || echo "")
    current_email=$(git config user.email 2>/dev/null || echo "")
    current_key=$(git config user.signingkey 2>/dev/null || echo "")
    current_gpgsign=$(git config commit.gpgsign 2>/dev/null || echo "false")
    current_gpgfmt=$(git config gpg.format 2>/dev/null || echo "")

    local ok=true

    if [ "$current_name" != "$REQUIRED_USER" ]; then
        echo -e "${RED}❌ user.name harus '$REQUIRED_USER'${NC}, saat ini: '$current_name'"
        echo "   Fix: git config user.name \"$REQUIRED_USER\""
        ok=false
    fi

    if [ "$current_email" != "$REQUIRED_EMAIL" ]; then
        echo -e "${RED}❌ user.email harus '$REQUIRED_EMAIL'${NC}, saat ini: '$current_email'"
        echo "   Fix: git config user.email \"$REQUIRED_EMAIL\""
        ok=false
    fi

    if [ -n "$current_key" ] && [ "$current_key" != "$REQUIRED_KEY" ]; then
        echo -e "${RED}❌ user.signingkey harus '$REQUIRED_KEY'${NC}, saat ini: '$current_key'"
        echo "   Fix: git config user.signingkey \"$REQUIRED_KEY\""
        ok=false
    fi

    if [ "$current_gpgsign" != "true" ]; then
        echo -e "${RED}❌ commit.gpgsign harus 'true'${NC}"
        echo "   Fix: git config commit.gpgsign true"
        ok=false
    fi

    if [ -n "$current_gpgfmt" ] && [ "$current_gpgfmt" != "ssh" ]; then
        echo -e "${RED}❌ gpg.format harus 'ssh'${NC}, saat ini: '$current_gpgfmt'"
        echo "   Fix: git config gpg.format ssh"
        ok=false
    fi

    if [ "$ok" = false ]; then
        echo ""
        echo -e "${YELLOW}💡 Jalankan 'safe-git.sh setup' untuk auto-konfigurasi${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Identitas: $REQUIRED_USER <$REQUIRED_EMAIL>${NC}"
    return 0
}

# ── check_remote ────────────────────────────────────
check_remote() {
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")

    if [ -z "$remote_url" ]; then
        echo -e "${YELLOW}⚠️  Tidak ada remote 'origin', skip pengecekan${NC}"
        return 0
    fi

    if [[ ! "$remote_url" =~ github-xenna ]]; then
        echo -e "${RED}❌ Remote harus menggunakan 'github-xenna'${NC}"
        echo "   Saat ini: $remote_url"
        echo "   Fix: git remote set-url origin git@github-xenna:The-Aetheris/<repo>.git"
        return 1
    fi

    echo -e "${GREEN}✅ Remote: $remote_url${NC}"
    return 0
}

# ── check_no_force ──────────────────────────────────
check_no_force() {
    for arg in "$@"; do
        if [[ "$arg" == "--force" || "$arg" == "-f" || "$arg" == "--force-with-lease" ]]; then
            echo -e "${RED}❌ FORCE PUSH DILARANG!${NC}"
            echo "   Gunakan git revert untuk mengembalikan perubahan."
            echo "   Jika benar-benar darurat, minta konfirmasi Athalla dulu."
            return 1
        fi
    done
    return 0
}

# ── check_signing_works ─────────────────────────────
check_signing_works() {
    if ! ssh-keygen -Y find-principals -f "$ALLOWED_SIGNERS" -s "$REQUIRED_KEY" >/dev/null 2>&1; then
        echo -e "${RED}❌ SSH key Xenna tidak ditemukan di allowed_signers${NC}"
        echo "   Path: $ALLOWED_SIGNERS"
        echo "   Key:  $REQUIRED_KEY"
        return 1
    fi
    return 0
}

# ── check_conventional_commit ───────────────────────
check_conventional_commit() {
    local msg="$1"
    # Conventional commit pattern: type(scope): description
    if [[ ! "$msg" =~ ^(feat|fix|docs|chore|refactor|style|test|ci|build|perf|revert)(\([a-zA-Z0-9_-]+\))?:.+ ]]; then
        echo -e "${YELLOW}⚠️  Commit message tidak mengikuti conventional commits format${NC}"
        echo "   Format: type(scope): description"
        echo "   Contoh: feat(skill): add github-operations guide"
        echo "   Types:  feat, fix, docs, chore, refactor, style, test, ci, build"
        echo ""
        echo -e "${YELLOW}   Lanjutkan? (y/N)${NC}"
        read -r answer
        if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
            echo "Dibatalkan."
            return 1
        fi
    fi
    echo -e "${GREEN}✅ Commit format valid${NC}"
    return 0
}

# ── check_secrets ───────────────────────────────────
check_secrets() {
    local secret_files=()
    for pattern in "*.env" "auth.json" "*.pem" "*.key" "*.token"; do
        while IFS= read -r file; do
            if [ -n "$file" ] && git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
                secret_files+=("$file")
            fi
        done < <(git diff --cached --name-only 2>/dev/null | grep -E "$pattern" || true)
    done

    if [ ${#secret_files[@]} -gt 0 ]; then
        echo -e "${RED}❌ TERDETEKSI POTENSI CREDENTIALS DI STAGING:${NC}"
        for f in "${secret_files[@]}"; do
            echo "   - $f"
        done
        echo ""
        echo -e "${YELLOW}   Unstage dengan: git restore --staged <file>${NC}"
        return 1
    fi
    return 0
}

# ── main ────────────────────────────────────────────
case "${1:-}" in
    setup)
        echo -e "${CYAN}🔧 Menerapkan konfigurasi Git untuk Xenna...${NC}"
        echo ""
        git config user.name "$REQUIRED_USER"
        git config user.email "$REQUIRED_EMAIL"
        git config user.signingkey "$REQUIRED_KEY"
        git config commit.gpgsign true
        git config gpg.format ssh
        git config gpg.ssh.allowedsignersfile "$ALLOWED_SIGNERS"
        echo -e "${GREEN}✅ Konfigurasi selesai!${NC}"
        echo ""
        git config --local --list | grep -E "user|commit|gpg" | sed 's/^/   /'
        echo ""
        echo -e "${YELLOW}⚠️  Pastikan remote menggunakan 'github-xenna':${NC}"
        git remote -v | sed 's/^/   /'
        ;;

    commit)
        if [ $# -lt 2 ]; then
            echo "Usage: safe-git.sh commit \"type(scope): description\" [files...]"
            exit 1
        fi
        local msg="$2"
        shift 2

        check_identity || exit 1
        check_signing_works || exit 1
        check_conventional_commit "$msg" || exit 1

        if [ $# -gt 0 ]; then
            echo -e "${CYAN}📦 Staging: $*${NC}"
            git add "$@"
        fi

        check_secrets || exit 1

        echo -e "${CYAN}📝 Commit: $msg${NC}"
        git commit -m "$msg"

        echo ""
        echo -e "${CYAN}🔐 Verifikasi signature:${NC}"
        git log --show-signature -1 --format="%C(yellow)%h%Creset %s %Cgreen%G?%Creset"
        ;;

    push)
        shift 2>/dev/null || true
        check_identity || exit 1
        check_remote || exit 1
        check_no_force "$@" || exit 1
        check_signing_works || exit 1

        echo -e "${CYAN}🚀 Push ke origin/main...${NC}"
        git push origin main "$@"
        echo -e "${GREEN}✅ Push berhasil${NC}"
        ;;

    status|log|diff|show|remote|branch|stash)
        git "$@"
        ;;

    check)
        echo -e "${CYAN}🔍 Verifikasi setup Git...${NC}"
        echo ""
        check_identity
        check_remote
        check_signing_works
        echo ""
        echo -e "${GREEN}✅ Semua pengecekan selesai${NC}"
        ;;

    *)
        echo "safe-git.sh — Git wrapper aman untuk agent The Aetheris"
        echo ""
        echo "Usage:"
        echo "  safe-git.sh setup              — Auto-konfigurasi Xenna di repo ini"
        echo "  safe-git.sh check              — Verifikasi semua aturan"
        echo "  safe-git.sh commit \"msg\" f... — Commit + verifikasi identitas + conventional format"
        echo "  safe-git.sh push               — Push aman (anti force-push)"
        echo "  safe-git.sh status|log|diff    — Git commands biasa"
        echo ""
        echo "Rules enforced:"
        echo "  1. SSH key Xenna (id_ed25519_xenna)"
        echo "  2. Identitas commit: Xenna <xennatheaetheris@gmail.com>"
        echo "  3. Verified commit (SSH signing)"
        echo "  4. NO force push"
        echo "  5. Conventional commits format"
        echo "  6. NO credentials in commits"
        exit 1
        ;;
esac
