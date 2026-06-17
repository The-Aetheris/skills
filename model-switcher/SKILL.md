# Model Switcher Skill

**Category:** System Administration & Hermes Agent Management

## Overview

Skill untuk switching provider dan model di Hermes Agent. Berguna saat agent butuh berpindah antara high-reasoning (tugas kompleks), medium-reasoning (tugas standar), atau low-reasoning (tugas cepat).

## Trigger Conditions

Gunakan skill ini saat:
- Sistem error karena model tidak tersedia
- Perlu reasoning yang lebih tinggi/rendah sesua kompleksitas tugas
- Provider (custom, deepseek, 9router) perlu diganti
- Model configuration terlalu lambat/tidak optimal

## Commands & Usage

### 1. Check Current Configuration
```bash
# Lihat model & provider aktif
hermes model show

# Lihat semua model & provider tersedia
hermes model list
```

### 2. Switch Thinking Level
```bash
# High thinking (untuk tugas kompleks, analisis mendalam)
hermes model high-thinking

# Medium thinking (untuk tugas standar, balanced)
hermes model medium-thinking

# Low thinking (untuk tugas cepat, execution bias)
hermes model low-thinking
```

### 3. Switch Provider
```bash
# Custom provider (default, local atau remote custom setup)
hermes provider custom

# Deepseek provider (jika tersedia)
hermes provider deepseek

# 9router provider (glm-5.2 routing)
hermes provider 9router
```

### 4. Combined Switch
```bash
# Switch ke high-thinking via 9router
hermes model high-thinking --provider 9router
```

## What Gets Changed

### Files Modified
1. **config.yaml** - Baris `model.default` dan `provider.base_url`
2. **SOUL.md** - Tidak berubah (agent identity)
3. **Memory** - Tidak berubah (persistent data)

### Provider URLs & Model Mapping

| Provider | Base URL | Model Notes |
|---|---|---|
| **custom** | `http://localhost:20128/v1` | default routing, semua model tersedia |
| **9router** | `http://localhost:20128/v1` | routing via 9router (glm-5.2) |
| **deepseek** | `https://api.deepseek.com/v1` | jika ada akses ke API |

### Model Behavior
- **high-thinking**: Kompleks reasoning, 3-5k tokens/context, analisis mendalam
- **medium-thinking**: Balanced reasoning, trade-off antara speed & depth
- **low-thinking**: Execution bias, 1-2k tokens/context, response cepat

## Critical Note: Session Restart Required

**WAJIB BACA:** Perubahan model/provider hanya berlaku untuk **session baru**.

```bash
# Setelah mengganti model, WAJIB mulai session baru:
/new

# Atau restart gateway:
hermes gateway restart
```

**Mengapa session baru diperlukan?**
- Prompt caching berdasarkan model yang aktif
- Token size berbeda antara model
- Provider connection setup di session initialization
- System prompt optimize per model level

## Troubleshooting

### Model Not Available Error
```bash
# Periksa model tersedia
hermes model list

# Coba fallback ke custom provider
hermes model high-thinking --provider custom
```

### Provider Connection Issues
```bash
# Test koneksi custom provider
curl -I http://localhost:20128/v1/models

# Restart 9router service jika perlu
pkill -f 9router && nohup 9router &
```

### Gateway Not Recognizing Changes
```bash
# Force restart gateway
hermes gateway restart

# Atau restart manual:
pkill -f hermes-gateway
cd ~/.hermes/profiles/[PROFILE_NAME] && hermes gateway run
```

## Examples

### Case 1: Debug Complex Error (Use High-Thinking)
```bash
hermes model high-thinking
/new
# Sekarang lakukan debugging yang kompleks
```

### Case 2: Quick Task Execution (Use Low-Thinking)
```bash
hermes model low-thinking
/new
# Sekarang eksekusi task yang sederhana
```

### Case 3: Switch ke 9router Provider
```bash
hermes provider 9router
hermes model medium-thinking
/new
# Sekarang menggunakan routing via 9router
```

## Who Can Use This

- **Xenna** (manager): Cross-profile switching, debugging system issues
- **Nooku** (engineer): Technical research, coding, debugging complex issues
- **Naaza** (creative): Content creation, brainstorming (biasanya medium/low thinking)

## Safety Rules

1. **Jangan ganti model di tengah session kompleks** - risk token mismatch
2. **Selalu cek `hermes model show` setelah switch** - konfirmasi perubahan
3. **Gunakan `/new` atau restart gateway** - mandatory untuk perubahan
4. **Backup config.yaml jika experimental** - bisa restore jika broken

---

*Skill dibuat untuk koordinasi agent collective The Aetheris. Semua perubahan harus dilakukan dengan penuh perhatian pada konsistensi sistem.*