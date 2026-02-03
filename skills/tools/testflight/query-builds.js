#!/usr/bin/env node
const crypto = require('crypto');
const https = require('https');
const fs = require('fs');
const path = require('path');

const credentialsPath = path.join(process.env.HOME, '.config/testflight/credentials.env');
const credentials = fs.readFileSync(credentialsPath, 'utf8');
const keyId = credentials.match(/TESTFLIGHT_API_KEY_ID="([^"]+)"/)?.[1];
const issuerId = credentials.match(/TESTFLIGHT_ISSUER_ID="([^"]+)"/)?.[1];
const keyPath = path.join(process.env.HOME, `.appstoreconnect/private_keys/AuthKey_${keyId}.p8`);
const privateKey = fs.readFileSync(keyPath, 'utf8');

function base64url(data) {
  return Buffer.from(data).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

function makeJWT() {
  const header = { alg: 'ES256', kid: keyId, typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const payload = { iss: issuerId, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' };
  const headerEnc = base64url(JSON.stringify(header));
  const payloadEnc = base64url(JSON.stringify(payload));
  const msg = `${headerEnc}.${payloadEnc}`;
  const sign = crypto.createSign('SHA256');
  sign.update(msg);
  const sig = sign.sign({ key: privateKey, dsaEncoding: 'ieee-p1363' });
  return `${msg}.${sig.toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')}`;
}

function apiGet(endpoint) {
  return new Promise((resolve, reject) => {
    const jwt = makeJWT();
    const options = {
      hostname: 'api.appstoreconnect.apple.com',
      path: endpoint,
      method: 'GET',
      headers: { 'Authorization': `Bearer ${jwt}` }
    };
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    });
    req.on('error', reject);
    req.end();
  });
}

const apps = {
  'Pfizer': '6737364780',
  'GMP': '6757438008',
  'Orchestrator': '6754814714',
  'MediaServer': '6757471795'
};

async function main() {
  for (const [name, id] of Object.entries(apps)) {
    console.log(`\n=== ${name} (${id}) ===`);
    try {
      const result = await apiGet(`/v1/builds?filter[app]=${id}&sort=-uploadedDate&limit=5`);
      if (result.data && result.data.length > 0) {
        for (const b of result.data) {
          const a = b.attributes;
          console.log(`  Build ${a.version} - ${a.uploadedDate?.slice(0,10) || '?'} - ${a.processingState}`);
        }
      } else if (result.errors) {
        console.log('  Error:', result.errors[0]?.detail || JSON.stringify(result.errors));
      } else {
        console.log('  No builds found');
      }
    } catch (e) {
      console.log('  Error:', e.message);
    }
  }
}
main();
