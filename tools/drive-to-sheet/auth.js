const fs = require('fs');
const path = require('path');
const { google } = require('googleapis');

const CRED_PATH = process.env.GDRIVE_CREDENTIALS || 'C:/Users/giaos/.claude/credentials.json';
const TOKEN_PATH = process.env.GDRIVE_TOKEN || 'C:/Users/giaos/.claude/token.json';

function loadJson(p) {
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function getOAuthClient() {
  const cred = loadJson(CRED_PATH);
  const tok = loadJson(TOKEN_PATH);
  const cfg = cred.installed || cred.web;
  const client = new google.auth.OAuth2(cfg.client_id, cfg.client_secret, (cfg.redirect_uris && cfg.redirect_uris[0]) || 'http://localhost');
  client.setCredentials({
    access_token: tok.token || tok.access_token,
    refresh_token: tok.refresh_token,
    expiry_date: tok.expiry ? new Date(tok.expiry).getTime() : undefined,
    scope: (tok.scopes || []).join(' '),
    token_type: 'Bearer',
  });
  client.on('tokens', (t) => {
    const merged = { ...tok };
    if (t.access_token) merged.token = t.access_token;
    if (t.refresh_token) merged.refresh_token = t.refresh_token;
    if (t.expiry_date) merged.expiry = new Date(t.expiry_date).toISOString();
    try { fs.writeFileSync(TOKEN_PATH, JSON.stringify(merged, null, 2)); } catch (_) {}
  });
  return client;
}

function getClients() {
  const auth = getOAuthClient();
  return {
    auth,
    drive: google.drive({ version: 'v3', auth }),
    sheets: google.sheets({ version: 'v4', auth }),
  };
}

module.exports = { getClients };
