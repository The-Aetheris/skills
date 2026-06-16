/**
 * config.template.js — Token storage for Fomo.id API
 *
 * Copy this file to config.js and fill in your token:
 *   cp config.template.js config.js
 *
 * Token adalah kode portal Fomo.id (format: <userId>:<base64string>).
 * Dikirim sebagai: Authorization: Basic <token>
 *
 * JANGAN commit config.js ke repo — sudah di .gitignore.
 */

const FOMO_CONFIG = {
  // Auth token (kode portal). Ganti dengan token kamu.
  // token: "<userId>:<base64string>",
  token: null,

  // Base URL untuk Fomo API
  baseUrl: "https://fomo.azurewebsites.net",

  // Default headers
  headers() {
    return {
      Authorization: `Basic ${this.token}`,
      "Content-Type": "application/json",
    };
  },
};

module.exports = { FOMO_CONFIG };
