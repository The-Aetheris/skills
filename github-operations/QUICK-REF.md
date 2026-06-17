# GitHub Operations — Quick Reference

## 🚀 Sebelum operasi Git APAPUN

```bash
# 1. Setup konfigurasi (cukup sekali per repo)
./safe-git.sh setup

# 2. Verifikasi semua aturan terpenuhi
./safe-git.sh check
```

## 📝 Commit

```bash
# Format: safe-git.sh commit "type(scope): description" file1 file2 ...
./safe-git.sh commit "feat(skill): add github-operations guide" SKILL.md safe-git.sh
```

## 📤 Push

```bash
# Push aman (otomatis cek identitas + remote + anti-force)
./safe-git.sh push
```

## 🔍 Cek Status

```bash
./safe-git.sh status
./safe-git.sh log --oneline -5
./safe-git.sh diff
```

## ⚡ Fix Cepat

| Masalah | Solusi |
|---|---|
| Commit pakai identitas Athalla | `./safe-git.sh setup` |
| Remote salah (github.com) | `git remote set-url origin git@github-xenna:The-Aetheris/<repo>.git` |
| Commit tidak verified | `git config user.signingkey "~/.ssh/id_ed25519_xenna.pub"` |
| Mau push tapi ada force flag | **JANGAN.** Gunakan `git revert` |

## 🏷️ Conventional Commit Types

```
feat     → Fitur baru
fix      → Bug fix
docs     → Dokumentasi
chore    → Maintenance
refactor → Ubah struktur kode
style    → Formatting
test     → Test
ci       → CI/CD
build    → Build system
```

## 🔑 Identitas yang Benar

```
user.name:       Xenna
user.email:      xennatheaetheris@gmail.com
user.signingkey: ~/.ssh/id_ed25519_xenna.pub
commit.gpgsign:  true
gpg.format:      ssh
remote.origin:   git@github-xenna:The-Aetheris/<repo>.git
```
